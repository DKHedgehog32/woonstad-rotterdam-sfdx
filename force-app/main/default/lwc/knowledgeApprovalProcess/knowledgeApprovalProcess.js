/**
 * ===============================================================================================
 * Class            : knowledgeApprovalProcess
 * Layer            : UI Controller (Lightning Web Component)
 * Purpose          : Collect a single approval/validation comment for the current Knowledge
 *                   article version and send it to Apex to update Approval_Comment__c +
 *                   ValidationStatus = 'Waiting For Validation'.
 * Author           : Dylan Pluk
 * Created          : 2025-11-06
 * -----------------------------------------------------------------------------------------------
 * Change Log
 * 2025-11-06 | DP | Initial creation.
 *************************************************************************************************/

import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationFinishEvent, FlowNavigationNextEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';

import updateKnowledgeVersion from '@salesforce/apex/KnowledgeApprovalProcessController.updateKnowledgeVersion';

export default class KnowledgeApprovalProcess extends LightningElement {

    @api recordId;
    @api approvalComment;

    @track comment = '';
    @track validationMessage = '';
    @track isSaving = false;
    showInfoBanner = true;

    handleCommentChange(event) {
        this.comment = event.target.value;
        this.validationMessage = '';

        // set comment as output for flow
        this.approvalComment = this.comment;
        this.dispatchEvent(
            new FlowAttributeChangeEvent('approvalComment', this.comment)
        );
    }

    validate() {
        if (!this.comment || !this.comment.trim()) {
            this.validationMessage = 'Vul eerst in wat je wilt vertellen over de wijziging.';
            const textarea = this.template.querySelector('lightning-textarea[data-required="true"]');
            if (textarea) {
                textarea.setCustomValidity('Dit veld is verplicht.');
                textarea.reportValidity();
            }
            return false;
        }

        const textarea = this.template.querySelector('lightning-textarea[data-required="true"]');
        if (textarea) {
            textarea.setCustomValidity('');
            textarea.reportValidity();
        }
        this.validationMessage = '';
        return true;
    }

    handleSave() {
        if (!this.recordId) {
            this.showToast(
                'Configuratiefout',
                'Geen Knowledge artikelversie (recordId) meegegeven aan het component.',
                'error'
            );
            return;
        }

        if (!this.validate()) {
            return;
        }

        this.isSaving = true;
        updateKnowledgeVersion({
            articleVersionId: this.recordId,
            approvalComment: this.comment
        })
            .then(() => {
                this.showToast(
                    'Opgeslagen',
                    'Je toelichting is opgeslagen en het artikel wacht nu op beoordeling.',
                    'success'
                );
                
                if (this.navigationMode === 'next') {
                    try {
                        this.dispatchEvent(new FlowNavigationNextEvent());
                    } catch (e) {
                        // ignore if not allowed
                    }
                } else {
                    this.dispatchEvent(new FlowNavigationFinishEvent());
                }
            })
            .catch(error => {
                const message =
                    error && error.body && error.body.message
                        ? error.body.message
                        : 'Onbekende fout bij het bijwerken van het artikel.';
                this.showToast('Fout', message, 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}