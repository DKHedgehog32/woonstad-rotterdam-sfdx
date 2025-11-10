/**
 * Controller class for the address entry LWC
 * Tested in KadasterClientTest
 */
public with sharing class AddressEntryController {
    @AuraEnabled
    public static KadasterAddressResponse queryKadaster(String postalCode, String houseNumber, String houseLetter, String houseNumberAddition) {
        return KadasterClient.getAddress(postalCode, houseNumber, houseLetter, houseNumberAddition);
    }
}