/*************************************************************************************************
 * Class            : woonstadFlowCaseCallLogEmailService
 * Layer            : Orchestrator / Invocable
 * Purpose          : Flow entry point. Orchestrates Case + Request creation and emails.
 *
 * Security         : CRUD/FLS enforced in called services.
 * Faults           : Logs via ApexFaultHandler.publishError; returns detailed error to Flow for debugging.
 *
 * Owner            : Woonstad
 * Author           : Dennis van Musschenbroek
 * Created          : 2025-07-31
 * Last Modified    : 2025-10-07
 * ===============================================================================================
 * Description:
 * This invocable class is the main orchestrator for the nameplate request flow. It:
 * 1. Creates a Case and Request__c record based on Flow input
 * 2. Resolves the appropriate supplier for the request
 * 3. Sends confirmation emails to both supplier and renter
 * 4. Closes the Case after successful processing
 * 
 * Template Selection Logic:
 * - Renter email template is selected based on Account.Label__c field:
 *   * If Label__c = 'Stadswonen' (exact match) → uses 'Naamplaatje_Bevestigingsmail_naar_klant_Stadswonen'
 *   * For ALL other values → uses 'Naamplaatje_Bevestigingsmail_naar_klant_Woonstad' (default):
 *     - 'Woonstad'
 *     - 'Woonstad & Stadswonen' (combined label)
 *     - null or blank
 *     - any unknown value
 * - Supplier email uses standard template: 'Opdracht_Naamplaatje_voor_Leverancier'
 * 
 * Organization-Wide Email Addresses:
 * - ALL emails (both supplier and renter) are sent FROM organization-specific addresses using 
 *   Salesforce Organization-Wide Email Addresses (not just Reply-To)
 * - Woonstad emails: FROM test-info@woonstadrotterdam.nl
 * - Stadswonen emails: FROM test-info@stadswonenrotterdam.nl
 * - Same logic applies to BOTH supplier and renter emails
 * - IMPORTANT: These addresses MUST be configured in Salesforce Setup → Organization-Wide Addresses
 *   and verified before emails will be sent from them
 * - If not configured, emails will gracefully fall back to user's default email address
 * 
 * Error Handling:
 * - All exceptions are caught, logged via ApexFaultHandler, and returned to Flow
 * - Response.status field contains either 'SUCCESS' or detailed error message
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-10-07 | Modified | BREAKING CHANGE: Both supplier AND renter emails now use Org-Wide Email
 *                        | Updated supplier email to also use Organization-Wide Email Addresses
 *                        | All emails (supplier + renter) now sent FROM organization addresses
 *                        | Both emails use same FROM address based on Account.Label__c
 * 2025-10-07 | Modified | BREAKING CHANGE: Switched from Reply-To to Organization-Wide Email Addresses
 *                        | Emails now sent FROM test-info@woonstadrotterdam.nl or 
 *                        | test-info@stadswonenrotterdam.nl (not just Reply-To header)
 *                        | Updated WoonstadEmailService.sendRenterEmailAndAttachCopy call
 *                        | Renamed determineReplyToAddress() to determineOrgWideEmailAddress()
 *                        | Updated constants to FROM_EMAIL_* pattern for clarity
 *                        | Requires Organization-Wide Email Addresses to be configured in Salesforce Setup
 * 2025-10-07 | Modified | Added organization-specific reply-to email addresses
 *                        | Woonstad emails use test-info@woonstadrotterdam.nl
 *                        | Stadswonen emails use test-info@stadswonenrotterdam.nl
 *                        | Added helper method determineReplyToAddress() for email selection
 *                        | Updated WoonstadEmailService.sendRenterEmailAndAttachCopy signature
 * 2025-10-07 | Modified | Added conditional template selection based on Account.Label__c
 *                        | Only Stadswonen Label gets Stadswonen template
 *                        | All other values (Woonstad, null, blank, unknown) default to Woonstad template
 *                        | Added helper method determineRenterTemplateDevName() for clarity
 *                        | Removed unused DEVNAME_RENTER_DEFAULT constant
 * 2025-08-25 | DvM      | Weijntjes only when selected; added detailed error reporting to Flow.
 * 2025-08-12 | DvM      | Email hardening & manual supplier logging.
 * 2025-07-31 | DvM      | Initial version.
 *************************************************************************************************/
public with sharing class woonstadFlowCaseCallLogEmailService {

    // Email template constants
    // Renter templates: Stadswonen gets its own template, everything else defaults to Woonstad
    private static final String DEVNAME_RENTER_WOONSTAD   = 'Naamplaatje_Bevestigingsmail_naar_klant_Woonstad';
    private static final String DEVNAME_RENTER_STADSWONEN = 'Naamplaatje_Bevestigingsmail_naar_klant_Stadswonen';
    
    // Supplier template remains constant
    private static final String DEVNAME_SUPPLIER = 'Opdracht_Naamplaatje_voor_Leverancier';
    
    // Organization-Wide Email Addresses for FROM field
    // These are the actual email addresses emails will be sent FROM (not just Reply-To)
    // IMPORTANT: These MUST be configured as Organization-Wide Email Addresses in Salesforce Setup
    // Setup → Organization-Wide Addresses → Add and verify these addresses
    private static final String FROM_EMAIL_WOONSTAD   = 'test-info@woonstadrotterdam.nl';
    private static final String FROM_EMAIL_STADSWONEN = 'test-info@stadswonenrotterdam.nl';

    // ================= Invocable DTOs =================
    
    /**
     * @description Input wrapper for Flow invocable method
     *              Contains all necessary data to create Case, Request, and send emails
     */
    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;
        
        @InvocableVariable(required=true)
        public Id contactId;
        
        @InvocableVariable(required=false)
        public Id supplierTemplateId; // deprecated
        
        @InvocableVariable(required=false)
        public Id renterTemplateId;   // deprecated
        
        @InvocableVariable(required=true)
        public String caseOrigin;
        
        @InvocableVariable(required=true)
        public String nameplateText;
        
        @InvocableVariable(required=false)
        public String flowStartTime;
        
        @InvocableVariable(required=false)
        public String caseReason;
        
        @InvocableVariable(required=false)
        public String supplierNameInput;
        
        @InvocableVariable(required=false)
        public String supplierEmailInput;
        
        @InvocableVariable(required=false)
        public String supplierNote;
    }
    
    /**
     * @description Output wrapper returned to Flow after processing
     *              Contains created record Ids and processing status
     */
    public class Response {
        @InvocableVariable
        public Id caseId;
        
        @InvocableVariable
        public Id requestId;
        
        @InvocableVariable
        public String status;
        
        @InvocableVariable
        public String supplierApiName;
        
        @InvocableVariable
        public String supplierName;
        
        @InvocableVariable
        public String supplierEmail;
        
        @InvocableVariable
        public String weijntjesApiName;
        
        @InvocableVariable
        public String weijntjesName;
        
        @InvocableVariable
        public String weijntjesEmail;
    }

    /**
     * @description Main invocable method called by Flow
     *              Processes list of requests and returns corresponding responses
     * @param requests List of Request objects from Flow
     * @return List of Response objects with processing results
     */
    @InvocableMethod(label='Create Case, Request, and Send Email')
    public static List<Response> execute(List<Request> requests) {
        List<Response> out = new List<Response>();
        
        // Handle null or empty input
        if (requests == null || requests.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'execute called with null or empty requests list');
            return out;
        }

        // Process each request individually
        for (Request req : requests) {
            Response res = new Response();
            try {
                // Calculate processing time if flowStartTime provided
                Integer processMinutes = WoonstadFlowTimeUtil.tryParseMinutesSince(req.flowStartTime);

                // Load Account record (includes Label__c for template selection)
                Account acc = WoonstadSelectors.accountByIdRequired(req.accountId);
                
                // Normalize Case reason for consistent data
                String normalizedReason = WoonstadCaseReasonService.normalize(req.caseReason);

                // Build input object for Case/Request creation service
                WoonstadCaseRequestService.Input input = new WoonstadCaseRequestService.Input();
                input.account         = acc;
                input.accountId       = req.accountId;
                input.contactId       = req.contactId;
                input.caseOrigin      = req.caseOrigin;
                input.nameplateText   = req.nameplateText;
                input.caseReasonValue = normalizedReason;
                input.supplierNote    = req.supplierNote;
                input.processMinutes  = processMinutes;

                // Resolve supplier (handles both automatic and manual selection)
                WoonstadSupplierService.SupplierContext supplierCtx =
                    WoonstadSupplierService.resolveSupplier(
                        req.accountId, 
                        req.supplierNameInput, 
                        req.supplierEmailInput
                    );

                // Create Case and Request__c records
                WoonstadCaseRequestService.Result cr =
                    WoonstadCaseRequestService.createCaseAndRequest(input, supplierCtx);

                // ===== TEMPLATE & EMAIL ADDRESS RESOLUTION =====
                // Determine renter template based on Account.Label__c
                String renterTemplateDevName = determineRenterTemplateDevName(acc.Label__c);
                Id renterTemplateId = WoonstadEmailTemplateResolver.resolveByExactDevName(renterTemplateDevName);
                
                // Determine Organization-Wide Email Address based on Account.Label__c
                // This email will be used as the FROM address (not just Reply-To)
                String orgWideFromEmail = determineOrgWideEmailAddress(acc.Label__c);
                
                // Supplier template is always the same
                Id supplierTemplateId = WoonstadEmailTemplateResolver.resolveByDevNameContains(DEVNAME_SUPPLIER);

                // Log which template and FROM email were selected (helpful for debugging)
                System.debug(LoggingLevel.INFO, 'Selected renter template: ' + renterTemplateDevName + 
                            ' and FROM email: ' + orgWideFromEmail + 
                            ' based on Account.Label__c: ' + acc.Label__c);

                // Determine Contact Id to use as email merge target
                Id renterTargetId = WoonstadEmailService.determineRenterTargetId(acc, req.contactId);

                // ===== SEND EMAILS =====
                // Send email to supplier with order details
                // Uses same organization-specific FROM address as renter email
                WoonstadEmailService.sendSupplierEmailAndLog(
                    supplierTemplateId, 
                    cr.caseRecord, 
                    renterTargetId, 
                    supplierCtx.email, 
                    supplierCtx.name,
                    orgWideFromEmail  // Organization-Wide Email Address for FROM field
                );
                
                // Send confirmation email to renter with organization-specific FROM address
                // Uses Organization-Wide Email Address so email appears FROM test-info@woonstadrotterdam.nl
                // or test-info@stadswonenrotterdam.nl (not just Reply-To)
                WoonstadEmailService.sendRenterEmailAndAttachCopy(
                    renterTemplateId, 
                    cr.caseRecord, 
                    renterTargetId, 
                    acc.PersonEmail,
                    orgWideFromEmail  // Organization-Wide Email Address for FROM field
                );

                // Close the Case now that processing is complete
                WoonstadCaseRequestService.closeCase(cr.caseRecord);

                // Populate successful response
                res.caseId           = cr.caseRecord.Id;
                res.requestId        = cr.requestRecord.Id;
                res.status           = 'SUCCESS';
                res.supplierApiName  = supplierCtx.apiName;
                res.supplierName     = supplierCtx.name;
                res.supplierEmail    = supplierCtx.email;
                res.weijntjesApiName = supplierCtx.weijntjesApiName;
                res.weijntjesName    = supplierCtx.weijntjesName;
                res.weijntjesEmail   = supplierCtx.weijntjesEmail;

            } catch (Exception e) {
                // Log error to platform events for monitoring
                ApexFaultHandler.publishError(
                    e.getTypeName() + ': ' + e.getMessage(),
                    'woonstadFlowCaseCallLogEmailService',
                    'execute'
                );
                
                // Return detailed error to Flow for user feedback
                res.status = 'ERROR: ' + e.getTypeName() + ': ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'Error in woonstadFlowCaseCallLogEmailService.execute: ' + 
                            e.getMessage() + '\n' + e.getStackTraceString());
            }
            
            out.add(res);
        }
        
        return out;
    }

    /**
     * @description Determines which renter email template to use based on Account.Label__c
     *              This enables different organizations (Woonstad vs Stadswonen) to have
     *              their own branded confirmation emails.
     *              
     *              LOGIC: Only exact 'Stadswonen' (case-insensitive) gets the Stadswonen template.
     *                     Everything else defaults to the Woonstad template, including:
     *                     - null or blank values
     *                     - 'Woonstad'
     *                     - 'Woonstad & Stadswonen' (combined label)
     *                     - any other unknown values
     * 
     * @param accountLabel The value of Account.Label__c field
     * @return String DeveloperName of the appropriate EmailTemplate
     * @example 
     * determineRenterTemplateDevName('Stadswonen')             // returns 'Naamplaatje_Bevestigingsmail_naar_klant_Stadswonen'
     * determineRenterTemplateDevName('Woonstad')               // returns 'Naamplaatje_Bevestigingsmail_naar_klant_Woonstad'
     * determineRenterTemplateDevName('Woonstad & Stadswonen')  // returns 'Naamplaatje_Bevestigingsmail_naar_klant_Woonstad' (default)
     * determineRenterTemplateDevName(null)                     // returns 'Naamplaatje_Bevestigingsmail_naar_klant_Woonstad' (default)
     * determineRenterTemplateDevName('Other')                  // returns 'Naamplaatje_Bevestigingsmail_naar_klant_Woonstad' (default)
     */
    @TestVisible
    private static String determineRenterTemplateDevName(String accountLabel) {
        // Check for exact 'Stadswonen' match (case-insensitive) - the only exception case
        // NOTE: 'Woonstad & Stadswonen' will NOT match here and defaults to Woonstad template
        if (String.isNotBlank(accountLabel) && accountLabel.equalsIgnoreCase('Stadswonen')) {
            System.debug(LoggingLevel.INFO, 'Account.Label__c = "' + accountLabel + '", using Stadswonen template');
            return DEVNAME_RENTER_STADSWONEN;
        }
        
        // Default to Woonstad for ALL other cases:
        // - null or blank
        // - 'Woonstad'
        // - 'Woonstad & Stadswonen' (combined)
        // - any unknown values
        if (String.isBlank(accountLabel)) {
            System.debug(LoggingLevel.INFO, 'Account.Label__c is blank/null, using Woonstad template (default)');
        } else {
            System.debug(LoggingLevel.INFO, 'Account.Label__c = "' + accountLabel + '", using Woonstad template (default)');
        }
        return DEVNAME_RENTER_WOONSTAD;
    }

    /**
     * @description Determines which Organization-Wide Email Address to use based on Account.Label__c
     *              This ensures renters receive emails FROM the correct organization email address.
     *              
     *              DIFFERENCE FROM REPLY-TO:
     *              - Reply-To: Email appears from user, but replies go to specified address
     *              - Org-Wide Address: Email appears FROM the specified address directly
     *              
     *              LOGIC: Same as template selection - only exact 'Stadswonen' gets Stadswonen email.
     *                     Everything else defaults to Woonstad email address.
     *              
     *              SETUP REQUIRED:
     *              These email addresses MUST be configured in Salesforce as Organization-Wide Email Addresses:
     *              Setup → Organization-Wide Addresses → Add
     *              - Display Name: Woonstad Rotterdam
     *                Email Address: test-info@woonstadrotterdam.nl
     *                Allow All Profiles: ✓
     *              - Display Name: Stadswonen Rotterdam
     *                Email Address: test-info@stadswonenrotterdam.nl
     *                Allow All Profiles: ✓
     *              
     *              Both addresses must be verified by Salesforce before use.
     *              If not configured, emails will fall back to user's default address.
     * 
     * @param accountLabel The value of Account.Label__c field
     * @return String Email address to use as FROM address via Organization-Wide Email Address
     * @example 
     * determineOrgWideEmailAddress('Stadswonen')             // returns 'test-info@stadswonenrotterdam.nl'
     * determineOrgWideEmailAddress('Woonstad')               // returns 'test-info@woonstadrotterdam.nl'
     * determineOrgWideEmailAddress('Woonstad & Stadswonen')  // returns 'test-info@woonstadrotterdam.nl' (default)
     * determineOrgWideEmailAddress(null)                     // returns 'test-info@woonstadrotterdam.nl' (default)
     */
    @TestVisible
    private static String determineOrgWideEmailAddress(String accountLabel) {
        // Check for exact 'Stadswonen' match (case-insensitive) - the only exception case
        // NOTE: 'Woonstad & Stadswonen' will NOT match here and defaults to Woonstad email
        if (String.isNotBlank(accountLabel) && accountLabel.equalsIgnoreCase('Stadswonen')) {
            System.debug(LoggingLevel.INFO, 'Account.Label__c = "' + accountLabel + '", using Stadswonen FROM email');
            return FROM_EMAIL_STADSWONEN;
        }
        
        // Default to Woonstad email for ALL other cases:
        // - null or blank
        // - 'Woonstad'
        // - 'Woonstad & Stadswonen' (combined)
        // - any unknown values
        System.debug(LoggingLevel.INFO, 'Using Woonstad FROM email (default) for Label__c: ' + 
                    (String.isBlank(accountLabel) ? 'blank/null' : '"' + accountLabel + '"'));
        return FROM_EMAIL_WOONSTAD;
    }
}