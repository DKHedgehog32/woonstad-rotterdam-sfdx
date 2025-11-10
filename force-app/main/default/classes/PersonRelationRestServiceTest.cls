/**
 * Created by harm on 08/01/2025.
 */

@IsTest
private class PersonRelationRestServiceTest {
    @TestSetup
    private static void setupData() {
        List<Account> testAccs = TestDataFactory.getPersonAccounts(2);
        testAccs[0].UUID__c = '12345';
        testAccs[0].Contact_UUID__pc = '12345';
        insert testAccs;
        testAccs = [SELECT Id, PersonContactId FROM Account];
        Relationship__c ships = TestDataFactory.getRelationship(testAccs[0].Id, testAccs[1].Id, 'BWI');
        insert ships;
        AccountContactRelation rel = TestDataFactory.getAccountContactRelationship(testAccs[0].Id, testAccs[1].PersonContactId, 'CPE');
        insert rel;
    }
    @IsTest
    static void testGet200() {
        Account acc = [SELECT UUID__c FROM Account WHERE UUID__c='12345']; // Returns 1 account
        Test.startTest();
        String uuid = acc.UUID__c;
        RestResponse resp = PersonRelationRestService.testGetCall(uuid);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(2, respResponse.relaties.size(), 'Expected 2 relations');
        System.assertEquals(200, resp.statusCode,'Expected 200 http code');
    }
    @IsTest
    static void testGet404() {
        Test.startTest();
        RestResponse resp = PersonRelationRestService.testGetCall('FLAUWEKULUUID');
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(false, respResponse.isSuccess,'Expected error response');
        System.assert(respResponse.errors[0].contains('Not Found'),'Expected "Not Found" response');
        System.assertEquals(404, resp.statusCode,'Expected 404 http code');
    }
    @IsTest
    static void testGet400() {
        Test.startTest();
        RestResponse resp = PersonRelationRestService.testGetCall(null);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(false, respResponse.isSuccess,'Expected error response');
        System.assert(respResponse.errors[0].contains('No resource requested'),'Expected "No resource requested" response');
        System.assertEquals(400, resp.statusCode,'Expected 400 http code');
    }
}