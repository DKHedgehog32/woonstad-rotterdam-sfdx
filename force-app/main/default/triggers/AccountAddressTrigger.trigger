trigger AccountAddressTrigger on Account_Address__c (before insert) {
    if(Trigger.isInsert) {
        AddressService.fillCompositeKeys(Trigger.new);
    }
}