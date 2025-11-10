import { LightningElement,api,track } from 'lwc';

export default class SelectedComplaintParticipantsLongIntake extends LightningElement {
    _recorddata = new Map(); // Holds map of record data as <id,{id,name,role,status}> pair. It will be filled and validated whenever api attribute recorddata is changed
    @track recorddataarr=[]; // Holds _recorddata in array format as {id: ,name: } which is used for renderring
    _showResults=false;
    _selectedData = new Map(); // Map which holds the records that are selected so far together is all c-selected-record(s) component(s). Holds in <id,{id,role,status}> pairs
    _rolepicklist;
    _statuspicklist;

    @api
    set rolepicklist(rolepicklist) {
        if(rolepicklist) {
            this._rolepicklist = rolepicklist;
        }
    }

    get rolepicklist() {
        return this._rolepicklist;
    }

    @api
    set statuspicklist(statuspicklist) {
        if(statuspicklist) {
            this._statuspicklist = statuspicklist;
        }
    }

    get statuspicklist() {
        return this._statuspicklist;
    }

    @api
    set recorddata(recorddata){
        for (let [key, value] of  recorddata.entries()) {
            // Note: Update this._recorddata only if key is not present in the Map. (i.e.) for the first time with default role,status values. 
            if(this._recorddata.has(key)) {
                console.log('##SelectedComplaintParticipantsLongIntake: already included record with id: ' + key);
            }
            else {
                this._recorddata.set(key,{
                    id: key,
                    name: value.name,
                    role: value.role, //TODO: Fetch and assign defaults
                    status: value.status,
                });
            }
        }

        // Note: this._recorddata will have the modified value of role,status (if modified). This is handelled in handleRecordChanged().
        // So, eventually this.recorddataarr will be pushed with modified values.
        this.recorddataarr=[];
        for (let [key, value] of this._recorddata.entries()) {
            console.log(key + " = " + JSON.stringify(value));
            this.recorddataarr.push({
                id: key,
                name: value.name,
                role: value.role,
                status: value.status,
            });
            if(this._selectedData.has(key)){
                console.log("##SelectedComplaintParticipantsLongIntake: key Already present in this._selectedData: " + key);
            }
            else {
                this._selectedData.set(key,{
                    "id":key,
                    "name":value.name,
                    "role":value.role,
                    "status":value.status
                })
            }
        }

        if (this.recorddataarr.length == 0) {
            console.log('##SelectedComplaintParticipantsLongIntake: Found zero record');
            this._showResults=false;
        }
        else
        {
            this._showResults=true;
        }

        this.sendDataChangedEvent();
    }

    sendDataChangedEvent() {
        const event = new CustomEvent('datachanged', {
            detail:this._selectedData
        });
        this.dispatchEvent(event);
    }
    
    get recorddata(){
        return this._recorddata;
    }

    handleDeleteRecord(evt) {
        let id = evt.detail;
        this._recorddata.delete(id);
        this._selectedData.delete(id);
        let temp=[]
        for (let [key, value] of this._recorddata.entries()) {
            console.log(key + " = " + this._selectedData.get(key).role)
            temp.push({
                id: key,
                name: value.name,
                role: this._selectedData.get(key).role, //Need to pass the selected data here which will be rerendered in the corresponding record picklist
                status: this._selectedData.get(key).status, //Need to pass the selected data here which will be rerendered in the corresponding record picklist
            })
        }
        this.recorddataarr=temp;

        if (this.recorddataarr.length == 0) {
            this._showResults=false;
        } else {
            this._showResults=true;
        }
        this.sendDataChangedEvent();

        let recMap = new Map();
        for (let [key, value] of this._recorddata.entries()) {
            recMap.set(key, value.name);
        }
        const event = new CustomEvent('rowdeleted', {
            detail:recMap
        });
        this.dispatchEvent(event);
    }

    handleRecordChanged(event) {
        let id = event.detail.id;
        //get name from this._recorddata only and retain it.
        let oldvalue = this._recorddata.get(id);
        //Its obvious that entries will be present in this._recorddata and this._selectedData. So accessing directly.
        this._recorddata.set(id,{
            "id":id,
            "name":oldvalue.name,
            "role":event.detail.role,
            "status":event.detail.status
        })
        this._selectedData.set(id,{
            "id":id,
            "name":event.detail.name,
            "role":event.detail.role,
            "status":event.detail.status
        })
        this.sendDataChangedEvent();
    }
}