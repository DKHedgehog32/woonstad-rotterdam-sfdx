@IsTest
private class ApexFaultHandlerTest {

    @IsTest
    static void testPublishErrorWithRecordId() {
        Exception simulatedException;

        // Force a real exception
        try {
            Integer i = 1 / 0;
        } catch (Exception ex) {
            simulatedException = ex;
        }

        Test.startTest();
        ApexFaultHandler.publishError(simulatedException, 'TestClass', 'testMethod', UserInfo.getUserId());
        Test.stopTest();
    }

    @IsTest
    static void testPublishErrorWithoutRecordId() {
        Exception simulatedException;

        try {
            List<Integer> numbers = new List<Integer>();
            Integer x = numbers[1]; // Index out of bounds
        } catch (Exception ex) {
            simulatedException = ex;
        }

        Test.startTest();
        ApexFaultHandler.publishError(simulatedException, 'TestClass', 'testMethod');
        Test.stopTest();
    }
}