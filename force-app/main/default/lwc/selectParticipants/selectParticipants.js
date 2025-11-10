import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";

const columns = [
    { label: 'Name', fieldName: 'name' },
    { label: 'City', fieldName: 'city' },
    { label: 'Address', fieldName: 'address' },
    { label: 'Type', fieldName: 'type' }
];

export default class SelectParticipants extends OmniscriptBaseMixin(LightningElement) {
    @track columns = columns;
    @track _recordList = [];
    _index = 0;

    constructor(){
        super();
        this._index = 0;
    }

    get showResults() {
        return this.recordList && (this.recordList.length > 0);
    }

    showEmptyMsg = false;

    @api
    set recordList(recordList) {
        this._recordList = [];
        if (recordList === undefined || recordList === null) {
            this.showEmptyMsg = false;
        } else if(recordList.length > 0) {
            const copyData = JSON.parse(JSON.stringify(recordList));
            if(copyData.length == 1 && typeof(copyData[0].LastName) == "undefined") {
                this._recordList = [];
            } else { 
                copyData.forEach(item => {
                    let record = {
                        id: item.Id,
                        name: item.Name,
                        indexNo: this._index++
                    };
                    if(item.Id.startsWith("001")) {
                        record.type="Account";
                        record.city=item.ShippingCity;
                        let address="";
                        if(item.ShippingAddress != null && item.ShippingAddress.street != null) {
                            address = item.ShippingAddress.street;
                        }
                        if(item.ShippingAddress != null && item.ShippingAddress.city != null) {
                            if(address != "") {
                                address = address + ", "
                            }
                            address = address + item.ShippingAddress.city;
                        }
                        if(item.ShippingAddress != null && item.ShippingAddress.state != null) {
                            if(address != "") {
                                address = address + ", "
                            }
                            address = address + item.ShippingAddress.state;
                        }
                        if(item.ShippingAddress != null && item.ShippingAddress.postalCode != null) {
                            if(address != "") {
                                address = address + " "
                            }
                            address = address + item.ShippingAddress.postalCode;
                        }
                        record.address=address;
                    }
                    else if(item.Id.startsWith("003")) {
                        record.type="Contact";
                        record.city=item.MailingCity;
                        let address="";
                        if(item.MailingAddress != null && item.MailingAddress.street != null) {
                            address = item.MailingAddress.street;
                        }
                        if(item.MailingAddress != null && item.MailingAddress.city != null) {
                            if(address != "") {
                                address = address + ", "
                            }
                            address = address + item.MailingAddress.city;
                        }
                        if(item.MailingAddress != null && item.MailingAddress.state != null) {
                            if(address != "") {
                                address = address + ", "
                            }
                            address = address + item.MailingAddress.state;
                        }
                        if(item.MailingAddress != null && item.MailingAddress.postalCode != null) {
                            if(address != "") {
                                address = address + " "
                            }
                            address = address + item.MailingAddress.postalCode;
                        }
                        record.address=address;
                    }
                    else {
                        console.log("Error: Different type passed: " + item.Id);
                    }
                    this._recordList.push(record);
                });
            }
            this.showEmptyMsg = false;
        } else {
            this.showEmptyMsg = true;
        }
    }

    get errorMsg() {
        if (this.isUndefinedOrNull(this.selectedRecords) || this.selectedRecords.length == 0) {
            return "Please add participants";
        }
        if (this.areSelectedRecordsValid) return "";
        return "Select Participant's Role and Status";
    }

    get recordList() {
        console.log('$$$ this._recordList:  ' + this._recordList + ';');
        return this._recordList;
    }

    areSelectedRecordsValid;
    isUndefinedOrNull(val) {
        return val === undefined || val === null || val === "";
    }
    valid (record) {
        return !this.isUndefinedOrNull(record.Name) && !this.isUndefinedOrNull(record.Id) 
        && !this.isUndefinedOrNull(record.Role) && !this.isUndefinedOrNull(record.Status);
    }

    @track _selectedRecords = [];
    _selectedRecordIdMap = {};
    @api set selectedRecords(selectedRecords) {
        this._selectedRecordIdMap = {};
        this.areSelectedRecordsValid = true;
        this._selectedRecords = !this.isUndefinedOrNull(selectedRecords)? JSON.parse(JSON.stringify(selectedRecords)) : [];
        for (const record of this._selectedRecords) {
            record.indexNo = String(this._index);
            this._index++;
            this._selectedRecordIdMap[record.indexNo] = record;
            this.areSelectedRecordsValid = this.areSelectedRecordsValid && this.valid(record);
        }
        this.omniApplyCallResp({
            "AreAddedParticipantValid": this.areSelectedRecordsValid
        });
    }
    get selectedRecords() {
        return this._selectedRecords;
    }

    get showSelectedRecords() {
        return this._selectedRecords && (this._selectedRecords.length > 0);
    }

    handleAddSelected() {
        const table = this.template.querySelector('lightning-datatable');
        if (table) {
            const rows = table.getSelectedRows();
            rows.forEach((row) => {
                if (!this._selectedRecordIdMap.hasOwnProperty(row.indexNo)) {
                    const record = {
                        Id: row.id,
                        Name: row.name,
                        indexNo: row.indexNo
                    };
                    this._selectedRecords.push(record);
                    this._selectedRecordIdMap[row.indexNo] = record;
                }
            });
        }
        this.omniApplyCallResp({
            "AddedParticipants": this._selectedRecords
        });
    }

    handleRoleChange(event) {
        const indexNo = event.currentTarget.getAttribute("data-id");
        const value = event.detail.value;
        this._selectedRecordIdMap[indexNo].Role = value;
        this.omniApplyCallResp({
            "AddedParticipants": this._selectedRecords
        });
    }

    handleStatusChange(event) {
        const indexNo = event.currentTarget.getAttribute("data-id");
        const value = event.detail.value;
        this._selectedRecordIdMap[indexNo].Status = value;
        this.omniApplyCallResp({
            "AddedParticipants": this._selectedRecords
        });
    }

    onDeleteClick(event) {
        const indexNo = event.currentTarget.getAttribute("data-id");
        this._selectedRecords = this._selectedRecords.filter((record) => record.indexNo !== indexNo);
        delete(this._selectedRecordIdMap[indexNo]);
        this.omniApplyCallResp({
            "AddedParticipants": this._selectedRecords
        });
    }
}