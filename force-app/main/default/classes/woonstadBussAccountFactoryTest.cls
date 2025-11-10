/*************************************************************************************************
 * Class           : woonstadBussAccountFactoryTest
 * Layer           : Test / Unit Testing
 * Purpose         : Comprehensive test class for woonstadCreateBussAccountFactory
 *                   Targets 95-100% code coverage with complete branch and conditional testing
 *
 * Description     : This test class provides comprehensive coverage of the business account factory
 *                   by testing every conditional branch, string operation, and method variant.
 *                   The tests are designed to work with the actual factory implementation,
 *                   accounting for commented-out VAT field assignments and org-specific fields.
 *
 * AWAF Principles : Follows AWAF.dev testing guidelines:
 *                   - Each test method focuses on a single scenario or branch
 *                   - Tests are readable with clear documentation
 *                   - Comprehensive edge case coverage including all conditional branches
 *                   - Tests all String.isBlank() conditions and trim() operations
 *                   - Validates both method variants and their interactions
 *                   - Uses consistent test data patterns
 *                   - Handles org-specific field configurations gracefully
 *
 * Coverage Target : 95-100% code coverage for woonstadCreateBussAccountFactory
 *                   Tests every line, branch, and conditional statement
 *                   Validates all possible execution paths through both factory methods
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-09-04
 * Last Modified   : 2025-09-04
 * 
 * Changelog:
 * 2025-09-04 | DvM | Initial comprehensive test class creation
 *                   | Complete branch testing for all conditional logic
 *                   | Edge case coverage for string handling operations
 *                   | Org-agnostic testing that handles field availability
 *                   | Aligned with actual factory implementation
 *************************************************************************************************/

@IsTest
public with sharing class woonstadBussAccountFactoryTest {
    
    // ===== TEST DATA CONSTANTS =====
    // Following AWAF principle of readable, maintainable test data
    private static final String VALID_COMPANY_NAME = 'Test Corporation BV';
    private static final String VALID_KVK_NUMBER = '12345678';
    private static final String VALID_VAT_NUMBER = 'NL123456789B01';
    private static final String VALID_PHONE = '+31201234567';
    private static final String VALID_EMAIL = 'test@testcorp.nl';
    private static final String VALID_MOBILE = '+31612345678';
    private static final String VALID_ACCOUNT_TYPE = 'Customer - Direct';
    
    // Edge case test data for comprehensive branch testing
    private static final String WHITESPACE_ONLY = '   ';
    private static final String EMPTY_STRING = '';
    private static final String LEADING_WHITESPACE = '   ValidValue';
    private static final String TRAILING_WHITESPACE = 'ValidValue   ';
    private static final String BOTH_WHITESPACE = '   ValidValue   ';
    private static final String SINGLE_SPACE = ' ';
    private static final String TAB_WHITESPACE = '\t\t';
    private static final String MIXED_WHITESPACE = ' \t \n ';
    
    /**
     * Test Data Setup Method
     * Creates common test data used across multiple test methods
     * Following AWAF principle of DRY (Don't Repeat Yourself) in tests
     */
    @TestSetup
    static void setupTestData() {
        System.debug('Test setup completed for woonstadBussAccountFactoryTest');
    }
    
    /**
     * POSITIVE TEST: Complete Valid Data - Main Method
     * Tests the primary buildBusiness method with all valid parameters
     * Validates every field assignment that is active in the factory
     * 
     * This test ensures 100% coverage of the "happy path" through the main method
     * and validates all field mappings when valid data is provided
     */
    @IsTest
    static void testBuildBusinessMainMethodAllValidFields() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        
        // Act
        Test.startTest();
        Account result = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId,
            VALID_COMPANY_NAME,
            VALID_KVK_NUMBER,
            VALID_VAT_NUMBER,
            VALID_PHONE,
            VALID_EMAIL,
            VALID_MOBILE,
            VALID_ACCOUNT_TYPE
        );
        Test.stopTest();
        
        // Assert - Validate every field assignment that is active in factory
        System.assertNotEquals(null, result, 'Factory should return non-null Account');
        System.assertEquals(mockRecordTypeId, result.RecordTypeId, 'RecordTypeId should match input');
        System.assertEquals(VALID_COMPANY_NAME, result.Name, 'Name should match company name input');
        System.assertEquals(VALID_ACCOUNT_TYPE, result.Type, 'Type should match account type input');
        System.assertEquals(VALID_KVK_NUMBER, result.Chamber_Of_Commerce_Number__c, 'KVK should match input');
        System.assertEquals(VALID_PHONE, result.Phone, 'Phone should match input');
        System.assertEquals(VALID_EMAIL, result.Business_Email__c, 'Business email should match input');
        System.assertEquals(VALID_MOBILE, result.Mobile_Business_Phone__c, 'Mobile should match input');
    }
    
    /**
     * POSITIVE TEST: Overloaded Method Coverage
     * Tests the overloaded method without Account Type parameter
     * Validates that the method properly delegates to the main method with null Account Type
     * 
     * This test ensures the overloaded method path is covered and that method delegation works
     */
    @IsTest
    static void testBuildBusinessOverloadedMethodValidData() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        
        // Act
        Test.startTest();
        Account result = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId,
            VALID_COMPANY_NAME,
            VALID_KVK_NUMBER,
            VALID_VAT_NUMBER,
            VALID_PHONE,
            VALID_EMAIL,
            VALID_MOBILE
        );
        Test.stopTest();
        
        // Assert - Verify overloaded method works and Account Type is null
        System.assertNotEquals(null, result, 'Overloaded method should return non-null Account');
        System.assertEquals(VALID_COMPANY_NAME, result.Name, 'Company name should be mapped');
        System.assertEquals(null, result.Type, 'Account Type should be null in overloaded method');
        System.assertEquals(VALID_KVK_NUMBER, result.Chamber_Of_Commerce_Number__c, 'KVK should be mapped');
        System.assertEquals(VALID_PHONE, result.Phone, 'Phone should be mapped');
        System.assertEquals(VALID_EMAIL, result.Business_Email__c, 'Email should be mapped');
        System.assertEquals(VALID_MOBILE, result.Mobile_Business_Phone__c, 'Mobile should be mapped');
    }
    
    /**
     * BRANCH TEST: Account Type isBlank() Condition - Null Value
     * Tests the specific branch where accountType is null
     * Ensures the !String.isBlank(accountType) condition is properly tested for null input
     */
    @IsTest
    static void testAccountTypeConditionWithNullValue() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        
        // Act - Specifically test null Account Type branch
        Test.startTest();
        Account result = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId,
            VALID_COMPANY_NAME,
            VALID_KVK_NUMBER,
            VALID_VAT_NUMBER,
            VALID_PHONE,
            VALID_EMAIL,
            VALID_MOBILE,
            null  // Null account type to test isBlank condition
        );
        Test.stopTest();
        
        // Assert - Verify null account type results in null Type field
        System.assertEquals(null, result.Type, 'Null account type should result in null Type field');
    }
    
    /**
     * BRANCH TEST: Account Type isBlank() Condition - Empty String
     * Tests the specific branch where accountType is empty string
     * Ensures the !String.isBlank(accountType) condition handles empty strings correctly
     */
    @IsTest
    static void testAccountTypeConditionWithEmptyString() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        
        // Act - Test empty string Account Type
        Test.startTest();
        Account result = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId,
            VALID_COMPANY_NAME,
            VALID_KVK_NUMBER,
            VALID_VAT_NUMBER,
            VALID_PHONE,
            VALID_EMAIL,
            VALID_MOBILE,
            EMPTY_STRING  // Empty string to test isBlank condition
        );
        Test.stopTest();
        
        // Assert - Verify empty string results in null Type field
        System.assertEquals(null, result.Type, 'Empty string account type should result in null Type field');
    }
    
    /**
     * BRANCH TEST: Account Type isBlank() Condition - Whitespace Only
     * Tests the specific branch where accountType contains only whitespace
     * Validates String.isBlank() properly identifies whitespace-only strings
     */
    @IsTest
    static void testAccountTypeConditionWithWhitespaceOnly() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        
        // Act - Test whitespace-only Account Type
        Test.startTest();
        Account result = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId,
            VALID_COMPANY_NAME,
            VALID_KVK_NUMBER,
            VALID_VAT_NUMBER,
            VALID_PHONE,
            VALID_EMAIL,
            VALID_MOBILE,
            WHITESPACE_ONLY  // Whitespace-only string
        );
        Test.stopTest();
        
        // Assert - Verify whitespace-only string results in null Type field
        System.assertEquals(null, result.Type, 'Whitespace-only account type should result in null Type field');
    }
    
    /**
     * BRANCH TEST: Account Type Trim Operation
     * Tests the trim() operation on Account Type when value is not blank
     * Ensures the trim() method is properly applied to valid Account Type values
     */
    @IsTest
    static void testAccountTypeTrimOperation() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        String accountTypeWithSpaces = '  Customer - Direct  ';
        
        // Act - Test Account Type with leading/trailing spaces
        Test.startTest();
        Account result = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId,
            VALID_COMPANY_NAME,
            VALID_KVK_NUMBER,
            VALID_VAT_NUMBER,
            VALID_PHONE,
            VALID_EMAIL,
            VALID_MOBILE,
            accountTypeWithSpaces
        );
        Test.stopTest();
        
        // Assert - Verify trimming occurred
        System.assertEquals(accountTypeWithSpaces.trim(), result.Type, 'Account Type should be trimmed');
        System.assertEquals('Customer - Direct', result.Type, 'Trimmed value should match expected');
    }
    
    /**
     * BRANCH TEST: KVK Number isBlank() and Trim Branches
     * Tests all branches for KVK Number field: null, empty, whitespace, and valid values
     * Ensures complete coverage of the KVK field assignment logic
     */
    @IsTest
    static void testKvkNumberAllBranches() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        
        Test.startTest();
        // Test 1: Null KVK
        Account result1 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, null, VALID_VAT_NUMBER,
            VALID_PHONE, VALID_EMAIL, VALID_MOBILE, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(null, result1.Chamber_Of_Commerce_Number__c, 'Null KVK should result in null field');
        
        // Test 2: Empty string KVK
        Account result2 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, EMPTY_STRING, VALID_VAT_NUMBER,
            VALID_PHONE, VALID_EMAIL, VALID_MOBILE, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(null, result2.Chamber_Of_Commerce_Number__c, 'Empty KVK should result in null field');
        
        // Test 3: Whitespace-only KVK
        Account result3 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, WHITESPACE_ONLY, VALID_VAT_NUMBER,
            VALID_PHONE, VALID_EMAIL, VALID_MOBILE, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(null, result3.Chamber_Of_Commerce_Number__c, 'Whitespace-only KVK should result in null field');
        
        // Test 4: Valid KVK with spaces (trim test)
        String kvkWithSpaces = '  12345678  ';
        Account result4 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, kvkWithSpaces, VALID_VAT_NUMBER,
            VALID_PHONE, VALID_EMAIL, VALID_MOBILE, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(kvkWithSpaces.trim(), result4.Chamber_Of_Commerce_Number__c, 'KVK should be trimmed');
        Test.stopTest();
    }
    
    /**
     * BRANCH TEST: Phone Number isBlank() and Trim Branches
     * Tests all branches for Phone field assignment logic
     * Ensures complete coverage of phone number processing
     */
    @IsTest
    static void testPhoneNumberAllBranches() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        
        Test.startTest();
        // Test 1: Null Phone
        Account result1 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, VALID_KVK_NUMBER, VALID_VAT_NUMBER,
            null, VALID_EMAIL, VALID_MOBILE, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(null, result1.Phone, 'Null phone should result in null field');
        
        // Test 2: Empty Phone
        Account result2 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, VALID_KVK_NUMBER, VALID_VAT_NUMBER,
            EMPTY_STRING, VALID_EMAIL, VALID_MOBILE, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(null, result2.Phone, 'Empty phone should result in null field');
        
        // Test 3: Phone with spaces (trim test)
        String phoneWithSpaces = '  +31201234567  ';
        Account result3 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, VALID_KVK_NUMBER, VALID_VAT_NUMBER,
            phoneWithSpaces, VALID_EMAIL, VALID_MOBILE, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(phoneWithSpaces.trim(), result3.Phone, 'Phone should be trimmed');
        Test.stopTest();
    }
    
    /**
     * BRANCH TEST: Email isBlank() Condition and Field Assignment
     * Tests the email field conditional logic and assignment branches
     * Covers both the isBlank check and the field assignment when email is valid
     */
    @IsTest
    static void testEmailFieldAllBranches() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        
        Test.startTest();
        // Test 1: Null email (should not enter the if block)
        Account result1 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, VALID_KVK_NUMBER, VALID_VAT_NUMBER,
            VALID_PHONE, null, VALID_MOBILE, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(null, result1.Business_Email__c, 'Null email should result in null field');
        
        // Test 2: Empty email (should not enter the if block)
        Account result2 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, VALID_KVK_NUMBER, VALID_VAT_NUMBER,
            VALID_PHONE, EMPTY_STRING, VALID_MOBILE, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(null, result2.Business_Email__c, 'Empty email should result in null field');
        
        // Test 3: Valid email with spaces (should enter if block and trim)
        String emailWithSpaces = '  test@example.com  ';
        Account result3 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, VALID_KVK_NUMBER, VALID_VAT_NUMBER,
            VALID_PHONE, emailWithSpaces, VALID_MOBILE, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(emailWithSpaces.trim(), result3.Business_Email__c, 'Email should be trimmed and assigned');
        Test.stopTest();
    }
    
    /**
     * BRANCH TEST: Mobile isBlank() Condition and Field Assignment
     * Tests the mobile field conditional logic and assignment branches
     * Covers both the isBlank check and the field assignment when mobile is valid
     */
    @IsTest
    static void testMobileFieldAllBranches() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        
        Test.startTest();
        // Test 1: Null mobile (should not enter the if block)
        Account result1 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, VALID_KVK_NUMBER, VALID_VAT_NUMBER,
            VALID_PHONE, VALID_EMAIL, null, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(null, result1.Mobile_Business_Phone__c, 'Null mobile should result in null field');
        
        // Test 2: Empty mobile (should not enter the if block)
        Account result2 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, VALID_KVK_NUMBER, VALID_VAT_NUMBER,
            VALID_PHONE, VALID_EMAIL, EMPTY_STRING, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(null, result2.Mobile_Business_Phone__c, 'Empty mobile should result in null field');
        
        // Test 3: Valid mobile with spaces (should enter if block and trim)
        String mobileWithSpaces = '  +31612345678  ';
        Account result3 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, VALID_KVK_NUMBER, VALID_VAT_NUMBER,
            VALID_PHONE, VALID_EMAIL, mobileWithSpaces, VALID_ACCOUNT_TYPE
        );
        System.assertEquals(mobileWithSpaces.trim(), result3.Mobile_Business_Phone__c, 'Mobile should be trimmed and assigned');
        Test.stopTest();
    }
    
    /**
     * COMPREHENSIVE TEST: Various Whitespace Types
     * Tests different types of whitespace handling across all fields
     * Ensures String.isBlank() works correctly with various whitespace characters
     */
    @IsTest
    static void testVariousWhitespaceTypes() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        
        Test.startTest();
        // Test with tab characters
        Account result1 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, TAB_WHITESPACE, TAB_WHITESPACE,
            TAB_WHITESPACE, TAB_WHITESPACE, TAB_WHITESPACE, TAB_WHITESPACE
        );
        
        // Test with mixed whitespace characters
        Account result2 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, MIXED_WHITESPACE, MIXED_WHITESPACE,
            MIXED_WHITESPACE, MIXED_WHITESPACE, MIXED_WHITESPACE, MIXED_WHITESPACE
        );
        
        // Test with single space
        Account result3 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, SINGLE_SPACE, SINGLE_SPACE,
            SINGLE_SPACE, SINGLE_SPACE, SINGLE_SPACE, SINGLE_SPACE
        );
        Test.stopTest();
        
        // Assert - All whitespace-only values should result in null fields
        System.assertEquals(null, result1.Chamber_Of_Commerce_Number__c, 'Tab whitespace KVK should be null');
        System.assertEquals(null, result1.Phone, 'Tab whitespace phone should be null');
        System.assertEquals(null, result1.Business_Email__c, 'Tab whitespace email should be null');
        System.assertEquals(null, result1.Mobile_Business_Phone__c, 'Tab whitespace mobile should be null');
        System.assertEquals(null, result1.Type, 'Tab whitespace account type should be null');
        
        System.assertEquals(null, result2.Chamber_Of_Commerce_Number__c, 'Mixed whitespace KVK should be null');
        System.assertEquals(null, result3.Phone, 'Single space phone should be null');
    }
    
    /**
     * EDGE CASE TEST: Extreme String Values
     * Tests factory with extreme string values to ensure robustness
     * Validates factory handles edge cases without errors
     * Note: Only tests fields that are actually assigned by the factory
     */
    @IsTest
    static void testExtremeStringValues() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        String veryLongString = 'A'.repeat(255); // Very long string
        String specialCharacters = '!@#$%^&*()_+-=[]{}|;:,.<>?';
        String unicodeCharacters = 'αβγδε ñáéíóú 中文测试';
        
        Test.startTest();
        Account result = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId,
            veryLongString,
            specialCharacters,
            unicodeCharacters, // VAT parameter - not assigned due to commented code in factory
            veryLongString,
            'test@' + specialCharacters + '.com',
            veryLongString,
            'Customer-' + specialCharacters
        );
        Test.stopTest();
        
        // Assert - Test only fields that are actually assigned by the factory
        System.assertNotEquals(null, result, 'Factory should handle extreme string values');
        System.assertEquals(veryLongString, result.Name, 'Very long company name should be stored');
        System.assertEquals(specialCharacters, result.Chamber_Of_Commerce_Number__c, 'Special characters should be stored');
        System.assertEquals(veryLongString, result.Phone, 'Very long phone should be stored');
        System.assertEquals('test@' + specialCharacters + '.com', result.Business_Email__c, 'Special character email should be stored');
        System.assertEquals(veryLongString, result.Mobile_Business_Phone__c, 'Very long mobile should be stored');
        System.assertEquals('Customer-' + specialCharacters, result.Type, 'Special character account type should be stored');
        
        // Note: VAT_Number__c is commented out in factory, so we don't test it
    }
    
    /**
     * COMPREHENSIVE TEST: All Parameter Combinations
     * Tests various combinations of parameters to ensure all code paths are covered
     * This test helps achieve the final percentage points of coverage
     */
    @IsTest
    static void testAllParameterCombinations() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        
        Test.startTest();
        // Test combination 1: Some fields valid, some null
        Account result1 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, VALID_KVK_NUMBER, null,
            null, VALID_EMAIL, null, VALID_ACCOUNT_TYPE
        );
        
        // Test combination 2: Some fields empty, some with whitespace
        Account result2 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, EMPTY_STRING, WHITESPACE_ONLY,
            TRAILING_WHITESPACE, EMPTY_STRING, LEADING_WHITESPACE, null
        );
        
        // Test combination 3: All fields with different whitespace patterns
        Account result3 = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId, VALID_COMPANY_NAME, LEADING_WHITESPACE, TRAILING_WHITESPACE,
            BOTH_WHITESPACE, '  test@email.com  ', '  +31612345678  ', '  Partner  '
        );
        Test.stopTest();
        
        // Assert - Verify combinations work correctly
        System.assertNotEquals(null, result1, 'Mixed valid/null combination should work');
        System.assertNotEquals(null, result2, 'Mixed empty/whitespace combination should work');
        System.assertNotEquals(null, result3, 'All whitespace patterns should work');
        
        // Verify specific field behaviors in combinations
        System.assertEquals(VALID_KVK_NUMBER, result1.Chamber_Of_Commerce_Number__c, 'Valid KVK should be preserved in combination');
        System.assertEquals(null, result2.Chamber_Of_Commerce_Number__c, 'Empty KVK should be null in combination');
        System.assertEquals(LEADING_WHITESPACE.trim(), result3.Chamber_Of_Commerce_Number__c, 'Whitespace should be trimmed in combination');
    }
    
    /**
     * FINAL COVERAGE TEST: String Trimming Logic Validation
     * Tests the string trimming operations across all fields to ensure complete coverage
     * Validates that trim() is called on all non-blank values
     */
    @IsTest
    static void testStringTrimmingLogicComprehensive() {
        // Arrange
        Id mockRecordTypeId = getMockRecordTypeId();
        String leadingSpaces = '   ValidValue';
        String trailingSpaces = 'ValidValue   ';
        String bothSpaces = '   ValidValue   ';
        
        // Act
        Test.startTest();
        Account result = woonstadCreateBussAccountFactory.buildBusiness(
            mockRecordTypeId,
            'Test Company',
            leadingSpaces,     // KVK with leading spaces
            trailingSpaces,    // VAT with trailing spaces (not assigned)
            bothSpaces,        // Phone with both
            leadingSpaces,     // Email with leading spaces
            trailingSpaces,    // Mobile with trailing spaces
            bothSpaces         // Account Type with both
        );
        Test.stopTest();
        
        // Assert - Verify trimming behavior on all assigned fields
        System.assertEquals(leadingSpaces.trim(), result.Chamber_Of_Commerce_Number__c, 'Leading spaces should be trimmed from KVK');
        System.assertEquals(bothSpaces.trim(), result.Phone, 'Both leading and trailing spaces should be trimmed from Phone');
        System.assertEquals(leadingSpaces.trim(), result.Business_Email__c, 'Leading spaces should be trimmed from Email');
        System.assertEquals(trailingSpaces.trim(), result.Mobile_Business_Phone__c, 'Trailing spaces should be trimmed from Mobile');
        System.assertEquals(bothSpaces.trim(), result.Type, 'Both spaces should be trimmed from Account Type');
    }
    
    // ===== HELPER METHODS =====
    
    /**
     * Helper method to get a Record Type ID for testing
     * Provides consistent RecordType ID across all test methods
     * 
     * @return Id Valid Record Type ID for testing purposes
     * 
     * @description Returns an actual Account RecordType ID if available,
     *              otherwise creates a valid mock ID for testing purposes.
     *              This approach ensures tests work in any org configuration.
     */
    private static Id getMockRecordTypeId() {
        // Try to get actual Account RecordTypes
        List<RecordType> accountRecordTypes = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Account' 
            LIMIT 1
        ];
        
        if (!accountRecordTypes.isEmpty()) {
            return accountRecordTypes[0].Id;
        } else {
            // Create a valid mock RecordType ID using proper Salesforce ID format
            return Id.valueOf('012000000000000');
        }
    }
}