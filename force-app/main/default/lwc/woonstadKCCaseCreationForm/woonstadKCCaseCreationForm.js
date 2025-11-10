/*************************************************************************************************
 * Component       : WoonstadKCCaseCreationForm (woonstadKCCaseCreationForm.js)
 * Layer           : UI Controller (Lightning Web Component)
 * Purpose         : Guided Case creation with record-type-aware picklists (Type & Origin)
 *                   resolved strictly by RecordType.DeveloperName IN ['Question','Vraag'].
 *                   Enhanced validation for all required fields including Contact and Description.
 *
 * Responsibilities:
 *  - Load picklists dynamically based on Question/Vraag Record Type
 *  - Manage form state for all Case creation fields
 *  - Perform comprehensive client-side validation before save
 *  - Filter and paginate related open Cases for context
 *  - Handle Flow navigation and toast notifications
 *
 * Security:
 *  - All data operations delegated to Apex with proper FLS/CRUD checks
 *  - Client-side validation only for UX; server-side validation remains primary
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-18
 * Last Modified   : 2025-09-18
 * ===============================================================================================
 * Change Log
 * -----------------------------------------------------------------------------------------------
 * 2025-09-18 | DvM | Fixed validation state clearing - fields now return to white when valid content is entered
 * 2025-09-18 | DvM | Enhanced validation to include Contact and Description as required fields
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

export default class WoonstadKCCaseCreationForm extends LightningElement {
  // ========= Flow IO =========
  
  /** @type {string} - Account Record Id provided by Flow (input) */
  @api recordId;
  
  /** @type {string} - Created Case Id returned to Flow (output) */
  @api caseId;

  // ========= Form State =========
  
  /** @type {string} - Case Subject entered by user */
  subject = '';
  
  /** @type {string} - Case Description entered by user */
  description = '';
  
  /** @type {string} - Selected Contact Id */
  contactId = '';
  
  /** @type {string} - Selected Case Type picklist value */
  caseType = '';
  
  /** @type {string} - Selected Case Origin picklist value */
  caseOrigin = '';

  // ========= Reference Data =========
  
  /** @type {Array<{label:string,value:string}>} - Contact picklist options */
  @track contactOptions = [];
  
  /** @type {string} - Account name for display purposes */
  @track accountName = '';

  // ========= UI State =========
  
  /** @type {boolean} - Loading state during save operation */
  isLoading = false;
  
  /** @type {string} - Validation error message displayed in banner */
  @track validationMessage = '';

  // ========= Right Column: Open Cases =========
  
  /** @type {Array} - All open Cases from Apex */
  @track allOpenCases = [];
  
  /** @type {Array} - Filtered list based on subject search */
  @track fullFilteredList = [];
  
  /** @type {Array} - Current page of filtered Cases for display */
  @track paginatedCases = [];
  
  /** @type {boolean} - Whether there are matching Cases to show */
  @track hasMatches = false;
  
  /** @type {number} - Timeout handle for subject search debouncing */
  searchTimeout;

  // ========= Pagination =========
  
  /** @type {number} - Current page number (1-based) */
  currentPage = 1;
  
  /** @type {number} - Number of Cases per page */
  pageSize = 6;
  
  /** @type {number} - Total number of pages */
  totalPages = 1;

  // ========= Picklists =========
  
  /** @type {Array<{label:string,value:string}>} - Case Type options from UI API */
  @track typeOptions = [];
  
  /** @type {Array<{label:string,value:string}>} - Case Origin options from UI API */
  @track originOptions = [];

  // ========= Record Type (DeveloperName match: 'Question' OR 'Vraag'; no fallback) =========
  
  /** @type {string} - Record Type Id for Question/Vraag type */
  questionRecordTypeId;

  /**
   * Wire to get Case object metadata and identify Question/Vraag Record Type.
   * This determines which picklist values are available for Type and Origin fields.
   */
  @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
  wiredCaseInfo({ data, error }) {
    if (data) {
      const infos = Object.values(data.recordTypeInfos || {});
      // DeveloperName is exposed as "name" in the record type info
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

  /**
   * Wire to get Case Type picklist values for the Question/Vraag Record Type.
   * Only loads when questionRecordTypeId is resolved to prevent wrong RT usage.
   */
  @wire(getPicklistValues, { recordTypeId: '$questionRecordTypeId', fieldApiName: TYPE_FIELD })
  wiredType({ data, error }) {
    if (data) {
      this.typeOptions = data.values.map(v => ({ label: v.label, value: v.value }));
      // Set default value if available and not already set
      if (!this.caseType && data.defaultValue) {
        this.caseType = data.defaultValue.value;
      }
    } else if (error && this.questionRecordTypeId) {
      this.showToast('Fout', 'Kon Case.Type (Question/Vraag RT) niet ophalen.', 'error');
    }
  }

  /**
   * Wire to get Case Origin picklist values for the Question/Vraag Record Type.
   * Only loads when questionRecordTypeId is resolved to prevent wrong RT usage.
   */
  @wire(getPicklistValues, { recordTypeId: '$questionRecordTypeId', fieldApiName: ORIGIN_FIELD })
  wiredOrigin({ data, error }) {
    if (data) {
      this.originOptions = data.values.map(v => ({ label: v.label, value: v.value }));
      // Set default value if available and not already set
      if (!this.caseOrigin && data.defaultValue) {
        this.caseOrigin = data.defaultValue.value;
      }
    } else if (error && this.questionRecordTypeId) {
      this.showToast('Fout', 'Kon Case.Herkomst (Question/Vraag RT) niet ophalen.', 'error');
    }
  }

  /**
   * Wire to get initial data including Account name and Contact options.
   * Loads based on the Account recordId from Flow.
   */
  @wire(getInitialData, { recordId: '$recordId' })
  wiredInitData({ error, data }) {
    if (data) {
      this.accountName = data.accountName;
      this.contactOptions = data.contactOptions || [];
    } else if (error) {
      this.showToast('Fout bij laden', 'Kon de contactgegevens niet ophalen.', 'error');
    }
  }

  /**
   * Wire to get open Cases for the Account to show contextual information.
   * Used for filtering and showing related Cases in the right column.
   */
  @wire(getOpenCases, { accountId: '$recordId' })
  wiredOpenCases({ error, data }) {
    if (data) {
      this.allOpenCases = Array.isArray(data) ? data : [];
    } else if (error) {
      this.showToast('Fout bij laden', 'Kon openstaande zaken niet ophalen.', 'error');
    }
  }

  // ========= Input Handlers =========

  /**
   * Clears validation errors from all form fields.
   * This method ensures that all fields return to their normal state when valid content is entered.
   */
  clearAllValidationErrors() {
    // Clear all field-level validation errors
    const allFields = this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');
    allFields.forEach(field => {
      field.setCustomValidity('');
      field.reportValidity();
    });
    
    // Clear the validation banner
    this.validationMessage = '';
  }

  /**
   * Handles Subject field changes with debounced Case filtering.
   * Clears validation message and field-level errors when user starts typing valid content.
   * @param {Event} e - Input event with the new value
   */
  handleSubjectKeyUp(e) {
    this.subject = e.target.value;
    
    // Clear validation state when user enters valid content
    if (this.subject && this.subject.trim()) {
      this.clearAllValidationErrors();
    }
    
    // Debounce the search to avoid excessive filtering
    clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => this.filterCases(), 300);
  }

  /**
   * Handles Description textarea changes.
   * Clears validation errors when user enters valid content.
   * @param {Event} e - Change event with the new value
   */
  handleDescriptionChange(e) { 
    this.description = e.target.value;
    
    // Clear validation state when user enters valid content
    if (this.description && this.description.trim()) {
      this.clearAllValidationErrors();
    }
  }

  /**
   * Handles Contact combobox selection.
   * Clears validation errors when user makes a valid selection.
   * @param {CustomEvent} e - Change event with selected Contact Id
   */
  handleContactChange(e) { 
    this.contactId = e.detail.value;
    
    // Clear validation state when user makes a valid selection
    if (this.contactId) {
      this.clearAllValidationErrors();
    }
  }

  /**
   * Handles Case Type combobox selection.
   * Clears validation errors when user makes a valid selection.
   * @param {CustomEvent} e - Change event with selected Type value
   */
  handleTypeChange(e) { 
    this.caseType = e.detail.value;
    
    // Clear validation state when user makes a valid selection
    if (this.caseType) {
      this.clearAllValidationErrors();
    }
  }

  /**
   * Handles Case Origin combobox selection.
   * Clears validation errors when user makes a valid selection.
   * @param {CustomEvent} e - Change event with selected Origin value
   */
  handleOriginChange(e) { 
    this.caseOrigin = e.detail.value;
    
    // Clear validation state when user makes a valid selection
    if (this.caseOrigin) {
      this.clearAllValidationErrors();
    }
  }

  // ========= Filter & Pagination =========

  /**
   * Filters open Cases based on Subject input using case-insensitive search.
   * Only filters when subject is longer than 2 characters to avoid too many results.
   * Resets pagination to page 1 when filter changes.
   */
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

  /**
   * Updates pagination state and slices the filtered list for current page display.
   */
  updatePagination() {
    this.totalPages = Math.max(1, Math.ceil(this.fullFilteredList.length / this.pageSize));
    const start = (this.currentPage - 1) * this.pageSize;
    this.paginatedCases = this.fullFilteredList.slice(start, start + this.pageSize);
  }

  /**
   * Handles pagination - goes to previous page if not already at first page.
   */
  handlePreviousPage() { 
    if (this.currentPage > 1) { 
      this.currentPage--; 
      this.updatePagination(); 
    } 
  }

  /**
   * Handles pagination - goes to next page if not already at last page.
   */
  handleNextPage() { 
    if (this.currentPage < this.totalPages) { 
      this.currentPage++; 
      this.updatePagination(); 
    } 
  }

  // ========= Pagination Getters =========

  /** @returns {boolean} Whether to show pagination controls */
  get showPagination() { 
    return this.totalPages > 1; 
  }

  /** @returns {boolean} Whether currently on first page */
  get isFirstPage() { 
    return this.currentPage === 1; 
  }

  /** @returns {boolean} Whether currently on last page */
  get isLastPage() { 
    return this.currentPage === this.totalPages; 
  }

  // ========= Actions =========

  /**
   * Handles save button click - validates form and creates Case via Apex.
   * On success: sets caseId and navigates to next Flow screen.
   * On error: shows toast with error message.
   */
  handleSave() {
    // Validate all required fields before proceeding
    if (!this.validateForm()) return;
    
    this.isLoading = true;
    
    createCase({
      accountId: this.recordId,
      contactId: this.contactId,
      subject: this.subject,
      description: this.description,
      caseType: this.caseType,
      caseOrigin: this.caseOrigin
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
      .finally(() => { 
        this.isLoading = false; 
      });
  }

  /**
   * Handles clicking on an open Case row - sets the Case ID and navigates to next screen.
   * This allows users to select an existing Case instead of creating a new one.
   * @param {Event} e - Click event with Case Id in dataset
   */
  handleRowClick(e) {
    this.caseId = e.currentTarget.dataset.id;
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  // ========= Validation =========

  /**
   * Comprehensive form validation for all required fields.
   * Validates both fields with data-required attribute and additional business-required fields.
   * Properly clears validation states for valid fields while setting errors for invalid ones.
   * Uses both Lightning component validation and custom business logic.
   * @returns {boolean} True if all validations pass, false otherwise
   */
  validateForm() {
    // First, validate fields marked with data-required="true" using Lightning validation
    const requiredDataFields = this.template.querySelectorAll(
      'lightning-input[data-required="true"], lightning-combobox[data-required="true"], lightning-textarea[data-required="true"]'
    );
    
    let allValid = true;
    const missingFields = [];

    // Check Lightning components with data-required attribute
    requiredDataFields.forEach(cmp => {
      const value = (cmp.value ?? '').toString().trim();
      if (!value) {
        allValid = false;
        cmp.setCustomValidity('Dit veld is verplicht.');
        
        // Collect field labels for summary message
        const label = cmp.label || cmp.name || 'Onbekend veld';
        missingFields.push(label);
      } else {
        // Clear validation for valid fields
        cmp.setCustomValidity('');
      }
      cmp.reportValidity();
    });

    // Additional business logic validation for non-data-required fields
    
    // Contact validation (business requirement)
    const contactField = this.template.querySelector('lightning-combobox[name="contact"]');
    if (!this.contactId || this.contactId.trim() === '') {
      allValid = false;
      missingFields.push('Contactpersoon');
      
      if (contactField) {
        contactField.setCustomValidity('Contactpersoon is verplicht.');
        contactField.reportValidity();
      }
    } else {
      // Clear validation if field is valid
      if (contactField) {
        contactField.setCustomValidity('');
        contactField.reportValidity();
      }
    }

    // Description validation (business requirement)  
    const descField = this.template.querySelector('lightning-textarea[label="Omschrijving"]');
    if (!this.description || this.description.trim() === '') {
      allValid = false;
      missingFields.push('Omschrijving');
      
      if (descField) {
        descField.setCustomValidity('Omschrijving is verplicht.');
        descField.reportValidity();
      }
    } else {
      // Clear validation if field is valid
      if (descField) {
        descField.setCustomValidity('');
        descField.reportValidity();
      }
    }

    // Set summary validation message
    if (!allValid) {
      if (missingFields.length === 1) {
        this.validationMessage = `${missingFields[0]} is verplicht.`;
      } else if (missingFields.length > 1) {
        this.validationMessage = `De volgende velden zijn verplicht: ${missingFields.join(', ')}.`;
      } else {
        this.validationMessage = 'Alle verplichte velden moeten ingevuld zijn.';
      }
    } else {
      // Clear validation message when all fields are valid
      this.validationMessage = '';
    }

    return allValid;
  }

  /**
   * Lifecycle hook that runs after the component renders.
   * Used to dynamically add asterisks to required field labels since CSS can't penetrate shadow DOM.
   */
  renderedCallback() {
    // Add asterisks to required fields dynamically
    this.addRequiredAsterisks();
  }

  /**
   * Adds red asterisks to required field labels by directly manipulating the DOM.
   * This is necessary because CSS cannot penetrate Lightning component shadow DOM boundaries.
   */
  addRequiredAsterisks() {
    const requiredFields = this.template.querySelectorAll('[data-required="true"]');
    
    requiredFields.forEach(field => {
      // Find the label element within the Lightning component
      const labelElement = field.querySelector('label.slds-form-element__label');
      
      if (labelElement && !labelElement.querySelector('.required-asterisk')) {
        // Create asterisk element
        const asterisk = document.createElement('span');
        asterisk.className = 'required-asterisk';
        asterisk.textContent = ' *';
        asterisk.style.color = '#e32';
        asterisk.style.fontWeight = 'bold';
        
        // Append asterisk to label
        labelElement.appendChild(asterisk);
      }
    });
  }

  /**
   * Shows a Lightning toast notification.
   * @param {string} title - Toast title
   * @param {string} message - Toast message body
   * @param {'success'|'info'|'warning'|'error'} variant - Toast styling variant
   */
  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  /**
   * Getter to determine if Question Record Type is resolved.
   * Used in template to conditionally enable/disable picklist fields.
   * @returns {boolean} True if Question/Vraag Record Type ID is available
   */
  get isQuestionRtResolved() { 
    return !!this.questionRecordTypeId; 
  }
}