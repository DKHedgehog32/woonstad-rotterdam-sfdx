/*************************************************************************************************
 * Component       : kadasterLookupFlow (JS)
 * Layer           : Lightning Web Component Controller
 * Purpose         : Kadaster BAG postcode+huisnummer lookup for NL + international manual address.
 *
 * Responsibilities:
 *  - Country picklist (default: NL)
 *  - NL: Kadaster lookup; right-hand preview (always shows header, centered)
 *  - Non-NL: Manual address form
 *  - Expose all address fields (NL + INTL) as @api outputs for Flow (including countryOutput + countryIsoOutput)
 *  - "Ingangsdatum" is required for both NL and non-NL, and emitted as ingangsdatumOutput
 *  - Legacy "Volgende" button to navigate Flow
 *
 * Accessibility   : SLDS inputs with native validation
 * Security        : UI-only; enforce CRUD/FLS + server checks separately
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-07
 * Last Modified   : 2025-09-02
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-09-02 | DvM | ADDED: countryIsoOutput @api property for ISO country codes.
 * 2025-09-02 | DvM | FIXED: Country output properly set for international addresses in handleNext().
 * 2025-09-02 | DvM | FIXED: clearInternationalOutputsOnly() preserves intlCountry value.
 * 2025-09-02 | DvM | FIXED: updateMainOutputsFromManual() sets intlCountry from countryOutput.
 * 2025-09-02 | DvM | FIXED: Moved all @api decorators inside class definition to properly expose Flow outputs.
 * 2025-08-29 | DvM | Fixed class structure - moved all @api decorators inside class definition.
 * 2025-08-29 | DvM | Added connectedCallback to dispatch initial country; fixed countryOutput initialization.
 * 2025-08-29 | DvM | Fixed countryOutput to use label instead of value; immediate Flow dispatch.
 * 2025-08-27 | DvM | Added ingangsdatumOutput (required, NL + non-NL) + validation; date field next to Postcode for NL.
 * 2025-08-26 | DvM | Added countryOutput (always set, NL + INTL) and emit to Flow on Next.
 * 2025-08-26 | DvM | Preview centered; header bold/brand-colored; flat right-hand preview.
 * 2025-08-25 | DvM | Added "Volgende", country picklist, non-NL manual, Flow outputs.
 * 2025-08-07 | DvM | Initial version.
 *************************************************************************************************/

import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import fetchAddresses from '@salesforce/apex/KadasterAddressLookupController.fetchAddresses';

export default class KadasterLookupFlow extends LightningElement {
    /* =========================================================================
       COUNTRY SELECTION
       ========================================================================= */
    country = 'NL';
    countryOptions = getAllCountries();

    /* =========================================================================
       FLOW OUTPUT PROPERTIES - ALL @api DECORATORS MUST BE INSIDE THE CLASS!
       ========================================================================= */
    
    /** Flow output for the selected country (always set to country label, not value) */
    @api countryOutput = 'Nederland';

    /** Flow output for the selected country ISO code (always set to country value/ISO code) */
    @api countryIsoOutput = 'NL';

    /* NL OUTPUTS */
    @api streetName = '';
    @api houseNumberOutput = '';
    @api houseLetter = '';
    @api houseNumberAddition = '';
    @api postalCodeOutput = '';
    @api city = '';
    @api addressableObjectIdentification = '';

    /** Ingangsdatum (yyyy-MM-dd string for Flow Date variable mapping), required in both modes */
    @api ingangsdatumOutput = '';

    /* INTERNATIONAL OUTPUTS (filled only when !isNl) */
    @api intlStreet = '';
    @api intlHouseNumber = '';
    @api intlHouseAddition = '';
    @api intlPostalCode = '';
    @api intlCity = '';
    @api intlState = '';
    @api intlCountry = '';

    /* =========================================================================
       LOCAL STATE
       ========================================================================= */
    /* Local state for the date input (bound in both NL and non-NL forms) */
    ingangsdatum = null;

    /* NL STATE */
    postalCodeInput = '';
    houseNumberInput = '';
    postalCodeValid = true;

    addressList = [];
    addressOptions = [];
    selectedAddressIndex = null;

    loading = false;
    error = null;
    debounceTimer;

    /* MANUAL INPUT STATE */
    manual = { street: '', houseNumber: '', addition: '', postalCode: '', city: '', state: '' };

    /* =========================================================================
       COMPUTED PROPERTIES
       ========================================================================= */
    get isNl() {
        return this.country === 'NL';
    }

    get hasNlSelection() {
        return this.isNl && !!(this.streetName && this.postalCodeOutput && this.city);
    }

    get nlStreetLine() {
        const num = [this.houseNumberOutput, this.houseLetter].filter(Boolean).join('');
        const add = this.houseNumberAddition ? ` ${this.houseNumberAddition}` : '';
        return [this.streetName, (num ? `${num}${add}` : '').trim()].filter(Boolean).join(' ');
    }

    get nlCityLine() {
        return [this.postalCodeOutput, this.city].filter(Boolean).join(' ');
    }

    get nlCountryLabel() {
        return 'Nederland';
    }

    /* =========================================================================
       LIFECYCLE METHODS
       ========================================================================= */
    // Lifecycle method to dispatch initial values to Flow
    connectedCallback() {
        // Dispatch the initial country output values to Flow when component loads
        this.dispatchEvent(new FlowAttributeChangeEvent('countryOutput', this.countryOutput));
        this.dispatchEvent(new FlowAttributeChangeEvent('countryIsoOutput', this.countryIsoOutput));
    }

    /* =========================================================================
       EVENT HANDLERS
       ========================================================================= */
    handleCountryChange(e) {
        this.country = e.detail.value;
        
        console.log('=== COUNTRY CHANGE ===');
        console.log('New country:', this.country);
        
        // Find the label for the selected country value
        const selectedOption = this.countryOptions.find(option => option.value === this.country);
        this.countryOutput = selectedOption ? selectedOption.label : this.country;
        this.countryIsoOutput = this.country; // ISO code is the value
        
        // Dispatch both country label and ISO code to Flow immediately
        this.dispatchEvent(new FlowAttributeChangeEvent('countryOutput', this.countryOutput));
        this.dispatchEvent(new FlowAttributeChangeEvent('countryIsoOutput', this.countryIsoOutput));
        
        this.clearOutputsAndSelection();
        this.resetManualInputs();
        this.error = null;
        
        // Clear ALL main output fields when switching countries
        this.clearMainOutputs();
        
        console.log('Country outputs set to:');
        console.log('  countryOutput (label):', this.countryOutput);
        console.log('  countryIsoOutput (ISO):', this.countryIsoOutput);
        console.log('=== END COUNTRY CHANGE ===\n');
    }

    /**
     * Clears the main output fields and dispatches to Flow
     */
    clearMainOutputs() {
        this.streetName = '';
        this.houseNumberOutput = '';
        this.houseLetter = '';
        this.houseNumberAddition = '';
        this.postalCodeOutput = '';
        this.city = '';
        this.addressableObjectIdentification = '';
        
        // Dispatch cleared values to Flow
        this.dispatchEvent(new FlowAttributeChangeEvent('streetName', this.streetName));
        this.dispatchEvent(new FlowAttributeChangeEvent('houseNumberOutput', this.houseNumberOutput));
        this.dispatchEvent(new FlowAttributeChangeEvent('houseLetter', this.houseLetter));
        this.dispatchEvent(new FlowAttributeChangeEvent('houseNumberAddition', this.houseNumberAddition));
        this.dispatchEvent(new FlowAttributeChangeEvent('postalCodeOutput', this.postalCodeOutput));
        this.dispatchEvent(new FlowAttributeChangeEvent('city', this.city));
        this.dispatchEvent(new FlowAttributeChangeEvent('addressableObjectIdentification', this.addressableObjectIdentification));
        
        console.log('✓ Main outputs cleared and dispatched to Flow');
    }

    handlePostalCodeChange(e) {
        const v = String(e.detail.value || '').trim().toUpperCase();
        this.postalCodeInput = v;
        this.postalCodeValid = /^[0-9]{4}[A-Z]{2}$/.test(v);

        this.clearOutputsAndSelection();
        if (this.postalCodeValid) this.scheduleDebouncedFetch();
    }

    handleIngangsdatumChange(e) {
        // lightning-input type="date" returns yyyy-MM-dd
        this.ingangsdatum = e.detail.value || null;
        this.ingangsdatumOutput = this.ingangsdatum;
        this.error = null;
    }

    handleHouseNumberChange(e) {
        this.houseNumberInput = String(e.detail.value || '').trim();
        this.clearOutputsAndSelection();
        this.scheduleDebouncedFetch();
    }

    handleManualChange(e) {
        const { name, value } = e.target;
        
        console.log('=== MANUAL CHANGE EVENT ===');
        console.log('Field name:', name, 'Field value:', value);
        
        this.manual = { ...this.manual, [name]: value ?? '' };
        this.error = null;
        
        // For international mode, immediately update the MAIN output fields
        if (!this.isNl) {
            console.log('International mode - updating main output fields immediately');
            this.updateMainOutputsFromManual();
        }
        
        console.log('=== END MANUAL CHANGE EVENT ===\n');
    }

    /**
     * Updates the main output fields from manual input and dispatches to Flow
     * This uses the same output fields for both NL and International addresses
     */
    updateMainOutputsFromManual() {
        console.log('=== UPDATING MAIN OUTPUTS FROM MANUAL ===');
        
        // Map international manual data to the MAIN output fields
        this.streetName = this.manual.street || '';
        this.houseNumberOutput = this.manual.houseNumber || '';
        this.houseLetter = ''; // Not used for international
        this.houseNumberAddition = this.manual.addition || '';
        this.postalCodeOutput = this.manual.postalCode || '';
        this.city = this.manual.city || '';
        this.addressableObjectIdentification = ''; // Not applicable for international
        
        // Set intlCountry from the selected country
        this.intlCountry = this.countryOutput || '';
        
        console.log('Main outputs set to:');
        console.log('  streetName:', this.streetName);
        console.log('  houseNumberOutput:', this.houseNumberOutput);
        console.log('  houseNumberAddition:', this.houseNumberAddition);
        console.log('  postalCodeOutput:', this.postalCodeOutput);
        console.log('  city:', this.city);
        console.log('  intlCountry:', this.intlCountry);
        console.log('  countryIsoOutput:', this.countryIsoOutput);
        
        // Dispatch to Flow immediately
        console.log('Dispatching main outputs to Flow...');
        this.dispatchEvent(new FlowAttributeChangeEvent('streetName', this.streetName));
        this.dispatchEvent(new FlowAttributeChangeEvent('houseNumberOutput', this.houseNumberOutput));
        this.dispatchEvent(new FlowAttributeChangeEvent('houseLetter', this.houseLetter));
        this.dispatchEvent(new FlowAttributeChangeEvent('houseNumberAddition', this.houseNumberAddition));
        this.dispatchEvent(new FlowAttributeChangeEvent('postalCodeOutput', this.postalCodeOutput));
        this.dispatchEvent(new FlowAttributeChangeEvent('city', this.city));
        this.dispatchEvent(new FlowAttributeChangeEvent('addressableObjectIdentification', this.addressableObjectIdentification));
        this.dispatchEvent(new FlowAttributeChangeEvent('intlCountry', this.intlCountry));
        this.dispatchEvent(new FlowAttributeChangeEvent('countryIsoOutput', this.countryIsoOutput));
        
        console.log('✓ Main outputs dispatched to Flow');
        console.log('=== END UPDATING MAIN OUTPUTS ===\n');
    }

    handleAddressSelect(e) {
        const value = e.detail.value;

        if (value === '' || value === null || value === undefined) {
            this.selectedAddressIndex = null;
            this.clearOutputsOnly();
            return;
        }

        const index = parseInt(value, 10);
        if (Number.isNaN(index) || !this.addressList[index]) {
            this.selectedAddressIndex = null;
            this.clearOutputsOnly();
            return;
        }

        this.selectedAddressIndex = value;
        this.setOutputsFrom(this.addressList[index]);
        this.error = null;
    }

    handleNext = () => {
        const { isValid, errorMessage } = this.validate();
        this.error = isValid ? null : errorMessage;
        if (!isValid) return;

        // Populate the SAME output fields based on country
        if (this.isNl) {
            // For NL: use Kadaster data in the main output fields
            // (NL fields are already set by setOutputsFrom method)
            // Just ensure international fields are cleared
            this.clearInternationalOutputsOnly();
        } else {
            // For International: map manual data to the MAIN output fields
            this.streetName = this.manual.street || '';
            this.houseNumberOutput = this.manual.houseNumber || '';
            this.houseLetter = ''; // Not used for international
            this.houseNumberAddition = this.manual.addition || '';
            this.postalCodeOutput = this.manual.postalCode || '';
            this.city = this.manual.city || '';
            this.addressableObjectIdentification = ''; // Not applicable for international
            
            // Set intlCountry from the selected country output
            this.intlCountry = this.countryOutput || '';
            
            // Dispatch the main outputs to Flow
            this.dispatchEvent(new FlowAttributeChangeEvent('streetName', this.streetName));
            this.dispatchEvent(new FlowAttributeChangeEvent('houseNumberOutput', this.houseNumberOutput));
            this.dispatchEvent(new FlowAttributeChangeEvent('houseLetter', this.houseLetter));
            this.dispatchEvent(new FlowAttributeChangeEvent('houseNumberAddition', this.houseNumberAddition));
            this.dispatchEvent(new FlowAttributeChangeEvent('postalCodeOutput', this.postalCodeOutput));
            this.dispatchEvent(new FlowAttributeChangeEvent('city', this.city));
            this.dispatchEvent(new FlowAttributeChangeEvent('addressableObjectIdentification', this.addressableObjectIdentification));
            this.dispatchEvent(new FlowAttributeChangeEvent('intlCountry', this.intlCountry));
            this.dispatchEvent(new FlowAttributeChangeEvent('countryIsoOutput', this.countryIsoOutput));
            
            // Clear unused international outputs (but keep intlCountry)
            this.clearInternationalOutputsOnly();
        }

        // Navigate to next Flow screen
        this.dispatchEvent(new FlowNavigationNextEvent());
    };

    /* =========================================================================
       VALIDATION & API METHODS
       ========================================================================= */
    @api validate() {
        // Ingangsdatum is required in BOTH NL and non-NL flows
        if (!this.ingangsdatum) {
            return { isValid: false, errorMessage: 'Vul een ingangsdatum in.' };
        }

        if (this.isNl) {
            if (
                this.addressList.length > 1 &&
                (this.selectedAddressIndex === null || this.selectedAddressIndex === undefined)
            ) {
                return { isValid: false, errorMessage: 'Selecteer eerst een adres voordat je doorgaat.' };
            }
            const ok = !!(this.streetName && this.addressableObjectIdentification);
            return { isValid: ok, errorMessage: ok ? null : 'Adresselectie is onvolledig.' };
        }

        // Non-NL required fields
        const ok =
            this.manual.street &&
            this.manual.houseNumber &&
            this.manual.postalCode &&
            this.manual.city;

        return { isValid: !!ok, errorMessage: ok ? null : 'Vul alle verplichte velden in (straat, huisnummer, postcode, plaats).' };
    }

    /* =========================================================================
       KADASTER FETCH METHODS
       ========================================================================= */
    scheduleDebouncedFetch() {
        if (this.debounceTimer) clearTimeout(this.debounceTimer);

        const ready =
            this.isNl &&
            this.postalCodeInput &&
            this.houseNumberInput &&
            this.postalCodeValid;

        if (ready) this.debounceTimer = setTimeout(() => this.fetchAddressData(), 600);
    }

    async fetchAddressData() {
        this.loading = true;
        this.error = null;
        this.addressOptions = [];
        this.selectedAddressIndex = null;

        try {
            const data = await fetchAddresses({
                postalCode: this.postalCodeInput,
                houseNumber: this.houseNumberInput
            });

            this.addressList = Array.isArray(data) ? data : [];

            if (this.addressList.length === 0) {
                this.error = 'Geen adres gevonden';
                this.clearOutputsOnly();
                return;
            }

            if (this.addressList.length === 1) {
                const only = this.addressList[0];
                this.addressOptions = [{ label: only.addressLabel, value: '0' }];
                this.selectedAddressIndex = '0';
                this.setOutputsFrom(only);
                return;
            }

            this.addressOptions = this.addressList.map((addr, idx) => ({
                label: addr.addressLabel,
                value: String(idx)
            }));
        } catch (e) {
            this.error = 'Er is een fout opgetreden bij het ophalen van het adres.';
            this.clearOutputsOnly();
        } finally {
            this.loading = false;
        }
    }

    /* =========================================================================
       HELPER METHODS
       ========================================================================= */
    
    /**
     * Updates and dispatches international output values to Flow immediately
     * This ensures Flow receives the international values as they are entered
     */
    updateInternationalOutputs() {
        console.log('=== UPDATE INTERNATIONAL OUTPUTS ===');
        console.log('Current manual object:', JSON.stringify(this.manual, null, 2));
        
        // Set international outputs from manual form (use empty string instead of null for Flow compatibility)
        this.intlStreet = this.manual.street || '';
        this.intlHouseNumber = this.manual.houseNumber || '';
        this.intlHouseAddition = this.manual.addition || '';
        this.intlPostalCode = this.manual.postalCode || '';
        this.intlCity = this.manual.city || '';
        this.intlState = this.manual.state || '';
        this.intlCountry = this.countryOutput || '';
        
        // Debug logging for each assignment
        console.log('Setting international outputs:');
        console.log('  intlStreet: "' + this.intlStreet + '" (from manual.street: "' + this.manual.street + '")');
        console.log('  intlHouseNumber: "' + this.intlHouseNumber + '" (from manual.houseNumber: "' + this.manual.houseNumber + '")');
        console.log('  intlHouseAddition: "' + this.intlHouseAddition + '" (from manual.addition: "' + this.manual.addition + '")');
        console.log('  intlPostalCode: "' + this.intlPostalCode + '" (from manual.postalCode: "' + this.manual.postalCode + '")');
        console.log('  intlCity: "' + this.intlCity + '" (from manual.city: "' + this.manual.city + '")');
        console.log('  intlState: "' + this.intlState + '" (from manual.state: "' + this.manual.state + '")');
        console.log('  intlCountry: "' + this.intlCountry + '" (from countryOutput: "' + this.countryOutput + '")');
        
        // Dispatch each international output to Flow immediately
        console.log('Dispatching to Flow:');
        
        console.log('  → Dispatching intlStreet:', this.intlStreet);
        this.dispatchEvent(new FlowAttributeChangeEvent('intlStreet', this.intlStreet));
        
        console.log('  → Dispatching intlHouseNumber:', this.intlHouseNumber);
        this.dispatchEvent(new FlowAttributeChangeEvent('intlHouseNumber', this.intlHouseNumber));
        
        console.log('  → Dispatching intlHouseAddition:', this.intlHouseAddition);
        this.dispatchEvent(new FlowAttributeChangeEvent('intlHouseAddition', this.intlHouseAddition));
        
        console.log('  → Dispatching intlPostalCode:', this.intlPostalCode);
        this.dispatchEvent(new FlowAttributeChangeEvent('intlPostalCode', this.intlPostalCode));
        
        console.log('  → Dispatching intlCity:', this.intlCity);
        this.dispatchEvent(new FlowAttributeChangeEvent('intlCity', this.intlCity));
        
        console.log('  → Dispatching intlState:', this.intlState);
        this.dispatchEvent(new FlowAttributeChangeEvent('intlState', this.intlState));
        
        console.log('  → Dispatching intlCountry:', this.intlCountry);
        this.dispatchEvent(new FlowAttributeChangeEvent('intlCountry', this.intlCountry));
        
        console.log('✓ All international outputs dispatched to Flow');
        
        // Clear NL outputs when in international mode
        this.clearNlOutputs();
        
        console.log('=== END UPDATE INTERNATIONAL OUTPUTS ===\n');
    }
    
    /**
     * Clears and dispatches NL output values to Flow
     */
    clearNlOutputs() {
        this.streetName = '';
        this.houseNumberOutput = '';
        this.houseLetter = '';
        this.houseNumberAddition = '';
        this.postalCodeOutput = '';
        this.city = '';
        this.addressableObjectIdentification = '';
        
        // Dispatch cleared NL outputs to Flow
        this.dispatchEvent(new FlowAttributeChangeEvent('streetName', this.streetName));
        this.dispatchEvent(new FlowAttributeChangeEvent('houseNumberOutput', this.houseNumberOutput));
        this.dispatchEvent(new FlowAttributeChangeEvent('houseLetter', this.houseLetter));
        this.dispatchEvent(new FlowAttributeChangeEvent('houseNumberAddition', this.houseNumberAddition));
        this.dispatchEvent(new FlowAttributeChangeEvent('postalCodeOutput', this.postalCodeOutput));
        this.dispatchEvent(new FlowAttributeChangeEvent('city', this.city));
        this.dispatchEvent(new FlowAttributeChangeEvent('addressableObjectIdentification', this.addressableObjectIdentification));
    }
    
    /**
     * Clears only the international output values except intlCountry
     * The intlCountry should be preserved as it contains the selected country value
     */
    clearInternationalOutputsOnly() {
        this.intlStreet = '';
        this.intlHouseNumber = '';
        this.intlHouseAddition = '';
        this.intlPostalCode = '';
        this.intlCity = '';
        this.intlState = '';
        // Don't clear intlCountry - it should keep the selected country value
        // this.intlCountry = ''; // This was clearing the country selection!
        
        // We don't dispatch these since we're not using them anymore
        // The main outputs (streetName, city, etc.) are used for both NL and international
        // But we do dispatch intlCountry since it's needed for country display
        console.log('✓ International outputs cleared (except intlCountry which preserves:', this.intlCountry, ')');
    }

    setOutputsFrom(a) {
        // Set NL address data in the main output fields
        this.streetName = a.streetName || '';
        this.houseNumberOutput = a.houseNumber != null ? String(a.houseNumber) : '';
        this.houseLetter = a.houseLetter || '';
        this.houseNumberAddition = a.houseNumberAddition || '';
        this.postalCodeOutput = a.postalCode || '';
        this.city = a.city || '';
        this.addressableObjectIdentification = a.addressableObjectIdentification || '';
        
        // Immediately dispatch NL outputs to Flow when address is selected
        this.dispatchEvent(new FlowAttributeChangeEvent('streetName', this.streetName));
        this.dispatchEvent(new FlowAttributeChangeEvent('houseNumberOutput', this.houseNumberOutput));
        this.dispatchEvent(new FlowAttributeChangeEvent('houseLetter', this.houseLetter));
        this.dispatchEvent(new FlowAttributeChangeEvent('houseNumberAddition', this.houseNumberAddition));
        this.dispatchEvent(new FlowAttributeChangeEvent('postalCodeOutput', this.postalCodeOutput));
        this.dispatchEvent(new FlowAttributeChangeEvent('city', this.city));
        this.dispatchEvent(new FlowAttributeChangeEvent('addressableObjectIdentification', this.addressableObjectIdentification));
        
        console.log('✓ NL address data set in main outputs and dispatched to Flow');
    }

    clearOutputsOnly() {
        // Clear main outputs (used for both NL and international)
        this.clearMainOutputs();
    }

    clearOutputsAndSelection() {
        this.selectedAddressIndex = null;
        this.addressOptions = [];
        this.clearOutputsOnly();
    }

    resetManualInputs() {
        this.manual = { street: '', houseNumber: '', addition: '', postalCode: '', city: '', state: '' };
        console.log('✓ Manual inputs reset');
    }
}

/* =========================================================================
   HELPER: Country list (replace with full ISO-3166 in production)
   ========================================================================= */
function getAllCountries() {
    return [
        { label: 'Nederland', value: 'NL' },
        { label: 'België', value: 'BE' },
        { label: 'Duitsland', value: 'DE' },
        { label: 'Frankrijk', value: 'FR' },
        { label: 'Verenigde Staten', value: 'US' },
        { label: 'Canada', value: 'CA' },
        { label: 'Italië', value: 'IT' },
        { label: 'Spanje', value: 'ES' },
        { label: 'Portugal', value: 'PT' },
        { label: 'Zwitserland', value: 'CH' }
    ];
}