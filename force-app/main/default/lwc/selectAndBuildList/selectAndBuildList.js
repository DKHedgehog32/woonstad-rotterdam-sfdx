import { LightningElement,api,track } from 'lwc';
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";
import pubsub from 'omnistudio/pubsub';


const columns = [
    { label: 'Account Name', fieldName: 'name' },
    { label: 'City', fieldName: 'city' },
    { label: 'Address', fieldName: 'address' },
    { label: 'Type', fieldName: 'type' }
];

export default class lwcdatatable extends OmniscriptBaseMixin(LightningElement) {
    @track columns = columns;
    _jsonDef;
    _headerJson;
    _omniJsonData;
    _showResults=false;
    _recordList;
    selectedData=new Map(); // Holds all the selected-rows in data-table on every rowSelection event.
    _selectedData=new Map(); // Holds the final list of selected data on click of "Add Selected" button which will be passed to c-selected-list component.
    
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

    @api
    set recordList(recordList) {
        console.log('### this._recordList:  ' + recordList.length + '; ' + JSON.stringify(recordList));
        if(recordList.length > 0) {
            const copyData = JSON.parse(JSON.stringify(recordList));
            if(copyData.length == 1 && typeof(copyData[0].id) == "undefined") {
                this._recordList = [];
            } else {
                for (let i = 0; i < copyData.length; i++) {
                    if(copyData[i].id.startsWith("001")) {
                        copyData[i].type="Account";
                    }
                    else if(copyData[i].id.startsWith("003")) {
                        copyData[i].type="Contact";
                    }
                    else {
                        console.log("Error: Different type passed: " + copyData[i].id);
                    }
                    let address="";
                    if(typeof(copyData[i].street) != "undefined" && copyData[i].street != null) {
                        address = copyData[i].street;
                    }
                    if(typeof(copyData[i].city) != "undefined" && copyData[i].city != null) {
                        if(address != "") {
                            address = address + ", "
                        }
                        address = address + copyData[i].city;
                    }
                    if(typeof(copyData[i].state) != "undefined" && copyData[i].state != null) {
                        if(address != "") {
                            address = address + ", "
                        }
                        address = address + copyData[i].state;
                    }
                    if(typeof(copyData[i].postalCode) != "undefined" && copyData[i].postalCode != null) {
                        if(address != "") {
                            address = address + " "
                        }
                        address = address + copyData[i].postalCode;
                    }
                    copyData[i].address=address;
                }
                this._recordList = [...copyData];
            }
            
            if (this._recordList.length == 0) {
                console.log('selectAndBuildList: Found zero record');
                this._showResults=false;
            }
            else
            {
                this._showResults=true;
            }
        }
    }
    
    get recordList() {
        console.log('$$$ this._recordList:  ' + this._recordList + ';');
        return this._recordList;
    }

    handleSelectedRows(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedData=new Map();
        for (let i = 0; i < selectedRows.length; i++) {
            console.log('selectAndBuildList: You selected row with id: ' + selectedRows[i].id);
            this.selectedData.set(selectedRows[i].id, selectedRows[i].name);
        }
    }

    handleAddSelected(event) {
        this._selectedData = this.selectedData;
        console.log('selectAndBuildList: handleAddSelected _selectedData: ' + this._selectedData.size);
    }

    handleRowDeleted(event) {
        const selection = event.detail;
        console.log('selectAndBuildList: handleRowDeleted: ' + selection.size);
        this._selectedData = selection;
    }

    handleDataChange(event) {
        const selectedList = event.detail;
        let recordArray=[];
        console.log('selectAndBuildList selectedList.size: ' + selectedList.size);
        for (let [key, value] of selectedList.entries()) {
            recordArray.push(value);
         }
        pubsub.fire("rowSelection", 'selection_changed', {"selectedData": recordArray});
    }
}