/*************************************************************************************************
 * Class            : WoonstadEmailService
 * Layer            : Service
 * Purpose          : Encapsulate email sending (supplier + renter), manual logging & files.
 *
 * Owner            : Woonstad
 * Author           : Dennis van Musschenbroek
 * Created          : 2025-08-25
 * Last Modified    : 2025-10-07
 * ===============================================================================================
 * Description:
 * This service class handles all email sending operations for the nameplate flow, including:
 * 1. Sending emails to suppliers with manual logging (uses Org-Wide Email Address)
 * 2. Sending confirmation emails to renters with file attachments (uses Org-Wide Email Address)
 * 3. Supporting organization-specific "from" addresses via Organization-Wide Email Addresses
 * 
 * The class ensures proper email logging, file attachments, and CRUD/FLS security.
 * 
 * IMPORTANT: Organization-Wide Email Addresses
 * This class uses Salesforce Organization-Wide Email Addresses to send ALL emails (both supplier
 * and renter) FROM specific addresses (not just Reply-To). For this to work, you MUST configure
 * Organization-Wide Email Addresses in Salesforce Setup:
 * 
 * Setup → Organization-Wide Addresses → Add
 * - Display Name: Woonstad Rotterdam
 * - Email Address: test-info@woonstadrotterdam.nl
 * - Allow All Profiles to Use This From Address: ✓
 * 
 * - Display Name: Stadswonen Rotterdam  
 * - Email Address: test-info@stadswonenrotterdam.nl
 * - Allow All Profiles to Use This From Address: ✓
 * 
 * These addresses must be verified by Salesforce before they can be used.
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-10-07 | Modified | BREAKING CHANGE: Both supplier AND renter emails now use Org-Wide Email
 *                        | Updated sendSupplierEmailAndLog() to accept orgWideFromEmail parameter
 *                        | Supplier emails now sent FROM test-info@woonstadrotterdam.nl or 
 *                        | test-info@stadswonenrotterdam.nl (same logic as renter emails)
 *                        | All emails (supplier + renter) now use Organization-Wide Email Addresses
 * 2025-10-07 | Modified | BREAKING CHANGE: Switched from setReplyTo() to Organization-Wide Email
 *                        | Addresses for actual FROM address control
 *                        | Added getOrgWideEmailAddressId() method to query OrgWideEmailAddress
 *                        | Updated sendRenterEmailAndAttachCopy() to accept orgWideFromEmail
 *                        | Emails now sent FROM test-info@woonstadrotterdam.nl or 
 *                        | test-info@stadswonenrotterdam.nl instead of using Reply-To
 *                        | Falls back gracefully if Organization-Wide Address not configured
 * 2025-10-07 | Modified | Added replyToAddress parameter to sendRenterEmailAndAttachCopy
 *                        | Enables organization-specific reply-to addresses (Woonstad vs Stadswonen)
 *                        | Updated method signature and documentation
 * 2025-08-25 | DvM      | Align to WoonstadCrudFlsGuard.require* + Security.stripInaccessible.
 * 2025-08-25 | DvM      | Switch selectors to top-level methods on WoonstadSelectors.
 *************************************************************************************************/
public with sharing class WoonstadEmailService {

    /**
     * @description Determines the appropriate Contact Id to use as the target for email merge
     *              Prioritizes PersonContactId from Account, falls back to provided contactId
     * @param acc Account record (should be PersonAccount)
     * @param fallbackContactId Contact Id to use if PersonContactId is not available
     * @return Id of Contact to use as merge target
     */
    public static Id determineRenterTargetId(Account acc, Id fallbackContactId) {
        if (acc != null && acc.PersonContactId != null) return acc.PersonContactId;
        return fallbackContactId;
    }
    
    /**
     * @description Queries for Organization-Wide Email Address Id by email address
     *              This allows emails to be sent FROM the specified address (not just Reply-To)
     *              
     *              HOW IT WORKS:
     *              1. Salesforce Organization-Wide Email Addresses must be configured in Setup
     *              2. This method queries the OrgWideEmailAddress object to find the matching record
     *              3. The returned Id can be used with setOrgWideEmailAddressId() on SingleEmailMessage
     *              4. The email will then be sent FROM that address (not just Reply-To)
     *              
     *              SETUP REQUIRED:
     *              Go to Setup → Organization-Wide Addresses and add:
     *              - test-info@woonstadrotterdam.nl (for Woonstad)
     *              - test-info@stadswonenrotterdam.nl (for Stadswonen)
     *              Both must be verified by Salesforce before use.
     *              
     * @param emailAddress Email address to look up (e.g. 'test-info@woonstadrotterdam.nl')
     * @return Id of matching OrgWideEmailAddress record, or null if not found
     * @example
     * Id orgWideId = getOrgWideEmailAddressId('test-info@woonstadrotterdam.nl');
     * if (orgWideId != null) {
     *     mail.setOrgWideEmailAddressId(orgWideId);
     * }
     */
    public static Id getOrgWideEmailAddressId(String emailAddress) {
        // Validate input
        if (String.isBlank(emailAddress)) {
            System.debug(LoggingLevel.WARN, 'getOrgWideEmailAddressId: emailAddress is blank');
            return null;
        }
        
        try {
            // Query for Organization-Wide Email Address by exact email match
            // Note: This query requires the Organization-Wide Email Address to be set up in Salesforce Setup
            List<OrgWideEmailAddress> orgWideAddresses = [
                SELECT Id, Address, DisplayName 
                FROM OrgWideEmailAddress 
                WHERE Address = :emailAddress
                LIMIT 1
            ];
            
            if (orgWideAddresses.isEmpty()) {
                // Organization-Wide Address not found - log warning but don't fail
                // Email will still be sent, just not from the specified address
                System.debug(LoggingLevel.WARN, 
                    'Organization-Wide Email Address not found for: ' + emailAddress + 
                    '. Email will be sent from default user address. ' +
                    'Please configure this address in Setup → Organization-Wide Addresses.');
                return null;
            }
            
            // Success - log and return the Id
            System.debug(LoggingLevel.INFO, 
                'Found Organization-Wide Email Address: ' + orgWideAddresses[0].DisplayName + 
                ' <' + orgWideAddresses[0].Address + '>');
            return orgWideAddresses[0].Id;
            
        } catch (QueryException e) {
            // Handle query errors gracefully
            System.debug(LoggingLevel.ERROR, 
                'Error querying Organization-Wide Email Address: ' + e.getMessage());
            return null;
        }
    }

    // ===================== Supplier email =====================
    
    /**
     * @description Sends email to supplier and creates manual activity log with file attachment
     *              Uses Organization-Wide Email Address to send FROM the specified email
     *              
     *              Same logic as renter emails - uses organization-specific FROM address
     *              based on which organization (Woonstad or Stadswonen) is processing the request.
     * 
     * @param templateId EmailTemplate Id to use for the email
     * @param c Case record to associate the email with
     * @param renterTargetContactId Contact Id to use for template merge (must be valid Contact)
     * @param toAddress Email address of the supplier
     * @param supplierName Name of the supplier (for logging purposes)
     * @param orgWideFromEmail Email address to use as FROM address via Organization-Wide Email Address
     *                         Example: test-info@woonstadrotterdam.nl or test-info@stadswonenrotterdam.nl
     *                         If not configured in Salesforce, email will be sent from user's default address
     */
    public static void sendSupplierEmailAndLog(
        Id templateId,
        Case c,
        Id renterTargetContactId,
        String toAddress,
        String supplierName,
        String orgWideFromEmail
    ) {
        if (String.isBlank(toAddress)) {
            System.debug(LoggingLevel.ERROR, 'Supplier email NOT sent: recipient blank');
            return;
        }
        if (templateId == null) {
            System.debug(LoggingLevel.ERROR, 'Supplier email NOT sent: templateId null');
            return;
        }
        if (renterTargetContactId == null || !String.valueOf(renterTargetContactId).startsWith('003')) {
            System.debug(LoggingLevel.ERROR, 'Supplier email NOT sent: renterTarget must be Contact.');
            return;
        }

        // Send supplier email via template (no activity log; we log manually)
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(templateId);
        mail.setWhatId(c.Id);
        mail.setTargetObjectId(renterTargetContactId);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setSaveAsActivity(false);
        mail.setToAddresses(new List<String>{ toAddress });
        
        // Use Organization-Wide Email Address to send FROM the specified address
        // This makes supplier emails appear FROM test-info@woonstadrotterdam.nl or 
        // test-info@stadswonenrotterdam.nl instead of the user's email address
        if (String.isNotBlank(orgWideFromEmail)) {
            // Query for the Organization-Wide Email Address Id
            Id orgWideId = getOrgWideEmailAddressId(orgWideFromEmail);
            
            if (orgWideId != null) {
                // SUCCESS: Set the Organization-Wide Email Address
                // Email will be sent FROM the specified address (not just Reply-To)
                mail.setOrgWideEmailAddressId(orgWideId);
                System.debug(LoggingLevel.INFO, 
                    'Supplier email will be sent FROM: ' + orgWideFromEmail + 
                    ' (Organization-Wide Email Address)');
            } else {
                // FALLBACK: Organization-Wide Address not found
                // Email will be sent from user's default address
                System.debug(LoggingLevel.WARN, 
                    'Could not find Organization-Wide Email Address for: ' + orgWideFromEmail + 
                    '. Supplier email will be sent from user default address.');
            }
        }

        Messaging.SendEmailResult[] r = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail }, false);
        if (r == null || r.isEmpty() || !r[0].isSuccess()) {
            String err = (r != null && !r.isEmpty() && r[0].getErrors() != null && !r[0].getErrors().isEmpty())
                ? r[0].getErrors()[0].getMessage()
                : 'Unknown send failure';
            System.debug(LoggingLevel.ERROR, 'Supplier email FAILED: ' + err);
        } else {
            System.debug(LoggingLevel.WARN, 'Supplier email SENT to ' + toAddress);
        }

        // Manual log to EmailMessage + attach merged copy as ContentVersion
        User sender = WoonstadSelectors.runningUser();
        EmailTemplate tmpl = WoonstadSelectors.emailTemplateByIdRequired(templateId);

        WoonstadMergeService.MergeInput mi = new WoonstadMergeService.MergeInput();
        mi.templateSubject = tmpl.Subject;
        mi.templateBodyHtmlOrText = (tmpl.HtmlValue != null ? tmpl.HtmlValue : tmpl.Body);
        mi.caseRecord = c;
        mi.account = WoonstadSelectors.accountByIdRequired(c.AccountId);
        mi.sender = sender;

        WoonstadMergeService.MergeOutput mo = WoonstadMergeService.render(mi);

        EmailMessage emDraft = new EmailMessage(
            ParentId    = c.Id,
            Status      = '3', // Sent
            FromAddress = orgWideFromEmail,
            FromName    = orgWideFromEmail,
            ToAddress   = toAddress,
            Subject     = mo.subjectMerged,
            HtmlBody    = mo.bodyHtmlMerged,
            TextBody    = mo.bodyTextMerged,
            MessageDate = System.now(),
            Incoming    = false
        );

        WoonstadCrudFlsGuard.requireCreate(EmailMessage.SObjectType, 'WoonstadEmailService', 'sendSupplierEmailAndLog');
        emDraft = (EmailMessage)Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{ emDraft }).getRecords()[0];
        insert emDraft;

        String fileBody = 'Email sent to Supplier: ' + toAddress +
                          '\nTemplate: ' + tmpl.DeveloperName + ' (' + tmpl.Name + ')' +
                          '\nCase: ' + c.CaseNumber +
                          '\nFrom Address (Org-Wide): ' + (String.isNotBlank(orgWideFromEmail) ? orgWideFromEmail : 'Not set (user default)') +
                          '\nSubject: ' + mo.subjectMerged +
                          '\n\n' + mo.bodyTextForFile;

        ContentVersion cvDraft = new ContentVersion(
            Title = 'Email Confirmation (Supplier) - ' + c.CaseNumber,
            PathOnClient = 'CaseEmailConfirmationSupplier.txt',
            VersionData = Blob.valueOf(fileBody),
            Origin = 'H'
        );

        WoonstadCrudFlsGuard.requireCreate(ContentVersion.SObjectType, 'WoonstadEmailService', 'sendSupplierEmailAndLog');
        cvDraft = (ContentVersion)Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{ cvDraft }).getRecords()[0];
        insert cvDraft;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cvDraft.Id].ContentDocumentId;

        ContentDocumentLink linkDraft = new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = c.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        WoonstadCrudFlsGuard.requireCreate(ContentDocumentLink.SObjectType, 'WoonstadEmailService', 'sendSupplierEmailAndLog');
        linkDraft = (ContentDocumentLink)Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{ linkDraft }).getRecords()[0];
        insert linkDraft;
    }

    // ===================== Renter email =====================
    
    /**
     * @description Sends confirmation email to renter and attaches a copy to the Case
     *              Uses Organization-Wide Email Address to send FROM the specified email
     *              
     *              HOW IT WORKS:
     *              1. Queries for Organization-Wide Email Address Id using orgWideFromEmail
     *              2. If found, uses setOrgWideEmailAddressId() to send FROM that address
     *              3. If not found, email is sent from default user address with warning logged
     *              4. Creates EmailMessage activity log and attaches copy to Case
     *              
     *              DIFFERENCE FROM REPLY-TO:
     *              - Reply-To: Email shows FROM user, but replies go to specified address
     *              - Org-Wide Address: Email shows FROM specified address directly
     *              
     *              SETUP REQUIRED:
     *              Configure Organization-Wide Email Addresses in Salesforce Setup:
     *              Setup → Organization-Wide Addresses → Add
     *              - test-info@woonstadrotterdam.nl (Woonstad)
     *              - test-info@stadswonenrotterdam.nl (Stadswonen)
     * 
     * @param templateId EmailTemplate Id to use for the email
     * @param c Case record to associate the email with
     * @param renterTargetContactId Contact Id to use for template merge
     * @param toAddress Email address of the renter
     * @param orgWideFromEmail Email address to use as FROM address via Organization-Wide Email Address
     *                         Example: test-info@woonstadrotterdam.nl or test-info@stadswonenrotterdam.nl
     *                         If not configured in Salesforce, email will be sent from user's default address
     */
    public static void sendRenterEmailAndAttachCopy(
        Id templateId,
        Case c,
        Id renterTargetContactId,
        String toAddress,
        String orgWideFromEmail
    ) {
        // Validate inputs
        if (String.isBlank(toAddress)) {
            System.debug(LoggingLevel.WARN, 'Skipping renter email: Account.PersonEmail is blank');
            return;
        }
        if (templateId == null || renterTargetContactId == null) {
            System.debug(LoggingLevel.ERROR, 'Renter email NOT sent: templateId/target is null');
            return;
        }

        // Native email send + activity log
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(templateId);
        mail.setWhatId(c.Id);
        mail.setSaveAsActivity(true);
        mail.setTargetObjectId(renterTargetContactId);
        mail.setToAddresses(new List<String>{ toAddress });
        
        // Use Organization-Wide Email Address to send FROM the specified address
        // This makes the email appear FROM test-info@woonstadrotterdam.nl or test-info@stadswonenrotterdam.nl
        // instead of the user's email address
        if (String.isNotBlank(orgWideFromEmail)) {
            // Query for the Organization-Wide Email Address Id
            Id orgWideId = getOrgWideEmailAddressId(orgWideFromEmail);
            
            if (orgWideId != null) {
                // SUCCESS: Set the Organization-Wide Email Address
                // Email will be sent FROM the specified address (not just Reply-To)
                mail.setOrgWideEmailAddressId(orgWideId);
                System.debug(LoggingLevel.INFO, 
                    'Renter email will be sent FROM: ' + orgWideFromEmail + 
                    ' (Organization-Wide Email Address)');
            } else {
                // FALLBACK: Organization-Wide Address not found
                // Email will be sent from user's default address
                // This is not an error - the email will still be sent
                System.debug(LoggingLevel.WARN, 
                    'Could not find Organization-Wide Email Address for: ' + orgWideFromEmail + 
                    '. Email will be sent from user default address. ' +
                    'To send FROM this address, configure it in Setup → Organization-Wide Addresses.');
            }
        }
        
        // Send the email
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

        // Attach a merged copy as ContentVersion (for record keeping)
        User sender = WoonstadSelectors.runningUser();
        EmailTemplate tmpl = WoonstadSelectors.emailTemplateByIdRequired(templateId);

        WoonstadMergeService.MergeInput mi = new WoonstadMergeService.MergeInput();
        mi.templateSubject = tmpl.Subject;
        mi.templateBodyHtmlOrText = (tmpl.HtmlValue != null ? tmpl.HtmlValue : tmpl.Body);
        mi.caseRecord = c;
        mi.account = WoonstadSelectors.accountByIdRequired(c.AccountId);
        mi.sender = sender;

        WoonstadMergeService.MergeOutput mo = WoonstadMergeService.render(mi);

        String fileBody = 'Email sent to Renter: ' + toAddress +
                          '\nTemplate: ' + tmpl.DeveloperName + ' (' + tmpl.Name + ')' +
                          '\nCase: ' + c.CaseNumber +
                          '\nFrom Address (Org-Wide): ' + (String.isNotBlank(orgWideFromEmail) ? orgWideFromEmail : 'Not set (user default)') +
                          '\nSubject: ' + mo.subjectMerged +
                          '\n\n' + mo.bodyTextForFile;

        ContentVersion cvDraft = new ContentVersion(
            Title = 'Email Confirmation (Renter) - ' + c.CaseNumber,
            PathOnClient = 'CaseEmailConfirmationRenter.txt',
            VersionData = Blob.valueOf(fileBody),
            Origin = 'H'
        );

        WoonstadCrudFlsGuard.requireCreate(ContentVersion.SObjectType, 'WoonstadEmailService', 'sendRenterEmailAndAttachCopy');
        cvDraft = (ContentVersion)Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{ cvDraft }).getRecords()[0];
        insert cvDraft;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cvDraft.Id].ContentDocumentId;

        ContentDocumentLink linkDraft = new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = c.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        WoonstadCrudFlsGuard.requireCreate(ContentDocumentLink.SObjectType, 'WoonstadEmailService', 'sendRenterEmailAndAttachCopy');
        linkDraft = (ContentDocumentLink)Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{ linkDraft }).getRecords()[0];
        insert linkDraft;
    }
}