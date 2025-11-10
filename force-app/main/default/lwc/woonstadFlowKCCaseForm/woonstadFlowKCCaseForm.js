/*************************************************************************************************
 * Component       : woonstadFlowKCCaseForm.js
 * Layer           : UI Controller (Lightning Web Component)
 * Purpose         : Displays and manages open Cases for an Account with legacy Woonstad styling.
 *
 * Responsibilities:
 *  - Fetch open Cases (Apex controller)
 *  - Provide client-side search and pagination
 *  - Render clickable, keyboard-accessible rows
 *  - Expose Flow outputs: selectedCaseId, newCaseRequested
 *  - Support optional auto-advance in Flow and in-modal Case creation Flow
 *
 * Accessibility   :
 *  - Keyboard support on rows (Enter/Space triggers select)
 *  - Search input has assistive label in HTML template
 *
 * Security        :
 *  - All data access is server-side via Apex (enforced CRUD/FLS there)
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-14
 * Last Modified   : 2025-08-25
 * ===============================================================================================
 * Change Log:
 * 2025-08-25 | DvM | Standardized header, added inline documentation, ensured Flow outputs dispatch.
 * 2025-08-15 | DvM | Added newCase warning getter and modal Flow handling.
 * 2025-08-14 | DvM | Initial version with legacy Woonstad look, search, pagination, Flow output.
 *************************************************************************************************/

import { LightningElement, api, track } from 'lwc';
import { FlowNavigationNextEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { loadStyle } from 'lightning/platformResourceLoader';
import WoonstadGlobalCSS from '@salesforce/resourceUrl/WoonstadGlobalCSS';
import getCases from '@salesforce/apex/WoonstadFlowKCCaseFormController.getCases';

export default class WoonstadFlowKCCaseForm extends LightningElement {
  /** Flow Inputs **/
  @api recordId;                 // Account Id context
  @api limitSize = 300;          // Server fetch cap
  @api pageSize = 5;             // Rows per page

  // Boolean @api props default to false (per LWC1099 compliance)
  @api showNewCaseButton = false;        // Intended default true
  @api emitNextOnNewCase = false;        // Intended default true
  @api enableModalFlow = false;          // Default off
  @api passRecordIdToModalFlow = false;  // Intended default true
  @api autoAdvanceOnSelect = false;      // Auto-advance Flow after row click
  @api flowApiName = 'Screen_Flow_Create_New_Request_Case';

  /** Flow Outputs **/
  @api newCaseRequested = false;
  @api selectedCaseId = '';

  /** Component State **/
  @track openCases = [];
  @track showFlowModal = false;

  openSearchTerm = '';
  openPage = 1;

  // ===== Effective Booleans (restore intended defaults while remaining LWC1099-compliant) =====
  get showNewCaseButtonEffective() { return this.showNewCaseButton !== false; }
  get emitNextOnNewCaseEffective() { return this.emitNextOnNewCase !== false; }
  get passRecordIdToModalFlowEffective() { return this.passRecordIdToModalFlow !== false; }
  get enableModalFlowEffective() { return this.enableModalFlow === true; }

  // ===== Derived Data =====
  get openCount() { return this.openFiltered.length; }
  get hasOpenCases() { return this.openCount > 0; } // Show warning if >0

  /** Filtered + formatted open cases list */
  get openFiltered() {
    return this.filterAndFormat(this.openCases, this.openSearchTerm);
  }

  /** Page slice with _isSelected marker for template */
  get openPageRows() {
    const start = (this.openPage - 1) * this.pageSize;
    const page = this.openFiltered.slice(start, start + this.pageSize);
    const sel = this.selectedCaseId;
    return page.map(r => ({ ...r, _isSelected: r.Id === sel }));
  }

  /** Paging flags */
  get openTotalPages() { return Math.max(1, Math.ceil(this.openFiltered.length / this.pageSize)); }
  get openPageIsFirst() { return this.openPage <= 1; }
  get openPageIsLast()  { return this.openPage >= this.openTotalPages; }
  get openIsEmpty()     { return this.openFiltered.length === 0; }

  // ===== Lifecycle =====
  connectedCallback() {
    loadStyle(this, WoonstadGlobalCSS).catch(() => {});
    this.fetchOpenCases();
  }

  // ===== Data Fetch =====
  async fetchOpenCases() {
    try {
      if (!this.recordId) {
        this.openCases = [];
        return;
      }
      const resp = await getCases({ recordId: this.recordId, limitSize: this.limitSize });
      const open = resp?.openCases || [];
      this.openCases = this.sortByCreatedDesc(open);
      this.openPage = 1;
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error('[woonstadFlowKCCaseForm] getCases error', e);
      this.openCases = [];
    }
  }

  // ===== Search & Pagination =====
  handleOpenSearch = (e) => {
    this.openSearchTerm = e.target.value || '';
    this.openPage = 1;
  };
  openPrev = () => { if (!this.openPageIsFirst) this.openPage -= 1; };
  openNext = () => { if (!this.openPageIsLast)  this.openPage += 1; };

  // ===== Row Selection =====
  handleRowClick = (e) => {
    const id = e.currentTarget?.dataset?.id;
    if (id) this.selectCase(id);
  };
  handleRowKeydown = (e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      const id = e.currentTarget?.dataset?.id;
      if (id) {
        e.preventDefault();
        this.selectCase(id);
      }
    }
  };
  selectCase(id) {
    this.selectedCaseId = id;

    // Flow output: selectedCaseId
    this.dispatchEvent(new FlowAttributeChangeEvent('selectedCaseId', this.selectedCaseId));

    // Optional auto-advance
    if (this.autoAdvanceOnSelect === true) {
      try {
        this.dispatchEvent(new FlowNavigationNextEvent());
      } catch {
        // Not running inside a Flow context – ignore
      }
    }
  }

  // ===== New Case Actions =====
  handleNewCaseClick() {
    if (this.emitNextOnNewCaseEffective) {
      this.newCaseRequested = true;
      this.dispatchEvent(new FlowAttributeChangeEvent('newCaseRequested', this.newCaseRequested));
      this.dispatchEvent(new FlowNavigationNextEvent());
    } else if (this.enableModalFlowEffective) {
      this.showFlowModal = true;
    }
  }

  handleFlowStatusChange(e) {
    const st = e?.detail?.status;
    if (st === 'FINISHED' || st === 'FINISHED_SCREEN') {
      this.closeFlowModal();
      this.fetchOpenCases(); // Refresh list
    }
  }

  closeFlowModal() { this.showFlowModal = false; }

  // ===== Utilities =====
  filterAndFormat(list, term) {
    const t = (term || '').toLowerCase();
    const arr = Array.isArray(list) ? list : [];
    const filtered = t
      ? arr.filter(r =>
          [r.CaseNumber, r.Status, r.Type, r.Subject, r.Description]
            .some(v => (v || '').toString().toLowerCase().includes(t))
        )
      : arr;

    return filtered.map(r => ({
      ...r,
      CreatedDateDisplay: this.formatDateTime(r.CreatedDate)
    }));
  }

  sortByCreatedDesc(list) {
    return [...(list || [])].sort((a, b) => {
      const ta = new Date(a.CreatedDate).getTime();
      const tb = new Date(b.CreatedDate).getTime();
      return tb - ta;
    });
  }

  formatDateTime(val) {
    if (!val) return '';
    try {
      const d = new Date(val);
      const dd = String(d.getDate()).padStart(2, '0');
      const mm = String(d.getMonth() + 1).padStart(2, '0');
      const yyyy = d.getFullYear();
      const hh = String(d.getHours()).padStart(2, '0');
      const mi = String(d.getMinutes()).padStart(2, '0');
      return `${dd}/${mm}/${yyyy}, ${hh}:${mi}`;
    } catch {
      return val;
    }
  }

  // Decorative search button for UI parity
  noop() {}
}