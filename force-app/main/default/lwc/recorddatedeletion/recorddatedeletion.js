/**
 * @description Lightning Web Component controller for deleting records by creation date
 * @author Dylan Pluk
 * @date december 2025
 */
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import WoonstadGlobalCSS from '@salesforce/resourceUrl/WoonstadGlobalCSS';
import getAvailableObjects from '@salesforce/apex/RecordDateDeletionController.getAvailableObjects';
import previewRecords from '@salesforce/apex/RecordDateDeletionController.previewRecords';
import deleteRecordsByDate from '@salesforce/apex/RecordDateDeletionController.deleteRecordsByDate';

export default class recordDateDeletion extends LightningElement {
    /**
     * @description The start date-time for filtering records
     * @type {String}
     */
    @track startDateTime;

    /**
     * @description The end date-time for filtering records
     * @type {String}
     */
    @track endDateTime;

    /**
     * @description Set of selected object API names
     * @type {Set<String>}
     */
    @track selectedObjects = new Set();

    /**
     * @description Record counts by object type
     * @type {Object}
     */
    @track recordCounts = {};

    /**
     * @description Loading state indicator
     * @type {Boolean}
     */
    @track isLoading = false;

    /**
     * @description Success message to display
     * @type {String}
     */
    @track successMessage = '';

    /**
     * @description Error message to display
     * @type {String}
     */
    @track errorMessage = '';

    /**
     * @description List of available objects from Custom Metadata
     * @type {Array}
     */
    @track availableObjects = [];

    /**
     * @description Map to track checkbox states dynamically
     * @type {Map}
     */
    checkboxStates = new Map();

    /**
     * @description List of deletion errors with details
     * @type {Array}
     */
    @track deletionErrors = [];

    /**
     * @description Flag to track if CSS has been loaded
     * @type {Boolean}
     */
    cssLoaded = false;

    /**
     * @description Load Woonstad Global CSS on component initialization
     */
    connectedCallback() {
        if (!this.cssLoaded) {
            loadStyle(this, WoonstadGlobalCSS)
                .then(() => {
                    this.cssLoaded = true;
                })
                .catch(error => {
                    console.error('Error loading WoonstadGlobalCSS:', error);
                });
        }
    }

    /**
     * @description Wire service to get available objects from Custom Metadata
     * @param {Object} result - The wire service result
     */
    @wire(getAvailableObjects)
    wiredAvailableObjects({ error, data }) {
        if (data) {
            this.availableObjects = data.map(obj => ({
                apiName: obj.apiName,
                displayLabel: obj.displayLabel,
                deletionOrder: obj.deletionOrder,
                isChecked: false
            }));
            this.error = undefined;
        } else if (error) {
            this.errorMessage = 'Fout bij het laden van beschikbare objecten: ' + this.getErrorMessage(error);
            this.showToast('Fout', this.errorMessage, 'error');
            this.availableObjects = [];
        }
    }

    /**
     * @description Computed property to determine if deletion errors should be shown
     * @returns {Boolean} True if deletion errors exist
     */
    get showDeletionErrors() {
        return this.deletionErrors && this.deletionErrors.length > 0;
    }

    /**
     * @description Computed property to get current datetime in ISO format for max attribute
     * @returns {String} Current datetime in ISO format
     */
    get currentDateTime() {
        // Return current datetime in ISO format (YYYY-MM-DDTHH:mm)
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        return `${year}-${month}-${day}T${hours}:${minutes}`;
    }

    /**
     * @description Computed property to build summary items array for template iteration
     * @returns {Array} Array of objects with displayLabel, apiName, and count
     */
    get summaryItems() {
        if (!this.availableObjects || Object.keys(this.recordCounts).length === 0) {
            return [];
        }

        return this.availableObjects
            .filter(obj => this.recordCounts[obj.apiName] > 0)
            .map(obj => ({
                apiName: obj.apiName,
                displayLabel: obj.displayLabel,
                count: this.recordCounts[obj.apiName]
            }));
    }

    /**
     * @description Computed property to determine if summary should be shown
     * @returns {Boolean} True if record counts exist
     */
    get showSummary() {
        return Object.keys(this.recordCounts).length > 0;
    }

    /**
     * @description Computed property to disable preview button
     * @returns {Boolean} True if datetime range or objects not selected
     */
    get isPreviewDisabled() {
        return !this.startDateTime || !this.endDateTime || this.selectedObjects.size === 0 || this.isLoading;
    }

    /**
     * @description Computed property to disable delete button
     * @returns {Boolean} True if no records found or loading
     */
    get isDeleteDisabled() {
        return !this.showSummary || this.isLoading;
    }

    /**
     * @description Handles start date-time input change
     * @param {Event} event - The change event from lightning-input
     */
    handleStartDateTimeChange(event) {
        this.startDateTime = event.target.value;
        this.recordCounts = {};
        this.clearMessages();
    }

    /**
     * @description Handles end date-time input change
     * @param {Event} event - The change event from lightning-input
     */
    handleEndDateTimeChange(event) {
        this.endDateTime = event.target.value;
        this.recordCounts = {};
        this.clearMessages();
        
        // Validate that end datetime is after start datetime
        if (this.startDateTime && this.endDateTime) {
            const startDate = new Date(this.startDateTime);
            const endDate = new Date(this.endDateTime);
            
            if (endDate < startDate) {
                this.errorMessage = 'Einddatum moet na de startdatum liggen.';
                this.endDateTime = ''; // Clear invalid value
                event.target.value = ''; // Clear the input
            }
        }
    }

    /**
     * @description Handles checkbox selection changes
     * @param {Event} event - The change event from checkbox input
     */
    handleCheckboxChange(event) {
        const objectName = event.target.value;
        const isChecked = event.target.checked;

        if (isChecked) {
            this.selectedObjects.add(objectName);
        } else {
            this.selectedObjects.delete(objectName);
        }

        // Update the checkbox state in our availableObjects array
        this.availableObjects = this.availableObjects.map(obj => {
            if (obj.apiName === objectName) {
                return { ...obj, isChecked: isChecked };
            }
            return obj;
        });

        this.recordCounts = {};
        this.clearMessages();
    }

    /**
     * @description Handles preview button click to count records
     */
    async handlePreview() {
        this.isLoading = true;
        this.clearMessages();
        this.recordCounts = {};

        try {
            const selectedObjectsList = Array.from(this.selectedObjects);
            const counts = await previewRecords({
                startDateTime: this.startDateTime,
                endDateTime: this.endDateTime,
                objectNames: selectedObjectsList
            });

            this.recordCounts = counts;

            if (Object.keys(counts).length === 0) {
                this.showToast('Info', 'Geen records gevonden voor de geselecteerde periode.', 'info');
            } else {
                this.showToast('Succes', 'Record(s) gevonden.', 'success');
            }
        } catch (error) {
            this.errorMessage = 'Fout bij het laden van het voorbeeld: ' + this.getErrorMessage(error);
            this.showToast('Fout', this.errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Handles delete button click to remove records
     */
    async handleDelete() {
        this.isLoading = true;
        this.clearMessages();
        this.deletionErrors = [];

        try {
            const selectedObjectsList = Array.from(this.selectedObjects);
            const result = await deleteRecordsByDate({
                startDateTime: this.startDateTime,
                endDateTime: this.endDateTime,
                objectNames: selectedObjectsList
            });

            // Check if there are any errors and if any records were successfully deleted
            const hasErrors = result.errors && result.errors.length > 0;
            const hasSuccesses = result.message && !result.message.includes('Er zijn geen records verwijderd');

            if (hasErrors && !hasSuccesses) {
                // All deletions failed
                this.deletionErrors = result.errors;
                this.errorMessage = result.message;
                this.showToast('Geen record(s) verwijderd', 'De record(s) konden niet worden verwijderd.', 'error');
            } else if (hasErrors && hasSuccesses) {
                // Some succeeded, some failed
                this.deletionErrors = result.errors;
                this.successMessage = result.message;
                this.showToast('Gedeeltelijk geslaagd', 'Sommige records zijn verwijderd, maar andere zijn mislukt.', 'warning');
            } else {
                // All succeeded
                this.successMessage = result.message;
                this.showToast('Succes', result.message, 'success');
            }
            
            // Reset the form
            this.recordCounts = {};
            this.startDateTime = '';
            this.endDateTime = '';
            this.resetCheckboxes();
        } catch (error) {
            this.errorMessage = 'Fout bij het verwijderen van records: ' + this.getErrorMessage(error);
            this.showToast('Fout', this.errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Clears all success and error messages
     */
    clearMessages() {
        this.successMessage = '';
        this.errorMessage = '';
        this.deletionErrors = [];
    }

    /**
     * @description Resets all checkboxes to unchecked state
     */
    resetCheckboxes() {
        this.selectedObjects.clear();
        this.availableObjects = this.availableObjects.map(obj => ({
            ...obj,
            isChecked: false
        }));
    }

    /**
     * @description Extracts error message from exception
     * @param {Object} error - The error object from apex call
     * @returns {String} The formatted error message
     */
    getErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        } else if (error.message) {
            return error.message;
        }
        return 'Er is een onbekende fout opgetreden';
    }

    /**
     * @description Shows a toast notification
     * @param {String} title - The toast title
     * @param {String} message - The toast message
     * @param {String} variant - The toast variant (success, error, warning, info)
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}