/**
 * =============================================
 * woonstadFlowNavigationButtons.js
 * =============================================
 * Date: 2025-08-05
 * Last Changed: 2025-08-05
 * Description:
 * Custom navigation buttons for Flow.
 * - Supports Cancel, Back, Next, Bevestigen buttons.
 * - Reads invalidVar from Flow (set by form).
 * - If invalidVar is undefined (Flow sync delay), it directly calls
 *   the form component's validate() for a real-time check.
 * - Prevents navigation if invalidVar is true or validate() fails.
 * - Includes DEBUG logs for traceability.
 * =============================================
 */

import { LightningElement, api } from 'lwc';
import {
    FlowNavigationNextEvent,
    FlowNavigationBackEvent,
    FlowNavigationFinishEvent
} from 'lightning/flowSupport';

export default class WoonstadFlowNavigationButtons extends LightningElement {
    @api showCancel = false;
    @api showBack = false;
    @api showNext = false;
    @api nextLabel = 'Volgende';
    @api showBevestigen = false;
    @api invalidVar; // Flow Boolean variable from form
    @api alignment = 'right';

    get containerClass() {
        return this.alignment === 'left'
            ? 'nav-container align-left'
            : 'nav-container align-right';
    }

    handleCancel() {
        console.log('[DEBUG] Cancel clicked. Ending flow.');
        this.dispatchEvent(new FlowNavigationFinishEvent());
    }

    handleBack() {
        console.log('[DEBUG] Back clicked. Going to previous screen.');
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    handleNext() {
        console.log('[DEBUG] Next clicked. Initial invalidVar =', this.invalidVar);

        setTimeout(() => {
            console.log('[DEBUG] Post-timeout invalidVar =', this.invalidVar);

            // Case 1: Flow already synced invalidVar
            if (this.invalidVar === true) {
                console.log('[DEBUG] Navigation blocked. invalidVar = true');
                return;
            }

            // Case 2: Flow variable not yet synced
            if (this.invalidVar === undefined) {
                console.log('[DEBUG] invalidVar undefined. Falling back to direct validate().');
                const formCmp = document.querySelector('c-woonstad-nameplate-form');
                if (formCmp && typeof formCmp.validate === 'function') {
                    const result = formCmp.validate();
                    console.log('[DEBUG] validate() returned:', result);
                    if (!result.isValid) {
                        console.log('[DEBUG] Navigation blocked by form validate().');
                        return;
                    }
                } else {
                    console.log('[DEBUG] Form component not found, cannot validate.');
                }
            }

            console.log('[DEBUG] Navigation allowed. Dispatching FlowNavigationNextEvent.');
            this.dispatchEvent(new FlowNavigationNextEvent());
        }, 150); // small delay to allow Flow to sync
    }

    handleBevestigen() {
        console.log('[DEBUG] Bevestigen clicked. Initial invalidVar =', this.invalidVar);

        setTimeout(() => {
            console.log('[DEBUG] Post-timeout invalidVar =', this.invalidVar);

            if (this.invalidVar === true) {
                console.log('[DEBUG] Navigation blocked. invalidVar = true');
                return;
            }

            if (this.invalidVar === undefined) {
                console.log('[DEBUG] invalidVar undefined. Falling back to direct validate().');
                const formCmp = document.querySelector('c-woonstad-nameplate-form');
                if (formCmp && typeof formCmp.validate === 'function') {
                    const result = formCmp.validate();
                    console.log('[DEBUG] validate() returned:', result);
                    if (!result.isValid) {
                        console.log('[DEBUG] Navigation blocked by form validate().');
                        return;
                    }
                }
            }

            console.log('[DEBUG] Navigation allowed. Dispatching FlowNavigationNextEvent.');
            this.dispatchEvent(new FlowNavigationNextEvent());
        }, 150);
    }
}