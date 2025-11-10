import { LightningElement, wire, api } from 'lwc';
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";
import { createRecord, getRecordCreateDefaults } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import pubsub from "omnistudio/pubsub";

export default class CreateRecordFull extends OmniscriptBaseMixin(LightningElement) {
    @api objectApiName;
    @api objectLabel;

    record;
    fieldMap = {};

    get title() {
        return "Create " + this.objectLabel;
    }

    get createButtonLabel() {
        return "Create new " + this.objectLabel;
    }

    @wire(getRecordCreateDefaults, {objectApiName: "$objectApiName"})
    getRecordCreateDefaults({data}) {
        if (data) {
            const fieldAddedInLayout = {};
            // updating list of fields to be displayed
            const sections = data.layout.sections;
            const objectInfo = data.objectInfos[data.layout.objectApiName];
            for (const section of sections) {
                for (const layoutRow of section.layoutRows) {
                    for (const layoutItem of layoutRow.layoutItems) {
                        // layoutComponents will have multiple items when the field is compound field like GeoLocation
                        for (const component of layoutItem.layoutComponents) {
                            // there are many types of component added in layout, we are only interested in Field type
                            if (component.componentType === 'Field') {
                                // have used same key name as it returns in objectInfo
                                const field = {
                                    apiName: component.apiName,
                                    label: component.label,
                                    required: objectInfo.fields[component.apiName].required,
                                    value: objectInfo.fields[component.apiName].value
                                };
                                fieldAddedInLayout[field.apiName] = field;
                            }
                        }
                    }
                }
            }
            this.fieldMap = fieldAddedInLayout;
        }
    }

    get allFields() {
        return Object.keys(this.fieldMap || {}).reduce((prev, curr) => {
            prev.push(this.fieldMap[curr]);
            return prev;
        }, []);
    }

    handleFieldValueChange(event) {
        const fieldName = event.currentTarget.fieldName;
        let value = event.detail.value ? event.detail.value : event.detail.checked;
        if (value instanceof Array) {
            value = value.length > 0 ? value[0] : undefined;
        }
        this.fieldMap[fieldName].value = value;
    }

    createRecord(event){
        event.preventDefault();       // stop the form from submitting
        const fields = {};
        for (const fieldApiName of Object.keys(this.fieldMap)) {
            if (this.fieldMap[fieldApiName].value !== undefined) {
                fields[fieldApiName] = this.fieldMap[fieldApiName].value;
            }
        }
        const recordInput = { apiName: this.objectApiName, fields };
        createRecord(recordInput)
            .then(record => {
                console.log("createRecord: Successfull in creating " + this.objectLabel + ": " + JSON.stringify(record.id));
                // Show a toast message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: this.objectLabel + ' created',
                        variant: 'success',
                    }),
                );
                // Fire the pub-sub event to close the flexcard modal.
                pubsub.fire("close_modal", 'close', {});
            })
            .catch(error => {
                console.log("createRecord: Error in creating " + this.objectLabel + ": " + JSON.stringify(error.body.message));
                // Show a toast message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating ' + this.objectLabel + ' record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
                // Fire the pub-sub event to close the flexcard modal.
                pubsub.fire("close_modal", 'close', {});
            });
     }
}