/**
 * =============================================
 * WoonstadStepPath.js
 * =============================================
 * Date: 2025-08-06
 * Last Changed: 2025-08-06
 * Description:
 * Woonstad Step Path for flows.
 * - Renders steps from JSON (number, label, tooltip).
 * - Completed => green with check; Active => blue; Future => grey.
 * - Single global tooltip anchored above the path row.
 * - Tooltip only shows for the active step; clamped to viewport edges.
 * =============================================
 */

import { LightningElement, api, track } from 'lwc';

export default class WoonstadStepPath extends LightningElement {
    // Internal state
    _jsonInput;
    _stepsRaw = [];
    _currentStep = 0;

    // Rendered steps
    @track steps = [];

    // Global tooltip state
    @track showTooltip = false;
    @track tooltipText = '';
    @track tooltipStyle = ''; // e.g., "top:100px;left:300px;width:280px;"

    /**
     * Public API: JSON input (array of steps).
     * Example:
     * [
     *  { "number":1, "label":"Vul de gegevens in", "tooltip":"Begin van de aanvraag" },
     *  { "number":2, "label":"Samenvatting",       "tooltip":"Controleer overzicht" }
     * ]
     */
    @api
    set jsonInput(value) {
        this._jsonInput = value;
        this.parseJson(value);
    }
    get jsonInput() {
        return this._jsonInput;
    }

    /**
     * Public API: active step (number).
     */
    @api
    set currentStep(value) {
        this._currentStep = Number(value);
        this._refreshSteps();
    }
    get currentStep() {
        return this._currentStep;
    }

    // Parse JSON safely
    parseJson(value) {
        try {
            this._stepsRaw = JSON.parse(value);
        } catch (e) {
            // On invalid JSON, reset
            // eslint-disable-next-line no-console
            console.error('Invalid JSON for step path:', e);
            this._stepsRaw = [];
        }
        this._refreshSteps();
    }

    // Build render model with classes
    _refreshSteps() {
        if (!Array.isArray(this._stepsRaw)) {
            this.steps = [];
            this._hideTooltip();
            return;
        }
        const current = this._currentStep;
        this.steps = this._stepsRaw.map(s => {
            const isCompleted = s.number < current;
            const isActive = s.number === current;
            return {
                ...s,
                isCompleted,
                isActive,
                displayValue: isCompleted ? '✓' : s.number,
                circleClass: `step-circle ${isCompleted ? 'completed' : isActive ? 'active' : 'inactive'}`,
                labelClass:  `step-label ${isActive ? 'active' : 'inactive'}`
            };
        });
        // When steps refresh, also hide the tooltip to avoid stale positions
        this._hideTooltip();
    }

    // Hover handlers - show only for active step; tooltip is global & fixed Y
    handleMouseOver(event) {
        const stepId = Number(event.currentTarget.dataset.id);
        const hovered = this.steps.find(x => x.number === stepId);
        if (!hovered || !hovered.isActive) {
            this._hideTooltip();
            return;
        }

        // Compute a fixed position above the path row, centered near the hovered step
        const pathEl = this.template.querySelector('[data-path]');
        const circleEl = event.currentTarget.querySelector('.step-circle');
        if (!pathEl || !circleEl) {
            this._hideTooltip();
            return;
        }

        const pathRect = pathEl.getBoundingClientRect();
        const circleRect = circleEl.getBoundingClientRect();

        // Tooltip sizing and viewport padding
        const tooltipWidth = 280;          // matches CSS min range
        const padding = 20;                // min distance from viewport edges
        const topOffset = 12;              // gap between tooltip and path row

        // Lock Y to above the path row (fixed spot), not per-circle
        const top = Math.max(padding, pathRect.top - topOffset - 40); // 40≈tooltip height/2 visual balance

        // Center over the hovered circle, then clamp to viewport
        let left = circleRect.left + circleRect.width / 2 - tooltipWidth / 2;
        const maxLeft = window.innerWidth - tooltipWidth - padding;
        if (left < padding) left = padding;
        if (left > maxLeft) left = maxLeft;

        this.tooltipText = hovered.tooltip || '';
        this.tooltipStyle = `top:${top}px; left:${left}px; width:${tooltipWidth}px;`;
        this.showTooltip = !!this.tooltipText;
    }

    handleMouseOut() {
        this._hideTooltip();
    }

    _hideTooltip() {
        this.showTooltip = false;
        this.tooltipText = '';
        this.tooltipStyle = '';
    }
}