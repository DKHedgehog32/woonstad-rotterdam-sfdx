/**
 * Created by harm on 06/11/2024.
 */

trigger ContactTrigger on Contact (before insert) {
    if(Trigger.isBefore) {
        for (Contact con : Trigger.new) {
            if (!con.IsPersonAccount) {
                con.Contact_UUID__c = IdentifierService.getUUID();
            }
        }
    }
}