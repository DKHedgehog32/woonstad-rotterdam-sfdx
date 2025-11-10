/*************************************************************************************************
 * Component       : woonstadKCCaseAction.js
 * Layer           : UI Controller (Lightning Web Component)
 * Purpose         : Hosts a modal with a Woonstad-styled header and an embedded Flow for
 *                   creating/updating a Case (Screen_Flow_KC_Create_Update_Case).
 *
 * Responsibilities:
 *  - Load custom modal styles (from static resource)
 *  - Pass recordId as Flow input
 *  - Close modal when Flow finishes (FINISHED/FINISHED_SCREEN)
 *
 * Accessibility   :
 *  - Relies on template <button> (aria-labeled) for modal close action
 *
 * Security        :
 *  - UI only; Flow/Apex handle authorization and data access
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-25
 * Last Modified   : 2025-08-25
 * ===============================================================================================
 * Change Log
 * -----------------------------------------------------------------------------------------------
 * 2025-08-25 | DvM | Added full header, Flow FINISHED handling, and style loading with error logging.
 *************************************************************************************************/

import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { loadStyle } from 'lightning/platformResourceLoader';

// Static resource for overriding Salesforce modal styles
import ModalStyles from '@salesforce/resourceUrl/wsrModalOverride';

export default class WoonstadKCCaseAction extends LightningElement {
    /** The record Id passed to the Flow. */
    @api recordId;

    /** The modal header title. */
    headerTitle = 'KC Zaak';

    /**
     * Load modal-specific styling on component initialization.
     */
    connectedCallback() {
        loadStyle(this, ModalStyles).catch((error) => {
            // eslint-disable-next-line no-console
            console.error('Error loading modal styles:', error);
        });
    }

    /**
     * Prepare Flow input variables based on current record context.
     */
    get flowInputs() {
        return this.recordId
            ? [{ name: 'recordId', type: 'String', value: this.recordId }]
            : [];
    }

    /**
     * Listen to Flow status changes and close modal when Flow completes.
     */
    handleStatusChange(event) {
        const status = event.detail.status;
        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            this.closeModal();
        }
    }

    /**
     * Dispatches the platform CloseActionScreenEvent to close the modal.
     */
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}