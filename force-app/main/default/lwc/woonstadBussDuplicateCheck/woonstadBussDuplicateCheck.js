/*************************************************************************************************
 * Component       : woonstadBussDuplicateCheck (JS)
 * Layer           : Lightning Web Component Controller
 * Purpose         : Search duplicates by business name/KVK/VAT/email/phone/mobile; show table or empty countdown.
 *                   Provide "Nieuw bedrijf aanmaken" blue pill (enabled by checkbox) to NEXT.
 *
 * Responsibilities:
 *  - Accept Flow inputs: companyName, kvkNumber, vatNumber, email, phone, mobile
 *  - Imperative Apex call (exact params for business search)
 *  - Debounce + prevent overlapping fetches; refetch when inputs change mid-flight
 *  - Loading spinner, results rendering, robust empty-state countdown (only after real fetch)
 *  - Row click navigates NEXT; Pill (when enabled) navigates NEXT
 *  - Flow outputs: selectedExisting & selectedAccountId (preserved)
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-29
 * Last Modified   : 2025-08-29
 * ===============================================================================================
 * Change Log
 * -----------------------------------------------------------------------------------------------
 * 2025-08-29 | DvM | Created business duplicate checker based on customer duplicate checker.
 * 2025-08-29 | DvM | Modified for business-specific search criteria and Apex integration.
 *************************************************************************************************/

import { LightningElement, api, track } from 'lwc';
import searchBusinessDuplicates from '@salesforce/apex/WoonstadBussDuplicateSearchController.searchBusinessDuplicates';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class WoonstadBussDuplicateCheck extends LightningElement {
    @api availableActions = [];

    // ---- Flow inputs with setters (schedule fetch when Flow sets them)
    _companyName = '';
    _kvkNumber = '';
    _vatNumber = '';
    _email = '';
    _phone = '';
    _mobile = '';

    @api get companyName() { return this._companyName; }
    set companyName(v) { this._companyName = (v || '').toString().trim(); this._scheduleFetch(); }

    @api get kvkNumber() { return this._kvkNumber; }
    set kvkNumber(v) { this._kvkNumber = (v || '').toString().trim(); this._scheduleFetch(); }

    @api get vatNumber() { return this._vatNumber; }
    set vatNumber(v) { this._vatNumber = (v || '').toString().trim(); this._scheduleFetch(); }

    @api get email() { return this._email; }
    set email(v) { this._email = (v || '').toString().trim(); this._scheduleFetch(); }

    @api get phone() { return this._phone; }
    set phone(v) { this._phone = (v || '').toString().trim(); this._scheduleFetch(); }

    @api get mobile() { return this._mobile; }
    set mobile(v) { this._mobile = (v || '').toString().trim(); this._scheduleFetch(); }

    // ---- Optional Flow inputs (kept for parity)
    @api autoAdvance = false;
    @api autoAdvanceDelayMs = 6000;

    // ---- Flow outputs
    @api selectedExisting = false;
    @api selectedAccountId = '';

    // ---- UI state
    @track rows = [];
    @track message = '';
    @track secondsRemaining = 5;
    @track loading = false;
    @track newBusinessChecked = false;

    // lifecycle/control
    _debounceId;
    _fetchInFlight = false;
    _autoNextFired = false;
    _intervalId;
    _timeoutId;

    // gating for countdown
    _hasCompletedFetchWithInputs = false;

    // if inputs change during fetch, refetch right after
    _needsRefetch = false;
    _pendingSig = '';

    /* =========================
       Computed Properties
       ========================= */
    get hasRows() { return Array.isArray(this.rows) && this.rows.length > 0; }
    get showEmptyState() { return !this.hasRows && !this.loading && this._hasCompletedFetchWithInputs && !this._needsRefetch; }
    get isCreateBtnDisabled() { return !this.newBusinessChecked; }

    /* =========================
       UI Event Handlers
       ========================= */
    /**
     * Handles clicking on a business row to select an existing business
     * Sets Flow outputs and navigates to next screen
     * @param {Event} evt - Click event from business row
     */
    handleRowClick = (evt) => {
        const id = evt?.currentTarget?.dataset?.id;
        if (!id) return;

        // Set outputs for Flow - existing business selected
        this.selectedExisting = true;
        this.selectedAccountId = id;
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedExisting', true));
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedAccountId', id));

        this._clearTimers();
        this._tryNext();
    };

    /**
     * Handles keyboard navigation on business rows (Enter/Space)
     * @param {KeyboardEvent} evt - Keydown event
     */
    handleRowKeydown = (evt) => {
        const key = evt?.key;
        if (key === 'Enter' || key === ' ') {
            evt.preventDefault();
            this.handleRowClick(evt);
        }
    };

    /**
     * Handles checkbox change for "new business" selection
     * Updates Flow outputs to reflect new business creation intent
     * @param {Event} evt - Checkbox change event
     */
    handleNewBusinessCheckbox = (evt) => {
        this.newBusinessChecked = !!evt?.target?.checked;

        // If creating new business → ensure outputs reflect "no existing selected"
        if (this.newBusinessChecked) {
            this.selectedExisting = false;
            this.selectedAccountId = '';
            this.dispatchEvent(new FlowAttributeChangeEvent('selectedExisting', false));
            this.dispatchEvent(new FlowAttributeChangeEvent('selectedAccountId', ''));
        }
    };

    /**
     * Handles "Nieuw bedrijf aanmaken" button click
     * Only enabled when checkbox is checked
     */
    handleNext = () => {
        if (this.isCreateBtnDisabled) return;
        this._clearTimers();
        this._tryNext();
    };

    /* =========================
       Search Logic
       ========================= */
    /**
     * Checks if any search input is provided
     * @returns {Boolean} True if any search criteria is available
     */
    _hasAnyInput() { 
        return !!(this._companyName || this._kvkNumber || this._vatNumber || this._email || this._phone || this._mobile); 
    }
    
    /**
     * Creates unique signature from all search inputs
     * Used for debouncing and refetch detection
     * @returns {String} Pipe-separated signature of all inputs
     */
    _signature() { 
        return [this._companyName, this._kvkNumber, this._vatNumber, this._email, this._phone, this._mobile].join('|'); 
    }

    /**
     * Schedules a debounced search operation
     * Handles overlapping fetch prevention and refetch queuing
     * @param {Number} delayMs - Debounce delay in milliseconds
     */
    _scheduleFetch(delayMs = 100) {
        if (!this._hasAnyInput()) return;

        if (this._fetchInFlight) {
            // Mark a refetch with latest signature to run after current finishes
            this._needsRefetch = true;
            this._pendingSig = this._signature();
            return;
        }

        if (this._debounceId) clearTimeout(this._debounceId);
        const sig = this._signature();
        this._debounceId = setTimeout(() => this._fetch(sig), delayMs);
    }

    /**
     * Performs the actual search operation via Apex
     * Handles loading states, results processing, and refetch logic
     * @param {String} sig - Signature used for this fetch operation
     */
    async _fetch(sig) {
        if (this._fetchInFlight) return;

        this._fetchInFlight = true;
        this.loading = true;
        this._clearTimers();

        // Prepare search parameters for business duplicate search
        const params = {
            companyName: this._companyName || '',
            kvkNumber: this._kvkNumber || '',
            vatNumber: this._vatNumber || '',
            email: this._email || '',
            phone: this._phone || '',
            mobile: this._mobile || ''
        };

        try {
            const resp = await searchBusinessDuplicates(params);

            const results = this._extractArray(resp);
            this.rows = Array.isArray(results) ? results : [];
            this.message = (resp && typeof resp.message === 'string') ? resp.message : '';

            this._hasCompletedFetchWithInputs = true;
            this.loading = false;

            if (this.hasRows) {
                // Results found - user can click a row
                this._clearTimers();
            } else {
                // Check if inputs changed mid-flight, refetch if needed
                if (this._needsRefetch) {
                    const againSig = this._pendingSig;
                    this._needsRefetch = false;
                    this._pendingSig = '';
                    this._fetchInFlight = false;
                    return this._fetch(againSig);
                }
                // Otherwise begin countdown for auto-advance
                this._startCountdownAndAutoNext(5);
            }
        } catch (e) {
            this.rows = [];
            this.message = 'Er is een fout opgetreden bij het zoeken naar bedrijfsgegevens.';
            this._hasCompletedFetchWithInputs = true;
            this.loading = false;

            if (this._needsRefetch) {
                const againSig = this._pendingSig;
                this._needsRefetch = false;
                this._pendingSig = '';
                this._fetchInFlight = false;
                return this._fetch(againSig);
            }
            this._startCountdownAndAutoNext(5);
        } finally {
            this._fetchInFlight = false;
        }
    }

    /**
     * Extracts array from various possible response formats
     * Handles different Apex response structures gracefully
     * @param {Object} resp - Response from Apex call
     * @returns {Array} Extracted array of results
     */
    _extractArray(resp) {
        if (Array.isArray(resp)) return resp;
        if (resp?.results && Array.isArray(resp.results)) return resp.results;
        if (resp?.records && Array.isArray(resp.records)) return resp.records;
        if (resp?.data && Array.isArray(resp.data)) return resp.data;
        if (resp?.items && Array.isArray(resp.items)) return resp.items;
        if (resp && typeof resp === 'object') {
            for (const k in resp) {
                if (Object.prototype.hasOwnProperty.call(resp, k) && Array.isArray(resp[k])) {
                    return resp[k];
                }
            }
        }
        return [];
    }

    /* =========================
       Navigation & Timer Control
       ========================= */
    /**
     * Starts countdown timer for auto-advance to next screen
     * Only starts if search completed and NEXT action is available
     * @param {Number} seconds - Countdown duration in seconds
     */
    _startCountdownAndAutoNext(seconds) {
        if (!this._hasCompletedFetchWithInputs || this._needsRefetch) return;

        this._clearTimers();

        const canNext =
            Array.isArray(this.availableActions) &&
            this.availableActions.includes('NEXT');
        if (!canNext) return;

        this.secondsRemaining = seconds;

        this._intervalId = window.setInterval(() => {
            if (this.secondsRemaining > 0) this.secondsRemaining -= 1;
        }, 1000);

        this._timeoutId = window.setTimeout(() => {
            this._tryNext();
        }, seconds * 1000);
    }

    /**
     * Attempts to navigate to next Flow screen
     * Prevents duplicate navigation and validates Flow actions
     */
    _tryNext() {
        if (this._autoNextFired) return;

        const canNext =
            Array.isArray(this.availableActions) &&
            this.availableActions.includes('NEXT');
        if (!canNext) { this._clearTimers(); return; }

        this._autoNextFired = true;
        this._clearTimers();
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    /**
     * Clears all active timers
     * Prevents memory leaks and stops countdown
     */
    _clearTimers() {
        if (this._intervalId) window.clearInterval(this._intervalId);
        if (this._timeoutId) window.clearTimeout(this._timeoutId);
        this._intervalId = undefined;
        this._timeoutId = undefined;
    }
}