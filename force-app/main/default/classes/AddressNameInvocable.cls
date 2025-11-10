//
// Invocable to construct the name for an address records
public class AddressNameInvocable {
    @InvocableMethod(label='Get name based on an address record')
    public static List<String> getAddressNames(List<Address__c> addresses) {
        try {
            return AddressService.getNameValues(addresses);
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'AddressNameInvocable', 'getAddressNames');
            throw ex;
        }
    }
}