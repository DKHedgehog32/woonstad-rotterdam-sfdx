/**
 * Created by harm on 22/07/2024.
 */
@IsTest
private class AddressNameInvocableTest {
    @IsTest
    private static void testAddressNameInvocable() {
        List<Address__c> adds = TestDataFactory.getAddresses(2);
        List<String> names = AddressNameInvocable.getAddressNames(adds);
        System.assertEquals(2, names.size(), 'Expected 2 names');
        System.assert(names[0].contains('Street0'), 'Expected Street0 in name');
        System.assert(names[1].contains('Street1'), 'Expected Street1 name');
    }
}