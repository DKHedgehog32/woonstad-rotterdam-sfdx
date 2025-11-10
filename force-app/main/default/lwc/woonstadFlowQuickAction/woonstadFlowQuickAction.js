/*************************************************************************************************
 * Component       : WoonstadFlowQuickAction (meta: woonstadFlowQuickAction.js-meta.xml)
 * Layer           : Metadata (LightningComponentBundle)
 * Purpose         : Wraps a Flow in a custom-styled modal for Quick Actions.
 *
 * Responsibilities:
 *  - Provides a consistent Woonstad-styled modal with:
 *      - Blue header bar and custom close button
 *      - Embedded Flow ("Screen_Flow_Create_Update_New_Case_V2")
 *  - Passes the current recordId as input to the Flow.
 *  - Closes automatically when the Flow finishes.
 *  - Loads external CSS (wsrModalOverride) to ensure consistent modal styling.
 *
 * Accessibility   : Close button uses proper event dispatch (CloseActionScreenEvent).
 * Security        : Inherits record context from Quick Action (FLS/CRUD applies in Flow/Apex).
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-06
 * Last Modified   : 2025-08-25
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-08-25 | DvM | Added standardized header, ensured Flow closes modal on completion.
 * 2025-08-06 | DvM | Initial creation with modal override and Flow integration.
 *************************************************************************************************/

import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { loadStyle } from 'lightning/platformResourceLoader';
import ModalStyles from '@salesforce/resourceUrl/wsrModalOverride';

export default class WoonstadFlowQuickAction extends LightningElement {
    @api recordId;
    headerTitle = 'Nieuwe Zaak';

    connectedCallback() {
        loadStyle(this, ModalStyles).catch(error => {
            console.error('Error loading modal styles:', error);
        });
    }

    get flowInputs() {
        return this.recordId
            ? [{ name: 'recordId', type: 'String', value: this.recordId }]
            : [];
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            this.closeModal();
        }
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}