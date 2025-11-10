/*************************************************************************************************
 * Component       : wsrPersonAccountModal
 * Layer           : UI Controller (Lightning Web Component)
 * Purpose         : Woonstad-styled content that runs inside a parent-provided modal shell.
 *
 * Aligns With     : KCCaseAction — no inner SLDS modal scaffold; parent provides overlay/chrome.
 *
 * Responsibilities:
 *  - Optional: load shared modal override styles (for consistent typography/spacing)
 *  - Pass recordId into the Flow when present
 *  - Close on Flow FINISHED / FINISHED_SCREEN
 *  - Support both Quick Action close and parent-driven modal close
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-26
 * Last Modified   : 2025-08-26
 * ===============================================================================================
 * Change Log
 * 2025-08-26 | DvM | Option A refactor — removed SLDS modal scaffold; parity with KCCaseAction.
 *************************************************************************************************/

import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { loadStyle } from 'lightning/platformResourceLoader';

// Optional: keep for consistent Woonstad modal look (doesn't add a shell)
import ModalStyles from '@salesforce/resourceUrl/wsrModalOverride';

export default class WsrPersonAccountModal extends LightningElement {
    /** Optional context record passed to the Flow. */
    @api recordId;

    /** Header title for the blue bar. */
    headerTitle = 'Nieuwe klant';

    connectedCallback() {
        // Load shared style overrides for consistent spacing/typography.
        loadStyle(this, ModalStyles).catch((e) => {
            // eslint-disable-next-line no-console
            console.warn('wsrPersonAccountModal: style override failed to load', e);
        });
    }

    /** Flow input variables (only pass when present). */
    get flowInputs() {
        return this.recordId
            ? [{ name: 'recordId', type: 'String', value: this.recordId }]
            : [];
    }

    /** Close on Flow finish events. */
    handleStatusChange(event) {
        const status = event?.detail?.status;
        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            this.closeModal();
        }
    }

    /** Universal close: works for Quick Actions and parent-controlled modals. */
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent()); // Quick Action contexts
        this.dispatchEvent(new CustomEvent('close'));     // Parent LWC/Aura/VF containers
    }
}