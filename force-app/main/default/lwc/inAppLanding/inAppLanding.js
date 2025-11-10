import { LightningElement, wire, api, track } from 'lwc';

export default class InAppLanding extends LightningElement {
    @api welcome_text = "Welcome to the Nonprofit Cloud Learning Org";
    @api description = "Getting Started with Nonprofit for Programs";
        

    get pass_false() {
        return false;
    }

    get pass_true() {
        return true;
    }

}