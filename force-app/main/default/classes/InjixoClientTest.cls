@IsTest
private class InjixoClientTest {
    @TestSetup
    static void setupData() {
        Injixo_Config__c config = new Injixo_Config__c();
        config.External_System__c = 'ApexTest';
        config.Integration_Configuration_Id__c = '12345';
        config.Use_Named_Credential__c = 'ApexTestNc';
        insert config;
    }
    @IsTest
    static void testInjixoAgentStatusRequest() {
        Test.setMock(HttpCalloutMock.class, new InjixoMocks.InjixoSuccess());
        InjixoAgentStatusRequest rq = InjixoAgentStatusRequest.getMock(2);
        List<InjixoAgentStatusModel> models = rq.data;

        Test.startTest();
        InjixoClient.sendAgentStatusRequest(models);
        Test.stopTest();
    }
    @IsTest
    static void testInjixoAgentStatusRequestErrors() {
        Test.setMock(HttpCalloutMock.class, new InjixoMocks.InjixoError());
        List<InjixoAgentStatusModel> models = new List<InjixoAgentStatusModel>();

        Test.startTest();
        try {
            InjixoClient.sendAgentStatusRequest(models);
            System.assert(false, 'Expected an exception');
        }
        catch(Injixoclient.InjixoClientException e) {
            System.assert(true, 'Expected an InjixoClientException');
        }
        Test.stopTest();
    }
    @IsTest
    static void testInjixoContactEventRequest() {
        Test.setMock(HttpCalloutMock.class, new InjixoMocks.InjixoSuccess());
        InjixoContactEventRequest rq = InjixoContactEventRequest.getMock(2);
        List<InjixoContactEventModel> models = rq.data;

        Test.startTest();
        InjixoClient.sendContactEventRequest(models);
        Test.stopTest();
    }
    @IsTest
    static void testInjixoContactEventRequestRequestErrors() {
        Test.setMock(HttpCalloutMock.class, new InjixoMocks.InjixoError());
        InjixoContactEventRequest rq = InjixoContactEventRequest.getMock(2);
        List<InjixoContactEventModel> models = new List<InjixoContactEventModel>();

        Test.startTest();
        try {

            InjixoClient.sendContactEventRequest(models);
            System.assert(false, 'Expected an exception');

        }
        catch(Injixoclient.InjixoClientException e) {
            System.assert(true, 'Expected an InjixoClientException');
        }
        Test.stopTest();
    }
}