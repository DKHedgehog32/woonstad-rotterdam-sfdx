import { LightningElement , api } from 'lwc';
import getReportList from '@salesforce/apex/GetRecordId.getReport'

export default class NonprofitProgramManagementHome extends LightningElement {
    @api app_welcome_text = "Getting Started with Program Management";
    @api app_description = "What category of capabilities are you interested in?";
    @api no_record_report = false;

    reportId;

    connectedCallback() {
        getReportList()
        .then(result => {
            console.debug("Report from getReport", result);
            if (result.length) {
                this.reportId = result[0].Id;
            } else {
                console.debug("Specified Report is not present");
                this.no_record_report = true;
                this.reportId = ""
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