/**
 * Generates test data
 */
public with sharing class TestDataFactory {
    public static List<Account> getPersonAccounts(Integer numberOfAccounts) {
        RecordType rt = [SELECT Id FROM RecordType WHERE IsPersonType=true AND SobjectType='Account' AND IsActive=true LIMIT 1];

        List<Account> output = new List<Account>();
        for(Integer x=0; x <numberOfAccounts; x++) {
            Account acc = new Account();
            acc.LastName = 'Test Acc '+x;
            acc.FirstName = 'Person';
            acc.RecordTypeId = rt.Id;
            output.add(acc);
        }
        return output;
    }
    public static List<Account> getBusinessAccounts(Integer numberOfAccounts) {
        RecordType rt = [SELECT Id FROM RecordType WHERE IsPersonType=false AND SobjectType='Account' AND IsActive=true LIMIT 1];

        List<Account> output = new List<Account>();
        for(Integer x=0; x <numberOfAccounts; x++) {
            Account acc = new Account();
            acc.Name = 'Test Acc '+x;
            acc.RecordTypeId = rt.Id;
            output.add(acc);
        }
        return output;
    }
    public static List<Address__c> getAddresses(Integer numberAddresses) {

        List<Address__c> output = new List<Address__c>();
        for(Integer x=0; x <numberAddresses; x++) {
            Address__c addr = new Address__c();
            addr.Street__c = 'Street'+x;
            addr.Postal_Code__c = '123'+x+'AA';
            addr.Country__c = 'NL';
            addr.House_Letter__c = 'a';
            addr.House_Number__c = String.valueOf(x);
            addr.City__c = 'Apexia';
            addr.Unique_Key__c = AddressService.getAddressKey(addr);
            addr.Name = AddressService.getNameValue(addr);
            output.add(addr);
        }
        return output;
    }
    public static List<Bank_Account__c> getBankAccounts(Integer numBankAccounts, ID accountId) {

        List<Bank_Account__c> output = new List<Bank_Account__c>();
        for(Integer x=0; x <numBankAccounts; x++) {
            Bank_Account__c bacc = new Bank_Account__c();
            bacc.Account__c = accountId;
            bacc.IBAN__c = 'NL73RABO0447391550';
            output.add(bacc);
        }
        return output;
    }
    public static Relationship__c getRelationship(Id primaryId, Id subsidiaryId, String type) {
        Relationship__c rl = new Relationship__c();
        rl.Primary_Relation__c = primaryId;
        rl.Subsidiary_Relation__c = subsidiaryId;
        rl.Type__c = type;
        return rl;
    }
    public static AccountContactRelation getAccountContactRelationship(Id accountId, Id contactId, String type) {
        AccountContactRelation rl = new AccountContactRelation();
        rl.AccountId = accountId;
        rl.ContactId = contactId;
        rl.Role_2__c = type;
        return rl;
    }
    public static Contract_Unit__c getContractUnit(String unitId) {
        Contract_Unit__c unit = new Contract_Unit__c();
        unit.External_Id__c = unitId;
        unit.Status__c = 'VEH';
        unit.Unit_Category__c = 'WOO';
        return unit;
    }
}