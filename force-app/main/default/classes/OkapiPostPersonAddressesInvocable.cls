/**
 * Invocable for the POST person addresses
 */
public with sharing class OkapiPostPersonAddressesInvocable {
    @InvocableMethod(Description='Create person addresses on the Okapi service' Label='Post Person Addresses')
    public static void postPersonAddresses(List<PersoonAdresModel> personAddresses) {
        try {
            OkapiClient.upsertPersonAddresses(personAddresses, 'POST');
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiPostPersonAddressesInvocable' ,'postPersonAddresses');
        }
    }
}