import { api, LightningElement } from 'lwc';
/**
 *  IMPORTANT! Generated class DO NOT MODIFY
 */
export default class sPCMSubmitReferralEnglish extends LightningElement {
    @api get dir() {
        return this.runtimeWrapper?.direction;
    }
    set dir(dir) {
        // no-op
    }
    @api get inline() {
        return this.runtimeWrapper?.inline;
    }
    set inline(inline) {
        // no-op
    }
    @api get inlineVariant() {
        return this.runtimeWrapper?.inlineVariant;
    }
    set inlineVariant(inlineVariant) {
        // no-op
    }
    @api get layout() {
        return this.runtimeWrapper?.theme;
    }
    set layout(layout) {
        // no-op
    }
    @api get recordId() {
        return this.runtimeWrapper?.recordId;
    }
    set recordId(recordId) {
        if (this.runtimeWrapper) {
            return this.runtimeWrapper.recordId = recordId;
        }
    }
    @api get omniscriptId() {
        return this.runtimeWrapper?.omniscriptId;
    }
    set omniscriptId(omniscriptId) {
        if (this.runtimeWrapper) {
            return this.runtimeWrapper.omniscriptId = omniscriptId;
        }
    }
    @api get prefill() {
        return this.runtimeWrapper?.prefill;
    }
    set prefill(prefill) {
        if (this.runtimeWrapper) {
            return this.runtimeWrapper.prefill = prefill;
        }
    }
    @api get instanceId() {
        return this.runtimeWrapper?.instanceId;
    }
    set instanceId(instanceId) {
        if (this.runtimeWrapper) {
            return this.runtimeWrapper.instanceId = instanceId;
        }
    }
    @api get runMode() {
        return this.runtimeWrapper?.runMode;
    }
    set runMode(runMode) {
        // no-op
    }

    // not supported in standard runtime but kept
    // for api compatibility.
    @api flexipageRegionWidth;
    @api inlineLabel;
    @api connection;
    @api jsonDataStr;
    @api jsonDef;
    @api seedJson
    @api resume;
    @api scriptHeaderDef;
    @api jsonData;
    @api applyCallResp(data, bApi = false, bValidation = false) {
    }
    @api reportValidity() {
    }
    @api handleInvalid() {
    }
    @api handleAdd() {
    }
    @api handleRemove() {
    }

    get runtimeWrapper() {
        return this.template.querySelector('omnistudio-omniscript-standard-runtime-wrapper')?.generatedOs;
    }
}