/*************************************************************************************************
 * Component       : WoonstadKCCaseChoice (woonstadKCCaseChoice.js)
 * Layer           : UI Controller (Lightning Web Component)
 * Purpose         : Handles click actions for KC cockpit choice cards:
 *                   - "Contactmoment vastleggen"
 *                   - "Nieuwe zaak aanmaken"
 *
 * Responsibilities:
 *  - Load global Woonstad styles (once)
 *  - Expose Flow output variables (var_contactmoment, var_nieuweZaak)
 *  - Navigate to next Flow step after a choice
 *
 * Accessibility   :
 *  - Actual focus & semantics should be handled in the HTML via <button> elements
 *    (instead of clickable <div>s) to ensure keyboard accessibility.
 *
 * Security        :
 *  - UI-only; any data access must be secured in Apex/Flow.
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-18
 * Last Modified   : 2025-08-25
 * ===============================================================================================
 * Change Log
 * -----------------------------------------------------------------------------------------------
 * 2025-08-25 | DvM | Standardized header & inline docs; added FlowAttributeChangeEvent emissions.
 * 2025-08-18 | DvM | Initial version: loads global CSS, handles card clicks, navigates Flow.
 *************************************************************************************************/

import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { loadStyle } from 'lightning/platformResourceLoader';

// Static resources (icons & global stylesheet)
import ICON_CONTACTMOMENT from '@salesforce/resourceUrl/wsrIconPhone';
import ICON_NIEUWE_ZAAK from '@salesforce/resourceUrl/wsrIconCase';
import GLOBAL_CSS from '@salesforce/resourceUrl/WoonstadGlobalCSS';

export default class WoonstadKCCaseChoice extends LightningElement {
    // ===== Public API (Flow outputs & layout) ================================================

    /** Flow output variable: string "true"/"false" to align with existing Flow config. */
    @api var_contactmoment;

    /** Flow output variable: string "true"/"false" to align with existing Flow config. */
    @api var_nieuweZaak;

    /** Optional: layout mode ("horizontal" | "vertical"). */
    @api layout = 'horizontal';

    // ===== Internal State =====================================================================

    /** Icon URLs bound in the template. */
    iconContactmoment = ICON_CONTACTMOMENT;
    iconNieuweZaak = ICON_NIEUWE_ZAAK;

    /** Ensure global CSS is loaded only once. */
    stylesLoaded = false;

    // ===== Lifecycle ==========================================================================

    /**
     * Loads shared Woonstad CSS once.
     */
    renderedCallback() {
        if (this.stylesLoaded) return;
        loadStyle(this, GLOBAL_CSS)
            .then(() => {
                this.stylesLoaded = true;
            })
            .catch((error) => {
                // eslint-disable-next-line no-console
                console.error('Global styles failed to load:', error);
            });
    }

    // ===== Event Handlers =====================================================================

    /**
     * Handles the "Contactmoment vastleggen" action.
     * Sets Flow outputs and advances to the next screen.
     */
    handleContactmomentClick() {
        // Keep string values to match Flow variable types
        this.var_contactmoment = 'true';
        this.var_nieuweZaak = 'false';

        // Inform the Flow about output changes explicitly
        this.dispatchEvent(new FlowAttributeChangeEvent('var_contactmoment', this.var_contactmoment));
        this.dispatchEvent(new FlowAttributeChangeEvent('var_nieuweZaak', this.var_nieuweZaak));

        // Proceed to next screen
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    /**
     * Handles the "Nieuwe zaak aanmaken" action.
     * Sets Flow outputs and advances to the next screen.
     */
    handleNieuweZaakClick() {
        this.var_contactmoment = 'false';
        this.var_nieuweZaak = 'true';

        this.dispatchEvent(new FlowAttributeChangeEvent('var_contactmoment', this.var_contactmoment));
        this.dispatchEvent(new FlowAttributeChangeEvent('var_nieuweZaak', this.var_nieuweZaak));

        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}