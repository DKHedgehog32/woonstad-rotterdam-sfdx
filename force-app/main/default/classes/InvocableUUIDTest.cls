@isTest
private class InvocableUUIDTest {
    @IsTest
    private static void testInvocable() {
        Test.startTest();
        String[] uuidString = InvocableUUID.generateUuid(new List<String> { 'adbe' });
        System.assertEquals(1, uuidString.size(), 'Expected 1 response');
        try {
            UUID fromStr = System.UUID.fromString(uuidString[0]);
            System.assertEquals(fromStr.toString(), uuidString[0], 'Expected UUID to match '+fromStr);
        }
        catch(Exception e) {
            System.assert(false, 'Did not expect exception '+e.getMessage());
        }

        Test.stopTest();
    }
}