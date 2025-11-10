import { LightningElement,api } from 'lwc';

export default class SelectedComplaintParticipantRecord extends LightningElement {
    @api recordid;
    @api recordname;
    @api rolevalue;
    @api statusvalue;
    @api rolepicklist;
    @api statuspicklist;

    sendDataUpdatedEvent() {
        const recordChangedEvent = new CustomEvent('recordchanged', {
            // detail contains new values
            detail: {
                "id":this.recordid,
                "role":this.rolevalue,
                "status":this.statusvalue
            }
        });
        this.dispatchEvent(recordChangedEvent);
    }

    handleRoleChange(event) {
        this.rolevalue = event.detail.value;
        this.sendDataUpdatedEvent();
    }

    handleStatusChange(event) {
        this.statusvalue = event.detail.value;
        this.sendDataUpdatedEvent();
    }

    onDeleteClick() {
        const event = new CustomEvent('deleterecord', {
            // detail contains id
            detail: this.recordid
        });
        this.dispatchEvent(event);
    }
}