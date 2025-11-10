/*************************************************************************************************
 * Class           : woonstadLogACallFormController
 * Layer           : Service (Apex Controller for LWC)
 * Purpose         : Handles data retrieval and logging for the Woonstad "Log a Call" LWC.
 *
 * Responsibilities:
 *  - Provide Case details for display in the form
 *  - Provide related Contact options based on AccountId
 *  - Persist a call as a Task and related FeedItem on the Case
 *
 * Security        :
 *  - with sharing: respects org-wide defaults & sharing
 *  - CRUD/FLS enforced via WoonstadCrudFlsGuard + Security.stripInaccessible
 *  - User-facing errors via AuraHandledException
 *
 * Fault Handling  :
 *  - Publishes Apex_Fault__e via ApexFaultHandler on access violations and exceptions
 *
 * Transactions    :
 *  - No DML in loops; single-record DML
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-17
 * Last Modified   : 2025-08-25
 * ===============================================================================================
 * Change Log
 * -----------------------------------------------------------------------------------------------
 * 2025-08-25 | D. van Musschenbroek | Added CRUD/FLS enforcement (WoonstadCrudFlsGuard) + fault publishing.
 * 2025-08-18 | D. van Musschenbroek | Final fix: direct DML on FeedItem & Task due to ConnectApi errors.
 * 2025-08-17 | D. van Musschenbroek | Initial creation.
 *************************************************************************************************/
public with sharing class woonstadLogACallFormController {

    @AuraEnabled(cacheable=true)
    public static String getCaseDetails(String caseId) {
        if (String.isBlank(caseId)) {
            return null;
        }

        if (!Schema.sObjectType.Case.fields.CaseNumber.isAccessible()
         || !Schema.sObjectType.Case.fields.Subject.isAccessible()) {
            ApexFaultHandler.publishError(
                'FLS denied for CaseNumber/Subject',
                'woonstadLogACallFormController',
                'getCaseDetails'
            );
            throw new AuraHandledException('You do not have permission to view Case details.');
        }

        try {
            Case foundCase = [
                SELECT CaseNumber, Subject
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];
            return foundCase.CaseNumber + ' - ' + foundCase.Subject;
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadLogACallFormController', 'getCaseDetails', caseId);
            throw new AuraHandledException('Case not found for the provided ID.');
        }
    }

    /**
     * @description Returns a list of Contacts for a given Account, used to populate a combobox.
     * @param accountId The Account Id to query Contacts for.
     * @return List of Contacts (Id, Name) ordered by Name; empty when accountId is blank.
     * @throws AuraHandledException User-friendly message when access fails.
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByAccountId(String accountId) {
        if (String.isBlank(accountId)) {
            return new List<Contact>();
        }

        try {
            // CRUD gate for reading Contact
            WoonstadCrudFlsGuard.requireRead(Contact.SObjectType, 'woonstadLogACallFormController', 'getContactsByAccountId');

            List<Contact> contacts = [
                SELECT Id, Name
                FROM Contact
                WHERE AccountId = :accountId
                ORDER BY Name
            ];

            // Manually convert to SObject list for sanitizeForRead (some API versions require this)
            List<SObject> toSanitize = new List<SObject>();
            for (Contact c : contacts) {
                toSanitize.add(c);
            }

            List<SObject> sanitized = WoonstadCrudFlsGuard.sanitizeForRead(
                toSanitize,
                'woonstadLogACallFormController',
                'getContactsByAccountId',
                accountId
            );

            // Cast back to Contact
            List<Contact> result = new List<Contact>();
            for (SObject so : sanitized) {
                result.add((Contact) so);
            }
            return result;

        } catch (AuraHandledException ahx) {
            ApexFaultHandler.publishError(ahx, 'woonstadLogACallFormController', 'getContactsByAccountId');
            throw ahx;
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadLogACallFormController', 'getContactsByAccountId', accountId);
            throw new AuraHandledException('Failed to retrieve contacts.');
        }
    }

    /**
     * @description Logs a call by creating a Task and posting a FeedItem on the Case.
     */
    @AuraEnabled
    public static void logCall(String subject, String comments, String whoId, String caseId) {
        try {
            WoonstadCrudFlsGuard.requireCreate(Task.SObjectType, 'woonstadLogACallFormController', 'logCall');
            WoonstadCrudFlsGuard.requireCreate(FeedItem.SObjectType, 'woonstadLogACallFormController', 'logCall');

            Task newTask = new Task(
                Subject      = 'Call',
                Description  = 'Onderwerp: ' + (subject == null ? '' : subject) + '\n\nOpmerkingen:\n' + (comments == null ? '' : comments),
                WhoId        = whoId,
                WhatId       = caseId,
                Status       = 'Completed',
                Type         = 'Call',
                TaskSubtype  = 'Call',
                ActivityDate = System.today()
            );

            FeedItem post = new FeedItem(
                ParentId = caseId,
                Type     = 'CallLogPost',
                Body     = comments,
                Title    = subject
            );

            newTask = (Task) WoonstadCrudFlsGuard.sanitizeForCreate(newTask, 'woonstadLogACallFormController', 'logCall', caseId);
            post    = (FeedItem) WoonstadCrudFlsGuard.sanitizeForCreate(post,    'woonstadLogACallFormController', 'logCall', caseId);

            insert newTask;
            insert post;

        } catch (AuraHandledException ahx) {
            ApexFaultHandler.publishError(ahx, 'woonstadLogACallFormController', 'logCall', caseId);
            throw ahx;
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadLogACallFormController', 'logCall', caseId);
            throw new AuraHandledException('Error creating call log: ' + ex.getMessage());
        }
    }
}