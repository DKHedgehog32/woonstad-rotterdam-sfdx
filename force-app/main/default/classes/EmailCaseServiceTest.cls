@IsTest
public class EmailCaseServiceTest {
    @IsTest
    static void testCloneCaseAndEmailMessageBulk() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id);
        insert testContact;

        List<Case> caseList = new List<Case>();
        List<EmailMessage> emailMessageList = new List<EmailMessage>();
        List<ContentVersion> contentVersionList = new List<ContentVersion>();

        for (Integer i = 0; i < 100; i++) {
            Case newCase = new Case(
                Subject = 'Test Case ' + i,
                Origin = 'Email',
                Case_Reason__c = 'Could not find information',
                RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Question').getRecordTypeId(),
                ContactId = testContact.Id,
                AccountId = testAccount.Id
            );
            caseList.add(newCase);
        }
        insert caseList;

        for (Case c : caseList) {
            EmailMessage emailMessage = new EmailMessage(
                ParentId = c.Id,
                Subject = 'Test Email ' + c.Subject,
                FromAddress = 'test@example.com',
                ToAddress = 'test@woonstadrotterdam.nl',
                TextBody = 'Test email for case ' + c.Subject + '.'
            );
            emailMessageList.add(emailMessage);
        }
        insert emailMessageList;

        for (EmailMessage em : emailMessageList) {
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Test Document ' + em.Subject,
                PathOnClient = 'TestDocument.pdf',
                VersionData = Blob.valueOf('Test file content for ' + em.Subject),
                IsMajorVersion = true,
                FirstPublishLocationId = em.Id
            );
            contentVersionList.add(contentVersion);
        }
        insert contentVersionList;

        // Create clone requests
        List<EmailCaseCloneRequest> cloneRequestList = new List<EmailCaseCloneRequest>();

        for (Integer i = 0; i < caseList.size(); i++) {
            EmailCaseCloneRequest cr = new EmailCaseCloneRequest();
            cr.caseId = caseList[i].Id;
            cr.emailMessageId = emailMessageList[i].Id;
            cloneRequestList.add(cr);
        }

        // Call the method
        Test.startTest();
        String serializedRequests = JSON.serialize(cloneRequestList);
        EmailCaseService.cloneCaseAndEmailMessage(serializedRequests);
        Test.stopTest();

        // Validate cloned data
        List<Case> clonedCases = [
            SELECT Id, Subject, Origin, Case_Reason__c, Description, ContactId, AccountId 
            FROM Case 
            WHERE Id NOT IN :caseList
        ];
        System.assertEquals(100, clonedCases.size(), 'There should be 100 cloned Cases.');

        List<EmailMessage> clonedEmailMessages = [
            SELECT Id, ParentId, Subject, TextBody 
            FROM EmailMessage 
            WHERE ParentId IN :clonedCases
        ];
        System.assertEquals(100, clonedEmailMessages.size(), 'There should be 100 cloned EmailMessages.');

        List<ContentDocumentLink> clonedContentDocumentLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN (SELECT Id FROM EmailMessage WHERE ParentId IN :clonedCases)
        ];
        System.assertEquals(100, clonedContentDocumentLinks.size(), 'There should be 100 cloned ContentDocumentLinks.');

        // Ensure data integrity
        for (Integer i = 0; i < clonedCases.size(); i++) {
            Case originalCase = caseList[i];
            Case clonedCase = clonedCases[i];
            System.assertEquals(originalCase.Subject, clonedCase.Subject, 'Cloned Case Subject should match the original.');
            System.assertEquals(emailMessageList[i].TextBody, clonedCase.Description, 'Cloned Case Description should match the EmailMessage TextBody.');

            EmailMessage clonedEmailMessage = clonedEmailMessages[i];
            System.assertEquals(clonedCase.Id, clonedEmailMessage.ParentId, 'Cloned EmailMessage Parent ID should match the cloned Case ID.');
        }
        // Fault path test
        try {
            EmailCaseCloneRequest invalidRequest = new EmailCaseCloneRequest();
            invalidRequest.caseId = 'InvalidCaseId';
            invalidRequest.emailMessageId = 'InvalidEmailMessageId';
            List<EmailCaseCloneRequest> invalidRequestList = new List<EmailCaseCloneRequest>{invalidRequest};

            String invalidSerializedRequests = JSON.serialize(invalidRequestList);
            Test.startTest();
            EmailCaseService.cloneCaseAndEmailMessage(invalidSerializedRequests);
            Test.stopTest();

            System.assert(false, 'Exception should have been thrown for invalid IDs.');
        } catch (Exception e) {
            System.assertEquals('System.StringException', e.getTypeName(), 'Exception should be of type StringException.');
        }
    }
}