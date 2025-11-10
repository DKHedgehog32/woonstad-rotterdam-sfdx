/*************************************************************************************************
 * Component       : woonstadDuplicateCheck (JS)
 * Layer           : Lightning Web Component Controller
 * Purpose         : Search duplicates by email/phone/mobile; show table or empty countdown.
 *                   Provide "Nieuwe klant aanmaken" blue pill (enabled by checkbox) to NEXT.
 *
 * Responsibilities:
 *  - Accept Flow inputs: email, phone, mobile
 *  - Imperative Apex call (exact params: { email, phone, mobile })
 *  - Debounce + prevent overlapping fetches; refetch when inputs change mid-flight
 *  - Loading spinner, results rendering, robust empty-state countdown (only after real fetch)
 *  - Row click navigates NEXT; Pill (when enabled) navigates NEXT
 *  - Flow outputs: selectedExisting & selectedAccountId (preserved)
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-12
 * Last Modified   : 2025-08-27
 * ===============================================================================================
 * Change Log
 * -----------------------------------------------------------------------------------------------
 * 2025-08-27 | DvM | Restored full legacy behavior; added blue pill + checkbox gating.
 * 2025-08-27 | DvM | Stabilized countdown + loading + refetch latch; exact Apex param names.
 * 2025-08-12 | DvM | Initial implementation.
 *************************************************************************************************/

import { LightningElement, api, track } from 'lwc';
import searchByEmailPhone from '@salesforce/apex/WoonstadDuplicateSearchController.searchByEmailPhone';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class WoonstadDuplicateCheck extends LightningElement {
    @api availableActions = [];

    // ---- Flow inputs with setters (schedule fetch when Flow sets them)
    _email = '';
    _phone = '';
    _mobile = '';

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
    @track newCustomerChecked = false;

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
       Computed
       ========================= */
    get hasRows() { return Array.isArray(this.rows) && this.rows.length > 0; }
    get showEmptyState() { return !this.hasRows && !this.loading && this._hasCompletedFetchWithInputs && !this._needsRefetch; }
    get isCreateBtnDisabled() { return !this.newCustomerChecked; }

    /* =========================
       UI Handlers
       ========================= */
    handleRowClick = (evt) => {
        const id = evt?.currentTarget?.dataset?.id;
        if (!id) return;

        // set outputs for Flow
        this.selectedExisting = true;
        this.selectedAccountId = id;
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedExisting', true));
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedAccountId', id));

        this._clearTimers();
        this._tryNext();
    };

    handleRowKeydown = (evt) => {
        const key = evt?.key;
        if (key === 'Enter' || key === ' ') {
            evt.preventDefault();
            this.handleRowClick(evt);
        }
    };

    handleNewCustomerCheckbox = (evt) => {
        this.newCustomerChecked = !!evt?.target?.checked;

        // If creating new → ensure outputs reflect "no existing selected"
        if (this.newCustomerChecked) {
            this.selectedExisting = false;
            this.selectedAccountId = '';
            this.dispatchEvent(new FlowAttributeChangeEvent('selectedExisting', false));
            this.dispatchEvent(new FlowAttributeChangeEvent('selectedAccountId', ''));
        }
    };

    handleNext = () => {
        if (this.isCreateBtnDisabled) return;
        this._clearTimers();
        this._tryNext();
    };

    /* =========================
       Fetch control
       ========================= */
    _hasAnyInput() { return !!(this._email || this._phone || this._mobile); }
    _signature()   { return [this._email, this._phone, this._mobile].join('|'); }

    _scheduleFetch(delayMs = 100) {
        if (!this._hasAnyInput()) return;

        if (this._fetchInFlight) {
            // mark a refetch with latest signature to run after current finishes
            this._needsRefetch = true;
            this._pendingSig = this._signature();
            return;
        }

        if (this._debounceId) clearTimeout(this._debounceId);
        const sig = this._signature();
        this._debounceId = setTimeout(() => this._fetch(sig), delayMs);
    }

    async _fetch(sig) {
        if (this._fetchInFlight) return;

        this._fetchInFlight = true;
        this.loading = true;
        this._clearTimers();

        const params = {
            email:  this._email  || '',
            phone:  this._phone  || '',
            mobile: this._mobile || ''
        };

        try {
            const resp = await searchByEmailPhone(params);

            const results = this._extractArray(resp);
            this.rows = Array.isArray(results) ? results : [];
            this.message = (resp && typeof resp.message === 'string') ? resp.message : '';

            this._hasCompletedFetchWithInputs = true;
            this.loading = false;

            if (this.hasRows) {
                // Do nothing; user can click a row
                this._clearTimers();
            } else {
                // If inputs changed mid-flight, refetch right away
                if (this._needsRefetch) {
                    const againSig = this._pendingSig;
                    this._needsRefetch = false;
                    this._pendingSig = '';
                    this._fetchInFlight = false;
                    return this._fetch(againSig);
                }
                // Otherwise begin countdown
                this._startCountdownAndAutoNext(5);
            }
        } catch (e) {
            this.rows = [];
            this.message = 'Er is een fout opgetreden bij het zoeken.';
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
       NEXT + timers
       ========================= */
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

    _clearTimers() {
        if (this._intervalId) window.clearInterval(this._intervalId);
        if (this._timeoutId) window.clearTimeout(this._timeoutId);
        this._intervalId = undefined;
        this._timeoutId = undefined;
    }
}