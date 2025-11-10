import { LightningElement,api,track,wire } from 'lwc';
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

const columns = [
    { label: 'Account Name', fieldName: 'name' },
    { label: 'City', fieldName: 'city' },
    { label: 'Address', fieldName: 'address' },
    { label: 'Type', fieldName: 'type' }
];

export default class SelectAndBuildComplaintParticipantsLongIntake extends OmniscriptBaseMixin(LightningElement) {
    @track columns = columns;
    _jsonDef;
    _headerJson;
    _omniJsonData;
    _showResults=false;
    _recordList=[];
    selectedData=new Map(); // Holds all the selected-rows in data-table on every rowSelection event.
    _selectedData=new Map(); // Holds the final list of selected data on click of "Add Selected" button which will be passed to c-selected-list component.
    _lastSearched;
    rolePickListValues;
    roleError;
    statusPicklistValues;
    statusError;

    @wire(getPicklistValues, {
        recordTypeId: '01206000001AUKqAAA', fieldApiName: 'ComplaintParticipant.Role'
    })
    wiredRolePicklistValues({data, error}) {
        if(data){
            this.rolePickListValues = data.values;
            this.statusError=undefined;
        }
        if(error){
            console.log(`Error while fetching Role picklist: ${error}`);
            this.statusError=error;
            this.rolePickListValues = undefined;
        }
    };

    @wire(getPicklistValues, {
        recordTypeId: '01206000001AUKqAAA', fieldApiName: 'ComplaintParticipant.Status'
    })
    wiredStatusPicklistValues({data, error}) {
        if(data){
            this.statusPicklistValues = data.values;
            this.roleError = undefined;
        }
        if(error){
            console.log(`Error while fetching Status picklist: ${error}`);
            this.roleError = error;
            this.statusPicklistValues = undefined;
        }
    };
    
    @api
    set omniJsonDef(json) {
        if(json) {
            this._jsonDef = json;
        }
    }

    get omniJsonDef() {
        return this._jsonDef;
    }

    @api 
    set omniScriptHeaderDef(headerJson) {
        if(headerJson) {
            this._headerJson = headerJson;
        }
    }

    get omniScriptHeaderDef() {
        return this._headerJson;
    }

    @api
    set omniJsonData(omniData) {
        if(omniData) {
            this._omniJsonData = omniData;
        }
    }

    get omniJsonData() {
        return this._omniJsonData;

    }

    restoreSaveState(stateData) {
        // Convert previous LWC state from array to map format.
        let selectedMap=new Map();
        for (let i = 0; i < stateData.selectedArray.length; i++) {
            selectedMap.set(stateData.selectedArray[i].id, {
                "id":stateData.selectedArray[i].id,
                "name":stateData.selectedArray[i].name,
                "role":stateData.selectedArray[i].role,
                "status":stateData.selectedArray[i].status
            });
        }
        this._selectedData = selectedMap;
        this.rolePickListValues = stateData.rolePickListValues;
        this.statusPicklistValues = stateData.statusPicklistValues;
    }

    connectedCallback() {
        let stateData = this.omniGetSaveState();
        const stateDataCleared = this.omniGetSaveState(this.omniJsonDef.name + '-$Vlocity.cleared');
        if (stateData && !stateDataCleared) {
            this.restoreSaveState(stateData);
        }
    }

    @api
    set recordList(recordList) {
        this._recordList = [];
        if(typeof(recordList.length) != "undefined" && recordList.length > 0) {
            const copyData = JSON.parse(JSON.stringify(recordList));
            if(copyData.length == 1 && typeof(copyData[0].LastName) == "undefined") {
                this._recordList = [];
            } else { 
                copyData.forEach(item => {
                    let record = {
                        id: item.Id,
                        name: item.Name
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
        }

        if (this._recordList.length == 0) {
            this._showResults=false;
        }
        else
        {
            this._showResults=true;
        }
    }
    
    get recordList() {
        return this._recordList;
    }

    handleSelectedRows(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedData=new Map();
        for (let i = 0; i < selectedRows.length; i++) {
            this.selectedData.set(selectedRows[i].id, {
                "id":selectedRows[i].id,
                "name":selectedRows[i].name,
                "role":this.rolePickListValues[0].value, //I think this is a problem
                "status":this.statusPicklistValues[0].value
            });
        }
    }

    handleAddSelected(event) {
        this._selectedData = this.selectedData;
    }

    handleRowDeleted(event) {
        const selection = event.detail;
        this._selectedData = selection;
    }

    handleDataChange(event) {
        this._lastSearched=true;
        const selectedList = event.detail;
        let recordArray=[];
        let selectedArray=[];
        for (let [key, value] of selectedList.entries()) {
            recordArray.push(value);
            selectedArray.push({
                id: key,
                name: value.name,
                role: value.role,
                status: value.status,
            });
        }
        this.omniUpdateDataJson(recordArray);
        this.omniSaveState({
            selectedArray:selectedArray,
            rolePickListValues:this.rolePickListValues,
            statusPicklistValues:this.statusPicklistValues}, null, true);
    }
}