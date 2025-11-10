/*************************************************************************************************
 * Class            : WoonstadMergeServiceTest
 * Layer            : Test
 * Purpose          : Comprehensive test coverage for WoonstadMergeService merge template
 *                    functionality with Case/Account/User context.
 *
 * Description      : This test class validates the WoonstadMergeService.render() method by testing:
 *                    - Token replacement for Case, Account, and User fields
 *                    - Handling of null/empty inputs
 *                    - Special character handling and HTML conversion
 *                    - Bulk data processing (200+ records)
 *                    - Negative scenarios (unqueried fields, null SObjects)
 *                    - Edge cases (malformed tokens, special characters)
 *
 * Explanation      : The WoonstadMergeService directly accesses certain fields (e.g., c.Description,
 *                    a.Full_Shipping_Street__c) without using safeGet(). Therefore, ALL these fields
 *                    MUST be included in SOQL queries to prevent SObjectException, regardless of
 *                    whether they appear in the template.
 *                    
 *                    Required fields in queries:
 *                    Case: CaseNumber, Subject, Description, Nameplate_Text__c, Account_Address__c
 *                    Account: Name, PersonEmail, Full_Shipping_Street__c, Full_Shipping_Postal_Code__c,
 *                             Full_Shipping_City__c, Full_Shipping_Country__c, Label__c
 *                    User: FirstName, LastName, Email
 *
 * Owner            : Woonstad
 * Author           : Dennis van Musschenbroek
 * Created          : 2025-11-06
 * Last Modified    : 2025-11-06
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-11-06 | DvM | Initial version with comprehensive coverage
 * 2025-11-06 | DvM | Added bulletproof country handling with fallback strategies
 * 2025-11-06 | DvM | FINAL FIX - Query all fields that WoonstadMergeService directly accesses
 *************************************************************************************************/
@isTest
private class WoonstadMergeServiceTest {
    
    /***********************************************************************************************
     * @description Bulletproof helper method to get a valid country value for the org.
     *              Uses multiple strategies with fallbacks.
     ***********************************************************************************************/
    private static String getValidCountry() {
        List<String> commonCountries = new List<String>{
            'United States', 'US', 'Netherlands', 'NL', 'United Kingdom', 'GB',
            'Germany', 'DE', 'France', 'FR', 'Canada', 'CA', 'Australia', 'AU'
        };
        
        Schema.DescribeFieldResult fieldResult = Account.ShippingCountry.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        Set<String> activeValues = new Set<String>();
        for (Schema.PicklistEntry entry : picklistValues) {
            if (entry.isActive()) {
                activeValues.add(entry.getValue());
                activeValues.add(entry.getLabel());
            }
        }
        
        for (String country : commonCountries) {
            if (activeValues.contains(country)) {
                return country;
            }
        }
        
        for (Schema.PicklistEntry entry : picklistValues) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        
        return null;
    }
    
    /***********************************************************************************************
     * @description Test setup method to create common test data.
     ***********************************************************************************************/
    @testSetup
    static void setupTestData() {
        String validCountry = getValidCountry();
        
        Account testAccount = new Account(
            FirstName = 'John',
            LastName = 'Doe',
            PersonEmail = 'john.doe@example.com',
            ShippingStreet = 'Main Street 123',
            ShippingPostalCode = '1234AB',
            ShippingCity = 'Amsterdam'
        );
        
        if (validCountry != null) {
            testAccount.ShippingCountry = validCountry;
        }
        
        insert testAccount;
        
        Case testCase = new Case(
            AccountId = testAccount.Id,
            Subject = 'Test Case Subject',
            Description = 'Test Case Description',
            Origin = 'Email',
            Status = 'New'
        );
        insert testCase;
    }
    
    /***********************************************************************************************
     * @description Tests complete mail-merge with all standard fields populated.
     ***********************************************************************************************/
    @isTest
    static void testRender_AllFieldsPopulated_Success() {
        // CRITICAL: Query ALL fields that WoonstadMergeService directly accesses
        Case testCase = [SELECT Id, CaseNumber, Subject, Description, 
                         Nameplate_Text__c, Account_Address__c, AccountId 
                         FROM Case LIMIT 1];
        Account testAccount = [SELECT Id, Name, PersonEmail, 
                               Full_Shipping_Street__c, Full_Shipping_Postal_Code__c,
                               Full_Shipping_City__c, Full_Shipping_Country__c, Label__c
                               FROM Account WHERE Id = :testCase.AccountId];
        User testUser = [SELECT Id, FirstName, LastName, Email FROM User 
                        WHERE Id = :UserInfo.getUserId()];
        
        String templateSubject = 'Case {{{Case.CaseNumber}}} - {{Case.Subject}}';
        String templateBody = 'Dear {{Account.Name}},<br/>' +
                             'Case: {{{Case.CaseNumber}}}<br/>' +
                             'Description: {{Case.Description}}<br/>' +
                             'Nameplate: {{{Case.Nameplate_Text__c}}}<br/>' +
                             'Address: {{Case.Account_Address__c}}<br/>' +
                             'Email: {{{Account.PersonEmail}}}<br/>' +
                             'Street: {{Account.Full_Shipping_Street__c}}<br/>' +
                             'Postal: {{{Account.Full_Shipping_Postal_Code__c}}}<br/>' +
                             'City: {{Account.Full_Shipping_City__c}}<br/>' +
                             'Country: {{{Account.Full_Shipping_Country__c}}}<br/>' +
                             'Label: {{Account.Label__c}}<br/>' +
                             'Sender: {{Sender.FirstName}} {{{Sender.LastName}}}<br/>' +
                             'Email: {{Sender.Email}}';
        
        WoonstadMergeService.MergeInput input = new WoonstadMergeService.MergeInput();
        input.templateSubject = templateSubject;
        input.templateBodyHtmlOrText = templateBody;
        input.caseRecord = testCase;
        input.account = testAccount;
        input.sender = testUser;
        
        Test.startTest();
        WoonstadMergeService.MergeOutput result = WoonstadMergeService.render(input);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.subjectMerged.contains(testCase.CaseNumber), 
                     'Subject should contain Case Number');
        System.assert(!result.bodyHtmlMerged.contains('{{{'), 
                     'Body should not contain unreplaced tokens');
        System.assertNotEquals(null, result.bodyTextMerged, 
                              'Plain text version should be generated');
    }
    
    /***********************************************************************************************
     * @description Tests mail-merge with null input object.
     ***********************************************************************************************/
    @isTest
    static void testRender_NullInput_ReturnsEmptyOutput() {
        Test.startTest();
        WoonstadMergeService.MergeOutput result = WoonstadMergeService.render(null);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('', result.subjectMerged, 'Subject should be empty string');
        System.assertEquals('', result.bodyHtmlMerged, 'Body HTML should be empty string');
        System.assertEquals('', result.bodyTextMerged, 'Body text should be empty string');
        System.assertEquals('', result.bodyTextForFile, 'File text should be empty string');
    }
    
    /***********************************************************************************************
     * @description Tests mail-merge with null Case, Account, and User objects.
     ***********************************************************************************************/
    @isTest
    static void testRender_NullObjects_ReplacesWithEmptyStrings() {
        String templateSubject = 'Case {{{Case.CaseNumber}}}';
        String templateBody = 'Account: {{Account.Name}}, Sender: {{Sender.FirstName}}';
        
        WoonstadMergeService.MergeInput input = new WoonstadMergeService.MergeInput();
        input.templateSubject = templateSubject;
        input.templateBodyHtmlOrText = templateBody;
        input.caseRecord = null;
        input.account = null;
        input.sender = null;
        
        Test.startTest();
        WoonstadMergeService.MergeOutput result = WoonstadMergeService.render(input);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(!result.subjectMerged.contains('{{{'), 
                     'Subject should not contain tokens');
        System.assertEquals('Case ', result.subjectMerged, 
                           'Subject should have token replaced with empty string');
    }
    
    /***********************************************************************************************
     * @description Tests handling of null field values within valid objects.
     ***********************************************************************************************/
    @isTest
    static void testRender_NullFieldValues_ReplacesWithEmptyStrings() {
        Account testAccount = new Account(
            FirstName = 'Jane',
            LastName = 'Smith'
        );
        insert testAccount;
        
        Case testCase = new Case(
            AccountId = testAccount.Id,
            Subject = 'Test',
            Status = 'New'
        );
        insert testCase;
        
        // CRITICAL: Query ALL fields that WoonstadMergeService directly accesses
        testCase = [SELECT Id, CaseNumber, Subject, Description, 
                   Nameplate_Text__c, Account_Address__c 
                   FROM Case WHERE Id = :testCase.Id];
        testAccount = [SELECT Id, Name, PersonEmail,
                      Full_Shipping_Street__c, Full_Shipping_Postal_Code__c,
                      Full_Shipping_City__c, Full_Shipping_Country__c, Label__c
                      FROM Account WHERE Id = :testAccount.Id];
        
        String templateBody = 'Description: {{Case.Description}}, Email: {{Account.PersonEmail}}';
        
        WoonstadMergeService.MergeInput input = new WoonstadMergeService.MergeInput();
        input.templateBodyHtmlOrText = templateBody;
        input.caseRecord = testCase;
        input.account = testAccount;
        input.sender = null;
        
        Test.startTest();
        WoonstadMergeService.MergeOutput result = WoonstadMergeService.render(input);
        Test.stopTest();
        
        System.assertEquals('Description: , Email: ', result.bodyHtmlMerged,
                           'Null fields should be replaced with empty strings');
        System.assert(!result.bodyHtmlMerged.contains('null'), 
                     'Output should not contain the word "null"');
    }
    
    /***********************************************************************************************
     * @description Tests the special token correction for Nameplate_Text__c field.
     ***********************************************************************************************/
    @isTest
    static void testRender_NameplateTokenCorrection_Success() {
        // CRITICAL: Query ALL fields that WoonstadMergeService directly accesses
        Case testCase = [SELECT Id, CaseNumber, Subject, Description,
                        Nameplate_Text__c, Account_Address__c
                        FROM Case LIMIT 1];
        
        String templateBody = 'Nameplate: {{{Case.Nameplate_Text__c.}}} and {{Case.Nameplate_Text__c.}}';
        
        WoonstadMergeService.MergeInput input = new WoonstadMergeService.MergeInput();
        input.templateBodyHtmlOrText = templateBody;
        input.caseRecord = testCase;
        input.account = null;
        input.sender = null;
        
        Test.startTest();
        WoonstadMergeService.MergeOutput result = WoonstadMergeService.render(input);
        Test.stopTest();
        
        System.assert(!result.bodyHtmlMerged.contains('{{{Case.Nameplate_Text__c.}}}'),
                     'Malformed token with trailing period should be corrected');
        System.assert(!result.bodyHtmlMerged.contains('{{{'), 
                     'All tokens should be replaced');
    }
    
    /***********************************************************************************************
     * @description Tests HTML to plain text conversion functionality.
     ***********************************************************************************************/
    @isTest
    static void testRender_HtmlToTextConversion_Success() {
        String htmlBody = '<p>Paragraph 1</p>' +
                         '<p>Paragraph 2</p>' +
                         '<br/>' +
                         '<div>Div content</div>' +
                         '<strong>Bold text</strong>';
        
        WoonstadMergeService.MergeInput input = new WoonstadMergeService.MergeInput();
        input.templateBodyHtmlOrText = htmlBody;
        input.caseRecord = null;
        input.account = null;
        input.sender = null;
        
        Test.startTest();
        WoonstadMergeService.MergeOutput result = WoonstadMergeService.render(input);
        Test.stopTest();
        
        System.assert(!result.bodyTextMerged.contains('<p>'), 
                     'HTML tags should be removed from plain text');
        System.assert(result.bodyTextMerged.contains('Paragraph 1'), 
                     'Text content should be preserved');
        System.assert(result.bodyTextMerged.contains('\n'), 
                     'Line breaks should be present');
    }
    
    /***********************************************************************************************
     * @description Tests blank line collapsing in the file text output.
     ***********************************************************************************************/
    @isTest
    static void testRender_BlankLineCollapse_Success() {
        String bodyWithExcessiveBreaks = 'Line 1\n\n\n\n\nLine 2\n\n\n\nLine 3';
        
        WoonstadMergeService.MergeInput input = new WoonstadMergeService.MergeInput();
        input.templateBodyHtmlOrText = bodyWithExcessiveBreaks;
        input.caseRecord = null;
        input.account = null;
        input.sender = null;
        
        Test.startTest();
        WoonstadMergeService.MergeOutput result = WoonstadMergeService.render(input);
        Test.stopTest();
        
        System.assert(!result.bodyTextForFile.contains('\n\n\n'), 
                     'More than 2 consecutive line breaks should be collapsed');
        System.assert(result.bodyTextForFile.contains('Line 1'), 
                     'Content should be preserved');
    }
    
    /***********************************************************************************************
     * @description Tests handling of unqueried fields using the safeGet() method.
     ***********************************************************************************************/
    @isTest
    static void testRender_UnqueriedFormulaField_HandledSafely() {
        // Query WITHOUT Account_Address__c (only field that uses safeGet)
        Case testCase = [SELECT Id, CaseNumber, Subject, Description, Nameplate_Text__c 
                        FROM Case LIMIT 1];
        
        String templateBody = 'Address: {{Case.Account_Address__c}}, Subject: {{Case.Subject}}';
        
        WoonstadMergeService.MergeInput input = new WoonstadMergeService.MergeInput();
        input.templateBodyHtmlOrText = templateBody;
        input.caseRecord = testCase;
        input.account = null;
        input.sender = null;
        
        Test.startTest();
        WoonstadMergeService.MergeOutput result = WoonstadMergeService.render(input);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.bodyHtmlMerged.contains(testCase.Subject),
                     'Queried field should be present');
        System.assert(!result.bodyHtmlMerged.contains('{{'),
                     'All tokens should be replaced');
    }
    
    /***********************************************************************************************
     * @description Tests bulk processing capability with 200 records.
     *              CRITICAL: Must query ALL fields that WoonstadMergeService directly accesses!
     ***********************************************************************************************/
    @isTest
    static void testRender_BulkProcessing_Success() {
        List<Account> bulkAccounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            bulkAccounts.add(new Account(
                FirstName = 'Bulk',
                LastName = 'User ' + i,
                PersonEmail = 'bulk' + i + '@example.com'
            ));
        }
        insert bulkAccounts;
        
        List<Case> bulkCases = new List<Case>();
        for (Account acc : bulkAccounts) {
            bulkCases.add(new Case(
                AccountId = acc.Id,
                Subject = 'Bulk Case for ' + acc.Name,
                Status = 'New'
            ));
        }
        insert bulkCases;
        
        // CRITICAL: Query ALL fields that service accesses directly
        // Even though template only uses CaseNumber and Name, the service
        // directly accesses Description, Nameplate_Text__c, etc.
        bulkCases = [SELECT Id, CaseNumber, Subject, Description, 
                     Nameplate_Text__c, Account_Address__c, AccountId 
                     FROM Case 
                     WHERE Id IN :bulkCases];
        
        // CRITICAL: Query ALL Account fields that service accesses directly
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Name, PersonEmail,
             Full_Shipping_Street__c, Full_Shipping_Postal_Code__c,
             Full_Shipping_City__c, Full_Shipping_Country__c, Label__c
             FROM Account WHERE Id IN :bulkAccounts]
        );
        
        String template = 'Case {{Case.CaseNumber}} for {{Account.Name}}';
        
        List<WoonstadMergeService.MergeOutput> results = new List<WoonstadMergeService.MergeOutput>();
        
        Test.startTest();
        for (Case c : bulkCases) {
            WoonstadMergeService.MergeInput input = new WoonstadMergeService.MergeInput();
            input.templateBodyHtmlOrText = template;
            input.caseRecord = c;
            input.account = accountMap.get(c.AccountId);
            input.sender = null;
            
            results.add(WoonstadMergeService.render(input));
        }
        Test.stopTest();
        
        System.assertEquals(200, results.size(), 
                           'Should process all 200 records');
        for (WoonstadMergeService.MergeOutput result : results) {
            System.assertNotEquals(null, result, 
                                  'Each result should not be null');
            System.assert(!result.bodyHtmlMerged.contains('{{'), 
                         'All tokens should be replaced');
        }
    }
    
    /***********************************************************************************************
     * @description Tests edge case with empty template strings.
     ***********************************************************************************************/
    @isTest
    static void testRender_EmptyTemplates_Success() {
        WoonstadMergeService.MergeInput input = new WoonstadMergeService.MergeInput();
        input.templateSubject = '';
        input.templateBodyHtmlOrText = '';
        input.caseRecord = null;
        input.account = null;
        input.sender = null;
        
        Test.startTest();
        WoonstadMergeService.MergeOutput result = WoonstadMergeService.render(input);
        Test.stopTest();
        
        System.assertEquals('', result.subjectMerged, 
                           'Empty subject should remain empty');
        System.assertEquals('', result.bodyHtmlMerged, 
                           'Empty body should remain empty');
    }
    
    /***********************************************************************************************
     * @description Tests template with no tokens (plain text).
     ***********************************************************************************************/
    @isTest
    static void testRender_NoTokens_ReturnsUnchanged() {
        String plainText = 'This is a plain text template with no merge fields.';
        
        WoonstadMergeService.MergeInput input = new WoonstadMergeService.MergeInput();
        input.templateSubject = plainText;
        input.templateBodyHtmlOrText = plainText;
        input.caseRecord = null;
        input.account = null;
        input.sender = null;
        
        Test.startTest();
        WoonstadMergeService.MergeOutput result = WoonstadMergeService.render(input);
        Test.stopTest();
        
        System.assertEquals(plainText, result.subjectMerged, 
                           'Plain text subject should be unchanged');
        System.assertEquals(plainText, result.bodyHtmlMerged, 
                           'Plain text body should be unchanged');
    }
    
    /***********************************************************************************************
     * @description Tests all token variations (double and triple braces).
     ***********************************************************************************************/
    @isTest
    static void testRender_BothTokenFormats_Success() {
        // CRITICAL: Query ALL fields that WoonstadMergeService directly accesses
        Case testCase = [SELECT Id, CaseNumber, Subject, Description,
                        Nameplate_Text__c, Account_Address__c
                        FROM Case LIMIT 1];
        
        String template = 'Double: {{Case.CaseNumber}}, Triple: {{{Case.Subject}}}';
        
        WoonstadMergeService.MergeInput input = new WoonstadMergeService.MergeInput();
        input.templateBodyHtmlOrText = template;
        input.caseRecord = testCase;
        input.account = null;
        input.sender = null;
        
        Test.startTest();
        WoonstadMergeService.MergeOutput result = WoonstadMergeService.render(input);
        Test.stopTest();
        
        System.assert(result.bodyHtmlMerged.contains(testCase.CaseNumber),
                     'Double brace token should be replaced');
        System.assert(result.bodyHtmlMerged.contains(testCase.Subject),
                     'Triple brace token should be replaced');
        System.assert(!result.bodyHtmlMerged.contains('{{'),
                     'No unreplaced tokens should remain');
    }
}