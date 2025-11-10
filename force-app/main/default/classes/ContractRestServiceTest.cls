/**
 * Created by harm on 14/10/2024.
 */
@IsTest
private class ContractRestServiceTest {
    @TestSetup
    private static void setupData() {
        insert TestDataFactory.getPersonAccounts(1);
    }

    @IsTest
    static void testPost201Contract() {
        Account acc = [SELECT Id, UUID__c FROM Account LIMIT 1];
        Contract_Unit__c unit = TestDataFactory.getContractUnit('12345669');
        insert unit;
        ContractModel con = ContractModel.getMock(acc.UUID__c);

        Test.startTest();
        RestResponse resp = ContractRestService.testPostCall(con);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(201, resp.statusCode,'Expected 201 http code: '+JSON.serializePretty(respResponse));
        Integer ctrCount = [SELECT count() FROM Real_Estate_Contract__c];
        System.assertEquals(1, ctrCount,'Expected 1 contract');
        Real_Estate_Contract__c ctrAfterCreate = [SELECT Parent_Contract_Number__c FROM Real_Estate_Contract__c LIMIT 1];
        System.assertEquals('1234', ctrAfterCreate.Parent_Contract_Number__c,'Expected 1234 bovenliggend contract');
        Integer contractLineCount = [SELECT count() FROM Contract_Line__c];
        System.assertEquals(1, contractLineCount,'Expected 1 contract line');

    }
    @IsTest
    static void testPost500Contract() {
    }

    @IsTest
    static void testPatch400Contract() {
    }
    @IsTest
    static void testPatch201Contract() {
        Account acc = [SELECT Id, UUID__c FROM Account LIMIT 1];
        Contract_Unit__c unit = TestDataFactory.getContractUnit('12345669');
        insert unit;
        ContractModel con = ContractModel.getMock(acc.UUID__c);

        Test.startTest();
        RestResponse resp = ContractRestService.testPostCall(con);
		RestServiceResponse respResponsex = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);

        Integer ctrCount = [SELECT count() FROM Real_Estate_Contract__c];
        System.assertEquals(1, ctrCount,'Expected 1 contract '+JSON.serializePretty(respResponsex));
        Real_Estate_Contract__c ctrAfterCreate = [SELECT Parent_Contract_Number__c FROM Real_Estate_Contract__c LIMIT 1];
        System.assertEquals('1234', ctrAfterCreate.Parent_Contract_Number__c,'Expected 1234 bovenliggend contract');
        Integer contractLineCount = [SELECT count() FROM Contract_Line__c];
        System.assertEquals(1, contractLineCount,'Expected 1 contract line');
        Contract_Line__c lineRecord = [SELECT External_Id__c FROM Contract_Line__c LIMIT 1];
        System.assertEquals('code123', lineRecord.External_Id__c,'Expected code123 als external line id');
        //
        // Change amount
        con.brutoContractprijs = 1200;
        RestResponse resp2 = ContractRestService.testPatchCall(con);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp2.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(201, resp.statusCode,'Expected 201 http code');
        Contract_Line__c ctrAfterUpdate = [SELECT Price__c FROM Contract_Line__c LIMIT 1];
        System.assertEquals(1200, ctrAfterUpdate.Price__c,'Expected 1200 price__c after patch');
    }

}