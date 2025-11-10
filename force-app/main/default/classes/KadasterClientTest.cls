/**
 * Test code for the KadasterClient and AddressEntryController
 */

@IsTest
private class KadasterClientTest {
    @IsTest
    static void testOneAddress() {
        Test.setMock(HttpCalloutMock.class, new KadasterMocks.GetAddressSuccess());
        Test.startTest();
        KadasterAddressResponse resp = KadasterClient.getAddress('8931CL','75','a','a');
        Test.stopTest();
        System.assertEquals('leeuwarden', resp.woonplaatsNaam.toLowerCase(),'Expected different mocked result');
    }
    @IsTest
    static void testNoAddresses() {
        Test.setMock(HttpCalloutMock.class, new KadasterMocks.GetAddressSuccessNoAddress());
        Test.startTest();
        KadasterAddressResponse resp = KadasterClient.getAddress('8931CL','75','a','a');
        Test.stopTest();
        System.assertEquals(System.Label.No_Results, resp.title,'Expected different no addresses message');
    }
    @IsTest
    static void testError400() {
        Test.setMock(HttpCalloutMock.class, new KadasterMocks.GetAddressError());
        Test.startTest();
        KadasterAddressResponse resp = KadasterClient.getAddress('8931CL','75','a','a');
        Test.stopTest();
        System.assertEquals(400, resp.status,'Expected different mocked error');
    }
    @IsTest
    static void testControllerEntry() {
        Test.setMock(HttpCalloutMock.class, new KadasterMocks.GetAddressSuccess());
        Test.startTest();
        //
        // Same effect as the first test
        KadasterAddressResponse resp = AddressEntryController.queryKadaster('8931CL','75','a','a');
        Test.stopTest();
        System.assertEquals('leeuwarden', resp.woonplaatsNaam.toLowerCase(),'Expected different mocked result');
    }
}