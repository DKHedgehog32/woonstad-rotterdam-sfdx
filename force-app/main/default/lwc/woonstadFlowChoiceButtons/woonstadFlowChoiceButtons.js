/**
 * ===============================================================================================
 * Component       : WoonstadFlowChoiceButtons
 * Layer           : Controller (LWC JS)
 * Purpose         : Display configurable Woonstad-style choice cards in a Flow screen.
 *                   Cards can represent actions like "Informatie vraag", "Naamplaatje aanvragen",
 *                   "Knowledge Goedkeuring" and "Knowledge Afwijzing".
 *
 * Behavior        :
 *   - Input  : availableChoices (String, comma-separated labels)
 *              Example: "Knowledge Goedkeuring, Knowledge Afwijzing, Naamplaatje aanvragen"
 *              Controls which cards are visible.
 *
 *   - Output : selectedChoice (String)
 *              The exact label of the selected card.
 *
 *   - Input  : autoNext (Boolean)
 *              Default true. If true, selection triggers FlowNavigationNextEvent (advances flow).
 *              If false, stays on the same screen — use for in-screen logic or conditional visibility.
 *
 *   - Input  : layout (String)
 *              "horizontal" or "vertical" card layout.
 *
 *   - Deprecated outputs: var_aanvraag, var_vraag (kept for backward compatibility)
 *
 * Author          : Woonstad KC
 * Created         : 2025-08-07
 * Last Modified   : 2025-11-06
 * ===============================================================================================
 */

import { LightningElement, api } from 'lwc';
import {
    FlowNavigationNextEvent,
    FlowAttributeChangeEvent
} from 'lightning/flowSupport';
import { loadStyle } from 'lightning/platformResourceLoader';

// Static resources
import ICON_VRAAG from '@salesforce/resourceUrl/WSRinfo';
import ICON_AANVRAAG from '@salesforce/resourceUrl/WSRcard';
import ICON_GOEDKEURING from '@salesforce/resourceUrl/wsrIconCheck';
import ICON_AFWIJZING from '@salesforce/resourceUrl/wsrIconChatten';
import GLOBAL_CSS from '@salesforce/resourceUrl/WoonstadGlobalCSS';

// =================================================================================================
// Constants
// =================================================================================================
const LABELS = Object.freeze({
    INFO_VRAAG: 'Informatie vraag',
    NAAMPLAATJE: 'Naamplaatje aanvragen',
    GOEDKEURING: 'Goedkeuring',
    AFWIJZING: 'Afwijzing'
});

// Lowercased lookup map for forgiving input
const NORMALIZED = new Map([
    [LABELS.INFO_VRAAG.toLowerCase(), LABELS.INFO_VRAAG],
    [LABELS.NAAMPLAATJE.toLowerCase(), LABELS.NAAMPLAATJE],
    [LABELS.GOEDKEURING.toLowerCase(), LABELS.GOEDKEURING],
    [LABELS.AFWIJZING.toLowerCase(), LABELS.AFWIJZING]
]);

// =================================================================================================
// Class
// =================================================================================================
export default class WoonstadFlowChoiceButtons extends LightningElement {
    // ===============================================================================================
    // Flow API
    // ===============================================================================================

    /** Available flow actions (NEXT, FINISH, etc.) */
    @api availableActions;

    /** Comma-separated list of visible choice labels */
    @api availableChoices;

    /** Output: selected card label */
    @api selectedChoice;

    /** Input: determines if a click triggers FlowNavigationNextEvent */
    @api autoNext = false;

    /** Deprecated outputs kept for backward compatibility */
    @api var_aanvraag;
    @api var_vraag;

    /** Alignment of cards, default center other option left **/
    @api align = 'center' 

    // ===============================================================================================
    // Internal State
    // ===============================================================================================
    iconVraag = ICON_VRAAG;
    iconAanvraag = ICON_AANVRAAG;
    iconGoedkeuring = ICON_GOEDKEURING;
    iconAfwijzing = ICON_AFWIJZING;
    stylesLoaded = false;

    // ===============================================================================================
    // Lifecycle Hooks
    // ===============================================================================================
    renderedCallback() {
        if (this.stylesLoaded) return;

        loadStyle(this, GLOBAL_CSS)
            .then(() => {
                this.stylesLoaded = true;
            })
            .catch((error) => {
                // Log to console — style load failure should not block functionality.
                // eslint-disable-next-line no-console
                console.error('Global styles failed to load:', error);
            });
    }

    // ===============================================================================================
    // Computed Properties
    // ===============================================================================================

    get showInfoVraag() {
        return this._isAllowed(LABELS.INFO_VRAAG);
    }

    get showNaamplaatje() {
        return this._isAllowed(LABELS.NAAMPLAATJE);
    }

    get showGoedkeuring() {
        return this._isAllowed(LABELS.GOEDKEURING);
    }

    get showAfwijzing() {
        return this._isAllowed(LABELS.AFWIJZING);
    }

    // ===============================================================================================
    // Event Handlers
    // ===============================================================================================
    /**
     * Handles click on any choice card.
     * Updates Flow outputs and optionally advances the Flow.
     */
    // === Add this new helper ===
getCardClass = (event) => {
    const label = event?.target?.dataset?.label;
    return `choice-card ${this.selectedChoice === label ? 'selected' : ''}`;
};

get containerClass() {
    // adds a modifier the CSS can target
    return `button-container ${this.align === 'left' ? 'align-left' : 'align-center'}`;
}

// === Update your handleClick() (only small addition) ===
handleClick(event) {
    const label = event?.currentTarget?.dataset?.label;
    if (!label) return;

    // set the selected label
    this.selectedChoice = label;

    // Update visual selection immediately
    this.template.querySelectorAll('.choice-card').forEach((card) => {
        const cardLabel = card.dataset.label;
        card.classList.toggle('selected', cardLabel === this.selectedChoice);
    });

    // --- Set Flow Outputs ---
    const isVraagGroup =
        label === LABELS.INFO_VRAAG;
    const isAanvraagGroup =
        label === LABELS.NAAMPLAATJE;

    this.var_vraag = String(isVraagGroup);
    this.var_aanvraag = String(isAanvraagGroup);

    this.dispatchEvent(
        new FlowAttributeChangeEvent('selectedChoice', this.selectedChoice)
    );
    this.dispatchEvent(
        new FlowAttributeChangeEvent('var_vraag', this.var_vraag)
    );
    this.dispatchEvent(
        new FlowAttributeChangeEvent('var_aanvraag', this.var_aanvraag)
    );

    // --- Conditional Navigation ---
    if (this.autoNext && this.availableActions?.includes('NEXT')) {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}

    // ===============================================================================================
    // Helpers
    // ===============================================================================================
    /**
     * Determines if a given card label should be displayed,
     * based on the comma-separated availableChoices input.
     */
    _isAllowed(label) {
        const list = this._normalizedChoices;
        if (!list || list.length === 0) return true; // show all by default
        return list.includes(label);
    }

    /** Parses and normalizes availableChoices once per render */
    get _normalizedChoices() {
        if (!this.availableChoices || !this.availableChoices.trim()) return [];
        return this.availableChoices
            .split(',')
            .map((s) => s.trim().toLowerCase())
            .map((k) => NORMALIZED.get(k))
            .filter(Boolean); // filter unknown labels
    }
}