/*************************************************************************************************
 * Class            : WoonstadStringUtilTest
 * Layer            : Test
 * Purpose          : Test class for WoonstadStringUtil - validates string concatenation utility
 *                    methods with positive, negative, and edge case scenarios.
 * Description      : This test class provides comprehensive coverage for the WoonstadStringUtil
 *                    class by testing all possible input combinations including valid names,
 *                    null values, empty strings, and whitespace handling. The tests ensure
 *                    the concatName method properly concatenates first and last names while
 *                    handling edge cases appropriately.
 * 
 * Test Coverage    : - WoonstadStringUtil.concatName() - 100%
 * 
 * Best Practices   : Following AWAF.dev and Salesforce best practices:
 *                    - @isTest annotation to exclude from code size limits
 *                    - seeAllData=false to ensure test isolation
 *                    - Descriptive test method names indicating what is being tested
 *                    - System.assert methods to validate expected outcomes
 *                    - Tests cover positive, negative, and edge cases
 *                    - No hardcoded data dependencies
 *                    - Single assertion focus per test method for clarity
 * 
 * Changelog:
 * Version  Date            Author          Description
 * -------  ----------      -------------   --------------------------------------------------
 * 1.0      2025-11-06      [Your Name]     Initial version - comprehensive test coverage for
 *                                          WoonstadStringUtil.concatName() method
 *************************************************************************************************/
@isTest(seeAllData=false)
private class WoonstadStringUtilTest {
    
    /*************************************************************************************************
     * Test Method: testConcatName_BothNamesProvided
     * Purpose: Verify that when both first and last names are provided, they are concatenated
     *          correctly with a single space between them
     * Expected: Returns 'John Doe' when first='John' and last='Doe'
     *************************************************************************************************/
    @isTest
    static void testConcatName_BothNamesProvided() {
        // Arrange - Set up test data with valid first and last names
        String firstName = 'John';
        String lastName = 'Doe';
        
        // Act - Call the method under test
        Test.startTest();
        String result = WoonstadStringUtil.concatName(firstName, lastName);
        Test.stopTest();
        
        // Assert - Verify the names are concatenated correctly
        System.assertEquals('John Doe', result, 
            'Expected full name to be "John Doe" when both first and last names are provided');
        System.assert(result.contains(' '), 
            'Result should contain a space between first and last name');
    }
    
    /*************************************************************************************************
     * Test Method: testConcatName_OnlyFirstNameProvided
     * Purpose: Verify that when only a first name is provided (last name is null), the method
     *          returns just the first name without extra spaces
     * Expected: Returns 'Jane' when first='Jane' and last=null
     *************************************************************************************************/
    @isTest
    static void testConcatName_OnlyFirstNameProvided() {
        // Arrange - Set up test data with only first name
        String firstName = 'Jane';
        String lastName = null;
        
        // Act - Call the method under test
        Test.startTest();
        String result = WoonstadStringUtil.concatName(firstName, lastName);
        Test.stopTest();
        
        // Assert - Verify only the first name is returned, properly trimmed
        System.assertEquals('Jane', result, 
            'Expected result to be "Jane" when only first name is provided');
        System.assertEquals(firstName, result, 
            'Result should match the provided first name exactly');
    }
    
    /*************************************************************************************************
     * Test Method: testConcatName_OnlyLastNameProvided
     * Purpose: Verify that when only a last name is provided (first name is null), the method
     *          returns just the last name without extra spaces
     * Expected: Returns 'Smith' when first=null and last='Smith'
     *************************************************************************************************/
    @isTest
    static void testConcatName_OnlyLastNameProvided() {
        // Arrange - Set up test data with only last name
        String firstName = null;
        String lastName = 'Smith';
        
        // Act - Call the method under test
        Test.startTest();
        String result = WoonstadStringUtil.concatName(firstName, lastName);
        Test.stopTest();
        
        // Assert - Verify only the last name is returned, properly trimmed
        System.assertEquals('Smith', result, 
            'Expected result to be "Smith" when only last name is provided');
        System.assertEquals(lastName, result, 
            'Result should match the provided last name exactly');
    }
    
    /*************************************************************************************************
     * Test Method: testConcatName_BothNamesNull
     * Purpose: Verify that when both names are null, the method returns an empty string
     * Expected: Returns '' (empty string) when both first and last are null
     *************************************************************************************************/
    @isTest
    static void testConcatName_BothNamesNull() {
        // Arrange - Set up test data with both names as null
        String firstName = null;
        String lastName = null;
        
        // Act - Call the method under test
        Test.startTest();
        String result = WoonstadStringUtil.concatName(firstName, lastName);
        Test.stopTest();
        
        // Assert - Verify an empty string is returned
        System.assertEquals('', result, 
            'Expected empty string when both first and last names are null');
        System.assert(String.isBlank(result), 
            'Result should be blank when both inputs are null');
    }
    
    /*************************************************************************************************
     * Test Method: testConcatName_BothNamesEmpty
     * Purpose: Verify that when both names are empty strings, the method returns an empty string
     * Expected: Returns '' (empty string) when first='' and last=''
     *************************************************************************************************/
    @isTest
    static void testConcatName_BothNamesEmpty() {
        // Arrange - Set up test data with empty strings
        String firstName = '';
        String lastName = '';
        
        // Act - Call the method under test
        Test.startTest();
        String result = WoonstadStringUtil.concatName(firstName, lastName);
        Test.stopTest();
        
        // Assert - Verify an empty string is returned
        System.assertEquals('', result, 
            'Expected empty string when both first and last names are empty strings');
    }
    
    /*************************************************************************************************
     * Test Method: testConcatName_NamesWithLeadingAndTrailingSpaces
     * Purpose: Verify that the method properly trims leading and trailing whitespace from both
     *          names before concatenation
     * Expected: Returns 'Alice Johnson' when first='  Alice  ' and last='  Johnson  '
     *************************************************************************************************/
    @isTest
    static void testConcatName_NamesWithLeadingAndTrailingSpaces() {
        // Arrange - Set up test data with excessive whitespace
        String firstName = '  Alice  ';
        String lastName = '  Johnson  ';
        
        // Act - Call the method under test
        Test.startTest();
        String result = WoonstadStringUtil.concatName(firstName, lastName);
        Test.stopTest();
        
        // Assert - Verify names are trimmed and concatenated properly
        System.assertEquals('Alice Johnson', result, 
            'Expected "Alice Johnson" with proper trimming of whitespace');
        System.assert(!result.startsWith(' ') && !result.endsWith(' '), 
            'Result should not have leading or trailing spaces');
    }
    
    /*************************************************************************************************
     * Test Method: testConcatName_FirstNameEmptyLastNameProvided
     * Purpose: Verify behavior when first name is empty string but last name has value
     * Expected: Returns 'Brown' when first='' and last='Brown'
     *************************************************************************************************/
    @isTest
    static void testConcatName_FirstNameEmptyLastNameProvided() {
        // Arrange - Set up test data with empty first name
        String firstName = '';
        String lastName = 'Brown';
        
        // Act - Call the method under test
        Test.startTest();
        String result = WoonstadStringUtil.concatName(firstName, lastName);
        Test.stopTest();
        
        // Assert - Verify only the last name is returned
        System.assertEquals('Brown', result, 
            'Expected "Brown" when first name is empty and last name is provided');
    }
    
    /*************************************************************************************************
     * Test Method: testConcatName_FirstNameProvidedLastNameEmpty
     * Purpose: Verify behavior when first name has value but last name is empty string
     * Expected: Returns 'Michael' when first='Michael' and last=''
     *************************************************************************************************/
    @isTest
    static void testConcatName_FirstNameProvidedLastNameEmpty() {
        // Arrange - Set up test data with empty last name
        String firstName = 'Michael';
        String lastName = '';
        
        // Act - Call the method under test
        Test.startTest();
        String result = WoonstadStringUtil.concatName(firstName, lastName);
        Test.stopTest();
        
        // Assert - Verify only the first name is returned
        System.assertEquals('Michael', result, 
            'Expected "Michael" when first name is provided and last name is empty');
    }
    
    /*************************************************************************************************
     * Test Method: testConcatName_OnlySpacesInBothNames
     * Purpose: Verify that names consisting only of spaces are treated as blank
     * Expected: Returns '' (empty string) when first='   ' and last='   '
     *************************************************************************************************/
    @isTest
    static void testConcatName_OnlySpacesInBothNames() {
        // Arrange - Set up test data with only spaces
        String firstName = '   ';
        String lastName = '   ';
        
        // Act - Call the method under test
        Test.startTest();
        String result = WoonstadStringUtil.concatName(firstName, lastName);
        Test.stopTest();
        
        // Assert - Verify an empty string is returned since spaces are trimmed
        System.assertEquals('', result, 
            'Expected empty string when both names contain only spaces');
        System.assert(String.isBlank(result), 
            'Result should be blank when names are only whitespace');
    }
    
    /*************************************************************************************************
     * Test Method: testConcatName_SpecialCharactersInNames
     * Purpose: Verify that the method handles special characters in names correctly
     * Expected: Returns 'Jean-Paul O\'Brien' when first='Jean-Paul' and last='O\'Brien'
     *************************************************************************************************/
    @isTest
    static void testConcatName_SpecialCharactersInNames() {
        // Arrange - Set up test data with hyphens and apostrophes
        String firstName = 'Jean-Paul';
        String lastName = 'O\'Brien';
        
        // Act - Call the method under test
        Test.startTest();
        String result = WoonstadStringUtil.concatName(firstName, lastName);
        Test.stopTest();
        
        // Assert - Verify special characters are preserved
        System.assertEquals('Jean-Paul O\'Brien', result, 
            'Expected special characters like hyphens and apostrophes to be preserved');
        System.assert(result.contains('-'), 
            'Hyphen should be preserved in the result');
        System.assert(result.contains('\''), 
            'Apostrophe should be preserved in the result');
    }
}