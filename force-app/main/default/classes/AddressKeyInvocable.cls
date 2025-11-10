//
// Invocable to get an address key
public class AddressKeyInvocable {
    @InvocableMethod(label='Get unique key based on an address record')
    public static List<String> getAddressKeys(List<Address__c> addresses) {
        try {
            return AddressService.getAddressKeys(addresses);
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'AddressKeyInvocable', 'getAddressKeys');
            throw ex;
        }
    }
}