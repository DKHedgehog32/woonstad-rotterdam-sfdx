/**
 * Created by harm on 02/09/2024.
 */
@IsTest
private class PersonRelationServiceTest {
    @IsTest
    private static void testAccountContactRelations() {
        PersoonModel pm = PersoonModel.getMock();
        pm.persoonRelaties[0].relatieRol.code = 'CPE'; // this role should exist in AccountContactRelation
        pm.persoonRelaties.add(PersoonRelatieModel.getMock('mock-id')); // Add a role that should not end up in AccountContactRelation
        //System.debug('## '+JSON.serializePretty(pm));
        Test.startTest();
        List<AccountContactRelation> rels = PersonRelationService.getAccountContactRelationRecordsForUpsert(pm, 'mock-id');
        System.assertEquals(1, rels.size(), 'Expected 1 record');
        System.assert(rels[0].Role_2__c.contains('CPE'), 'Expected CPE role: '+rels[0].Role_2__c);
        Test.stopTest();
    }
    @IsTest
    private static void testRelationships() {
        PersoonModel pm = PersoonModel.getMock();
        pm.persoonRelaties[0].relatieRol.code = 'BWI'; // this role should exist in Relationship__c
        pm.persoonRelaties.add(PersoonRelatieModel.getMock('mock-id')); // Add a role that should not end up in Relationship__c
        Test.startTest();
        List<Relationship__c> rels = PersonRelationService.getRelationshipRecordsForUpsert(pm, 'mock-id');
        System.assertEquals(1, rels.size(), 'Expected 1 record');
        System.assertEquals('BWI',rels[0].Type__c, 'Expected BWI type');
        Test.stopTest();
    }
    @IsTest
    private static void testTriggers() {
        Account[] accs = TestDataFactory.getPersonAccounts(2);
        accs[0].UUID__c = '1234';
        accs[1].UUID__c = '2234';
        upsert accs;
        Relationship__c rel = new Relationship__c();
        rel.Type__c = 'BWI';
        rel.Primary_Relation__r = new Account(UUID__c='1234');
        rel.Subsidiary_Relation__r = new Account(UUID__c='2234');
        AccountContactRelation rel2 = new AccountContactRelation();
        rel2.Role_2__c = 'CPE';
        rel2.Account = new Account(UUID__c='1234');
        rel2.Contact = new Contact(Contact_UUID__c='2234');
        Test.startTest();
        upsert rel;
        upsert rel2;
        System.assertNotEquals(null, rel.Id,'Expected ID in Relationship__c');
        System.assertNotEquals(null, rel2.Id,'Expected ID in AccountContactRelation');
        Test.stopTest();
    }
}