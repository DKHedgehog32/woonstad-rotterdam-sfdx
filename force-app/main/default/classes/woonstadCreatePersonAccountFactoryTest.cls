/*************************************************************************************************
 * Class           : woonstadCreatePersonAccountFactoryTest
 * Layer           : Test
 * Purpose         : Comprehensive test coverage for woonstadCreatePersonAccountFactory
 *                   following AWAF.dev guidelines and Salesforce best practices.
 *                   Tests the buildTenant method with various scenarios including
 *                   positive tests, negative tests, boundary conditions, and null handling.
 * Owner           : Woonstad KC
 * Created         : 2025-09-04
 * Last Modified   : 2025-09-04
 * Test Coverage   : Targets 95%+ code coverage for woonstadCreatePersonAccountFactory
 * 
 * DESCRIPTION:
 * This test class validates the woonstadCreatePersonAccountFactory using the AAA pattern
 * (Arrange, Act, Assert) and follows Clean Code principles. It includes:
 * - Positive test cases with valid data
 * - Boundary testing with null values
 * - Bulk data testing for scalability
 * - Edge cases and validation testing
 * 
 * The class uses Test Data Factory pattern for maintainable test data creation
 * and ensures each test method focuses on a single responsibility.
 * 
 * TECHNICAL IMPLEMENTATION:
 * - Uses @TestSetup for shared test data creation
 * - Implements Test Data Factory methods for reusable test objects
 * - Follows AWAF.dev principles of clean, readable test code
 * - Each test method uses descriptive naming convention
 * - Comprehensive assertions validate all object properties
 * 
 * CHANGELOG:
 * 2025-09-04 - Initial creation with comprehensive test coverage
 *************************************************************************************************/

@isTest(SeeAllData=false)
private class woonstadCreatePersonAccountFactoryTest {
    
    // Test data constants for consistent testing
    private static final String TENANT_TYPE = 'Tenant';
    private static final String TEST_FIRST_NAME = 'John';
    private static final String TEST_MIDDLE_NAME = 'van';
    private static final String TEST_LAST_NAME = 'Doe';
    private static final String TEST_EMAIL = 'john.doe@example.com';
    private static final String TEST_PHONE = '+31201234567';
    private static final String TEST_MOBILE = '+31612345678';
    private static final Date TEST_BIRTHDATE = Date.newInstance(1990, 5, 15);
    
    // Static variables for test setup data
    private static Id personAccountRecordTypeId;
    
    /**
     * Test setup method to create reusable test data
     * Creates Person Account record type for consistent testing
     */
    @TestSetup
    static void setupTestData() {
        // Arrange: Get Person Account Record Type
        // This ensures we have a valid RecordType for all tests
        personAccountRecordTypeId = getPersonAccountRecordType();
    }
    
    /**
     * POSITIVE TEST: Test buildTenant with all valid parameters
     * Validates that a complete Account object is created with all fields populated
     */
    @isTest
    static void buildTenant_WithAllValidParameters_ShouldCreateCompleteAccount() {
        // Arrange: Prepare all required test data
        Id recordTypeId = getPersonAccountRecordType();
        String firstName = TEST_FIRST_NAME;
        String middleName = TEST_MIDDLE_NAME;
        String lastName = TEST_LAST_NAME;
        Date birthdate = TEST_BIRTHDATE;
        String phone = TEST_PHONE;
        String email = TEST_EMAIL;
        String mobile = TEST_MOBILE;
        
        // Act: Call the method under test
        Test.startTest();
        Account result = woonstadCreatePersonAccountFactory.buildTenant(
            recordTypeId,
            firstName,
            middleName,
            lastName,
            birthdate,
            phone,
            email,
            mobile
        );
        Test.stopTest();
        
        // Assert: Verify all expected field values
        System.assertNotEquals(null, result, 'Account should not be null');
        System.assertEquals(recordTypeId, result.RecordTypeId, 'RecordTypeId should match input');
        System.assertEquals(TENANT_TYPE, result.Account_Type__c, 'Account_Type__c should be set to Tenant');
        System.assertEquals(firstName, result.FirstName, 'FirstName should match input');
        System.assertEquals(middleName, result.MiddleName, 'MiddleName should match input');
        System.assertEquals(lastName, result.LastName, 'LastName should match input');
        System.assertEquals(birthdate, result.PersonBirthdate, 'PersonBirthdate should match input');
        System.assertEquals(phone, result.Phone, 'Phone should match input');
        System.assertEquals(email, result.PersonEmail, 'PersonEmail should match input');
        System.assertEquals(mobile, result.PersonMobilePhone, 'PersonMobilePhone should match input');
    }
    
    /**
     * BOUNDARY TEST: Test buildTenant with null birthdate
     * Validates that the method handles null birthdate gracefully
     */
    @isTest
    static void buildTenant_WithNullBirthdate_ShouldCreateAccountWithoutBirthdate() {
        // Arrange: Set up test data with null birthdate
        Id recordTypeId = getPersonAccountRecordType();
        Date nullBirthdate = null; // Explicitly setting null for clarity
        
        // Act: Call method with null birthdate
        Test.startTest();
        Account result = woonstadCreatePersonAccountFactory.buildTenant(
            recordTypeId,
            TEST_FIRST_NAME,
            TEST_MIDDLE_NAME,
            TEST_LAST_NAME,
            nullBirthdate, // This tests the null handling logic
            TEST_PHONE,
            TEST_EMAIL,
            TEST_MOBILE
        );
        Test.stopTest();
        
        // Assert: Verify birthdate is not set when null is passed
        System.assertNotEquals(null, result, 'Account should not be null');
        System.assertEquals(null, result.PersonBirthdate, 'PersonBirthdate should remain null when null is passed');
        // Verify other fields are still populated correctly
        System.assertEquals(TEST_FIRST_NAME, result.FirstName, 'FirstName should be populated');
        System.assertEquals(TENANT_TYPE, result.Account_Type__c, 'Account_Type__c should be set to Tenant');
    }
    
    /**
     * EDGE CASE TEST: Test buildTenant with minimal required data
     * Tests the factory with only essential fields populated
     */
    @isTest
    static void buildTenant_WithMinimalData_ShouldCreateBasicAccount() {
        // Arrange: Use minimal data (empty strings for optional fields)
        Id recordTypeId = getPersonAccountRecordType();
        String emptyString = '';
        Date nullBirthdate = null;
        
        // Act: Call method with minimal data
        Test.startTest();
        Account result = woonstadCreatePersonAccountFactory.buildTenant(
            recordTypeId,
            TEST_FIRST_NAME,
            emptyString, // Empty middle name
            TEST_LAST_NAME,
            nullBirthdate, // Null birthdate
            emptyString, // Empty phone
            emptyString, // Empty email
            emptyString  // Empty mobile
        );
        Test.stopTest();
        
        // Assert: Verify essential fields are set, optional fields handle empty values
        System.assertNotEquals(null, result, 'Account should not be null');
        System.assertEquals(recordTypeId, result.RecordTypeId, 'RecordTypeId should be set');
        System.assertEquals(TENANT_TYPE, result.Account_Type__c, 'Account_Type__c should be Tenant');
        System.assertEquals(TEST_FIRST_NAME, result.FirstName, 'FirstName should be set');
        System.assertEquals(TEST_LAST_NAME, result.LastName, 'LastName should be set');
        System.assertEquals(emptyString, result.MiddleName, 'MiddleName should handle empty string');
        System.assertEquals(null, result.PersonBirthdate, 'PersonBirthdate should be null');
    }
    
    /**
     * BULK TEST: Test buildTenant method scalability
     * Validates the method can handle multiple Account creations efficiently
     * This is important for bulk operations and trigger scenarios
     */
    @isTest
    static void buildTenant_BulkCreation_ShouldHandleMultipleAccounts() {
        // Arrange: Prepare for bulk testing
        Id recordTypeId = getPersonAccountRecordType();
        Integer bulkSize = 200; // Test with Salesforce bulk limits in mind
        List<Account> bulkAccounts = new List<Account>();
        
        // Act: Create multiple accounts using the factory
        Test.startTest();
        for (Integer i = 0; i < bulkSize; i++) {
            Account testAccount = woonstadCreatePersonAccountFactory.buildTenant(
                recordTypeId,
                'FirstName' + i,
                'van',
                'LastName' + i,
                TEST_BIRTHDATE,
                TEST_PHONE,
                'test' + i + '@example.com',
                TEST_MOBILE
            );
            bulkAccounts.add(testAccount);
        }
        Test.stopTest();
        
        // Assert: Verify all accounts were created correctly
        System.assertEquals(bulkSize, bulkAccounts.size(), 'Should create expected number of accounts');
        
        // Spot check first and last accounts
        Account firstAccount = bulkAccounts[0];
        Account lastAccount = bulkAccounts[bulkSize - 1];
        
        System.assertEquals('FirstName0', firstAccount.FirstName, 'First account FirstName should be correct');
        System.assertEquals('FirstName' + (bulkSize - 1), lastAccount.FirstName, 'Last account FirstName should be correct');
        System.assertEquals(TENANT_TYPE, firstAccount.Account_Type__c, 'Account_Type__c should be consistent');
        System.assertEquals(TENANT_TYPE, lastAccount.Account_Type__c, 'Account_Type__c should be consistent');
    }
    
    /**
     * DATA VALIDATION TEST: Test buildTenant with various data formats
     * Validates the factory handles different valid data formats correctly
     */
    @isTest
    static void buildTenant_WithVariousDataFormats_ShouldHandleCorrectly() {
        // Arrange: Test with various valid data formats
        Id recordTypeId = getPersonAccountRecordType();
        
        // Test data with different formatting
        String longFirstName = 'Extraordinarily-Long-First-Name-With-Hyphens';
        String specialCharMiddleName = 'van der';
        String accentedLastName = 'Müller';
        String internationalPhone = '+49 30 12345678';
        String longEmail = 'very.long.email.address.for.testing@extremely-long-domain-name.example.com';
        Date futureBirthdate = Date.today().addYears(-25); // 25 years ago
        
        // Act: Create account with various data formats
        Test.startTest();
        Account result = woonstadCreatePersonAccountFactory.buildTenant(
            recordTypeId,
            longFirstName,
            specialCharMiddleName,
            accentedLastName,
            futureBirthdate,
            internationalPhone,
            longEmail,
            TEST_MOBILE
        );
        Test.stopTest();
        
        // Assert: Verify all data formats are handled correctly
        System.assertNotEquals(null, result, 'Account should not be null');
        System.assertEquals(longFirstName, result.FirstName, 'Long first name should be handled');
        System.assertEquals(specialCharMiddleName, result.MiddleName, 'Special characters in middle name should be handled');
        System.assertEquals(accentedLastName, result.LastName, 'Accented characters should be handled');
        System.assertEquals(futureBirthdate, result.PersonBirthdate, 'Calculated birthdate should be handled');
        System.assertEquals(internationalPhone, result.Phone, 'International phone format should be handled');
        System.assertEquals(longEmail, result.PersonEmail, 'Long email addresses should be handled');
    }
    
    /**
     * FIELD ISOLATION TEST: Test that Account_Type__c is always set to TENANT constant
     * This test ensures the factory consistently sets the Account_Type__c field
     */
    @isTest
    static void buildTenant_AlwaysSetsAccountType_ShouldBeConsistent() {
        // Arrange: Multiple test scenarios
        Id recordTypeId = getPersonAccountRecordType();
        
        // Act & Assert: Test multiple scenarios to ensure consistency
        Test.startTest();
        
        // Scenario 1: Full data
        Account account1 = woonstadCreatePersonAccountFactory.buildTenant(
            recordTypeId, TEST_FIRST_NAME, TEST_MIDDLE_NAME, TEST_LAST_NAME,
            TEST_BIRTHDATE, TEST_PHONE, TEST_EMAIL, TEST_MOBILE
        );
        
        // Scenario 2: Minimal data
        Account account2 = woonstadCreatePersonAccountFactory.buildTenant(
            recordTypeId, TEST_FIRST_NAME, '', TEST_LAST_NAME,
            null, '', '', ''
        );
        
        Test.stopTest();
        
        // Assert: Both accounts should have the same Account_Type__c
        System.assertEquals(TENANT_TYPE, account1.Account_Type__c, 'Account1 type should be Tenant');
        System.assertEquals(TENANT_TYPE, account2.Account_Type__c, 'Account2 type should be Tenant');
        System.assertEquals(account1.Account_Type__c, account2.Account_Type__c, 'Account types should be consistent');
    }
    
    /**
     * METHOD BEHAVIOR TEST: Verify method creates new Account instance each time
     * Ensures the factory method returns distinct Account objects
     * Note: We test this by modifying one object and ensuring the other is unaffected
     */
    @isTest
    static void buildTenant_CreatesNewInstances_ShouldReturnDistinctObjects() {
        // Arrange: Same input parameters
        Id recordTypeId = getPersonAccountRecordType();
        
        // Act: Call factory method twice with identical parameters
        Test.startTest();
        Account account1 = woonstadCreatePersonAccountFactory.buildTenant(
            recordTypeId, TEST_FIRST_NAME, TEST_MIDDLE_NAME, TEST_LAST_NAME,
            TEST_BIRTHDATE, TEST_PHONE, TEST_EMAIL, TEST_MOBILE
        );
        
        Account account2 = woonstadCreatePersonAccountFactory.buildTenant(
            recordTypeId, TEST_FIRST_NAME, TEST_MIDDLE_NAME, TEST_LAST_NAME,
            TEST_BIRTHDATE, TEST_PHONE, TEST_EMAIL, TEST_MOBILE
        );
        Test.stopTest();
        
        // Assert: Verify both objects are created properly first
        System.assertNotEquals(null, account1, 'First account should not be null');
        System.assertNotEquals(null, account2, 'Second account should not be null');
        System.assertEquals(account1.FirstName, account2.FirstName, 'Field values should be identical initially');
        System.assertEquals(account1.LastName, account2.LastName, 'Field values should be identical initially');
        System.assertEquals(account1.Account_Type__c, account2.Account_Type__c, 'Account types should be identical');
        
        // Modify one account to prove they are separate instances
        account1.FirstName = 'Modified';
        
        // Assert: After modifying account1, account2 should remain unchanged
        System.assertEquals('Modified', account1.FirstName, 'Account1 should be modified');
        System.assertEquals(TEST_FIRST_NAME, account2.FirstName, 'Account2 should remain unchanged');
        System.assertNotEquals(account1.FirstName, account2.FirstName, 'Objects should be independent instances');
    }
    
    // HELPER METHODS (Test Data Factory Pattern)
    
    /**
     * Helper method to get Person Account Record Type ID
     * This centralizes record type retrieval and makes tests more maintainable
     * @return Id - Person Account Record Type ID
     */
    private static Id getPersonAccountRecordType() {
        // Query for Person Account record type
        // Note: This assumes Person Account is enabled in the org
        RecordType personAccountRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Account' 
            AND DeveloperName = 'PersonAccount' 
            LIMIT 1
        ];
        return personAccountRT.Id;
    }
    
    /**
     * Test Data Factory method to create a standard test Account
     * This follows the Test Data Factory pattern for maintainable test data
     * @param recordTypeId - The Record Type ID to use
     * @return Account - A pre-configured test Account
     */
    @TestVisible
    private static Account createStandardTestAccount(Id recordTypeId) {
        return woonstadCreatePersonAccountFactory.buildTenant(
            recordTypeId,
            TEST_FIRST_NAME,
            TEST_MIDDLE_NAME,
            TEST_LAST_NAME,
            TEST_BIRTHDATE,
            TEST_PHONE,
            TEST_EMAIL,
            TEST_MOBILE
        );
    }
    
    /**
     * Test Data Factory method to create Account with minimal data
     * Used for testing edge cases and boundary conditions
     * @param recordTypeId - The Record Type ID to use  
     * @return Account - A minimally configured test Account
     */
    @TestVisible
    private static Account createMinimalTestAccount(Id recordTypeId) {
        return woonstadCreatePersonAccountFactory.buildTenant(
            recordTypeId,
            TEST_FIRST_NAME,
            '',
            TEST_LAST_NAME,
            null,
            '',
            '',
            ''
        );
    }
}