/**
 * ============================================================================
 * WOONSTAD FLOW CUSTOMER CHOICE COMPONENT
 * ============================================================================
 * 
 * DESCRIPTION:
 * Lightning Web Component for Salesforce Flow that provides a visual choice
 * interface for selecting between Company (Business) and Personal account types.
 * The component renders two clickable cards with icons and labels, allowing
 * users to make a selection that advances the Flow to the next step.
 * 
 * EXPLANATION:
 * This component uses @api properties to communicate with Salesforce Flow:
 * - var_company: Boolean flag set to true when company account is selected
 * - var_person: Boolean flag set to true when personal account is selected
 * - layout: Controls visual layout (horizontal/vertical orientation)
 * 
 * The component automatically equalizes card widths for consistent appearance
 * and loads custom Woonstad styling. When a choice is made, it sets the
 * appropriate boolean flag, clears the other option, and triggers Flow navigation.
 * 
 * CHANGELOG:
 * v1.0.0 - Initial version with Record ID output
 * v1.1.0 - Modified to output boolean true values instead of hardcoded Record IDs
 *        - Simplified click handlers to use boolean logic
 *        - Maintained all existing visual and functional behavior
 *        - Added comprehensive JSDoc documentation
 * 
 * AUTHOR: Dennis van Musschenbroek
 * CREATED: August 25, 2025
 * MODIFIED: August 29, 2025
 * ============================================================================
 */

import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { loadStyle } from 'lightning/platformResourceLoader';
import WOONSTAD_STYLES from '@salesforce/resourceUrl/WoonstadGlobalCSS';

import ICON_COMPANY from '@salesforce/resourceUrl/wsrIconCompany';
import ICON_PERSON from '@salesforce/resourceUrl/wsrIconPerson';

export default class WoonstadFlowCustChoice extends LightningElement {
    // API properties that Flow can read - these will now be boolean values
    @api var_company;
    @api var_person;
    @api layout = 'horizontal'; // Layout option: 'horizontal' or 'vertical'

    // Static resource references for icons
    iconCompany = ICON_COMPANY;
    iconPerson = ICON_PERSON;

    // Flag to prevent multiple CSS loads
    cssLoaded = false;

    /**
     * Lifecycle hook - runs after component renders
     * Loads custom CSS and equalizes card widths for consistent appearance
     */
    renderedCallback() {
        // Load custom CSS only once
        if (!this.cssLoaded) {
            loadStyle(this, WOONSTAD_STYLES).then(() => {
                this.cssLoaded = true;
            });
        }

        // Equalize card widths for consistent visual appearance
        const cards = this.template.querySelectorAll('.choice-card');
        if (cards.length === 0) return;

        // Find the maximum width needed
        let maxWidth = 0;
        cards.forEach(card => {
            card.style.width = 'auto'; // Reset to natural width
            const width = card.offsetWidth;
            if (width > maxWidth) {
                maxWidth = width;
            }
        });

        // Apply the maximum width to all cards
        cards.forEach(card => {
            card.style.width = `${maxWidth}px`;
        });
    }

    /**
     * Computed property for card layout CSS classes
     * Returns appropriate CSS class based on layout setting
     */
    get cardLayout() {
        return this.layout === 'vertical'
            ? 'card-content vertical'
            : 'card-content horizontal';
    }

    /**
     * Handle company/business account selection
     * Sets var_company to true and var_person to null, then proceeds to next flow step
     */
    handleCompanyClick() {
        this.var_company = true;  // Set company choice to true
        this.var_person = null;   // Clear person choice
        this.dispatchEvent(new FlowNavigationNextEvent()); // Proceed to next flow step
    }

    /**
     * Handle personal account selection  
     * Sets var_person to true and var_company to null, then proceeds to next flow step
     */
    handlePersonClick() {
        this.var_person = true;   // Set person choice to true
        this.var_company = null;  // Clear company choice
        this.dispatchEvent(new FlowNavigationNextEvent()); // Proceed to next flow step
    }
}