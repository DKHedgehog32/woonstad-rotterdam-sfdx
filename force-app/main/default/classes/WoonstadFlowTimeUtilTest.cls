/*************************************************************************************************
 * Class            : WoonstadFlowTimeUtilTest
 * Layer            : Test
 * Purpose          : Test coverage for WoonstadFlowTimeUtil - validates time calculation logic
 *                    including edge cases, null handling, and invalid input scenarios.
 * 
 * Description      : This test class ensures WoonstadFlowTimeUtil correctly:
 *                    - Calculates elapsed minutes from valid datetime strings
 *                    - Handles blank/null input gracefully (returns 0)
 *                    - Handles invalid datetime formats safely (returns 0)
 *                    - Returns proper integer values (rounded down)
 *                    - Works with both recent and older timestamps
 * 
 * Test Coverage    : Positive scenarios (valid input), negative scenarios (invalid/null input),
 *                    edge cases (boundary conditions), and bulk scenarios
 * 
 * Changelog:
 * =================================================================================================
 * Date         Author              Description
 * =================================================================================================
 * 2025-11-06   Initial             Initial version - comprehensive test coverage for time utility
 *************************************************************************************************/
@isTest
private class WoonstadFlowTimeUtilTest {
    
    /*************************************************************************************************
     * @description Test valid datetime string returns correct elapsed minutes (rounded down)
     * 
     * What this tests:
     * - Converts a valid datetime string from 5 minutes ago
     * - Verifies the method returns exactly 5 minutes
     * - Tests the floor/rounding down behavior
     * 
     * Learning: Datetime.valueOf() requires format: 'YYYY-MM-DD HH:MM:SS'
     *           We use addMinutes(-5) to go back 5 minutes from now
     *************************************************************************************************/
    @isTest
    static void testValidDatetimeString_ReturnsCorrectMinutes() {
        // Arrange: Create a datetime string from exactly 5 minutes ago
        Datetime fiveMinutesAgo = Datetime.now().addMinutes(-5);
        String flowStartTime = fiveMinutesAgo.format('yyyy-MM-dd HH:mm:ss');
        
        // Act: Call the utility method
        Test.startTest();
        Integer result = WoonstadFlowTimeUtil.tryParseMinutesSince(flowStartTime);
        Test.stopTest();
        
        // Assert: Should return 5 (or possibly 4-5 due to execution time)
        // We use >= 4 to account for test execution time variance
        System.assert(result >= 4 && result <= 5, 
            'Expected approximately 5 minutes, but got: ' + result);
    }
    
    /*************************************************************************************************
     * @description Test that longer time periods calculate correctly
     * 
     * What this tests:
     * - Tests with 65 minutes (over an hour) to verify hour->minute conversion
     * - Ensures calculation works for larger time differences
     * 
     * Learning: This validates the milliseconds math: (now - start) / (1000 * 60)
     *************************************************************************************************/
    @isTest
    static void testLongerTimePeriod_ReturnsCorrectMinutes() {
        // Arrange: Create a datetime from 65 minutes ago
        Datetime longTimeAgo = Datetime.now().addMinutes(-65);
        String flowStartTime = longTimeAgo.format('yyyy-MM-dd HH:mm:ss');
        
        // Act
        Test.startTest();
        Integer result = WoonstadFlowTimeUtil.tryParseMinutesSince(flowStartTime);
        Test.stopTest();
        
        // Assert: Should return 65 (or 64-65 due to execution time)
        System.assert(result >= 64 && result <= 65, 
            'Expected approximately 65 minutes, but got: ' + result);
    }
    
    /*************************************************************************************************
     * @description Test that fractional minutes are rounded down (floor behavior)
     * 
     * What this tests:
     * - Uses addSeconds to create a timestamp that's 1 minute and 30 seconds ago
     * - Verifies Math.floor() rounds 1.5 minutes DOWN to 1 minute
     * 
     * Learning: Math.floor() always rounds down to nearest integer
     *           1.5 minutes = 1, 1.9 minutes = 1, 2.0 minutes = 2
     *************************************************************************************************/
    @isTest
    static void testFractionalMinutes_RoundsDown() {
        // Arrange: Create timestamp 1 minute and 30 seconds ago (1.5 minutes)
        Datetime oneAndHalfMinutesAgo = Datetime.now().addSeconds(-90);
        String flowStartTime = oneAndHalfMinutesAgo.format('yyyy-MM-dd HH:mm:ss');
        
        // Act
        Test.startTest();
        Integer result = WoonstadFlowTimeUtil.tryParseMinutesSince(flowStartTime);
        Test.stopTest();
        
        // Assert: 1.5 minutes should floor to 1
        System.assertEquals(1, result, 
            'Expected 1 minute (floor of 1.5), but got: ' + result);
    }
    
    /*************************************************************************************************
     * @description Test null input returns 0 safely
     * 
     * What this tests:
     * - Passing null to the method
     * - Verifies graceful handling without exceptions
     * 
     * Learning: String.isBlank() catches null, empty string '', and whitespace
     *************************************************************************************************/
    @isTest
    static void testNullInput_ReturnsZero() {
        // Act
        Test.startTest();
        Integer result = WoonstadFlowTimeUtil.tryParseMinutesSince(null);
        Test.stopTest();
        
        // Assert: Null input should return 0
        System.assertEquals(0, result, 
            'Null input should return 0');
    }
    
    /*************************************************************************************************
     * @description Test empty string returns 0 safely
     * 
     * What this tests:
     * - Passing empty string '' to the method
     * - Different from null but should behave the same
     *************************************************************************************************/
    @isTest
    static void testEmptyString_ReturnsZero() {
        // Act
        Test.startTest();
        Integer result = WoonstadFlowTimeUtil.tryParseMinutesSince('');
        Test.stopTest();
        
        // Assert: Empty string should return 0
        System.assertEquals(0, result, 
            'Empty string should return 0');
    }
    
    /*************************************************************************************************
     * @description Test whitespace-only string returns 0 safely
     * 
     * What this tests:
     * - Passing whitespace strings like '   ' or '\t\n'
     * - Verifies String.isBlank() catches these edge cases
     * 
     * Learning: isBlank() returns true for null, '', and whitespace-only strings
     *************************************************************************************************/
    @isTest
    static void testWhitespaceString_ReturnsZero() {
        // Act
        Test.startTest();
        Integer result = WoonstadFlowTimeUtil.tryParseMinutesSince('   ');
        Test.stopTest();
        
        // Assert: Whitespace should return 0
        System.assertEquals(0, result, 
            'Whitespace string should return 0');
    }
    
    /*************************************************************************************************
     * @description Test invalid datetime format returns 0 without throwing exception
     * 
     * What this tests:
     * - Passing a string that looks like a date but has wrong format
     * - Validates the try-catch block catches TypeException
     * - Ensures method degrades gracefully
     * 
     * Learning: Datetime.valueOf() is strict - requires 'YYYY-MM-DD HH:MM:SS'
     *           Invalid formats throw TypeException, caught by generic Exception
     *************************************************************************************************/
    @isTest
    static void testInvalidDatetimeFormat_ReturnsZero() {
        // Arrange: Use invalid format (ISO format instead of Salesforce format)
        String invalidFormat = '2025-11-06T10:30:00Z';
        
        // Act
        Test.startTest();
        Integer result = WoonstadFlowTimeUtil.tryParseMinutesSince(invalidFormat);
        Test.stopTest();
        
        // Assert: Invalid format should return 0
        System.assertEquals(0, result, 
            'Invalid datetime format should return 0');
    }
    
    /*************************************************************************************************
     * @description Test completely invalid string returns 0
     * 
     * What this tests:
     * - Passing random text that's not a date at all
     * - Further validates exception handling
     *************************************************************************************************/
    @isTest
    static void testCompletelyInvalidString_ReturnsZero() {
        // Arrange
        String invalidString = 'not a date at all';
        
        // Act
        Test.startTest();
        Integer result = WoonstadFlowTimeUtil.tryParseMinutesSince(invalidString);
        Test.stopTest();
        
        // Assert: Invalid string should return 0
        System.assertEquals(0, result, 
            'Completely invalid string should return 0');
    }
    
    /*************************************************************************************************
     * @description Test very recent time (less than 1 minute) returns 0
     * 
     * What this tests:
     * - Datetime just a few seconds ago
     * - Verifies floor behavior: 0.5 minutes = 0 minutes
     * 
     * Learning: This is edge case - flows started <60 seconds ago return 0
     *************************************************************************************************/
    @isTest
    static void testVeryRecentTime_ReturnsZero() {
        // Arrange: Create datetime 30 seconds ago (0.5 minutes)
        Datetime thirtySecondsAgo = Datetime.now().addSeconds(-30);
        String flowStartTime = thirtySecondsAgo.format('yyyy-MM-dd HH:mm:ss');
        
        // Act
        Test.startTest();
        Integer result = WoonstadFlowTimeUtil.tryParseMinutesSince(flowStartTime);
        Test.stopTest();
        
        // Assert: 30 seconds should floor to 0 minutes
        System.assertEquals(0, result, 
            'Less than 1 minute should return 0 (floor behavior)');
    }
    
    /*************************************************************************************************
     * @description Test with multiple calls to ensure method is reusable
     * 
     * What this tests:
     * - Calling the method multiple times with different inputs
     * - Verifies no state is maintained between calls
     * - Tests bulk scenario (multiple invocations)
     * 
     * Learning: Utility methods should be stateless and reusable
     *           Each call should be independent
     *************************************************************************************************/
    @isTest
    static void testMultipleCalls_AllWorkCorrectly() {
        // Arrange: Create multiple test cases
        Datetime fiveMinutesAgo = Datetime.now().addMinutes(-5);
        Datetime tenMinutesAgo = Datetime.now().addMinutes(-10);
        
        String time1 = fiveMinutesAgo.format('yyyy-MM-dd HH:mm:ss');
        String time2 = tenMinutesAgo.format('yyyy-MM-dd HH:mm:ss');
        String time3 = null;
        String time4 = 'invalid';
        
        // Act
        Test.startTest();
        Integer result1 = WoonstadFlowTimeUtil.tryParseMinutesSince(time1);
        Integer result2 = WoonstadFlowTimeUtil.tryParseMinutesSince(time2);
        Integer result3 = WoonstadFlowTimeUtil.tryParseMinutesSince(time3);
        Integer result4 = WoonstadFlowTimeUtil.tryParseMinutesSince(time4);
        Test.stopTest();
        
        // Assert: Each should return expected values independently
        System.assert(result1 >= 4 && result1 <= 5, 
            'First call should return ~5 minutes');
        System.assert(result2 >= 9 && result2 <= 10, 
            'Second call should return ~10 minutes');
        System.assertEquals(0, result3, 
            'Null should return 0');
        System.assertEquals(0, result4, 
            'Invalid should return 0');
    }
    
    /*************************************************************************************************
     * @description Test with date in the past (historical) to ensure no upper limit issues
     * 
     * What this tests:
     * - Large time differences (days/hours ago)
     * - Verifies Integer doesn't overflow
     * - Tests realistic scenario where flow may have been started hours ago
     * 
     * Learning: Integer in Apex can hold up to 2,147,483,647
     *           That's ~4,000 years in minutes, so we're safe
     *************************************************************************************************/
    @isTest
    static void testHistoricalDate_ReturnsLargeNumber() {
        // Arrange: Create datetime from 2 days ago (2880 minutes)
        Datetime twoDaysAgo = Datetime.now().addDays(-2);
        String flowStartTime = twoDaysAgo.format('yyyy-MM-dd HH:mm:ss');
        
        // Act
        Test.startTest();
        Integer result = WoonstadFlowTimeUtil.tryParseMinutesSince(flowStartTime);
        Test.stopTest();
        
        // Assert: Should be approximately 2880 minutes (48 hours * 60)
        System.assert(result >= 2879 && result <= 2881, 
            'Expected approximately 2880 minutes (2 days), but got: ' + result);
    }
}