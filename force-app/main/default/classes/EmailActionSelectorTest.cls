@isTest
private class EmailActionSelectorTest {

    @isTest
    static void testEmailAction() {
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Email',
            Label__c = 'Woonstad'
        );
        insert testCase;
        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = Test.newSendEmailQuickActionDefaults(testCase.Id, null);
        Test.startTest();
        EmailActionSelector selector = new EmailActionSelector();
        selector.onInitDefaults(new List<QuickAction.QuickActionDefaults>{sendEmailDefaults});
        Test.stopTest();
        System.assertEquals(testCase.Id, sendEmailDefaults.getContextId(),'Expected case in context id');
    }
}