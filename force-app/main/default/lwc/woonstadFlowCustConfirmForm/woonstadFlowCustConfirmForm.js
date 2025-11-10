/*************************************************************************************************
 * Component       : woonstadFlowCustConfirmForm (JS)
 * Layer           : LWC Controller
 * Purpose         : Confirmation screen for customer + address data with inline editing capability.
 *
 * Responsibilities:
 *  - Accept all values via Flow inputs and provide outputs
 *  - Render two-column summary: customer (left) and address (right)
 *  - Toggle between confirmation view and edit mode
 *  - Show top banner with instructions based on current mode
 *  - Validate in both confirmation and edit modes
 *  - Navigate Back/Next via Flow events
 *  - Provide edited values back to Flow as outputs
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-26
 * Last Modified   : 2025-09-02
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-08-26 | DvM | Initial creation based on legacy style; two-columns; NL + INTL address support.
 * 2025-09-02 | DvM | Added edit mode toggle, converted properties to inputOutput, added inline editing.
 *************************************************************************************************/

import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';

export default class WoonstadFlowCustConfirmForm extends LightningElement {
    /* =========================================================================
       FLOW INPUT/OUTPUT PROPERTIES: Customer Data
       ========================================================================= */
    @api salutation;
    @api firstName;
    @api middleName;
    @api lastName;
    @api birthdate;
    @api phone1;
    @api phone2;
    @api email;

    /* =========================================================================
       FLOW OUTPUT PROPERTIES: Customer Data (for edited values)
       ========================================================================= */
    @api salutationOut;
    @api firstNameOut;
    @api middleNameOut;
    @api lastNameOut;
    @api birthdateOut;
    @api phone1Out;
    @api phone2Out;
    @api emailOut;

    /* =========================================================================
       FLOW INPUT PROPERTIES: Address Data (READ-ONLY in UI)
       These fields display address information but are not editable
       ========================================================================= */
    @api streetName;                       // NL street name
    @api houseNumberOutput;                // NL house number
    @api houseLetter;                      // NL house letter
    @api houseNumberAddition;              // NL house number addition
    @api postalCodeOutput;                 // NL postal code
    @api city;                             // NL city
    @api addressableObjectIdentification;  // NL AOI identifier

    @api intlStreet;       // International street
    @api intlHouseNumber;  // International house number
    @api intlHouseAddition;// International house addition
    @api intlPostalCode;   // International postal code
    @api intlCity;         // International city
    @api intlState;        // International state/province
    @api intlCountry;      // International country

    /* =========================================================================
       FLOW OUTPUT PROPERTIES: Address Data (for metadata compatibility only)
       These properties exist to match metadata but are not used in UI logic
       ========================================================================= */
    @api streetNameOut;
    @api houseNumberOutputOut;
    @api houseLetterOut;
    @api houseNumberAdditionOut;
    @api postalCodeOutputOut;
    @api cityOut;
    @api addressableObjectIdentificationOut;

    @api intlStreetOut;
    @api intlHouseNumberOut;
    @api intlHouseAdditionOut;
    @api intlPostalCodeOut;
    @api intlCityOut;
    @api intlStateOut;
    @api intlCountryOut;

    /* =========================================================================
       FLOW OUTPUT PROPERTIES: Control Flags
       ========================================================================= */
    @api wasModified;

    /* =========================================================================
       COMPONENT STATE
       ========================================================================= */
    // Controls whether the component is in edit mode or confirmation mode
    isEditMode = false;
    
    // Controls visibility of validation error banner
    showValidationBanner = false;

    /* =========================================================================
       GETTERS: Customer Data Display
       These getters format customer data for display in confirmation mode
       ========================================================================= */
    get displayName() {
        // Combines all name parts, filtering out empty values
        const parts = [
            this.salutation,
            this.firstName,
            this.middleName,
            this.lastName
        ].filter(Boolean);
        return parts.join(' ');
    }

    get displayFirstName() {
        // Shows first name or dash if empty
        return this.firstName || '—';
    }

    get displayBirthdate() {
        // Shows birthdate or dash if empty
        return this.birthdate || '—';
    }

    get displayPhone1() {
        // Shows primary phone or dash if empty
        return this.phone1 || '—';
    }

    get displayPhone2() {
        // Shows secondary phone or dash if empty
        return this.phone2 || '—';
    }

    get displayEmail() {
        // Shows email or dash if empty
        return this.email || '—';
    }

    /* =========================================================================
       GETTERS: Form Options
       ========================================================================= */
    get salutationOptions() {
        // Options for the salutation dropdown
        return [
            { label: 'Dhr.', value: 'Dhr.' },
            { label: 'Mevr.', value: 'Mevr.' },
            { label: 'De heer', value: 'De heer' },
            { label: 'Mevrouw', value: 'Mevrouw' }
        ];
    }

    /* =========================================================================
       GETTERS: Address Detection Logic
       These determine which address type (NL vs International) to display
       ========================================================================= */
    get hasNlAddress() {
        // Determines if Dutch address data is present by checking key fields
        return !!(this.streetName || this.postalCodeOutput || this.city);
    }

    get hasIntlAddress() {
        // Determines if international address data is present by checking key fields
        return !!(this.intlStreet || this.intlPostalCode || this.intlCity || this.intlCountry);
    }

    /* =========================================================================
       GETTERS: Dutch Address Display Formatting
       ========================================================================= */
    get nlStreetLine() {
        if (!this.hasNlAddress) return '—';
        
        // Combines house number and letter (if present)
        const num = [this.houseNumberOutput, this.houseLetter].filter(Boolean).join('');
        
        // Adds house number addition with space if present
        const add = this.houseNumberAddition ? ` ${this.houseNumberAddition}` : '';
        
        // Creates the complete house number suffix
        const suffix = (num ? `${num}${add}` : '').trim();
        
        // Combines street name with house number information
        return [this.streetName, suffix].filter(Boolean).join(' ');
    }

    get nlCityLine() {
        if (!this.hasNlAddress) return '';
        // Combines postal code and city with space
        return [this.postalCodeOutput, this.city].filter(Boolean).join(' ');
    }

    get nlCountryLabel() {
        // Use the country from Flow input if provided, otherwise default to Nederland
        // This allows Flow to override the country even for Dutch-format addresses
        return this.intlCountry || 'Nederland';
    }

    /* =========================================================================
       GETTERS: International Address Display Formatting
       ========================================================================= */
    get intlStreetLine() {
        if (!this.hasIntlAddress) return '—';
        
        // Combines international house number (simpler than Dutch format)
        const num = [this.intlHouseNumber].filter(Boolean).join('');
        
        // Adds house addition with space if present
        const add = this.intlHouseAddition ? ` ${this.intlHouseAddition}` : '';
        
        // Creates the complete house number suffix
        const suffix = (num ? `${num}${add}` : '').trim();
        
        // Combines street with house number information
        return [this.intlStreet, suffix].filter(Boolean).join(' ');
    }

    get intlCityLine() {
        if (!this.hasIntlAddress) return '';
        
        // Combines city and state (common for US/Australia/Canada)
        const cityState = [this.intlCity, this.intlState].filter(Boolean).join(', ');
        
        // Combines postal code with city/state information
        return [this.intlPostalCode, cityState].filter(Boolean).join(' ');
    }

    get intlCountryLabel() {
        // Shows the country as provided by Flow (could be ISO code or full name)
        return this.intlCountry || '—';
    }

    /* =========================================================================
       GETTERS: UI State and Messaging
       ========================================================================= */
    get bannerMessage() {
        // Changes instruction message based on current mode
        return this.isEditMode 
            ? 'Wijzig de gegevens en klik op "Opslaan" om door te gaan.'
            : 'Controleer de gegevens voordat u doorgaat.';
    }

    get nextButtonLabel() {
        // Changes button label based on current mode
        return this.isEditMode ? 'Opslaan' : 'Volgende';
    }

    get editButtonTitle() {
        // Changes button tooltip based on current mode
        return this.isEditMode ? 'Annuleren' : 'Bewerken';
    }

    /* =========================================================================
       VALIDATION LOGIC
       These methods check if required fields are filled
       ========================================================================= */
    get _hasRequiredCustomer() {
        // Validates that all required customer fields are present
        return !!(this.firstName && this.lastName && this.birthdate && this.phone1 && this.email);
    }

    get _hasRequiredAddress() {
        // Validates that either Dutch OR international address is complete
        const nlOk = !!(this.streetName && this.postalCodeOutput && this.city);
        const intlOk = !!(this.intlStreet && this.intlPostalCode && this.intlCity && this.intlCountry);
        return nlOk || intlOk;
    }

    /* =========================================================================
       EVENT HANDLERS: Mode Toggle
       ========================================================================= */
    handleEditToggle() {
        // Toggles between edit and confirmation modes
        this.isEditMode = !this.isEditMode;
        
        // Hide validation banner when switching modes
        this.showValidationBanner = false;
        
        // Scroll to top when entering edit mode for better UX
        if (this.isEditMode) {
            requestAnimationFrame(() => {
                this.template.querySelector('.woonstad')?.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            });
        }
    }

    /* =========================================================================
       PRIVATE METHODS: Data Synchronization
       ========================================================================= */
    _syncOutputValues() {
        // Sync only customer data to output properties for Flow
        // Address data is read-only in UI, so no output sync needed
        this.salutationOut = this.salutation;
        this.firstNameOut = this.firstName;
        this.middleNameOut = this.middleName;
        this.lastNameOut = this.lastName;
        this.birthdateOut = this.birthdate;
        this.phone1Out = this.phone1;
        this.phone2Out = this.phone2;
        this.emailOut = this.email;

        // Set modification flag
        this.wasModified = true;
    }

    /* =========================================================================
       EVENT HANDLERS: Customer Data Input Changes
       Only customer fields are editable - address fields are read-only
       ========================================================================= */
    handleSalutationChange(event) {
        this.salutation = event.target.value;
        this.salutationOut = event.target.value;
        this.wasModified = true;
    }

    handleFirstNameChange(event) {
        this.firstName = event.target.value;
        this.firstNameOut = event.target.value;
        this.wasModified = true;
    }

    handleMiddleNameChange(event) {
        this.middleName = event.target.value;
        this.middleNameOut = event.target.value;
        this.wasModified = true;
    }

    handleLastNameChange(event) {
        this.lastName = event.target.value;
        this.lastNameOut = event.target.value;
        this.wasModified = true;
    }

    handleBirthdateChange(event) {
        this.birthdate = event.target.value;
        this.birthdateOut = event.target.value;
        this.wasModified = true;
    }

    handlePhone1Change(event) {
        this.phone1 = event.target.value;
        this.phone1Out = event.target.value;
        this.wasModified = true;
    }

    handlePhone2Change(event) {
        this.phone2 = event.target.value;
        this.phone2Out = event.target.value;
        this.wasModified = true;
    }

    handleEmailChange(event) {
        this.email = event.target.value;
        this.emailOut = event.target.value;
        this.wasModified = true;
    }

    /* =========================================================================
       EVENT HANDLERS: Navigation
       ========================================================================= */
    handleBack() {
        // Sync output values before navigating back
        this._syncOutputValues();
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    handleNext() {
        // Validate required fields regardless of mode
        const valid = this._hasRequiredCustomer && this._hasRequiredAddress;
        this.showValidationBanner = !valid;

        if (!valid) {
            // Scroll validation banner into view for accessibility
            requestAnimationFrame(() => {
                this.template.querySelector('[data-id="validationBanner"]')?.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            });
            return;
        }

        if (this.isEditMode) {
            // If in edit mode, switch back to confirmation mode after saving
            this.isEditMode = false;
            this.showValidationBanner = false;
            // Sync all current values to output properties
            this._syncOutputValues();
        } else {
            // If in confirmation mode, sync output values and proceed to next Flow screen
            this._syncOutputValues();
            this.dispatchEvent(new FlowNavigationNextEvent());
        }
    }
}