/*************************************************************************************************
 * Component       : WoonstadConfirmationForm (Controller)
 * Layer           : Presentation Logic (LWC JS)
 * Purpose         : Handles UI logic for confirmation of customer/case data.
 *
 * Responsibilities:
 *  - Fetch account/address data from Apex (RealEstateSupplierFlowController)
 *  - Validate required fields (Name, Address) before proceeding
 *  - Dispatch Flow navigation events (Next/Back)
 *
 * Accessibility   : Banner is marked with role="alert" for screen readers.
 * Security        : Data integrity and CRUD/FLS enforced via Apex.
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-06
 * Last Modified   : 2025-08-25
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-08-25 | DvM | Added validation logic for Name/Address; introduced error banner; standardized header.
 * 2025-08-06 | DvM | Initial creation for Flow confirmation.
 *************************************************************************************************/

import { LightningElement, api, wire, track } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
import getFirstSupplier from '@salesforce/apex/RealEstateSupplierFlowController.getFirstSupplier';

export default class WoonstadConfirmationForm extends LightningElement {
    // ===== Flow Inputs =====
    @api recordId;
    @api flowInputNamePlate;
    @api flowInputName;
    @api flowInputReason;
    @api flowInputSupplierName;

    // ===== Apex Outputs =====
    @track klantNaam;
    @track fullStreet;
    @track postalCode;
    @track city;
    @track eigenaar;

    // ===== UI State =====
    @track showValidationError = false;

    // Mapping API value → label
    reasonOptions = [
        { label: 'Vernield / gestolen', value: 'Vandalism/stolen' },
        { label: 'Nieuwe woning', value: 'New tenant' },
        { label: 'Veranderde Samenstelling', value: 'New composition of residency' },
        { label: 'Verkeerde Spelling', value: 'Incorrect name spelling' }
    ];

    @wire(getFirstSupplier, { accountId: '$recordId' })
    wiredSupplier({ error, data }) {
        if (data) {
            this.klantNaam = data.klantNaam;
            this.fullStreet = data.fullStreet;
            this.postalCode = data.postalCode;
            this.city = data.city;
            this.eigenaar = data.eigenaar;
            this._renderAddress();
        } else if (error) {
            console.error('Error retrieving supplier data:', JSON.stringify(error, null, 2));
        }
    }

    renderedCallback() {
        this._renderAddress();
    }

    // ===== Computed =====
    get isNamePlateMissing() {
        return !this.flowInputNamePlate;
    }

    get displayNamePlate() {
        return this.flowInputNamePlate;
    }

    get displayReason() {
        const match = this.reasonOptions.find(opt => opt.value === this.flowInputReason);
        return match ? match.label : '...';
    }

    get displayAddress() {
        if (this.fullStreet || this.postalCode || this.city) {
            return `${this.fullStreet || ''}<br/>${this.postalCode || ''} ${this.city || ''}`.trim();
        }
        return '...';
    }

    get _hasValidName() {
        const nameVal = (this.klantNaam ?? this.flowInputName ?? '').trim();
        return nameVal.length > 0;
    }

    get _hasValidAddress() {
        const street = (this.fullStreet ?? '').trim();
        const pc = (this.postalCode ?? '').trim();
        const c = (this.city ?? '').trim();
        return street.length > 0 && (pc.length > 0 || c.length > 0);
    }

    // ===== Handlers =====
    handleNext() {
        const valid = this._hasValidName && this._hasValidAddress;
        this.showValidationError = !valid;

        if (!valid) {
            requestAnimationFrame(() => {
                const banner = this.template.querySelector('[data-id="validationBanner"]');
                banner?.scrollIntoView({ behavior: 'smooth', block: 'start' });
            });
            return;
        }

        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    handleBack() {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    // ===== Helpers =====
    _renderAddress() {
        const container = this.template?.querySelector?.('[data-id="addressContainer"]');
        if (container) container.innerHTML = this.displayAddress;
    }
}