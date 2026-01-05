/*************************************************************************************************
 * Component       : WoonstadKCCaseCreationForm (woonstadKCCaseCreationForm.js)
 * Layer           : UI Controller (Lightning Web Component)
 * Purpose         : Guided Case creation with record-type-aware picklists (Type & Origin)
 *                   resolved strictly by RecordType.DeveloperName IN ['Question','Vraag'].
 *                   No fallback to default RT (prevents showing wrong Type set).
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-18
 * Last Modified   : 2025-09-30
 * ===============================================================================================
 * Change Log
 * -----------------------------------------------------------------------------------------------
 * 2025-09-30 | DP  | Added Label field.
 * 2025-09-30 | DP  | Prefill Contact on form.
 * 2025-08-27 | DvM | Resolve RT by DeveloperName 'Question' OR 'Vraag'; picklists from that RT only.
 * 2025-08-27 | DvM | Dynamic picklists for Case.Type/Case.Origin via UI API.
 * 2025-08-25 | DvM | Deferred validation to Save only; pagination consistency.
 * 2025-08-18 | DvM | Initial version.
 *************************************************************************************************/

import { LightningElement, api, wire, track } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Apex
import getInitialData from '@salesforce/apex/woonstadKCCaseCreationFormController.getInitialData';
import getOpenCases from '@salesforce/apex/woonstadKCCaseCreationFormController.getOpenCases';
import createCase from '@salesforce/apex/woonstadKCCaseCreationFormController.createCase';

// UI API
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import TYPE_FIELD from '@salesforce/schema/Case.Type';
import ORIGIN_FIELD from '@salesforce/schema/Case.Origin';
import LABEL_FIELD from '@salesforce/schema/Case.Label__c';


export default class WoonstadKCCaseCreationForm extends LightningElement {
  // ---- Flow IO ----
  @api recordId;
  @api caseId;

  // ---- Form State ----
  subject = '';
  description = '';
  contactId = '';
  caseType = '';
  caseOrigin = '';
  caseLabel = '';

  // ---- Reference Data ----
  @track contactOptions = [];
  @track accountName = '';

  // ---- Guard so we only prefill once and never overwrite user choice ----
  prefilledContact = false; 

  // ---- UI State ----
  isLoading = false;
  @track validationMessage = '';

  // ---- Right Column: Open Cases ----
  @track allOpenCases = [];
  @track fullFilteredList = [];
  @track paginatedCases = [];
  @track hasMatches = false;
  searchTimeout;

  // ---- Pagination ----
  currentPage = 1;
  pageSize = 6;
  totalPages = 1;

  // ---- Picklists ----
  @track typeOptions = [];
  @track originOptions = [];
  @track labelOptions = [];

  // ---- Record Type (DeveloperName match: 'Question' OR 'Vraag'; no fallback) ----
  questionRecordTypeId;

  @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
  wiredCaseInfo({ data, error }) {
    if (data) {
      const infos = Object.values(data.recordTypeInfos || {});
      // DeveloperName is exposed as "name"
      const questionRT = infos.find(rti => rti?.name === 'Question' || rti?.name === 'Vraag');

      if (questionRT?.recordTypeId) {
        this.questionRecordTypeId = questionRT.recordTypeId;
      } else {
        this.questionRecordTypeId = null;
        this.showToast(
          'Configuratiefout',
          'Geen Recordtype met DeveloperName "Question" of "Vraag" gevonden op Case.',
          'error'
        );
      }
    } else if (error) {
      this.showToast('Fout', 'Kon Case recordtype-informatie niet ophalen.', 'error');
    }
  }

  // Only wire when the correct RT is resolved (prevents accidental default RT usage)
  @wire(getPicklistValues, { recordTypeId: '$questionRecordTypeId', fieldApiName: TYPE_FIELD })
  wiredType({ data, error }) {
    if (data) {
      this.typeOptions = data.values.map(v => ({ label: v.label, value: v.value }));
      if (!this.caseType && data.defaultValue) this.caseType = data.defaultValue.value;
    } else if (error && this.questionRecordTypeId) {
      this.showToast('Fout', 'Kon Case.Type (Question/Vraag RT) niet ophalen.', 'error');
    }
  }

  @wire(getPicklistValues, { recordTypeId: '$questionRecordTypeId', fieldApiName: ORIGIN_FIELD })
  wiredOrigin({ data, error }) {
    if (data) {
      this.originOptions = data.values.map(v => ({ label: v.label, value: v.value }));
      if (!this.caseOrigin && data.defaultValue) this.caseOrigin = data.defaultValue.value;
    } else if (error && this.questionRecordTypeId) {
      this.showToast('Fout', 'Kon Case.Herkomst (Question/Vraag RT) niet ophalen.', 'error');
    }
  }

  @wire(getPicklistValues, { recordTypeId: '$questionRecordTypeId', fieldApiName: LABEL_FIELD })
  wiredLabel({ data, error }) {
    if (data) {
      this.labelOptions = data.values.map(v => ({ label: v.label, value: v.value }));
      if (!this.caseLabel && data.defaultValue) this.caseLabel = data.defaultValue.value;
    } else if (error && this.questionRecordTypeId) {
      this.showToast('Fout', 'Kon Case.Label (Question/Vraag RT) niet ophalen.', 'error');
    }
  }

  // ---------- Data Loading (Apex) ----------
  @wire(getInitialData, { recordId: '$recordId' })
  wiredInitData({ error, data }) {
    if (data) {
      this.accountName = data.accountName;
      this.contactOptions = data.contactOptions || [];

      // Prefill Contact with the first option once, if none selected yet.
      // This preserves user changes and any Flow-provided default.
      if (!this.prefilledContact && !this.contactId && this.contactOptions.length > 0) {
        this.contactId = this.contactOptions[0].value;
        this.prefilledContact = true;
      }

      // Prefill Label once, only if empty, and only when server sent an allowed value
      if (!this.caseLabel && data.prefillLabel) {
        this.caseLabel = data.prefillLabel;
      }

    } else if (error) {
      this.showToast('Fout bij laden', 'Kon de contactgegevens niet ophalen.', 'error');
    }
  }

  @wire(getOpenCases, { accountId: '$recordId' })
  wiredOpenCases({ error, data }) {
    if (data) {
      this.allOpenCases = Array.isArray(data) ? data : [];
    } else if (error) {
      this.showToast('Fout bij laden', 'Kon openstaande zaken niet ophalen.', 'error');
    }
  }

  // ---- Handlers ----
  handleSubjectKeyUp(e) {
    this.subject = e.target.value;
    this.validationMessage = '';
    clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => this.filterCases(), 300);
  }
  handleDescriptionChange(e) { this.description = e.target.value; }
  handleContactChange(e) { this.contactId = e.detail.value; }
  handleTypeChange(e) { this.caseType = e.detail.value; }
  handleOriginChange(e) { this.caseOrigin = e.detail.value; }
  handleLabelChange(e) { this.caseLabel = e.detail.value; }

  // ---- Filter & Pagination ----
  filterCases() {
    const key = (this.subject || '').trim();
    if (key.length > 2) {
      const needle = key.toLowerCase();
      this.fullFilteredList = this.allOpenCases.filter(r =>
        r.Subject && r.Subject.toLowerCase().includes(needle)
      );
    } else {
      this.fullFilteredList = [];
    }
    this.hasMatches = this.fullFilteredList.length > 0;
    this.currentPage = 1;
    this.updatePagination();
  }
  updatePagination() {
    this.totalPages = Math.max(1, Math.ceil(this.fullFilteredList.length / this.pageSize));
    const start = (this.currentPage - 1) * this.pageSize;
    this.paginatedCases = this.fullFilteredList.slice(start, start + this.pageSize);
  }
  handlePreviousPage() { if (this.currentPage > 1) { this.currentPage--; this.updatePagination(); } }
  handleNextPage() { if (this.currentPage < this.totalPages) { this.currentPage++; this.updatePagination(); } }
  get showPagination() { return this.totalPages > 1; }
  get isFirstPage() { return this.currentPage === 1; }
  get isLastPage() { return this.currentPage === this.totalPages; }

  // ---- Save ----
  handleSave() {
    if (!this.validateForm()) return;
    this.isLoading = true;
    createCase({
      accountId: this.recordId,
      contactId: this.contactId,
      subject: this.subject,
      description: this.description,
      caseType: this.caseType,
      caseOrigin: this.caseOrigin,
      caseLabel: this.caseLabel
    })
      .then(id => {
        this.caseId = id;
        this.showToast('Success', 'Zaak succesvol aangemaakt.', 'success');
        this.dispatchEvent(new FlowNavigationNextEvent());
      })
      .catch(error => {
        const msg = (error && error.body && error.body.message) ? error.body.message : 'Onbekende fout';
        this.showToast('Fout bij opslaan', msg, 'error');
      })
      .finally(() => { this.isLoading = false; });
  }

  handleRowClick(e) {
    this.caseId = e.currentTarget.dataset.id;
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  // ---- Validation ----
  validateForm() {
    const inputs = this.template.querySelectorAll(
      'lightning-input[data-required="true"], lightning-combobox[data-required="true"], lightning-textarea[data-required="true"]'
    );
    let allValid = true;
    inputs.forEach(cmp => {
      const value = (cmp.value ?? '').toString().trim();
      if (!value) {
        allValid = false;
        cmp.setCustomValidity('Dit veld is verplicht.');
      } else {
        cmp.setCustomValidity('');
      }
      cmp.reportValidity();
    });
    this.validationMessage = allValid ? '' : 'Alle verplichte velden moeten ingevuld zijn.';
    return allValid;
  }

  // ---- Utility ----
  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  // Expose to HTML to disable picklists until RT is resolved
  get isQuestionRtResolved() { return !!this.questionRecordTypeId; }
}