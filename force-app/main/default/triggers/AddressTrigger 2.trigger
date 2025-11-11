trigger AddressTrigger on Address__c (before insert, before update) {
    //
    // Strip spaces from postal codes
    AddressService.normalizePostalCodesByReference(Trigger.new);
    //
    // Concatenate parts of address into a unique key and name
    for(Address__c addressRecord : Trigger.new) {
        if(String.isEmpty(addressRecord.Unique_Key__c)) {
            addressRecord.Unique_Key__c = AddressService.getAddressKey(addressRecord);
        }
        addressRecord.Name = AddressService.getNameValue(addressRecord);
        System.debug('### Address '+JSON.serializePretty(addressRecord));
    }
}