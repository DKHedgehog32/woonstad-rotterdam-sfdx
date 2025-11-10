/*************************************************************************************************
 * Component       : woonstadFlowCustDataForm (JS)
 * Layer           : LWC Controller
 * Purpose         : Legacy two-column customer form with a single "Volgende" button.
 *
 * Key Features    : - Geboortedatum manually typed in Dutch format (dd-mm-jjjj)
 *                   - Display value converted to ISO (yyyy-MM-dd) for Flow
 *                   - Dynamic salutation options fetched from Account.Salutation field
 *                   - Validation only triggered on "Volgende" button click
 *                   - Required fields show red asterisk without premature validation
 *
 * Responsibilities:
 *  - Collect customer personal and contact data
 *  - Validate required fields using native Lightning input validation
 *  - Format birthdate from Dutch display to ISO for Flow compatibility
 *  - Fetch salutation picklist values dynamically from Salesforce
 *  - Navigate to next Flow step on successful validation
 *
 * Required Fields : Voornaam, Achternaam, Telefoonnummer, E-mail, Geboortedatum
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-07
 * Last Modified   : 2025-09-03
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-09-03 | DvM | Updated validation handling to prevent premature validation while keeping red asterisk styling.
 * 2025-09-02 | DvM | Added dynamic salutation fetch from Account.Salutation via WoonstadFlowCustDataController.
 * 2025-08-26 | DvM | Birthdate Dutch typing (dd-mm-jjjj) + ISO conversion for Flow; deferred validation.
 * 2025-08-07 | DvM | Initial creation with legacy two-column layout and right-aligned "Volgende" button.
 *************************************************************************************************/

import { LightningElement, api, wire } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import getSalutationPicklistValues from '@salesforce/apex/WoonstadFlowCustDataController.getSalutationPicklistValues';

export default class WoonstadFlowCustDataForm extends LightningElement {
    /* =========================================================================
       FLOW OUTPUT PROPERTIES (Flow expects ISO birthdate)
       ========================================================================= */
    @api salutation;
    @api firstName;
    @api middleName;
    @api lastName;
    
    /** ISO birthdate (yyyy-MM-dd) sent back to Flow */
    @api birthdate;
    
    @api phone1;
    @api phone2;
    @api email;

    /* =========================================================================
       LOCAL UI STATE
       ========================================================================= */
    /** Controls visibility of validation error banner */
    showValidationBanner = false;

    /** Dutch display value (dd-mm-jjjj) for user input */
    birthdateDisplay;

    /** Dynamic salutation options from Account.Salutation field */
    salutationOptions = [];

    /* =========================================================================
       WIRE METHOD: Fetch Salutation Options
       ========================================================================= */
    @wire(getSalutationPicklistValues)
    wiredSalutationValues({ error, data }) {
        if (data) {
            // Transform Apex response to lightning-combobox format
            this.salutationOptions = data.map(option => ({
                label: option.label,
                value: option.value
            }));
            console.log('Salutation options loaded:', this.salutationOptions);
        } else if (error) {
            // Fallback to default values if Apex call fails
            console.error('Error fetching salutation values:', error);
            this.salutationOptions = [
                { label: 'Dhr.', value: 'Dhr.' },
                { label: 'Mevr.', value: 'Mevr.' },
                { label: 'Mx.', value: 'Mx.' }
            ];
        }
    }

    /* =========================================================================
       LIFECYCLE METHODS
       ========================================================================= */
    renderedCallback() {
        // If Flow prefilled an ISO date, reflect it in the display field once
        if (this.birthdate && !this.birthdateDisplay) {
            this.birthdateDisplay = this.isoToDutch(this.birthdate);
        }

        // Add red asterisks to required field labels manually
        this.addRequiredAsterisks();
    }

    /**
     * Manually add red asterisks to required field labels
     * This is needed since we removed the 'required' attribute to prevent premature validation
     */
    addRequiredAsterisks() {
        const requiredFields = this.template.querySelectorAll('.required-field');
        requiredFields.forEach(fieldContainer => {
            const label = fieldContainer.querySelector('label');
            if (label && !label.textContent.includes('*')) {
                label.innerHTML = label.innerHTML + ' <span style="color: #d02c2c;">*</span>';
            }
        });
    }

    /* =========================================================================
       EVENT HANDLERS (No validation here - deferred to "Volgende")
       ========================================================================= */
    handleInputChange(event) {
        const { name, value } = event.target;
        this[name] = value;
        
        // Clear any previous validation styling when user starts typing
        const fieldElement = event.target;
        if (fieldElement) {
            fieldElement.setCustomValidity('');
            fieldElement.removeAttribute('data-validation-error');
        }
        
        // No pre-validation per request - validation only on "Volgende" click
    }

    handleSalutationChange(event) {
        this.salutation = event.detail.value;
    }

    /* =========================================================================
       BIRTHDATE TYPING HELPERS
       ========================================================================= */
    handleBirthdateTyping(event) {
        // Allow only digits, auto-insert dashes -> dd-mm-jjjj format
        const digits = (event.target.value || '').replace(/\D/g, '').slice(0, 8);
        let formatted = '';
        
        if (digits.length >= 2) formatted = digits.slice(0, 2);
        if (digits.length >= 3) formatted += '-' + digits.slice(2, 4);
        if (digits.length >= 5) formatted += '-' + digits.slice(4, 8);
        
        this.birthdateDisplay = formatted;
        
        // Clear any previous validation styling when user starts typing
        const fieldElement = event.target;
        if (fieldElement) {
            fieldElement.setCustomValidity('');
            fieldElement.removeAttribute('data-validation-error');
        }
        
        // Do not set @api birthdate yet; conversion happens on change or submit
    }

    handleBirthdateChange(event) {
        // On change (blur), try to normalize to ISO if format is valid
        const displayValue = (event.target.value || '').trim();
        this.birthdateDisplay = displayValue;
        
        const isoValue = this.dutchToIso(displayValue);
        this.birthdate = isoValue || undefined; // undefined if invalid; validate on Next
        
        // Clear any previous validation styling when user changes value
        const fieldElement = event.target;
        if (fieldElement) {
            fieldElement.setCustomValidity('');
            fieldElement.removeAttribute('data-validation-error');
        }
    }

    /* =========================================================================
       VALIDATION AND NAVIGATION (Single point of validation)
       ========================================================================= */
    handleNext() {
        // Try converting current display value to ISO before validation
        if (this.birthdateDisplay && !this.birthdate) {
            const isoValue = this.dutchToIso(this.birthdateDisplay);
            this.birthdate = isoValue || undefined;
        }

        // Get required field elements for validation
        const firstNameEl = this.template.querySelector('[data-field="firstName"]');
        const lastNameEl  = this.template.querySelector('[data-field="lastName"]');
        const birthEl     = this.template.querySelector('[data-field="birthdate"]');
        const phoneEl     = this.template.querySelector('[data-field="phone1"]');
        const emailEl     = this.template.querySelector('[data-field="email"]');

        // Reset any previous custom validation messages and styling
        [firstNameEl, lastNameEl, birthEl, phoneEl, emailEl].forEach(el => {
            if (el) {
                el.setCustomValidity('');
                el.removeAttribute('data-validation-error');
            }
        });

        let isValid = true;

        // Validate required text fields and add validation styling
        if (firstNameEl && !this.firstName) { 
            firstNameEl.setCustomValidity('Verplicht veld');
            firstNameEl.setAttribute('data-validation-error', 'true');
            isValid = false; 
        }
        if (lastNameEl && !this.lastName) { 
            lastNameEl.setCustomValidity('Verplicht veld');
            lastNameEl.setAttribute('data-validation-error', 'true');
            isValid = false; 
        }
        if (phoneEl && !this.phone1) { 
            phoneEl.setCustomValidity('Verplicht veld');
            phoneEl.setAttribute('data-validation-error', 'true');
            isValid = false; 
        }
        if (emailEl && !this.email) { 
            emailEl.setCustomValidity('Verplicht veld');
            emailEl.setAttribute('data-validation-error', 'true');
            isValid = false; 
        }

        // Validate birthdate with Dutch format and date logic
        if (!this.birthdateDisplay || this.birthdateDisplay.trim() === '') {
            if (birthEl) {
                birthEl.setCustomValidity('Vul de geboortedatum in (dd-mm-jjjj).');
                birthEl.setAttribute('data-validation-error', 'true');
                isValid = false;
            }
        } else if (!this.isDutchDate(this.birthdateDisplay)) {
            if (birthEl) {
                birthEl.setCustomValidity('Gebruik notatie dd-mm-jjjj (bijv. 31-12-1990).');
                birthEl.setAttribute('data-validation-error', 'true');
                isValid = false;
            }
        } else {
            const isoValue = this.dutchToIso(this.birthdateDisplay);
            if (!isoValue) {
                if (birthEl) {
                    birthEl.setCustomValidity('Ongeldige datum. Controleer dag en maand (bijv. 29-02 alleen in schrikkeljaar).');
                    birthEl.setAttribute('data-validation-error', 'true');
                    isValid = false;
                }
            } else if (!this.isPlausibleBirthYear(isoValue)) {
                if (birthEl) {
                    birthEl.setCustomValidity('Ongeldig geboortejaar. Gebruik een jaar tussen 1900 en vandaag.');
                    birthEl.setAttribute('data-validation-error', 'true');
                    isValid = false;
                }
            } else {
                this.birthdate = isoValue; // Commit ISO value for Flow output
            }
        }

        // Trigger native Lightning input validation UI
        const validationResults = [
            firstNameEl?.reportValidity(),
            lastNameEl?.reportValidity(),
            birthEl?.reportValidity(),
            phoneEl?.reportValidity(),
            emailEl?.reportValidity()
        ];

        // Focus first invalid field for better UX
        const firstInvalidIndex = validationResults.findIndex(result => result === false);
        if (firstInvalidIndex !== -1) {
            const invalidElements = [firstNameEl, lastNameEl, birthEl, phoneEl, emailEl];
            invalidElements[firstInvalidIndex]?.focus();
        }

        // Show/hide validation banner
        this.showValidationBanner = !isValid;
        if (!isValid) return;

        // Push all values back to Flow (birthdate is in ISO format)
        [
            ['salutation', this.salutation],
            ['firstName',  this.firstName],
            ['middleName', this.middleName],
            ['lastName',   this.lastName],
            ['birthdate',  this.birthdate],   // ISO yyyy-MM-dd format
            ['phone1',     this.phone1],
            ['phone2',     this.phone2],
            ['email',      this.email]
        ].forEach(([fieldName, fieldValue]) => {
            this.dispatchEvent(new FlowAttributeChangeEvent(fieldName, fieldValue));
        });

        // Navigate to next Flow step
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    /* =========================================================================
       DATE UTILITY METHODS
       ========================================================================= */
    
    /**
     * Validates Dutch date format (dd-mm-yyyy) and checks for valid day/month combinations
     * @param {string} ddmmyyyy - Date string in dd-mm-yyyy format
     * @returns {boolean} True if valid Dutch date format and logical date
     */
    isDutchDate(ddmmyyyy) {
        // Check strict format: dd-mm-yyyy
        if (!/^\d{2}-\d{2}-\d{4}$/.test(ddmmyyyy)) return false;
        
        const [dd, mm, yyyy] = ddmmyyyy.split('-').map(n => parseInt(n, 10));
        
        // Basic range checks
        if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return false;

        // Check if day is valid for the specific month
        const lastDayOfMonth = new Date(yyyy, mm, 0).getDate();
        return dd <= lastDayOfMonth;
    }

    /**
     * Converts Dutch date format (dd-mm-yyyy) to ISO format (yyyy-MM-dd)
     * @param {string} ddmmyyyy - Date string in dd-mm-yyyy format
     * @returns {string|null} ISO date string or null if invalid
     */
    dutchToIso(ddmmyyyy) {
        if (!this.isDutchDate(ddmmyyyy)) return null;
        
        const [dd, mm, yyyy] = ddmmyyyy.split('-');
        return `${yyyy}-${mm}-${dd}`; // yyyy-MM-dd format for Flow
    }

    /**
     * Converts ISO date format (yyyy-MM-dd) to Dutch format (dd-mm-yyyy)
     * @param {string} iso - Date string in yyyy-MM-dd format
     * @returns {string} Dutch formatted date string
     */
    isoToDutch(iso) {
        // Handle both yyyy-MM-dd and yyyy-M-d formats
        const match = /^(\d{4})-(\d{1,2})-(\d{1,2})$/.exec(iso);
        if (!match) return iso;
        
        const yyyy = match[1];
        const mm = match[2].padStart(2, '0');
        const dd = match[3].padStart(2, '0');
        
        return `${dd}-${mm}-${yyyy}`;
    }

    /**
     * Validates that the birth year is within a reasonable range
     * @param {string} iso - Date string in yyyy-MM-dd format
     * @returns {boolean} True if birth year is between 1900 and today
     */
    isPlausibleBirthYear(iso) {
        const date = new Date(iso);
        if (isNaN(date.getTime())) return false;
        
        const minDate = new Date(1900, 0, 1);
        const maxDate = new Date();
        
        return date >= minDate && date <= maxDate;
    }

    /* =========================================================================
       COMPUTED PROPERTIES
       ========================================================================= */
    
    /**
     * Computed property to check if all required fields have values
     * @returns {boolean} True if all required fields are filled
     */
    get _hasRequiredFields() {
        return !!(this.firstName && this.lastName && this.phone1 && this.email && this.birthdate);
    }

    /* =========================================================================
       FLOW VALIDATE HOOK (Called by Flow if needed)
       ========================================================================= */
    @api
    validate() {
        // Use same validation logic as handleNext but without UI side effects
        const isoValue = this.dutchToIso(this.birthdateDisplay || '');
        const isFormValid = this._hasRequiredFields && !!isoValue && this.isPlausibleBirthYear(isoValue);

        if (isFormValid) {
            this.birthdate = isoValue;
        }
        
        return { isValid: isFormValid };
    }
}