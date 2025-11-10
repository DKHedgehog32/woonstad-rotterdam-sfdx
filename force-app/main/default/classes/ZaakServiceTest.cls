@IsTest
private class ZaakServiceTest {
    @IsTest
    static void testEnrichmentContentVersion() {
        ContentVersion v = new ContentVersion();
        v.PathOnClient = 'test.txt';
        v.VersionData = Blob.valueOf('Test');
        v.Title = 'test.txt';
        insert v;

        ZaakModel zaakModel = ZaakModel.getMock('xxxx');
        zaakModel.contentVersionIds = new List<Id> { v.Id };
        Test.startTest();
        ZaakService.enrichZaakWithFilesByReference(new List<ZaakModel> { zaakModel });
        System.assertEquals(1, zaakModel.informatieobjecten?.size(),'Expected 1 informatie object');
        System.assertEquals('test.txt', zaakModel.informatieobjecten[0].beschrijving,'Expected test.txt beschrijving');
        Test.stopTest();
    }

    @IsTest
    static void testEnrichmentContentDcoument() {
        ContentVersion v = new ContentVersion();
        v.PathOnClient = 'test.txt';
        v.VersionData = Blob.valueOf('Test');
        v.Title = 'test.txt';
        insert v;
        //
        // Re-query to obtain the contentdocument id to call the logic with
        // contentdocument id's instead of versions
        v = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :v.Id];
        ZaakModel zaakModel = ZaakModel.getMock('yyy');
        zaakModel.contentDocumentIds = new List<Id> { v.ContentDocumentId };
        Test.startTest();
        ZaakService.enrichZaakWithFilesByReference(new List<ZaakModel> { zaakModel });
        System.assertEquals(1, zaakModel.informatieobjecten?.size(),'Expected 1 informatie object');
        System.assertEquals('test.txt', zaakModel.informatieobjecten[0].beschrijving,'Expected test.txt beschrijving');
        Test.stopTest();
    }
    @IsTest
    static void testModelConversion() {
        ContentVersion v = new ContentVersion();
        v.PathOnClient = 'test.txt';
        v.VersionData = Blob.valueOf('Test');
        v.Title = 'test.txt';
        insert v;
        Test.startTest();
        InformatieObjectModel infoModel = ZaakService.getModel(v);
        System.assertEquals('test.txt', infoModel.beschrijving,'Expected test.txt as the beschrijving');
        Test.stopTest();
    }
}