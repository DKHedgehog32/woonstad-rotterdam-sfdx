import { LightningElement, wire, api } from 'lwc';
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";
import { getRecord } from 'lightning/uiRecordApi';

const columns = [
    { label: 'Participant', fieldName: 'Name' },
    { label: 'Applicant Type', fieldName: 'aType' },
    { label: 'If Contact or Account Exists', fieldName: 'isExists' },
];

export default class DefaultReferralParticipants extends OmniscriptBaseMixin(LightningElement) {
    @api alreadySentData;
    columns = columns;

    @api set referralName(n1) {
        this._referralName = n1;
    }
    get referralName() { 
        return this._referralName; 
    }

    @api set clientName(n1) {
        this._clientName = n1;
    }
    get clientName() { 
        return this._clientName;
    }

    _referrerAccountId;
    _referrerContactId;
    _referrerId;
    _clientId;
    _waitToReferrerWireReturn = true;;
    _waitToClientWireReturn = true;

    @api set referralId(n1) {
        this._referrerId = n1;
        if (n1 !== null && n1 !== undefined && n1.length >= 15) {
            this._waitToReferrerWireReturn = false;
            if (n1.startsWith("001")) {
                this._referrerAccountId = n1;
            } else {
                this._referrerContactId = n1;
            }
        }
    }
    get referralId() { 
        return this._referrerId; 
    }

    @api set clientId(id) {
        if (id !== null && id !== undefined && id.length >= 15) {
            this._clientId = id;
            this._waitToClientWireReturn = false;
        }
    }
    get clientId() {
        return this._clientId;
    }

    _referralName;
    _clientName;

    @wire(getRecord, {recordId: "$_referrerAccountId", fields:['Account.Id','Account.Name']})
    referralRecordAccount({data, error}) {
        if (data) {
            this._referralName = data.fields.Name.value;
            this._waitToReferrerWireReturn = true;
            this.updateOmniscript();
        }
    }

    @wire(getRecord, {recordId: "$_referrerContactId", fields:['Contact.Id','Contact.Name']})
    referralRecordContact({data, error}) {
        if (data) {
            this._referralName = data.fields.Name.value;
            this._waitToReferrerWireReturn = true;
            this.updateOmniscript();
        }
    }

    @wire(getRecord, {recordId: "$clientId", fields:['Account.Id','Account.Name']})
    clientRecord({data, error}) {
        if (data) {
            this._clientName = data.fields.Name.value;
            this._waitToClientWireReturn = true;
            this.updateOmniscript();
        }
    }

    updateOmniscript() {
        if (this._waitToClientWireReturn && this._waitToReferrerWireReturn) {
            if (!this.alreadySentData) {
                const s1 = [];
                if (this._clientId) {
                    s1.push({
                        'Id': this._clientId,
                        'Name' : this._clientName,
                        'isExists': true
                    });
                }
                if (this._referrerId) {
                    s1.push({
                        'Id': this._referrerId,
                        'Name': this._referralName,
                        'isExists': true
                    });
                }
                this.omniApplyCallResp({
                    "AddedParticipants": s1,
                    "DefaultRecordsSaved": true
                });
            }
        }
    }

    get recordList() {
        const t1 = [];
        if (this._referrerId || this._referralName) {
            t1.push({
                'Id': this._referrerId,
                'Name': this._referralName,
                'aType': "Referrer",
                'isExists': this.getRecordType(this.referralId)
            });
        }
        if (this._clientName || this.clientId) {
            t1.push({
                'Id': this._clientId,
                'Name': this._clientName,
                'aType': "Client",
                'isExists': this.getRecordType(this.clientId)
            });
        }
        return t1;
    }
    
    getRecordType(id) {
        return (id === null || id === undefined) ? "None" : (id.startsWith("001") ? "Account" : "Contact");
    }
}