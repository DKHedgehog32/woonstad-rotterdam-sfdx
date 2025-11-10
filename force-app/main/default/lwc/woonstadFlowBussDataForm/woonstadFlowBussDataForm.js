/*************************************************************************************************
 * Component       : woonstadFlowBussDataForm (JS)
 * Layer           : LWC Controller
 * Purpose         : Business data collection form for Salesforce Flow with company and contact info.
 *
 * Responsibilities:
 *  - Collect required business data: Account Type, Company Name, KVK Number, Email, Phone
 *  - Collect optional business data: VAT Number, Mobile Phone
 *  - Fetch Account Type picklist values from Salesforce
 *  - Validate required fields on form submission
 *  - Output all field values to Flow for further processing
 *  - Handle loading states and error scenarios
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-29
 * Last Modified   : 2025-09-01
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-08-29 | DvM | Created business data form for Flow integration.
 * 2025-09-01 | DvM | Added Account Type field with picklist integration and Apex controller.
 *************************************************************************************************/

import { LightningElement, api, wire } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import getAccountTypeOptions from '@salesforce/apex/WoonstadFlowBussDataFormController.getAccountTypeOptions';

export default class WoonstadFlowBussDataForm extends LightningElement {
    /* =========================================================================
       FLOW OUTPUT VARIABLES: Business Data
       These @api properties will be available as output variables in Flow
       ========================================================================= */
    
    /**
     * Selected account type from picklist
     * @type {String}
     * @api This value will be passed to Flow as output variable
     */
    @api accountType = '';

    /**
     * Company/business name (required field)
     * @type {String}
     * @api This value will be passed to Flow as output variable
     */
    @api companyName = '';

    /**
     * KVK (Chamber of Commerce) registration number (required field)
     * @type {String}
     * @api This value will be passed to Flow as output variable
     */
    @api kvkNumber = '';

    /**
     * BTW/VAT tax identification number (optional field)
     * @type {String}
     * @api This value will be passed to Flow as output variable
     */
    @api vatNumber = '';

    /**
     * Primary/landline phone number (required field)
     * @type {String}
     * @api This value will be passed to Flow as output variable
     */
    @api phone1 = '';

    /**
     * Mobile/secondary phone number (optional field)
     * @type {String}
     * @api This value will be passed to Flow as output variable
     */
    @api phone2 = '';

    /**
     * Business email address (required field)
     * @type {String}
     * @api This value will be passed to Flow as output variable
     */
    @api email = '';

    /* =========================================================================
       COMPONENT STATE PROPERTIES
       ========================================================================= */
    
    /**
     * Loading state for Account Type picklist
     * @type {Boolean}
     */
    loading = true;

    /**
     * Options for Account Type combobox, populated from Apex
     * @type {Array<Object>}
     */
    accountTypeOptions = [];

    /**
     * Flag to show/hide validation banner
     * @type {Boolean}
     */
    showValidationBanner = false;

    /* =========================================================================
       APEX WIRE SERVICE: Fetch Account Type Picklist Values
       ========================================================================= */
    
    /**
     * Wire service to fetch Account Type picklist values from Apex controller
     * This method is cacheable and will automatically refresh if needed
     * 
     * @param {Object} result - Wire service result containing data or error
     */
    @wire(getAccountTypeOptions)
    wiredAccountTypes({ error, data }) {
        this.loading = false; // Always stop loading regardless of success/failure
        
        if (data) {
            // Success: Store the picklist options for the combobox
            this.accountTypeOptions = data;
            console.log('Successfully loaded Account Type options:', data.length);
        } else if (error) {
            // Error: Log error and show empty options (graceful degradation)
            console.error('Error loading Account Type options:', error);
            this.accountTypeOptions = [];
            
            // Could show a toast message here if needed
            // this.showToast('Error', 'Could not load Account Types', 'error');
        }
    }

    /* =========================================================================
       EVENT HANDLERS: Form Input Changes
       ========================================================================= */
    
    /**
     * Handles changes to the Account Type combobox
     * Updates the accountType property when user selects a different option
     * 
     * @param {Event} event - Change event from lightning-combobox
     */
    handleAccountTypeChange(event) {
        // Extract the selected value from the combobox event
        this.accountType = event.detail.value;
        
        // Clear validation banner when user makes changes
        this.showValidationBanner = false;
        
        // Debug logging to help with troubleshooting
        console.log('Account Type changed to:', this.accountType);
    }

    /**
     * Handles changes to regular input fields
     * Updates the corresponding property when user types in any input field
     * 
     * @param {Event} event - Change event from lightning-input
     */
    handleInputChange(event) {
        // Get the field name from the input's name attribute
        const fieldName = event.target.name;
        // Get the new value from the input
        const fieldValue = event.target.value;

        // Update the corresponding property using bracket notation
        this[fieldName] = fieldValue;

        // Clear validation banner when user makes changes
        this.showValidationBanner = false;

        // Debug logging to help with troubleshooting
        console.log(`${fieldName} changed to:`, fieldValue);
    }

    /* =========================================================================
       VALIDATION LOGIC
       ========================================================================= */
    
    /**
     * Validates all required fields before allowing navigation to next step
     * Required fields: accountType, companyName, kvkNumber, phone1, email
     * 
     * @returns {Boolean} True if all required fields have values, false otherwise
     */
    validateRequiredFields() {
        // List of required field names for easy maintenance
        const requiredFields = ['accountType', 'companyName', 'kvkNumber', 'phone1', 'email'];
        
        // Check if all required fields have non-empty values
        const allFieldsValid = requiredFields.every(fieldName => {
            const fieldValue = this[fieldName];
            const isValid = fieldValue && fieldValue.trim().length > 0;
            
            if (!isValid) {
                console.log(`Validation failed for required field: ${fieldName}`);
            }
            
            return isValid;
        });

        return allFieldsValid;
    }

    /* =========================================================================
       FLOW NAVIGATION
       ========================================================================= */
    
    /**
     * Handles the "Volgende" (Next) button click
     * Validates all required fields before proceeding to next Flow screen
     * Shows validation banner if required fields are missing
     */
    handleNext() {
        // Perform validation check
        const isValid = this.validateRequiredFields();

        if (!isValid) {
            // Show validation banner to inform user about missing fields
            this.showValidationBanner = true;
            
            // Scroll to top of form so user can see the validation message
            // Using requestAnimationFrame to ensure DOM has updated
            requestAnimationFrame(() => {
                const banner = this.template.querySelector('[data-id="validationBanner"]');
                if (banner) {
                    banner.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            });

            // Stop processing - don't navigate to next screen
            return;
        }

        // All validations passed - proceed to next Flow screen
        // The @api properties will automatically be available as Flow variables
        console.log('Form validation passed. Proceeding to next step with data:', {
            accountType: this.accountType,
            companyName: this.companyName,
            kvkNumber: this.kvkNumber,
            vatNumber: this.vatNumber,
            phone1: this.phone1,
            phone2: this.phone2,
            email: this.email
        });

        // Dispatch Flow navigation event to move to next screen
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}