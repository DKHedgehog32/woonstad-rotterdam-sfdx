/**
 * =============================================
 * Component       : woonstadLogACallForm
 * File            : woonstadLogACallForm.js
 * Purpose         : JS controller for the Woonstad "Log a Call" form LWC.
 * Responsibilities:
 *  - Manage local UI state (subject, comments, whoId, loading/error states)
 *  - Load case details and related contacts via Apex (@wire)
 *  - Emit Flow output attribute changes and navigate next on success
 *  - Perform comprehensive client-side validation for all required fields
 *  - Show user feedback (toasts and error banners)
 * Accessibility   :
 *  - Validation exposes clear error banner messages consumed by the template
 *  - Required field indicators in HTML template
 * Security        :
 *  - No FLS/DML here; all data ops are delegated to Apex
 * Dependencies    :
 *  - Apex: WoonstadLogACallFormController (getCaseDetails, getContactsByAccountId, logCall)
 *  - Static resource: WoonstadGlobalCSS (loaded once in renderedCallback)
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Last Modified   : 2025-09-18
 * =============================================
 * Change Log
 * ---------------------------------------------
 * 2025-09-18 | D. van Musschenbroek | Enhanced validation to include Contact and Comments as required fields
 * 2025-08-25 | D. van Musschenbroek | Standardized header, inline JSDoc, and sectioning. No functional changes.
 * 2025-08-20 | D. van Musschenbroek | Updated error message to be consistent with other forms.
 * 2025-08-17 | D. van Musschenbroek | Initial creation.
 * =============================================
 */

import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import { FlowNavigationNextEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';

import WoonstadGlobalCSS from '@salesforce/resourceUrl/WoonstadGlobalCSS';
import getCaseDetails from '@salesforce/apex/woonstadLogACallFormController.getCaseDetails';
import getContactsByAccountId from '@salesforce/apex/woonstadLogACallFormController.getContactsByAccountId';
import logCall from '@salesforce/apex/woonstadLogACallFormController.logCall';

export default class WoonstadLogACallForm extends LightningElement {
    // ========= Public API (Flow inputs/outputs) =========

    /** @type {string} - Case Id provided by Flow context (input). */
    @api caseId;

    /** @type {string} - Account Id used to query related Contacts (input). */
    @api accountId;

    /** @type {string} - Subject entered by user (output to Flow). */
    @api subject = '';

    /** @type {string} - Comments/description entered by user (output to Flow). */
    @api comments = '';

    /** @type {string} - Selected Contact Id ("Gemeld door") (output to Flow). */
    @api whoId;

    // ========= Internal reactive state =========

    /** @type {string} - Read-only display of the related Case for the UI. */
    caseDetails;

    /** @type {Array<{label:string,value:string}>} - Options for the Contact combobox. */
    contactOptions = [];

    /** @type {boolean} - Ensures global CSS loads only once. */
    stylesLoaded = false;

    /** @type {boolean} - Spinner/disabled state during save. */
    isLoading = false;

    // Error banner state
    /** @type {boolean} - Whether to show the error banner in the UI. */
    @track hasError = false;

    /** @type {string} - Error banner message. */
    @track errorMessage = '';

    // ========= Getters =========

    /**
     * Returns container classes for the subject input, highlighting when invalid.
     * @returns {string}
     */
    get subjectContainerClass() {
        return this.hasError ? 'form-input input-error' : 'form-input';
    }

    // ========= Wired Apex calls =========

    /**
     * Loads a human-readable Case display string.
     * Uses @wire to automatically refresh when caseId changes.
     * Handles errors gracefully by showing fallback text.
     */
    @wire(getCaseDetails, { caseId: '$caseId' })
    wiredCaseDetails({ error, data }) {
        if (data) {
            this.caseDetails = data;
        } else if (error) {
            // Keep console logging for troubleshooting while showing friendly UI text
            // (Details should be logged server-side for production).
            // eslint-disable-next-line no-console
            console.error('Error fetching case details:', error);
            this.caseDetails = 'Case niet gevonden';
        }
    }

    /**
     * Loads Contact picklist options scoped to the provided Account.
     * Uses @wire to automatically refresh when accountId changes.
     * Maps Contact records to combobox-compatible format.
     */
    @wire(getContactsByAccountId, { accountId: '$accountId' })
    wiredContacts({ error, data }) {
        if (data) {
            // Transform Contact records into combobox options
            this.contactOptions = data.map((contact) => ({
                label: contact.Name,
                value: contact.Id
            }));
        } else if (error) {
            // eslint-disable-next-line no-console
            console.error('Error fetching contacts:', error);
            this.contactOptions = [];
        }
    }

    // ========= Lifecycle =========

    /**
     * Loads the shared Woonstad global stylesheet once when the component renders.
     * Uses platformResourceLoader for safe, deferred loading.
     * Only loads CSS once to avoid multiple requests.
     */
    renderedCallback() {
        if (!this.stylesLoaded) {
            loadStyle(this, WoonstadGlobalCSS)
                .then(() => {
                    this.stylesLoaded = true;
                })
                .catch((error) => {
                    // eslint-disable-next-line no-console
                    console.error('Error loading WoonstadGlobalCSS', error);
                });
        }
    }

    // ========= Input field handlers =========

    /**
     * Handles updates to the Subject field and emits Flow attribute change.
     * Hides the error banner when the user starts typing again.
     * @param {CustomEvent} event - Input change event containing the new value
     */
    handleSubjectChange(event) {
        this.subject = event.target.value;
        // Emit the change to Flow so it can track this output variable
        this.dispatchEvent(new FlowAttributeChangeEvent('subject', this.subject));

        // Clear error state when user starts typing
        if (this.subject && this.subject.trim()) {
            this.hasError = false;
        }
    }

    /**
     * Handles updates to the Comments field and emits Flow attribute change.
     * Clears error state when user enters valid content.
     * @param {CustomEvent} event - Textarea change event containing the new value
     */
    handleCommentsChange(event) {
        this.comments = event.target.value;
        // Emit the change to Flow so it can track this output variable
        this.dispatchEvent(new FlowAttributeChangeEvent('comments', this.comments));

        // Clear error state when user starts typing
        if (this.comments && this.comments.trim()) {
            this.hasError = false;
        }
    }

    /**
     * Handles updates to the Contact combobox and emits Flow attribute change.
     * Clears error state when user makes a selection.
     * @param {CustomEvent} event - Combobox change event containing the selected Contact Id
     */
    handleContactChange(event) {
        this.whoId = event.detail.value;
        // Emit the change to Flow so it can track this output variable
        this.dispatchEvent(new FlowAttributeChangeEvent('whoId', this.whoId));

        // Clear error state when user makes a selection
        if (this.whoId) {
            this.hasError = false;
        }
    }

    // ========= Actions =========

    /**
     * Validates all required inputs and invokes Apex to log the call.
     * Shows comprehensive validation errors for missing fields.
     * On success: shows toast and navigates to the next Flow screen.
     * On failure: shows an error toast with the Apex message.
     */
    handleSave() {
        // Validate all required fields before proceeding
        if (!this.validateInput()) {
            return;
        }

        // Set loading state to disable button and show spinner
        this.isLoading = true;

        // Call Apex method to persist the data
        logCall({
            subject: this.subject,
            comments: this.comments,
            whoId: this.whoId,
            caseId: this.caseId
        })
            .then(() => {
                // Success: show positive feedback and move to next screen
                this.showToast('Succes', 'Gesprek succesvol geregistreerd!', 'success');
                this.dispatchEvent(new FlowNavigationNextEvent());
            })
            .catch((error) => {
                // Error: extract message from Apex exception and show to user
                const message = error?.body?.message || 'Onbekende fout bij opslaan.';
                this.showToast('Fout bij opslaan', message, 'error');
            })
            .finally(() => {
                // Always reset loading state regardless of success/failure
                this.isLoading = false;
            });
    }

    // ========= Helpers =========

    /**
     * Performs comprehensive required field validation for Subject, Contact, and Comments.
     * Checks for both null/undefined values and empty strings (whitespace-only).
     * Sets error banner with specific messaging about which fields are missing.
     * @returns {boolean} True if all required fields are valid; otherwise false.
     */
    validateInput() {
        const missingFields = [];
        
        // Check Subject field (trim to handle whitespace-only input)
        if (!this.subject || this.subject.trim() === '') {
            missingFields.push('Onderwerp');
        }
        
        // Check Contact selection
        if (!this.whoId) {
            missingFields.push('Gemeld door');
        }
        
        // Check Comments field (trim to handle whitespace-only input)
        if (!this.comments || this.comments.trim() === '') {
            missingFields.push('Opmerkingen');
        }
        
        // If any fields are missing, show specific error message
        if (missingFields.length > 0) {
            if (missingFields.length === 1) {
                // Single field missing: "Onderwerp is verplicht."
                this.errorMessage = `${missingFields[0]} is verplicht.`;
            } else {
                // Multiple fields missing: "De volgende velden zijn verplicht: Onderwerp, Gemeld door."
                this.errorMessage = `De volgende velden zijn verplicht: ${missingFields.join(', ')}.`;
            }
            this.hasError = true;
            return false;
        }
        
        // All validations passed - clear any previous errors
        this.hasError = false;
        this.errorMessage = '';
        return true;
    }

    /**
     * Shows a Lightning toast message with specified styling.
     * @param {string} title - Toast title (bold text)
     * @param {string} message - Toast body message
     * @param {'success'|'info'|'warning'|'error'} variant - Toast styling variant
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}