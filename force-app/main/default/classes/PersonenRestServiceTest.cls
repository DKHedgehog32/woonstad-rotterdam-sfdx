/**
 * Created by harm on 28/06/2024.
 */

@IsTest
private class PersonenRestServiceTest {
    @TestSetup
    private static void setupData() {
        insert TestDataFactory.getPersonAccounts(1);
    }
    @IsTest
    static void testGet200() {
        Account acc = [SELECT UUID__c FROM Account]; // Returns 1 account
        Test.startTest();
        String uuid = acc.UUID__c;
        RestResponse resp = PersonenRestService.testGetCall(uuid);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(null, respResponse.persoon.idExtern,'Expected this Id to be empty');
        System.assertEquals(uuid, respResponse.persoon.id,'Expected this specific account UUID');
        System.assertEquals(true, respResponse.isSuccess,'Expected success response');
        System.assertEquals(200, resp.statusCode,'Expected 200 http code');
    }
    @IsTest
    static void testGet404() {
        Test.startTest();
        RestResponse resp = PersonenRestService.testGetCall('FLAUWEKULUUID');
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(false, respResponse.isSuccess,'Expected error response');
        System.assert(respResponse.errors[0].contains('Not Found'),'Expected "Not Found" response');
        System.assertEquals(404, resp.statusCode,'Expected 404 http code');
    }
    @IsTest
    static void testPost201Person() {
        //
        // Needs a mock response, since flow may trigger outbound call
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());

        PersoonModel p = PersoonModel.getMock();
        p.achternaam = 'Alberts';
        p.voornaam = 'Koos';
        p.geboortedatum = System.Today().addYears(-100);
        p.initialen = 'K.A.';
        p.aanschrijfnaam = 'Weledelgeboren Koossie';
        p.soort = new ReferentieCodeModel();
        p.soort.code = 'NAT';
        p.idExtern = 'abcd';
        p.idAdministratie = 'WOCAS';
        Test.startTest();
        RestResponse resp = PersonenRestService.testPostCall(p);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        Account acc = [SELECT Id, UUID__c, External_Id__c, LastName FROM Account WHERE LastName = 'Alberts' LIMIT 1];
        System.assertEquals(acc.External_Id__c, respResponse.persoon.idExtern,'Expected this specific account Id');
        System.assertEquals(acc.UUID__c, respResponse.persoon.id,'Expected this specific account to have UUID '+acc.UUID__c);
        System.assertEquals(true, respResponse.isSuccess,'Expected success response');
        System.assertEquals(201, resp.statusCode,'Expected 201 http code');
    }
    @IsTest
    static void testPost500Person() {
        PersoonModel p = PersoonModel.getMock();
        p.achternaam = null;
        p.voornaam = 'Koos';
        p.geboortedatum = System.Today().addYears(-100);
        p.initialen = 'K.A.';
        p.aanschrijfnaam = 'Weledelgeboren Koossie';
        p.soort = new ReferentieCodeModel();
        p.soort.code = 'NAT';
        Test.startTest();
        RestResponse resp = PersonenRestService.testPostCall(p);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(false, respResponse.isSuccess,'Expected error response');
        System.assertEquals(1, respResponse.errors.size(),'Expected errors in response');
        System.assertEquals(400, resp.statusCode,'Expected 400 http code');
    }
    @IsTest
    static void testPost201Company() {
        //
        // Needs a mock response, since flow may trigger outbound call
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());

        PersoonModel p = PersoonModel.getMock();
        p.naam = 'Cobra';
        p.kvkNummer = 'abcd1234';
        p.soort.code = 'REC';
        p.idExtern = 'abcd';
        p.idAdministratie = 'WOCAS';
        Test.startTest();
        RestResponse resp = PersonenRestService.testPostCall(p);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        Account acc = [SELECT Id, UUID__c, External_Id__c, Name, RecordType.IsPersonType FROM Account WHERE Name = 'Cobra' LIMIT 1];
        System.assertEquals(acc.External_Id__c, respResponse.persoon.idExtern,'Expected this specific account Id');
        System.assertEquals(false, acc.RecordType.IsPersonType,'Expected business account');
        System.assertEquals(acc.UUID__c, respResponse.persoon.id,'Expected this specific account to have UUID '+acc.UUID__c);
        System.assertEquals(true, respResponse.isSuccess,'Expected success response');
        System.assertEquals(201, resp.statusCode,'Expected 201 http code');
    }
    @IsTest
    static void testPost400Company() {
        PersoonModel p = PersoonModel.getMock();
        p.naam = null;
        p.kvkNummer = 'abcd1234';
        p.soort.code = 'REC';
        p.idExtern = 'abcd';
        p.idAdministratie = 'WOCAS';
        Test.startTest();
        RestResponse resp = PersonenRestService.testPostCall(p);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(false, respResponse.isSuccess,'Expected error response');
        System.assertEquals(1, respResponse.errors.size(),'Expected errors in response');
        System.assertEquals(400, resp.statusCode,'Expected 400 http code');
    }
    @IsTest
    static void testPatch400Company() {
        PersoonModel p = PersoonModel.getMock();
        p.naam = null;
        p.kvkNummer = 'abcd1234';
        p.soort.code = 'REC';
        p.idExtern = 'abcd';
        p.idAdministratie = 'WOCAS';
        p.id = IdentifierService.getUUID();
        Test.startTest();
        RestResponse resp = PersonenRestService.testPatchCall(p, p.id); // Null name
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        System.assertEquals(false, respResponse.isSuccess,'Expected error response');
        System.assertEquals(1, respResponse.errors.size(),'Expected errors in response');
        System.assertEquals(500, resp.statusCode,'Expected 400 http code');
    }
    @IsTest
    static void testPatch201Company() {
        //
        // Needs a mock response, since flow may trigger outbound call
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());
        PersoonModel p = PersoonModel.getMock();
        p.naam = 'Cobra';
        p.kvkNummer = 'abcd1234';
        p.soort.code = 'REC';
        p.idExtern = 'abcd';
        p.idAdministratie = 'WOCAS';
        p.id = IdentifierService.getUUID();

        Test.startTest();
        RestResponse resp = PersonenRestService.testPatchCall(p, p.id);
        Test.stopTest();
        RestServiceResponse respResponse = (RestServiceResponse) JSON.deserialize(resp.responseBody.toString(), RestServiceResponse.class);
        Account acc = [SELECT Id, UUID__c, External_Id__c, Name, RecordType.IsPersonType FROM Account WHERE Name = 'Cobra' LIMIT 1];
        System.assertEquals(acc.External_Id__c, respResponse.persoon.idExtern,'Expected this specific account Id');
        System.assertEquals(false, acc.RecordType.IsPersonType,'Expected business account');
        System.assertEquals(acc.UUID__c, respResponse.persoon.id,'Expected this specific account to have UUID '+acc.UUID__c);
        System.assertEquals(true, respResponse.isSuccess,'Expected success response');
        System.assertEquals(201, resp.statusCode,'Expected 201 http code');
    }

}