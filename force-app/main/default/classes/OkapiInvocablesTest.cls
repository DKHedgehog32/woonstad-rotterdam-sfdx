/**
 Just the invocables, callout behavior tested in OkapiClientTest
 */

@IsTest
private class OkapiInvocablesTest {
    @IsTest
    static void testGetPersonen() {

        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());
        Test.startTest();
        List<String> uuids = new List<String> { 'abcd', 'efgh', 'jklm'};
        List<PersoonModel> persons = OkapiGetPersoonInvocable.getPersons(uuids);
        Test.stopTest();
        System.assertEquals(3, persons.size(),'Expected 3 responses');
    }
    @IsTest
    static void testPostPersonen() {

        Test.setMock(HttpCalloutMock.class, new OkapiMocks.UpsertRelationSuccess());
        Test.startTest();
        List<PersoonModel> persons = new List<PersoonModel> { PersoonModel.getMock() };
        OkapiPostPersoonInvocable.postPersons(persons); // Void, no feedback. Service behavior tested in OkapiClientTest
        System.assert(true,'Expected to call the invocable without exceptions');

        Test.stopTest();
    }
    @IsTest
    static void testFetchPersonen() {

        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GenericSuccess());
        Test.startTest();
        List<PersoonModel> persons = new List<PersoonModel> { PersoonModel.getMock() };
        FetchPersonenInvocable.fetchPersonen(persons); // Void, no feedback. Service behavior tested in OkapiClientTest
        System.assert(true,'Expected to call the invocable without exceptions');

        Test.stopTest();
    }
    @IsTest
    static void testPatchPersonen() {

        Test.setMock(HttpCalloutMock.class, new OkapiMocks.UpsertRelationSuccess());
        Test.startTest();
        List<PersoonModel> persons = new List<PersoonModel> { PersoonModel.getMock() };
        OkapiPatchPersoonInvocable.patchPersons(persons); // Void, no feedback. Service behavior tested in OkapiClientTest
        System.assert(true,'Expected to call the invocable without exceptions');

        Test.stopTest();
    }
    @IsTest
    static void testPostBankgegevens() {

        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GenericSuccess());
        Test.startTest();
        List<BetaalgegevenModel> bgs = new List<BetaalgegevenModel> { BetaalgegevenModel.getMock() };
        OkapiPostBankaccountsInvocable.postBankaccounts(bgs); // Void, no feedback. Service behavior tested in OkapiClientTest
        System.assert(true,'Expected to call the invocable without exceptions');

        Test.stopTest();
    }
    @IsTest
    static void testPostRelations() {

        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GenericSuccess());
        Test.startTest();
        List<PersoonRelatieModel> rels = new List<PersoonRelatieModel> { PersoonRelatieModel.getMock('mock-id') };
        OkapiPostPersonRelationsInvocable.postPersonRelations(rels); // Void, no feedback. Service behavior tested in OkapiClientTest
        System.assert(true,'Expected to call the invocable without exceptions');

        Test.stopTest();
    }
    @IsTest
    static void testPatchRelations() {

        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GenericSuccess());
        Test.startTest();
        List<PersoonRelatieModel> rels = new List<PersoonRelatieModel> { PersoonRelatieModel.getMock('mock-id') };
        OkapiPatchPersonRelationsInvocable.patchPersonRelations(rels); // Void, no feedback. Service behavior tested in OkapiClientTest
        System.assert(true,'Expected to call the invocable without exceptions');

        Test.stopTest();
    }
    @IsTest
    static void testPostPersonAddresses() {

        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GenericSuccess());
        Test.startTest();
        List<PersoonAdresModel> adds = new List<PersoonAdresModel> { PersoonAdresModel.getMock('mock-id') };
        OkapiPostPersonAddressesInvocable.postPersonAddresses(adds); // Void, no feedback. Service behavior tested in OkapiClientTest
        System.assert(true,'Expected to call the invocable without exceptions');
        Test.stopTest();
    }
    @IsTest
    static void testPostZaken() {

        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GenericSuccess());
        Test.startTest();
        List<ZaakModel> zaken = new List<ZaakModel> { ZaakModel.getMock('mock-id') };
        OkapiPostZaakInvocable.postZaken(zaken); // Void, no feedback. Service behavior tested in OkapiClientTest
        System.assert(true,'Expected to call the invocable without exceptions');
        Test.stopTest();
    }
}