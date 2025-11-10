import { LightningElement , api } from 'lwc';
import getReferralList from '@salesforce/apex/GetRecordId.getReferral'
import getCaseList from '@salesforce/apex/GetRecordId.getCase'

export default class NonprofitCaseManagementHome extends LightningElement {
    @api app_welcome_text = "Getting Started with Case Management";
    @api app_description = "What category of capabilities are you interested in?";
    @api no_record_referral = false;
    @api no_record_case = false;

    referralId;
    caseId;

    connectedCallback() {
        getReferralList()
        .then(result => {
            console.debug("Referral from getReferral", result);
            if (result.length) {
                this.referralId = result[0].Id;
            } else {
                console.debug("Specified Report is not present");
                this.no_record_referral = true;
                this.referralId = ""
            }
        })

        getCaseList()
        .then(result => {
            console.debug("Case from getCase", result);
            if (result.length) {
                this.caseId = result[0].Id;
            } else {
                console.debug("Specified Report is not present");
                this.no_record_case = true;
                this.caseId = ""
            }
        })
    }

    get pass_false() {
        return false;
    }

    get pass_true() {
        return true;
    }

    get load_data() {
        return false;
    }
    
}