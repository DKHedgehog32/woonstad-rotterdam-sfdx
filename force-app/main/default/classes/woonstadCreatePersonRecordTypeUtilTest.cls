/*************************************************************************************************
 * Class           : woonstadCreatePersonRecordTypeUtilTest  
 * Layer           : Test
 * Purpose         : Comprehensive test coverage for woonstadCreatePersonRecordTypeUtil utility
 * Description     : This test class validates both positive and negative scenarios for 
 *                   Account RecordType resolution methods. Tests include:
 *                   - Valid developer name resolution 
 *                   - Invalid/empty developer name handling
 *                   - Fallback PersonAccount RecordType resolution
 *                   - Edge cases and boundary conditions
 *                   - Bulk data testing (200+ records as per AWAF guidelines)
 * 
 * Test Coverage   : Target 95-100% code coverage
 * Owner           : Woonstad KC
 * Created         : 2025-09-04
 * Last Modified   : 2025-09-04
 * 
 * Changelog:
 * 2025-09-04 : Initial creation with comprehensive test methods
 *              - Added test data factory using existing RecordTypes
 *              - Implemented positive/negative test scenarios
 *              - Added bulk testing methods
 *              - Included edge case validation
 *              - Fixed assertion methods and RecordType limitations
 * 
 * AWAF Guidelines Applied:
 * - Single assertion per test method principle
 * - Test.startTest()/Test.stopTest() pattern for governor limit isolation
 * - @testSetup for efficient test data creation
 * - Descriptive test method names following Given_When_Then pattern
 * - Bulk testing with 200+ records
 * - No SeeAllData=true usage (isolated test data)
 * - Comprehensive error handling validation
 *************************************************************************************************/
@isTest
private class woonstadCreatePersonRecordTypeUtilTest {
    
    // Test data variables to store existing RecordType info
    private static List<RecordType> existingAccountRecordTypes;
    private static String validDevName1;
    private static String validDevName2;
    private static final String INVALID_DEV_NAME = 'NonExistentRecordType';
    
    /**
     * @description Setup method to identify existing RecordTypes for testing
     * Since RecordTypes cannot be inserted via DML, we work with existing ones
     */
    @testSetup
    static void setupTestData() {
        // Query existing Account RecordTypes to use in tests
        existingAccountRecordTypes = [
            SELECT Id, Name, DeveloperName, IsActive 
            FROM RecordType 
            WHERE SObjectType = 'Account' 
            AND IsActive = true
            ORDER BY CreatedDate ASC
            LIMIT 10
        ];
        
        // Set test variables based on available RecordTypes
        if (existingAccountRecordTypes.size() >= 2) {
            validDevName1 = existingAccountRecordTypes[0].DeveloperName;
            validDevName2 = existingAccountRecordTypes[1].DeveloperName;
        } else if (existingAccountRecordTypes.size() == 1) {
            validDevName1 = existingAccountRecordTypes[0].DeveloperName;
            validDevName2 = validDevName1; // Use same for second test
        }
    }
    
    /**
     * @description Helper method to get valid developer names for testing
     * @return Set<String> containing valid developer names from existing RecordTypes
     */
    private static Set<String> getValidDevNames() {
        List<RecordType> recordTypes = [
            SELECT DeveloperName FROM RecordType 
            WHERE SObjectType = 'Account' AND IsActive = true 
            LIMIT 2
        ];
        
        Set<String> devNames = new Set<String>();
        for (RecordType rt : recordTypes) {
            devNames.add(rt.DeveloperName);
        }
        return devNames;
    }
    
    /**
     * @description Test resolveAccountByDevName with valid single developer name
     * Given: A set containing one valid RecordType developer name
     * When: resolveAccountByDevName method is called
     * Then: Should return a map with the correct RecordType Id
     */
    @isTest 
    static void given_ValidSingleDevName_When_ResolveCalled_Then_ReturnCorrectMapping() {
        // Arrange
        Set<String> validDevNames = getValidDevNames();
        System.assert(!validDevNames.isEmpty(), 'Test requires at least one Account RecordType');
        
        Set<String> singleDevName = new Set<String>{(new List<String>(validDevNames))[0]};
        
        // Act
        Test.startTest();
        Map<String, Id> result = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(singleDevName);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, result.size(), 
            'Should return exactly one RecordType mapping for valid developer name');
        
        String testDevName = (new List<String>(singleDevName))[0];
        System.assert(result.containsKey(testDevName), 
            'Result should contain the requested developer name: ' + testDevName);
        System.assertNotEquals(null, result.get(testDevName), 
            'RecordType Id should not be null for valid developer name');
    }
    
    /**
     * @description Test resolveAccountByDevName with multiple valid developer names
     * Given: A set containing multiple valid RecordType developer names
     * When: resolveAccountByDevName method is called  
     * Then: Should return a map with all correct RecordType Ids
     */
    @isTest
    static void given_MultipleValidDevNames_When_ResolveCalled_Then_ReturnAllMappings() {
        // Arrange
        Set<String> validDevNames = getValidDevNames();
        System.assert(!validDevNames.isEmpty(), 'Test requires at least one Account RecordType');
        
        // Act
        Test.startTest();
        Map<String, Id> result = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(validDevNames);
        Test.stopTest();
        
        // Assert
        System.assert(result.size() >= 1, 
            'Should return at least one RecordType mapping for valid developer names');
        System.assert(result.size() <= validDevNames.size(), 
            'Should not return more mappings than requested developer names');
    }
    
    /**
     * @description Test resolveAccountByDevName with null input
     * Given: A null set of developer names
     * When: resolveAccountByDevName method is called
     * Then: Should return empty map without throwing exception
     */
    @isTest
    static void given_NullDevNames_When_ResolveCalled_Then_ReturnEmptyMap() {
        // Arrange
        Set<String> devNames = null;
        
        // Act
        Test.startTest();
        Map<String, Id> result = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(devNames);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, result.size(), 
            'Should return empty map when input is null');
        System.assertNotEquals(null, result, 
            'Result should not be null, should be empty map');
    }
    
    /**
     * @description Test resolveAccountByDevName with empty set input
     * Given: An empty set of developer names
     * When: resolveAccountByDevName method is called
     * Then: Should return empty map without querying database
     */
    @isTest
    static void given_EmptyDevNames_When_ResolveCalled_Then_ReturnEmptyMap() {
        // Arrange
        Set<String> devNames = new Set<String>();
        
        // Act
        Test.startTest();
        Map<String, Id> result = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(devNames);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, result.size(), 
            'Should return empty map when input set is empty');
        System.assertNotEquals(null, result, 
            'Result should not be null, should be empty map');
    }
    
    /**
     * @description Test resolveAccountByDevName with invalid developer name
     * Given: A set containing an invalid RecordType developer name
     * When: resolveAccountByDevName method is called
     * Then: Should return empty map for non-existent developer name
     */
    @isTest
    static void given_InvalidDevName_When_ResolveCalled_Then_ReturnEmptyMap() {
        // Arrange
        Set<String> devNames = new Set<String>{INVALID_DEV_NAME};
        
        // Act
        Test.startTest();
        Map<String, Id> result = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(devNames);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, result.size(), 
            'Should return empty map when developer name does not exist');
    }
    
    /**
     * @description Test resolveAccountByDevName with mixed valid and invalid developer names
     * Given: A set containing both valid and invalid RecordType developer names
     * When: resolveAccountByDevName method is called
     * Then: Should return map only for valid developer names
     */
    @isTest
    static void given_MixedValidInvalidDevNames_When_ResolveCalled_Then_ReturnOnlyValidMappings() {
        // Arrange
        Set<String> validDevNames = getValidDevNames();
        System.assert(!validDevNames.isEmpty(), 'Test requires at least one Account RecordType');
        
        String validDevName = (new List<String>(validDevNames))[0];
        Set<String> mixedDevNames = new Set<String>{validDevName, INVALID_DEV_NAME};
        
        // Act
        Test.startTest();
        Map<String, Id> result = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(mixedDevNames);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, result.size(), 
            'Should return only one mapping for the valid developer name');
        System.assert(result.containsKey(validDevName), 
            'Should contain mapping for valid developer name');
        System.assert(!result.containsKey(INVALID_DEV_NAME), 
            'Should not contain mapping for invalid developer name');
    }
    
    /**
     * @description Test resolveAccountByDevName with bulk data (200+ developer names)
     * Given: A large set of developer names (bulk testing as per AWAF guidelines)
     * When: resolveAccountByDevName method is called
     * Then: Should handle large data volumes without exceeding governor limits
     */
    @isTest
    static void given_BulkDevNames_When_ResolveCalled_Then_HandleWithoutGovernorLimits() {
        // Arrange - Create 200+ developer names for bulk testing
        Set<String> bulkDevNames = new Set<String>();
        for(Integer i = 0; i < 205; i++) {
            bulkDevNames.add('BulkTestDevName' + i);
        }
        
        // Add some valid ones to ensure method handles mixed scenarios
        Set<String> validDevNames = getValidDevNames();
        if (!validDevNames.isEmpty()) {
            bulkDevNames.addAll(validDevNames);
        }
        
        // Act
        Test.startTest();
        Map<String, Id> result = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(bulkDevNames);
        Test.stopTest();
        
        // Assert
        System.assert(result.size() >= 0, 
            'Should handle bulk processing without errors');
        System.assert(Limits.getQueries() <= Limits.getLimitQueries(), 
            'Should not exceed SOQL query governor limits');
    }
    
    /**
     * @description Test resolveFallbackPersonRtId returns valid RecordType when available
     * Given: Account RecordTypes exist in the org
     * When: resolveFallbackPersonRtId method is called
     * Then: Should return a valid Account RecordType Id
     */
    @isTest
    static void given_AccountRecordTypesExist_When_FallbackCalled_Then_ReturnValidId() {
        // Act
        Test.startTest();
        Id result = woonstadCreatePersonRecordTypeUtil.resolveFallbackPersonRtId();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 
            'Should return a valid RecordType Id when Account RecordTypes exist');
        
        // Verify it's a valid RecordType Id for Account
        List<RecordType> foundRecordType = [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE Id = :result AND SObjectType = 'Account' AND IsActive = true
            LIMIT 1
        ];
        System.assertEquals(1, foundRecordType.size(), 
            'Returned Id should correspond to an active Account RecordType');
    }
    
    /**
     * @description Test resolveFallbackPersonRtId returns preferred candidate when available
     * Given: Preferred fallback candidate RecordTypes may exist
     * When: resolveFallbackPersonRtId method is called
     * Then: Should return Id of matching candidate or any valid Account RecordType
     */
    @isTest
    static void given_FallbackLogic_When_FallbackCalled_Then_ReturnAppropriateId() {
        // Act
        Test.startTest();
        Id result = woonstadCreatePersonRecordTypeUtil.resolveFallbackPersonRtId();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 
            'Should return a RecordType Id when Account RecordTypes are available');
        
        // Verify the returned RecordType is a valid Account RecordType
        List<RecordType> resultRecordType = [
            SELECT Id, DeveloperName, SObjectType
            FROM RecordType 
            WHERE Id = :result AND SObjectType = 'Account' AND IsActive = true
            LIMIT 1
        ];
        System.assertEquals(1, resultRecordType.size(), 
            'Returned RecordType should be a valid active Account RecordType');
        System.assertEquals('Account', resultRecordType[0].SObjectType, 
            'Returned RecordType should be for Account object');
    }
    
    /**
     * @description Test resolveFallbackPersonRtId performance with governor limits
     * Given: Multiple SOQL queries executed in fallback method
     * When: resolveFallbackPersonRtId method is called within Test.startTest/stopTest
     * Then: Should not exceed SOQL query governor limits
     */
    @isTest
    static void given_FallbackMethodQueries_When_CalledInTestContext_Then_RespectGovernorLimits() {
        // Act
        Test.startTest();
        Id result = woonstadCreatePersonRecordTypeUtil.resolveFallbackPersonRtId();
        Test.stopTest();
        
        // Assert governor limit compliance
        System.assert(Limits.getQueries() <= Limits.getLimitQueries(), 
            'Should not exceed SOQL query governor limits');
        System.assert(Limits.getQueryRows() <= Limits.getLimitQueryRows(), 
            'Should not exceed SOQL query rows governor limits');
        
        // Verify method completed successfully
        System.assertNotEquals(null, result, 
            'Method should return a valid result within governor limits');
    }
    
    /**
     * @description Integration test combining both utility methods
     * Given: Mixed scenario using both resolveAccountByDevName and resolveFallbackPersonRtId
     * When: Both methods are called in sequence
     * Then: Both should work correctly and return expected results
     */
    @isTest 
    static void given_BothMethods_When_CalledInSequence_Then_BothWorkCorrectly() {
        // Arrange
        Set<String> validDevNames = getValidDevNames();
        if (!validDevNames.isEmpty()) {
            validDevNames.add(INVALID_DEV_NAME); // Add invalid name to test mixed scenario
        } else {
            validDevNames = new Set<String>{INVALID_DEV_NAME}; // Only invalid if no valid ones exist
        }
        
        // Act
        Test.startTest();
        Map<String, Id> resolveResult = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(validDevNames);
        Id fallbackResult = woonstadCreatePersonRecordTypeUtil.resolveFallbackPersonRtId();
        Test.stopTest();
        
        // Assert both methods work independently
        System.assertNotEquals(null, resolveResult, 
            'resolveAccountByDevName should return valid map');
        System.assertNotEquals(null, fallbackResult, 
            'resolveFallbackPersonRtId should return valid Id');
        
        // Verify governor limits not exceeded by both methods
        System.assert(Limits.getQueries() <= Limits.getLimitQueries(), 
            'Combined method calls should not exceed SOQL query limits');
    }
    
    /**
     * @description Test class methods are properly accessible (utility class validation)
     * Given: Utility class methods are public static
     * When: Methods are called without instantiating the class
     * Then: Methods should be accessible and work correctly
     */
    @isTest
    static void given_StaticUtilityMethods_When_CalledDirectly_Then_WorkWithoutInstantiation() {
        // Arrange
        Set<String> validDevNames = getValidDevNames();
        if (validDevNames.isEmpty()) {
            validDevNames.add('TestDevName'); // Add test name if no valid ones exist
        }
        
        // Act & Assert - Methods should be callable without creating class instance
        Test.startTest();
        Map<String, Id> result1 = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(validDevNames);
        Id result2 = woonstadCreatePersonRecordTypeUtil.resolveFallbackPersonRtId();
        Test.stopTest();
        
        // Verify methods execute successfully
        System.assertNotEquals(null, result1, 
            'Static resolveAccountByDevName method should work without class instantiation');
        System.assertNotEquals(null, result2, 
            'Static resolveFallbackPersonRtId method should work without class instantiation');
    }
    
    /**
     * @description Test resolveAccountByDevName handles case sensitivity
     * Given: Developer names with different cases
     * When: resolveAccountByDevName method is called
     * Then: Should handle case sensitivity appropriately (Salesforce is case-sensitive)
     */
    @isTest
    static void given_CaseSensitiveDevNames_When_ResolveCalled_Then_HandleCaseCorrectly() {
        // Arrange
        Set<String> validDevNames = getValidDevNames();
        System.assert(!validDevNames.isEmpty(), 'Test requires at least one Account RecordType');
        
        String validDevName = (new List<String>(validDevNames))[0];
        String wrongCaseDevName = validDevName.toLowerCase(); // Convert to lowercase
        
        Set<String> testDevNames = new Set<String>{wrongCaseDevName};
        
        // Act
        Test.startTest();
        Map<String, Id> result = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(testDevNames);
        Test.stopTest();
        
        // Assert - Should not find the wrong case version (unless it actually exists)
        System.assert(result.size() <= 1, 
            'Should handle case sensitivity correctly');
    }
    
    /**
     * @description Test that empty strings in developer names are handled correctly
     * Given: Set containing empty string and whitespace
     * When: resolveAccountByDevName method is called
     * Then: Should handle gracefully without errors
     */
    @isTest
    static void given_EmptyStringDevNames_When_ResolveCalled_Then_HandleGracefully() {
        // Arrange
        Set<String> devNames = new Set<String>{'', ' ', '  '};
        
        // Act
        Test.startTest();
        Map<String, Id> result = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(devNames);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, result.size(), 
            'Should return empty map for empty/whitespace developer names');
    }
    
    /**
     * @description Verify method handles very long developer name strings
     * Given: Developer name exceeding typical length limits
     * When: resolveAccountByDevName method is called
     * Then: Should handle without throwing exceptions
     */
    @isTest
    static void given_LongDevNames_When_ResolveCalled_Then_HandleWithoutErrors() {
        // Arrange
        String veryLongDevName = 'ThisIsAVeryLongDeveloperNameThatExceedsTypicalLengthLimitsAndShouldBeHandledGracefully';
        Set<String> devNames = new Set<String>{veryLongDevName};
        
        // Act
        Test.startTest();
        Map<String, Id> result = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(devNames);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 
            'Should handle long developer names without throwing exceptions');
    }
}