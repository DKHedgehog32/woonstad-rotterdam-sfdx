trigger AccountTrigger on Account (before insert, before update) {
    if(Trigger.isBefore) {
        for (Account acc : Trigger.new) {
            if(String.isEmpty(acc.UUID__c)) {
                acc.UUID__c = IdentifierService.getUUID();
            }
            if (acc.IsPersonAccount) {
                acc.Contact_UUID__pc = acc.UUID__c;
            }
            //
            // Set fields by reference
            AddressService.setPrimaryAddressInStandardFields(acc);
        }
    }
}