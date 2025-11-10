//
// Logic tested in InjixoClientTest
@IsTest
private class InjixoInvocablesTest {
    @TestSetup
    static void setupData() {
        Injixo_Config__c config = new Injixo_Config__c();
        config.External_System__c = 'ApexTest';
        config.Integration_Configuration_Id__c = '12345';
        config.Use_Named_Credential__c = 'ApexTestNc';
        insert config;
    }
    @IsTest
    static void testAgentStatusInvocable() {
        Test.setMock(HttpCalloutMock.class, new InjixoMocks.InjixoSuccess());
        InjixoAgentStatusRequest rq = InjixoAgentStatusRequest.getMock(2);
        List<InjixoAgentStatusModel> models = rq.data;
        List<List<InjixoAgentStatusModel>> wrapperList = new List<List<InjixoAgentStatusModel>>();
        wrapperList.add(models);
        Test.startTest();
        InjixoAgentStatusInvocable.sendAgentStatuses(wrapperList);
        Test.stopTest();
    }
    @IsTest
    static void testAgentStatusInvocableFuture() {
        Test.setMock(HttpCalloutMock.class, new InjixoMocks.InjixoSuccess());
        InjixoAgentStatusRequest rq = InjixoAgentStatusRequest.getMock(2);
        List<InjixoAgentStatusModel> models = rq.data;

        Test.startTest();
        InjixoAgentStatusInvocable.sendStatusesFuture(JSON.serialize(models));
        Test.stopTest();
    }
    @IsTest
    static void testContactEventInvocable() {
        Test.setMock(HttpCalloutMock.class, new InjixoMocks.InjixoSuccess());
        InjixoContactEventRequest req = InjixoContactEventRequest.getMock(2);
        List<InjixoContactEventModel> models = req.data;
        List<List<InjixoContactEventModel>> wrapperList = new List<List<InjixoContactEventModel>>();
        wrapperList.add(models);
        Test.startTest();
        InjixoContactEventInvocable.sendContactEvents(wrapperList);
        Test.stopTest();
    }
    @IsTest
    static void testContactEventInvocableFuture() {
        Test.setMock(HttpCalloutMock.class, new InjixoMocks.InjixoSuccess());
        InjixoContactEventRequest req = InjixoContactEventRequest.getMock(2);
        List<InjixoContactEventModel> models = req.data;

        Test.startTest();
        InjixoContactEventInvocable.sendEventsFuture(JSON.serialize(models));
        Test.stopTest();
    }
}