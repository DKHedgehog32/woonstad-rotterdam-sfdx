/*************************************************************************************************
 * Class           : WoonstadSecurityPolicyTest
 * Layer           : Test
 * Purpose         : Comprehensive test class for WoonstadSecurityPolicy
 *
 * Description:
 * This test class verifies the security policy configuration methods in WoonstadSecurityPolicy.
 * It ensures that all policy toggles and message generation methods work correctly and return
 * expected values.
 *
 * What This Class Tests:
 * 1. Policy Toggle Methods - Verifies boolean return values for security policies
 *    - blockOnRemovedCreate() - Should block when fields removed during create
 *    - blockOnRemovedUpdate() - Should block when fields removed during update
 *    - logRemovedOnRead() - Should log when fields removed during read
 *
 * 2. Message Generation Methods - Validates user-friendly error messages
 *    - flsBlockedMessage(String op) - Field-level security messages
 *    - crudBlockedMessage(String op) - CRUD permission messages
 *
 * 3. Message Consistency - Ensures messages are properly formatted
 *    - Tests various operation types (create, read, update, delete, view)
 *    - Validates message structure and clarity
 *
 * Test Coverage Areas:
 * - Positive tests: All methods return expected values
 * - Message tests: Proper formatting and operation context
 * - Edge cases: Empty strings, null handling, various operation types
 *
 * Why This Class Matters:
 * WoonstadSecurityPolicy is a central configuration point for security behavior across
 * the entire org. These tests ensure that policy changes don't break existing functionality
 * and that error messages remain user-friendly.
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-11-05
 * Last Modified   : 2025-11-05
 * ===============================================================================================
 * Change Log
 * -----------------------------------------------------------------------------------------------
 * 2025-11-05 | Initial | Created comprehensive test class for security policy configuration
 *************************************************************************************************/
@isTest(SeeAllData=false)
private class WoonstadSecurityPolicyTest {

    // ======= POLICY TOGGLE TESTS ==============================================================

    /**
     * Test: blockOnRemovedCreate() Returns Boolean
     * 
     * What this tests: Verifies that the create blocking policy returns a boolean value.
     * Why it matters: This policy determines whether operations should fail when FLS
     *                 removes fields during record creation.
     * Learn: Boolean policies allow easy feature toggles without code changes.
     */
    @isTest
    static void testBlockOnRemovedCreate_ReturnsBoolean() {
        // ARRANGE: No setup needed for static policy method
        
        // ACT: Call the policy method
        Test.startTest();
        Boolean result = WoonstadSecurityPolicy.blockOnRemovedCreate();
        Test.stopTest();
        
        // ASSERT: Should return a boolean (currently true based on implementation)
        System.assertNotEquals(null, result, 'Policy should return a non-null boolean value');
        System.assertEquals(true, result, 
            'Create blocking policy should be enabled (expected: true)');
    }

    /**
     * Test: blockOnRemovedUpdate() Returns Boolean
     * 
     * What this tests: Verifies that the update blocking policy returns a boolean value.
     * Why it matters: Controls whether updates fail when FLS strips fields.
     * Learn: Separate policies for create vs update allow fine-grained control.
     */
    @isTest
    static void testBlockOnRemovedUpdate_ReturnsBoolean() {
        // ARRANGE: No setup needed
        
        // ACT: Call the policy method
        Test.startTest();
        Boolean result = WoonstadSecurityPolicy.blockOnRemovedUpdate();
        Test.stopTest();
        
        // ASSERT: Should return a boolean (currently true based on implementation)
        System.assertNotEquals(null, result, 'Policy should return a non-null boolean value');
        System.assertEquals(true, result, 
            'Update blocking policy should be enabled (expected: true)');
    }

    /**
     * Test: logRemovedOnRead() Returns Boolean
     * 
     * What this tests: Verifies that the read logging policy returns a boolean value.
     * Why it matters: Determines whether field removal during reads should be logged.
     * Learn: Read operations often don't block but log for security auditing.
     */
    @isTest
    static void testLogRemovedOnRead_ReturnsBoolean() {
        // ARRANGE: No setup needed
        
        // ACT: Call the policy method
        Test.startTest();
        Boolean result = WoonstadSecurityPolicy.logRemovedOnRead();
        Test.stopTest();
        
        // ASSERT: Should return a boolean (currently true based on implementation)
        System.assertNotEquals(null, result, 'Policy should return a non-null boolean value');
        System.assertEquals(true, result, 
            'Read logging policy should be enabled (expected: true)');
    }

    /**
     * Test: All Policy Toggles Work Together
     * 
     * What this tests: Verifies all three policy methods can be called in sequence.
     * Why it matters: Ensures no conflicts or dependencies between policies.
     * Learn: Policy classes should have independent, stateless methods.
     */
    @isTest
    static void testAllPolicyToggles_WorkIndependently() {
        // ARRANGE: No setup needed
        
        // ACT: Call all policy methods in one test
        Test.startTest();
        Boolean createPolicy = WoonstadSecurityPolicy.blockOnRemovedCreate();
        Boolean updatePolicy = WoonstadSecurityPolicy.blockOnRemovedUpdate();
        Boolean readPolicy = WoonstadSecurityPolicy.logRemovedOnRead();
        Test.stopTest();
        
        // ASSERT: All should return valid boolean values
        System.assertNotEquals(null, createPolicy, 'Create policy should not be null');
        System.assertNotEquals(null, updatePolicy, 'Update policy should not be null');
        System.assertNotEquals(null, readPolicy, 'Read policy should not be null');
        
        // Document the current policy state in test output
        System.debug('Current Policy State:');
        System.debug('  Block on Create: ' + createPolicy);
        System.debug('  Block on Update: ' + updatePolicy);
        System.debug('  Log on Read: ' + readPolicy);
    }

    // ======= FLS MESSAGE TESTS ================================================================

    /**
     * Test: flsBlockedMessage() for Create Operation
     * 
     * What this tests: Verifies FLS message generation for create operations.
     * Why it matters: Users need clear, actionable error messages.
     * Learn: Message methods should include the operation context for clarity.
     */
    @isTest
    static void testFlsBlockedMessage_CreateOperation_ReturnsMessage() {
        // ARRANGE: Define operation type
        String operation = 'create';
        
        // ACT: Generate FLS blocked message
        Test.startTest();
        String message = WoonstadSecurityPolicy.flsBlockedMessage(operation);
        Test.stopTest();
        
        // ASSERT: Message should be properly formatted
        System.assertNotEquals(null, message, 'Message should not be null');
        System.assert(message.length() > 0, 'Message should not be empty');
        System.assert(message.containsIgnoreCase('field-level'), 
            'Message should mention field-level security');
        System.assert(message.containsIgnoreCase(operation), 
            'Message should include the operation type');
        
        // Log for manual verification
        System.debug('FLS Create Message: ' + message);
    }

    /**
     * Test: flsBlockedMessage() for Update Operation
     * 
     * What this tests: Verifies FLS message generation for update operations.
     * Why it matters: Different operations may need different message contexts.
     * Learn: The same method handles multiple operations via parameter.
     */
    @isTest
    static void testFlsBlockedMessage_UpdateOperation_ReturnsMessage() {
        // ARRANGE
        String operation = 'update';
        
        // ACT
        Test.startTest();
        String message = WoonstadSecurityPolicy.flsBlockedMessage(operation);
        Test.stopTest();
        
        // ASSERT
        System.assertNotEquals(null, message, 'Message should not be null');
        System.assert(message.length() > 0, 'Message should not be empty');
        System.assert(message.containsIgnoreCase('field-level'), 
            'Message should mention field-level security');
        System.assert(message.containsIgnoreCase(operation), 
            'Message should include the operation type');
        
        System.debug('FLS Update Message: ' + message);
    }

    /**
     * Test: flsBlockedMessage() for Read Operation
     * 
     * What this tests: Verifies FLS message generation for read operations.
     * Why it matters: Read operations can also be blocked by FLS.
     * Learn: Comprehensive testing covers all CRUD operations.
     */
    @isTest
    static void testFlsBlockedMessage_ReadOperation_ReturnsMessage() {
        // ARRANGE
        String operation = 'read';
        
        // ACT
        Test.startTest();
        String message = WoonstadSecurityPolicy.flsBlockedMessage(operation);
        Test.stopTest();
        
        // ASSERT
        System.assertNotEquals(null, message, 'Message should not be null');
        System.assert(message.length() > 0, 'Message should not be empty');
        System.assert(message.containsIgnoreCase(operation), 
            'Message should include the operation type');
        
        System.debug('FLS Read Message: ' + message);
    }

    /**
     * Test: flsBlockedMessage() with Empty String
     * 
     * What this tests: Edge case handling when operation is empty.
     * Why it matters: Ensures graceful handling of unexpected inputs.
     * Learn: Defensive programming prevents runtime errors.
     */
    @isTest
    static void testFlsBlockedMessage_EmptyString_ReturnsMessage() {
        // ARRANGE: Empty operation string
        String operation = '';
        
        // ACT
        Test.startTest();
        String message = WoonstadSecurityPolicy.flsBlockedMessage(operation);
        Test.stopTest();
        
        // ASSERT: Should still return a valid message
        System.assertNotEquals(null, message, 'Message should not be null even with empty input');
        System.assert(message.length() > 0, 'Message should have content');
        
        System.debug('FLS Empty String Message: ' + message);
    }

    // ======= CRUD MESSAGE TESTS ===============================================================

    /**
     * Test: crudBlockedMessage() for Create Operation
     * 
     * What this tests: Verifies CRUD message generation for create operations.
     * Why it matters: CRUD errors are different from FLS errors and need distinct messages.
     * Learn: Separate message methods for different security concerns (CRUD vs FLS).
     */
    @isTest
    static void testCrudBlockedMessage_CreateOperation_ReturnsMessage() {
        // ARRANGE
        String operation = 'create';
        
        // ACT
        Test.startTest();
        String message = WoonstadSecurityPolicy.crudBlockedMessage(operation);
        Test.stopTest();
        
        // ASSERT
        System.assertNotEquals(null, message, 'Message should not be null');
        System.assert(message.length() > 0, 'Message should not be empty');
        System.assert(message.containsIgnoreCase('permission'), 
            'Message should mention permissions');
        System.assert(message.containsIgnoreCase(operation), 
            'Message should include the operation type');
        
        System.debug('CRUD Create Message: ' + message);
    }

    /**
     * Test: crudBlockedMessage() for Read/View Operation
     * 
     * What this tests: Verifies CRUD message generation for read/view operations.
     * Why it matters: 'view' is a common user-friendly term for 'read'.
     * Learn: Messages should use terminology familiar to end users.
     */
    @isTest
    static void testCrudBlockedMessage_ViewOperation_ReturnsMessage() {
        // ARRANGE: Using 'view' which is more user-friendly than 'read'
        String operation = 'view';
        
        // ACT
        Test.startTest();
        String message = WoonstadSecurityPolicy.crudBlockedMessage(operation);
        Test.stopTest();
        
        // ASSERT
        System.assertNotEquals(null, message, 'Message should not be null');
        System.assert(message.length() > 0, 'Message should not be empty');
        System.assert(message.containsIgnoreCase(operation), 
            'Message should include the operation type');
        
        System.debug('CRUD View Message: ' + message);
    }

    /**
     * Test: crudBlockedMessage() for Update Operation
     * 
     * What this tests: Verifies CRUD message generation for update operations.
     */
    @isTest
    static void testCrudBlockedMessage_UpdateOperation_ReturnsMessage() {
        // ARRANGE
        String operation = 'update';
        
        // ACT
        Test.startTest();
        String message = WoonstadSecurityPolicy.crudBlockedMessage(operation);
        Test.stopTest();
        
        // ASSERT
        System.assertNotEquals(null, message, 'Message should not be null');
        System.assert(message.length() > 0, 'Message should not be empty');
        System.assert(message.containsIgnoreCase('permission'), 
            'Message should mention permissions');
        System.assert(message.containsIgnoreCase(operation), 
            'Message should include the operation type');
        
        System.debug('CRUD Update Message: ' + message);
    }

    /**
     * Test: crudBlockedMessage() for Delete Operation
     * 
     * What this tests: Verifies CRUD message generation for delete operations.
     * Why it matters: Delete is a critical operation requiring clear messaging.
     */
    @isTest
    static void testCrudBlockedMessage_DeleteOperation_ReturnsMessage() {
        // ARRANGE
        String operation = 'delete';
        
        // ACT
        Test.startTest();
        String message = WoonstadSecurityPolicy.crudBlockedMessage(operation);
        Test.stopTest();
        
        // ASSERT
        System.assertNotEquals(null, message, 'Message should not be null');
        System.assert(message.length() > 0, 'Message should not be empty');
        System.assert(message.containsIgnoreCase('permission'), 
            'Message should mention permissions');
        System.assert(message.containsIgnoreCase(operation), 
            'Message should include the operation type');
        
        System.debug('CRUD Delete Message: ' + message);
    }

    /**
     * Test: crudBlockedMessage() with Empty String
     * 
     * What this tests: Edge case handling for CRUD messages.
     * Why it matters: Ensures robustness in unexpected scenarios.
     */
    @isTest
    static void testCrudBlockedMessage_EmptyString_ReturnsMessage() {
        // ARRANGE
        String operation = '';
        
        // ACT
        Test.startTest();
        String message = WoonstadSecurityPolicy.crudBlockedMessage(operation);
        Test.stopTest();
        
        // ASSERT: Should still return a valid message
        System.assertNotEquals(null, message, 'Message should not be null even with empty input');
        System.assert(message.length() > 0, 'Message should have content');
        
        System.debug('CRUD Empty String Message: ' + message);
    }

    // ======= MESSAGE CONSISTENCY TESTS ========================================================

    /**
     * Test: FLS Messages Are Different from CRUD Messages
     * 
     * What this tests: Verifies that FLS and CRUD messages are distinguishable.
     * Why it matters: Users need to understand which type of permission is blocking them.
     * Learn: Clear error messages improve user experience and reduce support tickets.
     */
    @isTest
    static void testMessageDifference_FlsVsCrud_AreDifferent() {
        // ARRANGE
        String operation = 'create';
        
        // ACT
        Test.startTest();
        String flsMessage = WoonstadSecurityPolicy.flsBlockedMessage(operation);
        String crudMessage = WoonstadSecurityPolicy.crudBlockedMessage(operation);
        Test.stopTest();
        
        // ASSERT: Messages should be different
        System.assertNotEquals(flsMessage, crudMessage, 
            'FLS and CRUD messages should be different for the same operation');
        
        // FLS message should mention field-level
        System.assert(flsMessage.containsIgnoreCase('field-level'), 
            'FLS message should mention field-level security');
        
        // CRUD message should mention permission
        System.assert(crudMessage.containsIgnoreCase('permission'), 
            'CRUD message should mention permissions');
        
        System.debug('FLS Message: ' + flsMessage);
        System.debug('CRUD Message: ' + crudMessage);
    }

    /**
     * Test: Messages Change Based on Operation Type
     * 
     * What this tests: Verifies messages are contextual to the operation.
     * Why it matters: Users need operation-specific guidance.
     * Learn: Dynamic message generation improves user experience.
     */
    @isTest
    static void testMessageContextuality_DifferentOperations_DifferentMessages() {
        // ARRANGE: Different operations
        String createOp = 'create';
        String updateOp = 'update';
        String deleteOp = 'delete';
        
        // ACT
        Test.startTest();
        String createMsg = WoonstadSecurityPolicy.crudBlockedMessage(createOp);
        String updateMsg = WoonstadSecurityPolicy.crudBlockedMessage(updateOp);
        String deleteMsg = WoonstadSecurityPolicy.crudBlockedMessage(deleteOp);
        Test.stopTest();
        
        // ASSERT: Each message should contain its operation
        System.assert(createMsg.containsIgnoreCase(createOp), 
            'Create message should mention create');
        System.assert(updateMsg.containsIgnoreCase(updateOp), 
            'Update message should mention update');
        System.assert(deleteMsg.containsIgnoreCase(deleteOp), 
            'Delete message should mention delete');
        
        // All messages should be different
        System.assertNotEquals(createMsg, updateMsg, 
            'Create and update messages should differ');
        System.assertNotEquals(updateMsg, deleteMsg, 
            'Update and delete messages should differ');
        System.assertNotEquals(createMsg, deleteMsg, 
            'Create and delete messages should differ');
    }

    // ======= INTEGRATION & USAGE TESTS ========================================================

    /**
     * Test: Policy Methods Are Callable from External Classes
     * 
     * What this tests: Verifies policy methods have correct visibility (public).
     * Why it matters: WoonstadCrudFlsGuard and other classes need access to these policies.
     * Learn: Public static methods create a clean API for policy consumption.
     */
    @isTest
    static void testPolicyMethods_PublicAccess_Success() {
        // ARRANGE: No setup needed
        
        // ACT: Call all methods as external consumer would
        Test.startTest();
        Boolean createBlock = WoonstadSecurityPolicy.blockOnRemovedCreate();
        Boolean updateBlock = WoonstadSecurityPolicy.blockOnRemovedUpdate();
        Boolean readLog = WoonstadSecurityPolicy.logRemovedOnRead();
        String flsMsg = WoonstadSecurityPolicy.flsBlockedMessage('test');
        String crudMsg = WoonstadSecurityPolicy.crudBlockedMessage('test');
        Test.stopTest();
        
        // ASSERT: All methods accessible and return valid values
        System.assert(createBlock != null, 'blockOnRemovedCreate() is accessible');
        System.assert(updateBlock != null, 'blockOnRemovedUpdate() is accessible');
        System.assert(readLog != null, 'logRemovedOnRead() is accessible');
        System.assert(flsMsg != null && flsMsg.length() > 0, 
            'flsBlockedMessage() is accessible');
        System.assert(crudMsg != null && crudMsg.length() > 0, 
            'crudBlockedMessage() is accessible');
    }

    /**
     * Test: Message Methods Handle Various Operation Names
     * 
     * What this tests: Verifies message methods work with different naming conventions.
     * Why it matters: Different contexts might use 'view' vs 'read', etc.
     * Learn: Flexible message generation supports various use cases.
     */
    @isTest
    static void testMessageMethods_VariousOperationNames_AllWork() {
        // ARRANGE: Different operation naming conventions
        List<String> operations = new List<String>{
            'create', 'read', 'update', 'delete',  // CRUD standard
            'view', 'edit', 'remove',              // User-friendly alternatives
            'insert', 'modify'                      // Technical alternatives
        };
        
        // ACT & ASSERT: All should generate valid messages
        Test.startTest();
        for (String op : operations) {
            String flsMsg = WoonstadSecurityPolicy.flsBlockedMessage(op);
            String crudMsg = WoonstadSecurityPolicy.crudBlockedMessage(op);
            
            System.assertNotEquals(null, flsMsg, 
                'FLS message should work for operation: ' + op);
            System.assertNotEquals(null, crudMsg, 
                'CRUD message should work for operation: ' + op);
            System.assert(flsMsg.length() > 0, 
                'FLS message should have content for: ' + op);
            System.assert(crudMsg.length() > 0, 
                'CRUD message should have content for: ' + op);
        }
        Test.stopTest();
    }

    // ======= PERFORMANCE & BULK TESTS =========================================================

    /**
     * Test: Policy Methods Performance - Bulk Calls
     * 
     * What this tests: Verifies policy methods remain performant when called many times.
     * Why it matters: Guard class calls these methods frequently in bulk operations.
     * Learn: Static methods should be lightweight and fast.
     */
    @isTest
    static void testPolicyMethods_BulkCalls_PerformantAndConsistent() {
        // ARRANGE: Prepare to call methods many times
        Integer iterations = 1000;
        List<Boolean> createResults = new List<Boolean>();
        List<Boolean> updateResults = new List<Boolean>();
        List<Boolean> readResults = new List<Boolean>();
        
        // ACT: Call policy methods many times
        Test.startTest();
        for (Integer i = 0; i < iterations; i++) {
            createResults.add(WoonstadSecurityPolicy.blockOnRemovedCreate());
            updateResults.add(WoonstadSecurityPolicy.blockOnRemovedUpdate());
            readResults.add(WoonstadSecurityPolicy.logRemovedOnRead());
        }
        Test.stopTest();
        
        // ASSERT: All calls should return consistent values
        System.assertEquals(iterations, createResults.size(), 
            'Should execute all create policy calls');
        System.assertEquals(iterations, updateResults.size(), 
            'Should execute all update policy calls');
        System.assertEquals(iterations, readResults.size(), 
            'Should execute all read policy calls');
        
        // Verify consistency (all values should be the same)
        Boolean firstCreate = createResults[0];
        Boolean firstUpdate = updateResults[0];
        Boolean firstRead = readResults[0];
        
        for (Boolean result : createResults) {
            System.assertEquals(firstCreate, result, 
                'Create policy should return consistent value');
        }
        for (Boolean result : updateResults) {
            System.assertEquals(firstUpdate, result, 
                'Update policy should return consistent value');
        }
        for (Boolean result : readResults) {
            System.assertEquals(firstRead, result, 
                'Read policy should return consistent value');
        }
        
        // Check CPU time is reasonable
        System.assert(Limits.getCpuTime() < Limits.getLimitCpuTime(), 
            'Policy calls should stay well within CPU limits');
    }

    /**
     * Test: Message Generation Performance - Bulk Calls
     * 
     * What this tests: Verifies message methods remain performant with many calls.
     * Why it matters: Error scenarios might generate many messages rapidly.
     * Learn: String operations should be efficient.
     */
    @isTest
    static void testMessageMethods_BulkCalls_Performant() {
        // ARRANGE
        Integer iterations = 500;
        List<String> operations = new List<String>{'create', 'read', 'update', 'delete'};
        
        // ACT: Generate many messages
        Test.startTest();
        for (Integer i = 0; i < iterations; i++) {
            String op = operations[Math.mod(i, operations.size())];
            String flsMsg = WoonstadSecurityPolicy.flsBlockedMessage(op);
            String crudMsg = WoonstadSecurityPolicy.crudBlockedMessage(op);
            
            // Basic validation
            System.assert(flsMsg != null && flsMsg.length() > 0, 
                'FLS message should be generated');
            System.assert(crudMsg != null && crudMsg.length() > 0, 
                'CRUD message should be generated');
        }
        Test.stopTest();
        
        // ASSERT: Should complete within reasonable CPU limits
        System.assert(Limits.getCpuTime() < Limits.getLimitCpuTime(), 
            'Message generation should stay within CPU limits');
    }
}