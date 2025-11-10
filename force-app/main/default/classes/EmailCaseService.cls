//
// Clones the Case, EmailMessage and ContentDocumentLinks
public class EmailCaseService {
    @Future
    public static void cloneCaseAndEmailMessage(String cloneRequestList) {
        try {
            List<EmailCaseCloneRequest> cloneRequests = (List<EmailCaseCloneRequest>) JSON.deserialize(cloneRequestList, List<EmailCaseCloneRequest>.class);

            //
            // Get the record Ids
            Set<Id> caseIds = new Set<Id>();
            Set<Id> emailMessageIds = new Set<Id>();
            for(EmailCaseCloneRequest cr : cloneRequests) {
                caseIds.add(cr.caseId);
                emailMessageIds.add(cr.emailMessageId);
            }

            //
            // Fetch fields to clone
            Map<Id, Case> caseByIdMap = new Map<Id, Case>([
                SELECT Id, Type, Subject, Origin, Case_Reason__c, RecordTypeId, ContactId, AccountId, Comments 
                FROM Case 
                WHERE Id IN :caseIds
            ]);

            Map<Id, EmailMessage> emailMessageByIdMap = new Map<Id, EmailMessage>([
                SELECT Id, BccAddress, CcAddress, FromAddress, FromName, HasAttachment, Headers, HtmlBody, IsExternallyVisible, Incoming, MessageDate, Status, Subject, TextBody, ToAddress 
                FROM EmailMessage 
                WHERE Id IN :emailMessageIds
            ]);

            //
            // Index all links per mail Id
            List<ContentDocumentLink> emailLinks = [
                SELECT Id, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :emailMessageIds
            ];

            Map<Id, List<ContentDocumentLink>> linksByEmailIdMap = new Map<Id, List<ContentDocumentLink>>();
            for(ContentDocumentLink link : emailLinks) {
                List<ContentDocumentLink> temp = new List<ContentDocumentLink>();
                if(linksByEmailIdMap.containsKey(link.LinkedEntityId)) {
                    temp = linksByEmailIdMap.get(link.LinkedEntityId);
                }
                temp.add(link);
                linksByEmailIdMap.put(link.LinkedEntityId, temp);
            }

            //
            // Clone the Cases
            Map<Id, Case> clonedCases = new Map<Id, Case>();
            for(EmailCaseCloneRequest cr : cloneRequests) {
                Case caseToClone = caseByIdMap.get(cr.caseId);
                Case clonedCase = caseToClone.clone(false);
                clonedCase.Description = emailMessageByIdMap.get(cr.emailMessageId)?.TextBody;
                clonedCases.put(caseToClone.Id, clonedCase);
            }

            //
            // Insert the Case clones in database
            insert clonedCases.values();

            //
            // Clone the EmailMessages
            Map<Id, EmailMessage> clonedEmailMessages = new Map<Id, EmailMessage>();
            for(EmailCaseCloneRequest cr : cloneRequests) {
                Case newClonedCase = clonedCases.get(cr.caseId);
                EmailMessage originEmail = emailMessageByIdMap.get(cr.emailMessageId);
                EmailMessage clonedEmailMessage = originEmail.clone(false);
                clonedEmailMessage.ParentId = newClonedCase.Id;
                clonedEmailMessages.put(originEmail.Id, clonedEmailMessage);
            }

            //
            // Insert the EmailMessage clones in database
            insert clonedEmailMessages.values();

            //
            // Clone the ContentDocumentLinks for the EmailMessage
            List<ContentDocumentLink> clonedLinks = new List<ContentDocumentLink>();
            for(EmailCaseCloneRequest cr : cloneRequests) {
                List<ContentDocumentLink> originalLinks = linksByEmailIdMap.get(cr.emailMessageId);
                EmailMessage clonedEmailMessage = clonedEmailMessages.get(cr.emailMessageId);
                Case clonedCase = clonedCases.get(cr.caseId);
                for(ContentDocumentLink link : originalLinks) {
                    ContentDocumentLink clonedEmailLink = link.clone(false);
                    clonedEmailLink.LinkedEntityId = clonedEmailMessage.Id;
                    clonedLinks.add(clonedEmailLink);

                    ContentDocumentLink clonedCaseLink = link.clone(false);
                    clonedCaseLink.LinkedEntityId = clonedCase.Id;
                    clonedLinks.add(clonedCaseLink);
                }
            }

            //
            // Insert the ContentDocumentLink clones for the EmailMessage in the database
            insert clonedLinks;

        } catch (Exception e) {
            ApexFaultHandler.publishError(e, 'EmailCaseService', 'cloneCaseAndEmailMessage');
        }
    }
}