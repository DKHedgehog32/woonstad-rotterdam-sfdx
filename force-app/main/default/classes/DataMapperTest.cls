/**
 * Some tests to cover the unused/undeployed datamapper parts. Logic is tested elsewhere
 */
@IsTest
private class DataMapperTest {
    @IsTest
    private static void testAccountToPersoon() {
        List<Account> paccs = TestDataFactory.getPersonAccounts(1);
        List<Account> baccs = TestDataFactory.getBusinessAccounts(1);
        Test.startTest();
        PersoonModel pm1 = DataMapper.accountToPersoon(paccs[0]);
        PersoonModel pm2 = DataMapper.accountToPersoon(baccs[0]);

        Test.stopTest();
    }
    @IsTest
    private static void testAdresModelToAddress() {
        AdresModel amNl = AdresModel.getMock();
        AdresModel amBu = AdresModel.getMock();
        amBu.land.code = 'BE';
        Test.startTest();
        DataMapper.mapAdresModelToAddress(amNl);
        DataMapper.mapAdresModelToAddress(amBu);
        Test.stopTest();
    }
    @IsTest
    private static void testBankAccountToBetaalGegevenModel() {
        Account[] accs = TestDataFactory.getPersonAccounts(1);
        accs[0].UUID__c = '1234';
        upsert accs;
        List<Bank_Account__c> baccs = TestDataFactory.getBankAccounts(1, accs[0].Id);
        Test.startTest();
        DataMapper.mapBankAccountToBetaalGegevenModel(baccs[0]);
        Test.stopTest();
    }
    @IsTest
    private static void testRelationShipToPersoonRelatieModel() {
        Account[] accs = TestDataFactory.getPersonAccounts(2);
        accs[0].UUID__c = '1234';
        accs[1].UUID__c = '4321';
        upsert accs;
        Relationship__c rel = new Relationship__c();
        rel.Type__c = 'BWI';
        rel.Primary_Relation__c = accs[0].Id;
        rel.Subsidiary_Relation__c = accs[1].Id;
        insert rel;
        Test.startTest();
        DataMapper.mapRelationShipToPersoonRelatieModel(rel);
        Test.stopTest();
    }
}