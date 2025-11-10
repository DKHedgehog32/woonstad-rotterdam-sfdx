/**
 * Created by harm on 01/05/2024.
 */

@IsTest
private class IdentifierServiceTest {
    @IsTest
    static void testGetUuid() {
        Test.startTest();
        String uuid = IdentifierService.getUUID();
        try {
            UUID fromStr = System.UUID.fromString(uuid);
            System.assertEquals(fromStr.toString(), uuid, 'Expected UUID to match '+fromStr);
        }
        catch(Exception e) {
            System.assert(false, 'Did not expect exception '+e.getMessage());
        }
        Test.stopTest();
    }
    //
    // For lack of a better spot, test read: cover) the Contact trigger here, as it assigns a UUID
    @IsTest
    static void testContactTrigger() {
        Test.startTest();
        try {
            Contact c = new Contact();
            c.LastName = 'APEX';
            insert c;
            c = [SELECT Id, Contact_UUID__c FROM Contact WHERE Id=:c.Id];
            System.assertNotEquals(null, c.Contact_UUID__c, 'Expected UUID on contact');
        }
        catch(Exception e) {
            System.assert(false, 'Did not expect exception '+e.getMessage());
        }
        Test.stopTest();
    }
}