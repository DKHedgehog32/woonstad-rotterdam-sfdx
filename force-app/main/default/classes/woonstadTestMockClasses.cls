/*************************************************************************************************
 * Test Class      : woonstadTestMockClasses
 * Layer           : Test Support
 * Purpose         : Mock classes for testing woonstad services
 * Security        : @isTest annotation
 * Owner           : Woonstad KC
 * Last Modified   : 2025-01-27
 *************************************************************************************************/
@isTest
public class woonstadTestMockClasses {
    
    /**
     * @description Test data factory for creating test records
     */
    public static List<Account> createTestAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        
        for(Integer i = 0; i < count; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '555-000' + i,
                BillingStreet = 'Test Street ' + i,
                BillingCity = 'Test City',
                BillingPostalCode = '1000' + i,
                BillingCountry = 'Netherlands'
            );
            accounts.add(acc);
        }
        
        return accounts;
    }
    
    public static List<Address__c> createTestAddresses(Integer count) {
        List<Address__c> addresses = new List<Address__c>();
        
        for(Integer i = 0; i < count; i++) {
            Address__c addr = new Address__c(
                Street__c = 'Test Street ' + i,
                Postal_Code__c = '100' + i + ' AB',
                House_Number__c = String.valueOf(i + 1),
                House_Letter__c = null,
                House_Number_Addition__c = null,
                Country__c = 'Netherlands',
                City__c = 'Test City ' + i,
                BAG_Id__c = 'BAG' + String.valueOf(1000000 + i),
                Address_Line_1__c = 'Test Street ' + i + ' ' + (i + 1)
            );
            addresses.add(addr);
        }
        
        return addresses;
    }
    
    public static List<Account_Address__c> createTestLinks(
        List<Account> accounts, 
        List<Address__c> addresses
    ) {
        List<Account_Address__c> links = new List<Account_Address__c>();
        
        Integer maxLinks = Math.min(accounts.size(), addresses.size());
        
        for(Integer i = 0; i < maxLinks; i++) {
            Account_Address__c link = new Account_Address__c(
                Account__c = accounts[i].Id,
                Address__c = addresses[i].Id,
                Is_Primary__c = (i == 0),
                Start_Date__c = Date.today().addDays(-i),
                Type__c = 'WOO'
            );
            links.add(link);
        }
        
        return links;
    }
}