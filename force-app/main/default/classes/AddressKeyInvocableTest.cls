/**
 * Created by harm on 22/07/2024.
 */
@IsTest
private class AddressKeyInvocableTest {
    @IsTest
    private static void testAddressKeyInvocable() {
        List<Address__c> adds = TestDataFactory.getAddresses(2);
        List<String> keys = AddressKeyInvocable.getAddressKeys(adds);
        System.assertEquals(2, keys.size(), 'Expected 2 keys');
        System.assert(keys[0].contains('1230'), 'Expected 1230 in key');
        System.assert(keys[1].contains('1231'), 'Expected 1231 key');
    }
}