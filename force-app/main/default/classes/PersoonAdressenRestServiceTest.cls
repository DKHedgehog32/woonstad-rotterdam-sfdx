@IsTest
private class PersoonAdressenRestServiceTest {
    @TestSetup
    private static void setupData() {
        //
        // Needs a mock response, since flow may trigger outbound call
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());

        insert TestDataFactory.getPersonAccounts(1);
        Account acc = [SELECT UUID__c FROM Account]; // Returns 1 account
        String uuid = acc.UUID__c;
        List<Address__c> addresses = TestDataFactory.getAddresses(2);
        upsert addresses Address__c.Unique_Key__c;
        List<Account_Address__c> accAddresses = new List<Account_Address__c>();
        accAddresses.add(AddressService.getAccountAddressForUpsert(uuid, addresses[0]));
        accAddresses.add(AddressService.getAccountAddressForUpsert(uuid, addresses[1]));
        upsert accAddresses;
        acc.Primary_Shipping_Address__c=addresses[0].Id;
        acc.Primary_Shipping_Address__c=addresses[1].Id;
        update acc;
    }
    @IsTest
    static void testGet200() {

        Account acc = [SELECT UUID__c FROM Account]; // Returns 1 account
        String uuid = acc.UUID__c;
        Test.startTest();
        RestResponse resp = PersoonAdressenRestService.testGetCall(uuid);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(2, respResponse.addresses.size(),'Expected 2 addresses for this Account');
        System.assertEquals(200, resp.statusCode,'Expected 200 http code');
    }
    @IsTest
    static void testGet404() {
        Test.startTest();
        RestResponse resp = PersoonAdressenRestService.testGetCall('nonsense');
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(null, respResponse.addresses,'Expected no addresses for this uuid');
        System.assertEquals(404, resp.statusCode,'Expected 404 http code');
    }
    @IsTest
    static void testGet400() {

        Test.startTest();
        RestResponse resp = PersoonAdressenRestService.testGetCall(null);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(null, respResponse.addresses,'Expected no addresses for this uuid');
        System.assertEquals('No resource requested; uuid parameter is mandatory', respResponse.errors[0],'Expected error about missing uuid');
        System.assertEquals(400, resp.statusCode,'Expected 400 http code');
    }
    @IsTest
    static void testPost201() {
        //
        // Needs a mock response, since flow may trigger outbound call
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());

        Account acc = [SELECT UUID__c FROM Account]; // Returns 1 account
        String uuid = acc.UUID__c;
        PersoonAdresModel pa = PersoonAdresModel.getMock(uuid);
        pa.idPersoon = uuid;
        //
        // Identical address, should not result in extra Account Address record
        PersoonAdresModel pa2 = PersoonAdresModel.getMock(uuid);
        pa2.idPersoon = uuid;
        Test.startTest();
        RestResponse resp = PersoonAdressenRestService.testPostCall(pa);
        RestResponse resp2= PersoonAdressenRestService.testPostCall(pa2);
        Test.stopTest();
        List<Account_Address__c> accAddresses = [SELECT Id, Deduplication_Key__c FROM Account_Address__c WHERE Account__r.UUID__c=:uuid];
        System.Debug('### 201: '+JSON.serializePretty(accAddresses));
        List<Address__c> addr = [SELECT Id FROM Address__c];
        System.assertEquals(3, addr.size(),'Expected a new address, 3 in total now');
        System.assertEquals(2, accAddresses.size(),'Expected a new account address, 3 in total now');
        //
        // Modified address, should result in extra Account Address record
        PersoonAdresModel pa3 = PersoonAdresModel.getMock(uuid);
        pa3.idPersoon = uuid;
        pa3.adres.postcode = '5555ZZ';
        RestResponse resp3 = PersoonAdressenRestService.testPostCall(pa3);
        List<Address__c> addr2 = [SELECT Id FROM Address__c];
        List<Account_Address__c> accAddresses2 = [SELECT Id, Deduplication_Key__c FROM Account_Address__c WHERE Account__r.UUID__c=:uuid];
        System.assertEquals(4, addr2.size(),'Expected a new address, 4 in total now');
        System.assertEquals(2, accAddresses2.size(),'Expected a new account address, 4 in total now');
    }
    @IsTest
    static void testPost400() {
        Test.startTest();
        RestResponse resp = PersoonAdressenRestService.testPostCall(null);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(400, resp.statusCode,'Expected 404 http code');
        System.assertEquals(1, respResponse.errors.size(),'Expected 1 error');
    }
}