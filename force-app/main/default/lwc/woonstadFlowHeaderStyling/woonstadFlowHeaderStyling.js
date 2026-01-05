/**
 * =============================================
 * Woonstad Flow Header Styling
 * =============================================
 * Date: 2025-08-05
 * Last Changed: 2025-08-05
 * Description:
 * Flow header component showing a label with Woonstad
 * brand styling. Ensures positioning aligns correctly
 * within Flow screens and text stays in one line.
 */

import { LightningElement, api } from 'lwc';

export default class WoonstadFlowHeaderStyling extends LightningElement {
    @api label = 'Wat voor zaak wil je aanmaken?';
    @api top = '0px';
    @api left = '0px';
    @api width = '500px';
    @api height = '40px';
    @api fontSize = '24px';
    @api fontWeight = '700';

    get computedStyle() {
        return `
            position: absolute;
            top: calc(${this.top} - 24px);
            left: ${this.left};
            width: ${this.width};
            height: ${this.height};
            font-family: 'Arboria', sans-serif;
            font-style: normal;
            font-weight: ${this.fontWeight};
            font-size: ${this.fontSize};
            line-height: ${this.height};
            color: #00215B;
            display: flex;
            align-items: center;
            white-space: nowrap;
        `;
    }
}