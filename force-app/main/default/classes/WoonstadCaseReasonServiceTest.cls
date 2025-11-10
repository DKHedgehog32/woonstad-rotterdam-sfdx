/*************************************************************************************************
 * Class            : WoonstadCaseReasonServiceTest
 * Layer            : Test
 * Purpose          : Validate normalization logic for Case_Reason__c picklist values
 *
 * Owner            : Woonstad
 * Author           : Test Implementation
 * Created          : 2025-11-06
 * Last Modified    : 2025-11-06
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-11-06 | Initial | Created comprehensive test class following AWAF.dev best practices
 *************************************************************************************************/
@IsTest
private class WoonstadCaseReasonServiceTest {
    
    /*********************************************************************************************
     * Test Method     : normalize_WithDutchLabel_ReturnsEnglishValue
     * Purpose         : Verify Dutch labels are correctly mapped to English API values
     * Code Coverage   : WoonstadCaseReasonService.normalize() - happy path
     *********************************************************************************************/
    @IsTest
    static void normalize_WithDutchLabel_ReturnsEnglishValue() {
        // ARRANGE - Set up test data with Dutch labels from the mapping
        String dutchLabel1 = 'Vernield / gestolen';
        String dutchLabel2 = 'Nieuwe woning';
        String dutchLabel3 = 'Veranderde Samenstelling';
        String dutchLabel4 = 'Verkeerde Spelling';
        
        // ACT - Call normalize method for each Dutch label
        Test.startTest();
        String result1 = WoonstadCaseReasonService.normalize(dutchLabel1);
        String result2 = WoonstadCaseReasonService.normalize(dutchLabel2);
        String result3 = WoonstadCaseReasonService.normalize(dutchLabel3);
        String result4 = WoonstadCaseReasonService.normalize(dutchLabel4);
        Test.stopTest();
        
        // ASSERT - Verify Dutch labels are converted to correct English values
        Assert.areEqual('Vandalism/stolen', result1, 
            'Expected Dutch label "Vernield / gestolen" to map to "Vandalism/stolen"');
        Assert.areEqual('New Tenant', result2, 
            'Expected Dutch label "Nieuwe woning" to map to "New Tenant"');
        Assert.areEqual('New composition of residency', result3, 
            'Expected Dutch label "Veranderde Samenstelling" to map to "New composition of residency"');
        Assert.areEqual('Incorrect name spelling', result4, 
            'Expected Dutch label "Verkeerde Spelling" to map to "Incorrect name spelling"');
    }
    
    /*********************************************************************************************
     * Test Method     : normalize_WithEnglishValue_ReturnsSameValue
     * Purpose         : Verify English API values pass through unchanged (LWC direct submission)
     * Code Coverage   : WoonstadCaseReasonService.normalize() - pass-through logic
     *********************************************************************************************/
    @IsTest
    static void normalize_WithEnglishValue_ReturnsSameValue() {
        // ARRANGE - Set up test data with English API values
        String englishValue1 = 'Vandalism/stolen';
        String englishValue2 = 'New Tenant';
        String unknownValue = 'Some Other Reason';
        
        // ACT - Call normalize method with English values
        Test.startTest();
        String result1 = WoonstadCaseReasonService.normalize(englishValue1);
        String result2 = WoonstadCaseReasonService.normalize(englishValue2);
        String result3 = WoonstadCaseReasonService.normalize(unknownValue);
        Test.stopTest();
        
        // ASSERT - Verify values pass through unchanged
        Assert.areEqual(englishValue1, result1, 
            'Expected English value to pass through unchanged');
        Assert.areEqual(englishValue2, result2, 
            'Expected English value to pass through unchanged');
        Assert.areEqual(unknownValue, result3, 
            'Expected unknown value to pass through unchanged for extensibility');
    }
    
    /*********************************************************************************************
     * Test Method     : normalize_WithNullOrBlank_ReturnsNull
     * Purpose         : Verify null and blank inputs are handled gracefully
     * Code Coverage   : WoonstadCaseReasonService.normalize() - edge cases
     *********************************************************************************************/
    @IsTest
    static void normalize_WithNullOrBlank_ReturnsNull() {
        // ARRANGE - Set up edge case inputs
        String nullValue = null;
        String emptyString = '';
        String whitespaceOnly = '   ';
        
        // ACT - Call normalize with edge case values
        Test.startTest();
        String result1 = WoonstadCaseReasonService.normalize(nullValue);
        String result2 = WoonstadCaseReasonService.normalize(emptyString);
        String result3 = WoonstadCaseReasonService.normalize(whitespaceOnly);
        Test.stopTest();
        
        // ASSERT - Verify null is returned for blank inputs (String.isBlank checks null, empty, whitespace)
        Assert.isNull(result1, 
            'Expected null input to return null');
        Assert.isNull(result2, 
            'Expected empty string to return null (handled by String.isBlank)');
        Assert.isNull(result3, 
            'Expected whitespace-only string to return null (handled by String.isBlank)');
    }
    
    /*********************************************************************************************
     * Test Method     : normalize_WithMixedCase_IsCaseSensitive
     * Purpose         : Verify the mapping is case-sensitive (important for data integrity)
     * Code Coverage   : WoonstadCaseReasonService.normalize() - case sensitivity validation
     *********************************************************************************************/
    @IsTest
    static void normalize_WithMixedCase_IsCaseSensitive() {
        // ARRANGE - Set up mixed-case variations
        String lowerCase = 'vernield / gestolen';  // Should NOT match
        String upperCase = 'VERNIELD / GESTOLEN';  // Should NOT match
        String correctCase = 'Vernield / gestolen'; // Should match
        
        // ACT - Test case sensitivity
        Test.startTest();
        String result1 = WoonstadCaseReasonService.normalize(lowerCase);
        String result2 = WoonstadCaseReasonService.normalize(upperCase);
        String result3 = WoonstadCaseReasonService.normalize(correctCase);
        Test.stopTest();
        
        // ASSERT - Verify case-sensitive behavior
        Assert.areEqual(lowerCase, result1, 
            'Expected lowercase variant to pass through unchanged (no match)');
        Assert.areEqual(upperCase, result2, 
            'Expected uppercase variant to pass through unchanged (no match)');
        Assert.areEqual('Vandalism/stolen', result3, 
            'Expected exact case match to be mapped correctly');
    }
}