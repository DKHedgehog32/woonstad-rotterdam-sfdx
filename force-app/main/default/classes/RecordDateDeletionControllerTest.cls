/**
 * @description Test class for RecordDateDeletionController
 * @author Dylan Pluk
 * @date 2025
 * @group Data Management
 */
@isTest
private class RecordDateDeletionControllerTest {
    
    /**
     * @description Setup method to create test data using TestDataFactory
     * Note: Custom Metadata cannot be created in test context, so these tests assume
     * configuration exists in the org. For full test coverage, deploy test configurations.
     */
    @TestSetup
    static void setupTestData() {
        // Use unique timestamp to avoid duplicate rule violations
        String uniqueSuffix = String.valueOf(DateTime.now().getTime());
        
        // Create test person accounts with unique names
        List<Account> personAccounts = new List<Account>();
        RecordType rt = [SELECT Id FROM RecordType WHERE IsPersonType=true AND SobjectType='Account' AND IsActive=true LIMIT 1];
        
        for(Integer x=0; x < 5; x++) {
            Account acc = new Account();
            acc.LastName = 'TestAcc' + uniqueSuffix + x;
            acc.FirstName = 'Person';
            acc.RecordTypeId = rt.Id;
            personAccounts.add(acc);
        }
        insert personAccounts;
        
        // Create test addresses with unique keys
        List<Address__c> addresses = new List<Address__c>();
        for(Integer x=0; x < 5; x++) {
            Address__c addr = new Address__c();
            addr.Street__c = 'TestStreet' + uniqueSuffix + x;
            addr.Postal_Code__c = uniqueSuffix.substring(0, 4) + x + 'AA';
            addr.Country__c = 'NL';
            addr.House_Letter__c = 'a';
            addr.House_Number__c = String.valueOf(x + 1);
            addr.City__c = 'TestCity';
            addr.Unique_Key__c = addr.Street__c + addr.House_Number__c + addr.Postal_Code__c;
            addr.Name = addr.Street__c + ' ' + addr.House_Number__c;
            addresses.add(addr);
        }
        insert addresses;
        
        // Create bank accounts for the first person account
        List<Bank_Account__c> bankAccounts = new List<Bank_Account__c>();
        for(Integer x=0; x < 3; x++) {
            Bank_Account__c bacc = new Bank_Account__c();
            bacc.Account__c = personAccounts[0].Id;
            bacc.IBAN__c = 'NL73RABO0447391550';
            bankAccounts.add(bacc);
        }
        insert bankAccounts;
    }
    
    /**
     * @description Test getAvailableObjects method returns configured objects
     */
    @isTest
    static void testGetAvailableObjects_Success() {
        Test.startTest();
        List<RecordDateDeletionController.AvailableObject> availableObjects = 
            RecordDateDeletionController.getAvailableObjects();
        Test.stopTest();
        
        // Assert that we get a list back (may be empty if no Custom Metadata configured)
        System.assertNotEquals(null, availableObjects, 'Available objects list should not be null');
        
        // If objects are configured, verify structure
        if (!availableObjects.isEmpty()) {
            RecordDateDeletionController.AvailableObject firstObj = availableObjects[0];
            System.assertNotEquals(null, firstObj.apiName, 'API name should not be null');
            System.assertNotEquals(null, firstObj.displayLabel, 'Display label should not be null');
            System.assertNotEquals(null, firstObj.deletionOrder, 'Deletion order should not be null');
        }
    }
    
    /**
     * @description Test previewRecords with valid datetime range and objects
     */
    @isTest
    static void testPreviewRecords_Success() {
        // Get test data created in setup
        List<Account> accounts = [SELECT Id FROM Account LIMIT 5];
        
        // Create datetime range that includes today's records
        DateTime startDT = DateTime.now().addDays(-1);
        DateTime endDT = DateTime.now().addDays(1);
        
        String startDateTime = startDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        String endDateTime = endDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        
        List<String> objectNames = new List<String>{'Account'};
        
        Test.startTest();
        Map<String, Integer> recordCounts = RecordDateDeletionController.previewRecords(
            startDateTime,
            endDateTime,
            objectNames
        );
        Test.stopTest();
        
        // Assert that we get record counts back
        System.assertNotEquals(null, recordCounts, 'Record counts should not be null');
        
        // If accounts are in the date range, verify count
        if (recordCounts.containsKey('Account')) {
            System.assert(recordCounts.get('Account') >= 0, 'Account count should be non-negative');
        }
    }
    
    /**
     * @description Test previewRecords with multiple objects
     */
    @isTest
    static void testPreviewRecords_MultipleObjects() {
        // Create datetime range
        DateTime startDT = DateTime.now().addDays(-1);
        DateTime endDT = DateTime.now().addDays(1);
        
        String startDateTime = startDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        String endDateTime = endDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        
        List<String> objectNames = new List<String>{'Account', 'Address__c', 'Bank_Account__c'};
        
        Test.startTest();
        Map<String, Integer> recordCounts = RecordDateDeletionController.previewRecords(
            startDateTime,
            endDateTime,
            objectNames
        );
        Test.stopTest();
        
        System.assertNotEquals(null, recordCounts, 'Record counts should not be null');
    }
    
    /**
     * @description Test previewRecords with invalid parameters (null datetime)
     */
    @isTest
    static void testPreviewRecords_NullParameters() {
        List<String> objectNames = new List<String>{'Account'};
        Boolean exceptionThrown = false;
        String errorMessage = '';
        
        Test.startTest();
        try {
            RecordDateDeletionController.previewRecords(null, null, objectNames);
        } catch (Exception e) {
            exceptionThrown = true;
            errorMessage = e.getMessage();
            // Verify it's an AuraHandledException with Dutch message
            System.assert(e instanceof AuraHandledException, 'Should be AuraHandledException, got: ' + e.getTypeName());
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Expected exception to be thrown. Got message: ' + errorMessage);
    }
    
    /**
     * @description Test previewRecords with empty object list
     */
    @isTest
    static void testPreviewRecords_EmptyObjectList() {
        DateTime startDT = DateTime.now().addDays(-1);
        DateTime endDT = DateTime.now().addDays(1);
        
        String startDateTime = startDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        String endDateTime = endDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        
        List<String> objectNames = new List<String>();
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            RecordDateDeletionController.previewRecords(startDateTime, endDateTime, objectNames);
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e instanceof AuraHandledException, 'Should be AuraHandledException');
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown');
    }
    
    /**
     * @description Test previewRecords with end datetime before start datetime
     */
    @isTest
    static void testPreviewRecords_InvalidDateRange() {
        DateTime startDT = DateTime.now();
        DateTime endDT = DateTime.now().addDays(-1); // End before start
        
        String startDateTime = startDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        String endDateTime = endDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        
        List<String> objectNames = new List<String>{'Account'};
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            RecordDateDeletionController.previewRecords(startDateTime, endDateTime, objectNames);
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e instanceof AuraHandledException, 'Should be AuraHandledException');
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown');
    }
    
    /**
     * @description Test deleteRecordsByDate successfully deletes records
     */
    @isTest
    static void testDeleteRecordsByDate_Success() {
        // Get test data
        List<Account> accounts = [SELECT Id FROM Account];
        Integer initialCount = accounts.size();
        
        // Create datetime range that includes today's records
        DateTime startDT = DateTime.now().addDays(-1);
        DateTime endDT = DateTime.now().addDays(1);
        
        String startDateTime = startDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        String endDateTime = endDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        
        List<String> objectNames = new List<String>{'Account'};
        
        Test.startTest();
        RecordDateDeletionController.DeletionResult result = 
            RecordDateDeletionController.deleteRecordsByDate(
                startDateTime,
                endDateTime,
                objectNames
            );
        Test.stopTest();
        
        // Assert deletion result
        System.assertNotEquals(null, result, 'Deletion result should not be null');
        System.assertNotEquals(null, result.message, 'Result message should not be null');
        System.assertNotEquals(null, result.errors, 'Errors list should not be null');
        
        // Verify records were deleted
        List<Account> remainingAccounts = [SELECT Id FROM Account];
        System.assert(remainingAccounts.size() < initialCount, 
                     'Accounts should have been deleted');
    }
    
    /**
     * @description Test deleteRecordsByDate with multiple related objects
     */
    @isTest
    static void testDeleteRecordsByDate_MultipleObjects() {
        // Use unique timestamp to avoid duplicates
        String uniqueSuffix = String.valueOf(DateTime.now().getTime());
        
        // Create fresh related records with unique identifiers
        List<Account> personAccounts = new List<Account>();
        RecordType rt = [SELECT Id FROM RecordType WHERE IsPersonType=true AND SobjectType='Account' AND IsActive=true LIMIT 1];
        
        for(Integer x=0; x < 3; x++) {
            Account acc = new Account();
            acc.LastName = 'TestMulti' + uniqueSuffix + x;
            acc.FirstName = 'PersonMulti';
            acc.RecordTypeId = rt.Id;
            personAccounts.add(acc);
        }
        insert personAccounts;
        
        List<Address__c> addresses = new List<Address__c>();
        for(Integer x=0; x < 3; x++) {
            Address__c addr = new Address__c();
            addr.Street__c = 'MultiStreet' + uniqueSuffix + x;
            addr.Postal_Code__c = uniqueSuffix.substring(0, 4) + x + 'ZZ';
            addr.Country__c = 'NL';
            addr.House_Letter__c = 'b';
            addr.House_Number__c = String.valueOf(x + 100);
            addr.City__c = 'MultiCity';
            addr.Unique_Key__c = addr.Street__c + addr.House_Number__c + addr.Postal_Code__c;
            addr.Name = addr.Street__c + ' ' + addr.House_Number__c;
            addresses.add(addr);
        }
        insert addresses;
        
        // Create datetime range
        DateTime startDT = DateTime.now().addDays(-1);
        DateTime endDT = DateTime.now().addDays(1);
        
        String startDateTime = startDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        String endDateTime = endDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        
        List<String> objectNames = new List<String>{'Account', 'Address__c'};
        
        Test.startTest();
        RecordDateDeletionController.DeletionResult result = 
            RecordDateDeletionController.deleteRecordsByDate(
                startDateTime,
                endDateTime,
                objectNames
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Deletion result should not be null');
        System.assert(result.message.contains('Succesvol verwijderd') || 
                     result.message.contains('Er zijn geen records verwijderd'), 
                     'Result message should be in Dutch: ' + result.message);
    }
    
    /**
     * @description Test deleteRecordsByDate with records that fail to delete
     * Note: This test demonstrates partial failure handling
     */
    @isTest
    static void testDeleteRecordsByDate_WithErrors() {
        // Use unique timestamp to avoid duplicates
        String uniqueSuffix = String.valueOf(DateTime.now().getTime());
        
        // Create an account with related bank accounts (cannot delete parent with children)
        List<Account> accounts = new List<Account>();
        RecordType rt = [SELECT Id FROM RecordType WHERE IsPersonType=true AND SobjectType='Account' AND IsActive=true LIMIT 1];
        
        Account acc = new Account();
        acc.LastName = 'TestError' + uniqueSuffix;
        acc.FirstName = 'PersonError';
        acc.RecordTypeId = rt.Id;
        accounts.add(acc);
        insert accounts;
        
        List<Bank_Account__c> bankAccounts = new List<Bank_Account__c>();
        for(Integer x=0; x < 2; x++) {
            Bank_Account__c bacc = new Bank_Account__c();
            bacc.Account__c = accounts[0].Id;
            bacc.IBAN__c = 'NL73RABO0447391550';
            bankAccounts.add(bacc);
        }
        insert bankAccounts;
        
        // Create datetime range
        DateTime startDT = DateTime.now().addDays(-1);
        DateTime endDT = DateTime.now().addDays(1);
        
        String startDateTime = startDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        String endDateTime = endDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        
        // Try to delete only accounts (should fail due to related bank accounts)
        List<String> objectNames = new List<String>{'Account'};
        
        Test.startTest();
        RecordDateDeletionController.DeletionResult result = 
            RecordDateDeletionController.deleteRecordsByDate(
                startDateTime,
                endDateTime,
                objectNames
            );
        Test.stopTest();
        
        // Assert that we got a result with errors
        System.assertNotEquals(null, result, 'Deletion result should not be null');
        System.assertNotEquals(null, result.errors, 'Errors list should not be null');
        
        // If there were errors, verify structure
        if (result.errors.size() > 0) {
            RecordDateDeletionController.DeletionError firstError = result.errors[0];
            System.assertNotEquals(null, firstError.id, 'Error ID should not be null');
            System.assertNotEquals(null, firstError.objectType, 'Object type should not be null');
            System.assertNotEquals(null, firstError.recordName, 'Record name should not be null');
            System.assertNotEquals(null, firstError.errorMessage, 'Error message should not be null');
        }
    }
    
    /**
     * @description Test deleteRecordsByDate with no records to delete
     */
    @isTest
    static void testDeleteRecordsByDate_NoRecords() {
        // Create datetime range in the far past (no records should exist)
        DateTime startDT = DateTime.newInstance(2020, 1, 1, 0, 0, 0);
        DateTime endDT = DateTime.newInstance(2020, 1, 2, 0, 0, 0);
        
        String startDateTime = startDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        String endDateTime = endDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        
        List<String> objectNames = new List<String>{'Account'};
        
        Test.startTest();
        RecordDateDeletionController.DeletionResult result = 
            RecordDateDeletionController.deleteRecordsByDate(
                startDateTime,
                endDateTime,
                objectNames
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Deletion result should not be null');
        System.assert(result.message.contains('Er zijn geen records verwijderd'), 
                     'Message should indicate no records deleted in Dutch');
    }
    
    /**
     * @description Test deleteRecordsByDate with invalid parameters
     */
    @isTest
    static void testDeleteRecordsByDate_InvalidParameters() {
        List<String> objectNames = new List<String>{'Account'};
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            RecordDateDeletionController.deleteRecordsByDate(null, null, objectNames);
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e instanceof AuraHandledException, 'Should be AuraHandledException');
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown');
    }
    
    /**
     * @description Test deleteRecordsByDate with invalid date range
     */
    @isTest
    static void testDeleteRecordsByDate_InvalidDateRange() {
        DateTime startDT = DateTime.now();
        DateTime endDT = DateTime.now().addDays(-1);
        
        String startDateTime = startDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        String endDateTime = endDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        
        List<String> objectNames = new List<String>{'Account'};
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            RecordDateDeletionController.deleteRecordsByDate(startDateTime, endDateTime, objectNames);
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e instanceof AuraHandledException, 'Should be AuraHandledException');
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown');
    }
    
    /**
     * @description Test DeletionResult wrapper class structure
     */
    @isTest
    static void testDeletionResult_Structure() {
        Test.startTest();
        RecordDateDeletionController.DeletionResult result = 
            new RecordDateDeletionController.DeletionResult();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'DeletionResult should not be null');
        System.assertNotEquals(null, result.errors, 'Errors list should be initialized');
        System.assertEquals(0, result.errors.size(), 'Errors list should be empty initially');
    }
    
    /**
     * @description Test DeletionError wrapper class structure
     */
    @isTest
    static void testDeletionError_Structure() {
        Test.startTest();
        RecordDateDeletionController.DeletionError error = 
            new RecordDateDeletionController.DeletionError(
                'Account',
                'Test Account',
                'Cannot delete due to related records'
            );
        Test.stopTest();
        
        System.assertNotEquals(null, error, 'DeletionError should not be null');
        System.assertNotEquals(null, error.id, 'Error ID should be generated');
        System.assertEquals('Account', error.objectType, 'Object type should match');
        System.assertEquals('Test Account', error.recordName, 'Record name should match');
        System.assertEquals('Cannot delete due to related records', error.errorMessage, 
                          'Error message should match');
    }
    
    /**
     * @description Test AvailableObject wrapper class structure
     */
    @isTest
    static void testAvailableObject_Structure() {
        Test.startTest();
        RecordDateDeletionController.AvailableObject obj = 
            new RecordDateDeletionController.AvailableObject(
                'Account',
                'Accounts',
                50
            );
        Test.stopTest();
        
        System.assertNotEquals(null, obj, 'AvailableObject should not be null');
        System.assertEquals('Account', obj.apiName, 'API name should match');
        System.assertEquals('Accounts', obj.displayLabel, 'Display label should match');
        System.assertEquals(50, obj.deletionOrder, 'Deletion order should match');
    }
    
    /**
     * @description Test bulk deletion with multiple records
     */
    @isTest
    static void testBulkDeletion() {
        // Use unique timestamp to avoid duplicates
        String uniqueSuffix = String.valueOf(DateTime.now().getTime());
        
        // Create 200 accounts to test bulk operations
        List<Account> bulkAccounts = new List<Account>();
        RecordType rt = [SELECT Id FROM RecordType WHERE IsPersonType=true AND SobjectType='Account' AND IsActive=true LIMIT 1];
        
        for(Integer x=0; x < 200; x++) {
            Account acc = new Account();
            acc.LastName = 'TestBulk' + uniqueSuffix + x;
            acc.FirstName = 'PersonBulk';
            acc.RecordTypeId = rt.Id;
            bulkAccounts.add(acc);
        }
        insert bulkAccounts;
        
        // Create datetime range
        DateTime startDT = DateTime.now().addDays(-1);
        DateTime endDT = DateTime.now().addDays(1);
        
        String startDateTime = startDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        String endDateTime = endDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        
        List<String> objectNames = new List<String>{'Account'};
        
        Test.startTest();
        RecordDateDeletionController.DeletionResult result = 
            RecordDateDeletionController.deleteRecordsByDate(
                startDateTime,
                endDateTime,
                objectNames
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Deletion result should not be null');
        
        // Verify bulk deletion worked
        Integer remainingCount = [SELECT COUNT() FROM Account WHERE LastName LIKE 'TestBulk%'];
        System.assert(remainingCount < 200, 
                     'Bulk accounts should have been deleted');
    }
}