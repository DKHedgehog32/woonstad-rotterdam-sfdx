/**
 * Created by harm on 28/06/2024.
 */

@IsTest
private class PersoonServiceTest {
    @IsTest
    static void testGet() {
        Account[] accs = TestDataFactory.getPersonAccounts(1);
        accs[0].UUID__c = '1234';
        upsert accs;
        Test.startTest();
        System.debug('## ACCS '+JSON.serializePretty([SELECT Id, Name, UUID__c FROM Account]));
        PersoonModel pm = PersoonService.getPersoonByUuid('1234');
        System.assertNotEquals(null, pm, 'Expected persoon for 1234');
        PersoonModel pm2 = PersoonService.getPersoonByUuid('abcd');
        System.assertEquals(null, pm2, 'Expected null result for abcd');
        Test.stopTest();
    }
    @IsTest
    static void testPost() {
        //
        // Needs a mock response, since flow may trigger outbound call
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());

        PersoonModel p = PersoonModel.getMock();
        Test.startTest();
        PersoonModel pm = PersoonService.postPersoon(p);
        System.assertNotEquals(null, pm.id, 'Expected UUID');
        Test.stopTest();
    }
    @IsTest
    static void testPatch() {
        //
        // Needs a mock response, since flow may trigger outbound call
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());

        Account[] accs = TestDataFactory.getPersonAccounts(1);
        accs[0].UUID__c = '1234';
        upsert accs;
        PersoonModel p = PersoonModel.getMock();
        p.soort.code = 'NAT';
        Test.startTest();
        PersoonModel pm = PersoonService.patchPersoon('1234',p);
        System.assertEquals('1234', pm.id, 'Expected UUID 1234');
        Test.stopTest();
    }
    @IsTest
    static void testValidatePath1() {
        Test.startTest();
        PersoonModel p = PersoonModel.getMock();
        p.naam = null;
        p.soort = new ReferentieCodeModel();
        p.soort.code = 'REC';
        PersoonService.PersoonRequestValidationResult result = PersoonService.validatePostRequest(p);
        System.assertEquals(false, result.isValid,'Expected invalid result');
        System.assert(result.validationErrors[0].contains('Missing Naam for Rechtspersoon'),'Expected "Missing Naam for Rechtspersoon" result');
        Test.stopTest();
    }
    @IsTest
    static void testValidatePath2() {
        Test.startTest();
        PersoonModel p = PersoonModel.getMock();
        p.achternaam = null;
        p.soort = new ReferentieCodeModel();
        p.soort.code = 'NAT';
        PersoonService.PersoonRequestValidationResult result = PersoonService.validatePostRequest(p);
        System.assertEquals(false, result.isValid,'Expected invalid result');
        System.assert(result.validationErrors[0].contains('Missing Achternaam for Natuurlijkpersoon'),'Expected "Missing Achternaam for Natuurlijkpersoon" result');
        Test.stopTest();
    }
    @IsTest
    static void testValidatePath3() {
        Test.startTest();
        PersoonModel p = PersoonModel.getMock();
        p.soort = null;
        PersoonService.PersoonRequestValidationResult result = PersoonService.validatePostRequest(p);
        System.assertEquals(false, result.isValid,'Expected invalid result');
        System.assert(result.validationErrors[0].contains('Missing Persoon Soort'),'Expected "Missing Persoon Soort" result');
        Test.stopTest();
    }
    @IsTest
    static void testValidatePath4() {
        Test.startTest();
        PersoonModel p; // Null
        PersoonService.PersoonRequestValidationResult result = PersoonService.validatePostRequest(p);
        System.assertEquals(false, result.isValid,'Expected invalid result');
        System.assert(result.validationErrors[0].contains('Missing Persoon'),'Expected "Missing Persoon" result');
        Test.stopTest();
    }
}