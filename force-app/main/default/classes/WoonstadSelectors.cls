/*************************************************************************************************
 * Class            : WoonstadSelectors
 * Layer            : Selector
 * Purpose          : Centralize safe SOQL queries with CRUD/FLS enforcement.
 *
 * Owner            : Woonstad
 * Author           : Dennis van Musschenbroek
 * Created          : 2025-08-25
 * Last Modified    : 2025-11-06
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-08-25 | DvM | Added Case.Account_Address__c; using sanitizeForRead for all SObjects.
 * 2025-11-06 | Fix | CRITICAL: Use setMessage() for AuraHandledException in test contexts
 * 2025-11-06 | Fix | Constructor message alone doesn't work in test - must call setMessage()
 * 2025-11-06 | Fix | Follows Salesforce best practice for testable exception handling
 * ===============================================================================================
 * 
 * CRITICAL FIX EXPLANATION:
 * 
 * PROBLEM: AuraHandledException messages were not accessible in test contexts.
 * Tests were catching "Script-thrown exception" instead of descriptive messages.
 * 
 * ROOT CAUSE: In Salesforce test contexts, AuraHandledException requires EXPLICIT
 * message setting via setMessage(). The constructor message alone is NOT preserved
 * for getMessage() calls in tests.
 * 
 * SOLUTION: For each AuraHandledException:
 * 1. Create the exception with constructor message
 * 2. Call setMessage() with the same message
 * 3. Then throw it
 * 
 * This ensures the message is accessible in both production AND test contexts.
 * 
 * REFERENCE: Salesforce documentation on testing Aura-enabled Apex
 * AWAF BEST PRACTICE: Always use setMessage() for testable exceptions
 *************************************************************************************************/
public with sharing class WoonstadSelectors {

    /*************************************************************************************************
     * METHOD: accountByIdRequired
     * 
     * CRITICAL CHANGES:
     * - Now properly sets exception messages using setMessage()
     * - Ensures test assertions can access the descriptive error messages
     *************************************************************************************************/
    public static Account accountByIdRequired(Id accountId) {
        // Validate input with properly set exception message
        if (accountId == null) {
            AuraHandledException ex = new AuraHandledException('AccountId is required.');
            ex.setMessage('AccountId is required.');
            throw ex;
        }
        
        WoonstadCrudFlsGuard.requireRead(Account.SObjectType, 'WoonstadSelectors', 'accountByIdRequired');

        List<Account> rows = [
            SELECT Id, Name, PersonEmail,
                   Full_Shipping_Street__c, Full_Shipping_Postal_Code__c,
                   Full_Shipping_City__c, Full_Shipping_Country__c,
                   IsPersonAccount, PersonContactId, Label__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        
        // Check for not found with properly set exception message
        if (rows.isEmpty()) {
            AuraHandledException ex = new AuraHandledException('Account not found: ' + accountId);
            ex.setMessage('Account not found: ' + accountId);
            throw ex;
        }
        
        List<SObject> filtered = WoonstadCrudFlsGuard.sanitizeForRead(
            (List<SObject>)rows, 'WoonstadSelectors', 'accountByIdRequired', accountId
        );
        return (Account)filtered[0];
    }

    /*************************************************************************************************
     * METHOD: caseByIdRequired
     * 
     * CRITICAL CHANGES:
     * - Now properly sets exception messages using setMessage()
     *************************************************************************************************/
    public static Case caseByIdRequired(Id id) {
        WoonstadCrudFlsGuard.requireRead(Case.SObjectType, 'WoonstadSelectors', 'caseByIdRequired');

        List<Case> rows = [
            SELECT Id, CaseNumber, Subject, Description,
                   Nameplate_Text__c, AccountId, Status, Request__c,
                   Account_Address__c
            FROM Case
            WHERE Id = :id
            LIMIT 1
        ];
        
        // Check for not found with properly set exception message
        if (rows.isEmpty()) {
            AuraHandledException ex = new AuraHandledException('Case not found: ' + id);
            ex.setMessage('Case not found: ' + id);
            throw ex;
        }
        
        List<SObject> filtered = WoonstadCrudFlsGuard.sanitizeForRead(
            (List<SObject>)rows, 'WoonstadSelectors', 'caseByIdRequired', id
        );
        return (Case)filtered[0];
    }

    /*************************************************************************************************
     * METHOD: requestByIdRequired
     * 
     * CRITICAL CHANGES:
     * - Now properly sets exception messages using setMessage()
     *************************************************************************************************/
    public static Request__c requestByIdRequired(Id id) {
        WoonstadCrudFlsGuard.requireRead(Request__c.SObjectType, 'WoonstadSelectors', 'requestByIdRequired');

        List<Request__c> rows = [
            SELECT Id, Case__c, Account__c, Name_Plate_Text__c, Type__c, Request_Status__c
            FROM Request__c
            WHERE Id = :id
            LIMIT 1
        ];
        
        // Check for not found with properly set exception message
        if (rows.isEmpty()) {
            AuraHandledException ex = new AuraHandledException('Request__c not found: ' + id);
            ex.setMessage('Request__c not found: ' + id);
            throw ex;
        }
        
        List<SObject> filtered = WoonstadCrudFlsGuard.sanitizeForRead(
            (List<SObject>)rows, 'WoonstadSelectors', 'requestByIdRequired', id
        );
        return (Request__c)filtered[0];
    }

    /*************************************************************************************************
     * METHOD: runningUser
     * 
     * NOTE: This method doesn't throw exceptions since UserInfo.getUserId() 
     * always returns a valid ID and the user record always exists.
     *************************************************************************************************/
    public static User runningUser() {
        WoonstadCrudFlsGuard.requireRead(User.SObjectType, 'WoonstadSelectors', 'runningUser');

        List<User> rows = [
            SELECT Id, FirstName, LastName, Email
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        List<SObject> filtered = WoonstadCrudFlsGuard.sanitizeForRead(
            (List<SObject>)rows, 'WoonstadSelectors', 'runningUser', UserInfo.getUserId()
        );
        return (User)filtered[0];
    }

    /*************************************************************************************************
     * METHOD: emailTemplateByIdRequired
     * 
     * CRITICAL CHANGES:
     * - Now properly sets exception messages using setMessage()
     *************************************************************************************************/
    public static EmailTemplate emailTemplateByIdRequired(Id id) {
        WoonstadCrudFlsGuard.requireRead(EmailTemplate.SObjectType, 'WoonstadSelectors', 'emailTemplateByIdRequired');

        List<EmailTemplate> rows = [
            SELECT Id, Subject, HtmlValue, Body, DeveloperName, Name
            FROM EmailTemplate
            WHERE Id = :id
            LIMIT 1
        ];
        
        // Check for not found with properly set exception message
        if (rows.isEmpty()) {
            AuraHandledException ex = new AuraHandledException('EmailTemplate not found: ' + id);
            ex.setMessage('EmailTemplate not found: ' + id);
            throw ex;
        }
        
        List<SObject> filtered = WoonstadCrudFlsGuard.sanitizeForRead(
            (List<SObject>)rows, 'WoonstadSelectors', 'emailTemplateByIdRequired', id
        );
        return (EmailTemplate)filtered[0];
    }
}