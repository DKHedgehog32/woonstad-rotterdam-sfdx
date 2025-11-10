/*************************************************************************************************
 * Component       : woonstadNameplateForm
 * Purpose         : Flow screen with deferred validation using native Lightning validity APIs.
 * Approach        : setCustomValidity() + reportValidity() -> SLDS handles red borders/messages.
 *************************************************************************************************/

import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import getFirstSupplier from '@salesforce/apex/RealEstateSupplierFlowController.getFirstSupplier';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import NAMEPLATE_FIELD from '@salesforce/schema/Account.Nameplate__c';

const FIELDS = [NAME_FIELD, NAMEPLATE_FIELD];

export default class WoonstadNameplateForm extends LightningElement {
  // Flow I/O
  @api nameplateNameIn;
  @api reasonIn;
  @api supplierNameIn;
  @api supplierEmailIn;
  @api supplierNoteIn;

  @api nameplateName;
  @api reason;
  @api supplierName;
  @api supplierEmail;
  @api supplierNote;
  @api invalidVar;

  // State
  _recordId;
  @api
  get recordId() { return this._recordId; }
  set recordId(val) {
    this._recordId = val;
    if (this._recordId && !this.apexInitialized) {
      this.fetchSupplierFromApex();
    }
  }

  @track accountName;
  @track accountNameplate;
  @track showErrorMessage = false;

  @track supplierOptions = [];
  apexInitialized = false;

  reasonOptions = [
    { label: 'Vernield / gestolen', value: 'Vandalism/stolen' },
    { label: 'Nieuwe woning', value: 'New tenant' },
    { label: 'Veranderde samenstelling', value: 'New composition of residency' },
    { label: 'Verkeerde spelling', value: 'Incorrect name spelling' }
  ];

  noSupplierOption = { label: 'Geen leverancier gevonden', value: 'Geen leverancier gevonden', email: null };

  connectedCallback() {
    this.reasonOptions.sort((a, b) => a.label.localeCompare(b.label, 'nl-NL', { sensitivity: 'base' }));
    this.supplierOptions = [
      { label: "Keller's IJzerhandel B.V.", value: "Keller's IJzerhandel B.V.", email: 'denniskristoffers@icloud.com' },
      { label: 'Het Zuider Sleutelhuis B.V.', value: 'Het Zuider Sleutelhuis B.V.', email: 'denniskristoffers@gmail.com' },
      { label: 'IJzerhandel Overschie', value: 'IJzerhandel Overschie', email: 'denniskristoffers@icloud.com' },
      { label: 'Weijntjes Hang- en Sluitwerk', value: 'Weijntjes Hang- En Sluitwerk', email: 'dennis.kristoffers@cobracrm.nl' }
    ];
    if (this._recordId && !this.apexInitialized) {
      this.fetchSupplierFromApex();
    }
  }

  renderedCallback() {
    if (this.nameplateNameIn) this.nameplateName = this.nameplateNameIn;
    if (this.reasonIn) this.reason = this.reasonIn;
    if (this.supplierNoteIn) this.supplierNote = this.supplierNoteIn;
    if (this.supplierNameIn) this.applySupplier(this.supplierNameIn, this.supplierEmailIn);

    this.setInvalidVar(!this.isSupplierChosen());
  }

  @wire(getRecord, { recordId: '$_recordId', fields: FIELDS })
  wiredAccount({ data, error }) {
    if (error) return;
    if (data) {
      this.accountName = data.fields.Name.value;
      this.accountNameplate = data.fields.Nameplate__c.value;
    }
  }

  get accountNameSuggestion() {
    return this.accountNameplate || this.accountName;
  }

  // Apex
  async fetchSupplierFromApex() {
    if (!this._recordId) return;

    if (this.supplierNameIn) {
      this.applySupplier(this.supplierNameIn, this.supplierEmailIn || null);
      this.apexInitialized = true;
      return;
    }
    try {
      const data = await getFirstSupplier({ accountId: this._recordId });
      const nameFromApex = data ? data.supplierName : null;
      const emailFromApex = data ? data.supplierEmail : null;
      if (nameFromApex && nameFromApex !== this.noSupplierOption.value) {
        this.applySupplier(nameFromApex, emailFromApex || null);
      } else {
        this.applySupplier(this.noSupplierOption.value, null);
      }
    } catch {
      this.applySupplier(this.noSupplierOption.value, null);
    } finally {
      this.apexInitialized = true;
    }
  }

  applySupplier(name, email) {
    let exists = this.supplierOptions.find(o => o.value === name);
    if (!exists) {
      this.supplierOptions = [...this.supplierOptions, { label: name, value: name, email: email || null }];
      exists = this.supplierOptions.find(o => o.value === name);
    }
    this.supplierName = name;
    this.supplierEmail = email || (exists ? exists.email : null);

    this.dispatchEvent(new FlowAttributeChangeEvent('supplierName', this.supplierName));
    this.dispatchEvent(new FlowAttributeChangeEvent('supplierEmail', this.supplierEmail));

    this.setInvalidVar(!this.isSupplierChosen());
  }

  // Handlers
  handleNameChange(e) {
    this.nameplateName = (e.target.value || '').trim();
    this.dispatchEvent(new FlowAttributeChangeEvent('nameplateName', this.nameplateName));
    // Clear live error if banner shown
    if (this.showErrorMessage) this.clearFieldError('name');
  }

  handleSuggestionClick() {
    if (!this.nameplateName || this.nameplateName.trim() === '') {
      this.nameplateName = this.accountNameSuggestion;
      this.dispatchEvent(new FlowAttributeChangeEvent('nameplateName', this.nameplateName));
      if (this.showErrorMessage) this.clearFieldError('name');
    }
  }

  handleReasonChange(e) {
    this.reason = e.detail.value;
    this.dispatchEvent(new FlowAttributeChangeEvent('reason', this.reason));
    if (this.showErrorMessage) this.clearFieldError('reason');
  }

  handleSupplierChange(e) {
    const selectedName = e.detail.value;
    const selected = this.supplierOptions.find(s => s.value === selectedName);
    this.applySupplier(selectedName, selected ? selected.email : null);
    if (this.showErrorMessage) this.clearFieldError('supplier');
  }

  handleNoteChange(e) {
    this.supplierNote = (e.target.value || '').trim();
    this.dispatchEvent(new FlowAttributeChangeEvent('supplierNote', this.supplierNote));
  }

  // Validation (deferred)
  handleConfirm() {
    const nameEl = this.template.querySelector('lightning-input[data-field="name"]');
    const reasonEl = this.template.querySelector('lightning-combobox[data-field="reason"]');
    const supplierEl = this.template.querySelector('lightning-combobox[data-field="supplier"]');

    // Reset all
    this.resetFieldError(nameEl);
    this.resetFieldError(reasonEl);
    this.resetFieldError(supplierEl);

    // Validate
    let ok = true;

    if (!this.nameplateName || this.nameplateName.trim() === '') {
      nameEl.setCustomValidity('Vul de naam voor het naamplaatje in.');
      ok = false;
    }

    if (!this.reason) {
      reasonEl.setCustomValidity('Selecteer een reden.');
      ok = false;
    }

    if (!this.isSupplierChosen()) {
      supplierEl.setCustomValidity(
        this.supplierName === this.noSupplierOption.value
          ? 'Er is geen geldige leverancier gevonden. Kies een andere leverancier.'
          : 'Selecteer een leverancier.'
      );
      ok = false;
    }

    // Trigger native SLDS red borders/messages
    nameEl.reportValidity();
    reasonEl.reportValidity();
    supplierEl.reportValidity();

    this.showErrorMessage = !ok;
    this.setInvalidVar(!ok);

    if (ok) {
      this.dispatchEvent(new FlowNavigationNextEvent());
    }
  }

  isSupplierChosen() {
    return !!(
      this.supplierName &&
      this.supplierName.trim() !== '' &&
      this.supplierName !== this.noSupplierOption.value
    );
  }

  // Helpers for validity UI
  resetFieldError(el) {
    if (el) el.setCustomValidity('');
  }
  clearFieldError(fieldApi) {
    const el = this.template.querySelector(`[data-field="${fieldApi}"]`);
    if (!el) return;
    el.setCustomValidity('');
    el.reportValidity(); // clears red state instantly
  }

  @api
  validate() {
    // Flow external validation hook (kept simple)
    const isValid = !!(this.nameplateName && this.nameplateName.trim()) && !!this.reason && this.isSupplierChosen();
    this.setInvalidVar(!isValid);
    return { isValid };
  }

  setInvalidVar(value) {
    this.invalidVar = value;
    this.dispatchEvent(new FlowAttributeChangeEvent('invalidVar', this.invalidVar));
  }
}