@IsTest
private class ContractServiceTest {
    @IsTest
    static void testCompositeKeys() {
        Test.startTest();
        String expectedDateString = IdentifierService.getDateStamp(System.today());
        String lineCompositeKey = ContractService.getLineCompositeId('xxx', 'yyyy', new Contract_Line__c(Active_from_Date__c=System.today()));
        String ccrCompositeKey = ContractService.getContractContactRoleCompositeId('xxx', 'yyyy', new Contract_Contact_Role__c(Start_Date__c=System.today(), Role__c='BEW'));
        String clrCompositeKey = ContractService.getClusterRoleCompositeId('xxx', 'yyyy', new Cluster_Role__c(Start_Date__c=System.today(), Role__c='VVE'));
        System.assertEquals('xxx-yyyy-'+expectedDateString, lineCompositeKey, 'Expected different line key');
        System.assertEquals('xxx-yyyy-BEW-'+expectedDateString, ccrCompositeKey, 'Expected different contract contact role key');
        System.assertEquals('xxx-yyyy-VVE-'+expectedDateString, clrCompositeKey, 'Expected different cluster role key');
        Test.stopTest();
    }
}