/**
 * Test Class for outbound Okapi client
 */
@isTest
private class OkapiClientTest {
    @TestSetup
    private static void prepareTests() {
        Okapi_Settings__c setting = new Okapi_Settings__c();
        setting.Use_Named_Credential__c = 'http://www.dummy.org/';
        insert setting;
    }
    @IsTest
    private static void testGetPersoonSuccess() {
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());
        Test.startTest();
        List<String> uuids = new List<String> { 'abcd', 'efgh', 'jklm'};
        List<PersoonModel> persons = OkapiClient.getPersons(uuids);
        Test.stopTest();
        System.assertEquals(3, persons.size(), 'Expected 3 responses');
    }
    @IsTest
    private static void testGetPersoonError() {
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationError());
        Test.startTest();
        List<String> uuids = new List<String> { 'abcd', 'efgh'};
        try {
            List<PersoonModel> persons = OkapiClient.getPersons(uuids);
            System.assert(false,'Expected exception');

        }
        catch(Exception e) {
            System.assert(true,'Expected exception');
            System.assert(e.getMessage().contains('Okapi error in getPersons'),'Expected "Okapi error in getPersons" exception');
        }
        Test.stopTest();
    }
    @IsTest
    private static void testUpsertPersoonSuccess() {
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.UpsertRelationSuccess());
        Test.startTest();
        PersoonModel pm = PersoonModel.getMock();
        try {
            OkapiClient.upsertPersons(new List<PersoonModel> { pm },'POST');
            System.assert(true, 'Expected successful execution');

        }
        catch (Exception e) {
            System.assert(false, 'Expected no exceptions');
        }
        Test.stopTest();

    }
    @IsTest
    private static void testUpsertPersoonError() {
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.UpsertRelationError());
        Test.startTest();
        PersoonModel pm;
        try {
            OkapiClient.upsertPersons(new List<PersoonModel> { pm },'POST');
            System.assert(false, 'Expected exception');
        }
        catch (Exception e) {
            System.assert(true, 'Expected exception');
            System.assert(e.getMessage().contains('Null input not allowed'),'Expected "Null input not allowed" exception');
        }
        Test.stopTest();

    }
    @IsTest
    private static void testUpsertPersoonOverLimit() {
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.UpsertRelationError());
        Test.startTest();
        List<PersoonModel> pml = new List<PersoonModel>();
        for(Integer x=0; x < 105; x++) {
            pml.add(PersoonModel.getMock());
        }
        try {
            OkapiClient.upsertPersons(pml,'POST');
            System.assert(false, 'Expected exception');
        }
        catch (Exception e) {
            System.assert(true, 'Expected exceptions');
        }
        Test.stopTest();

    }
    @IsTest
    private static void testRequestPersonPushErrorOverLimit() {
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.RequestPersonPushError());
        List<PersoonModel> pml = new List<PersoonModel>();
        for(Integer x=0; x < 101; x++) {
            PersoonModel pm = new PersoonModel();
            pm.idExtern = String.valueOf(x);
            pm.idAdministratie = 'WOCAS';
            pml.add(pm);
        }

        Test.startTest();
        try {
            OkapiClient.requestPersonsPush(pml);
            System.assert(false, 'Expected exception');
        }
        catch (Exception e) {
            System.assert(true, 'Expected exceptions');
        }


        Test.stopTest();
    }
    @IsTest
    private static void testRequestPersonPushError() {
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.RequestPersonPushError());
        List<PersoonModel> pml = new List<PersoonModel>();
        for(Integer x=0; x < 99; x++) {
            PersoonModel pm = new PersoonModel();
            pm.idExtern = String.valueOf(x);
            pm.idAdministratie = 'WOCAS';
            pml.add(pm);
        }

        Test.startTest();
        List<OkapiResponseModel> res = OkapiClient.requestPersonsPush(pml);
        System.assertEquals(99, res.size(),'Expected 99 responses');
        System.assertEquals(false, res[0].isSuccess,'Expected errors');
        System.assert(res[0].errors[0].contains('400'),'Expected 400 in error');

        Test.stopTest();
    }
    @IsTest
    private static void testRequestPersonPushSuccess() {
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.RequestPersonPushSuccess());
        List<PersoonModel> pml = new List<PersoonModel>();
        for(Integer x=0; x < 99; x++) {
            PersoonModel pm = new PersoonModel();
            pm.idExtern = String.valueOf(x);
            pm.idAdministratie = 'WOCAS';
            pml.add(pm);
        }

        Test.startTest();
        List<OkapiResponseModel> res = OkapiClient.requestPersonsPush(pml);
        System.assertEquals(99, res.size(),'Expected 99 responses');
        System.assertEquals(true, res[0].isSuccess,'Expected success');
        Test.stopTest();
    }
}