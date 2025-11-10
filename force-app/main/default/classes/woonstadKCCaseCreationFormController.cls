/*************************************************************************************************
 * Apex Class       : woonstadKCCaseCreationFormController
 * Layer            : Service (Apex Controller for LWC)
 * Purpose          : Data access and Case creation for the woonstadKCCaseCreationForm LWC.
 *
 * Responsibilities :
 *  - Resolve Account context from Account/Contact
 *  - Provide initial form data (Account name + Contact options)
 *  - Provide open Cases for an Account
 *  - Create a new Case with CRUD/FLS enforcement
 *
 * Security         :
 *  - with sharing (respects sharing)
 *  - CRUD/FLS enforced via WoonstadCrudFlsGuard (+ stripInaccessible)
 *  - User-facing errors via AuraHandledException
 *
 * Fault Handling   :
 *  - Publishes Apex_Fault__e via ApexFaultHandler on access violations and exceptions
 *
 * Transactions     :
 *  - No DML inside loops; single-record DML
 *
 * Author           : Dennis van Musschenbroek
 * Owner            : Woonstad KC
 * Created          : 2025-08-22
 * Last Modified    : 2025-11-10
 * ===============================================================================================
 * Change Log
 * -----------------------------------------------------------------------------------------------
 * 2025-11-10 | DvM | FIXED: Changed RecordType from 'Question' to 'Request' for Name Plate Cases
 * 2025-11-10 | DvM | ROOT CAUSE: All Name Plate Cases in both UAT and PROD use 'Request' RecordType
 * 2025-11-10 | DvM | VERIFICATION: Queried WSRUAT and WSRPROD - 100% of Name Plate use Request RT
 * 2025-08-25 | DvM | Integrated WoonstadCrudFlsGuard + ApexFaultHandler across all methods; sanitized READs.
 * 2025-08-22 | DvM | Formatting, DTOs, record type caching, safer queries.
 *************************************************************************************************/
public with sharing class woonstadKCCaseCreationFormController {

    // ------------------------------------------------------------------------------------------------
    // Constants / Caches
    // ------------------------------------------------------------------------------------------------
    private static final String  CASE_SOBJECT                  = 'Case';
    private static final String  REQUEST_RECORDTYPE_DEVELOPER  = 'Request';  // Changed from 'Question'
    private static final Integer CONTACT_QUERY_LIMIT           = 500;
    private static final Integer CASE_QUERY_LIMIT              = 500;

    // Cache for RecordType Id lookups per SObjectType+DeveloperName
    private static final Map<String, Id> RECORD_TYPE_CACHE = new Map<String, Id>();

    // ------------------------------------------------------------------------------------------------
    // DTOs
    // ------------------------------------------------------------------------------------------------
    public class InitialDataDTO {
        @AuraEnabled public String          accountName    { get; set; }
        @AuraEnabled public List<OptionDTO> contactOptions { get; set; }
        @AuraEnabled public String          prefillLabel   { get; set; }
    }
    public class OptionDTO {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        public OptionDTO(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    // ------------------------------------------------------------------------------------------------
    // Public API (AuraEnabled)
    // ------------------------------------------------------------------------------------------------

    /**
     * Fetches initial data (account name + contacts for that account) based on a context recordId
     * that may be an Account or a Contact.
     */
    @AuraEnabled(cacheable=true)
    public static InitialDataDTO getInitialData(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('Record ID is required.');
        }

        try {
            Id accountId = resolveAccountId(recordId);

            // CRUD gates for READ
            WoonstadCrudFlsGuard.requireRead(Account.SObjectType, 'woonstadKCCaseCreationFormController', 'getInitialData');
            WoonstadCrudFlsGuard.requireRead(Contact.SObjectType, 'woonstadKCCaseCreationFormController', 'getInitialData');

            // Query Account (Name + Label)
            Account acc = [
                SELECT Name, Label__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];
            // Sanitize READ
            List<SObject> accSanitized = WoonstadCrudFlsGuard.sanitizeForRead(
                new List<SObject>{ acc },
                'woonstadKCCaseCreationFormController',
                'getInitialData',
                accountId
            );
            Account safeAcc = (Account) accSanitized[0];

            // Query Contacts for picklist
            List<Contact> contacts = [
                SELECT Id, Name
                FROM Contact
                WHERE AccountId = :accountId
                ORDER BY Name
                LIMIT :CONTACT_QUERY_LIMIT
            ];
            // Sanitize READ for Contacts
            List<SObject> contactsAsSobj = new List<SObject>();
            for (Contact c : contacts) contactsAsSobj.add(c);
            List<SObject> contactsSanitized = WoonstadCrudFlsGuard.sanitizeForRead(
                contactsAsSobj,
                'woonstadKCCaseCreationFormController',
                'getInitialData',
                accountId
            );

            // Build DTO
            InitialDataDTO dto = new InitialDataDTO();
            dto.accountName = safeAcc.Name;

            if (safeAcc.Label__c == 'Stadswonen' || safeAcc.Label__c == 'Woonstad') {
                dto.prefillLabel = safeAcc.Label__c;
            } else {
                dto.prefillLabel = null;
            }


            dto.contactOptions = new List<OptionDTO>();
            for (SObject so : contactsSanitized) {
                Contact c = (Contact) so;
                dto.contactOptions.add(new OptionDTO(c.Name, (String) String.valueOf(c.Id)));
            }
            return dto;

        } catch (AuraHandledException ahx) {
            ApexFaultHandler.publishError(ahx, 'woonstadKCCaseCreationFormController', 'getInitialData');
            throw ahx;
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadKCCaseCreationFormController', 'getInitialData', recordId);
            throw new AuraHandledException('Kon initiële gegevens niet ophalen.');
        }
    }

    /**
     * Returns open Cases for an Account.
     */
    @AuraEnabled(cacheable=true)
    public static List<Case> getOpenCases(Id accountId) {
        if (accountId == null) {
            return new List<Case>();
        }

        try {
            WoonstadCrudFlsGuard.requireRead(Case.SObjectType, 'woonstadKCCaseCreationFormController', 'getOpenCases');

            List<Case> cases = [
                SELECT Id, CaseNumber, Subject, Description, Status
                FROM Case
                WHERE AccountId = :accountId
                  AND IsClosed = false
                ORDER BY CreatedDate DESC
                LIMIT :CASE_QUERY_LIMIT
            ];

            // Sanitize READ before returning to UI
            List<SObject> asSobj = new List<SObject>();
            for (Case c : cases) asSobj.add(c);
            List<SObject> sanitized = WoonstadCrudFlsGuard.sanitizeForRead(
                asSobj,
                'woonstadKCCaseCreationFormController',
                'getOpenCases',
                accountId
            );

            List<Case> result = new List<Case>();
            for (SObject so : sanitized) result.add((Case) so);
            return result;

        } catch (AuraHandledException ahx) {
            ApexFaultHandler.publishError(ahx, 'woonstadKCCaseCreationFormController', 'getOpenCases');
            throw ahx;
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadKCCaseCreationFormController', 'getOpenCases', accountId);
            throw new AuraHandledException('Kon open zaken niet ophalen.');
        }
    }

    /**
     * Creates a new Case.
     */
    @AuraEnabled
    public static Id createCase(
        Id      accountId,
        Id      contactId,
        String  subject,
        String  description,
        String  caseType,
        String  caseOrigin,
        String  caseLabel
    ) {
        if (accountId == null) {
            throw new AuraHandledException('AccountId is verplicht.');
        }
        if (String.isBlank(subject)) {
            throw new AuraHandledException('Onderwerp is verplicht.');
        }

        try {
            // CRUD gate (CREATE Case)
            WoonstadCrudFlsGuard.requireCreate(Case.SObjectType, 'woonstadKCCaseCreationFormController', 'createCase');

            Id rtId = getRecordTypeId(CASE_SOBJECT, REQUEST_RECORDTYPE_DEVELOPER);
            if (rtId == null) {
                ApexFaultHandler.publishError('Recordtype "Request" niet gevonden.', 'woonstadKCCaseCreationFormController', 'createCase');
                throw new AuraHandledException('Recordtype "Request" is niet gevonden.');
            }

            Case draft = new Case(
                AccountId    = accountId,
                ContactId    = contactId,
                Subject      = subject,
                Description  = description,
                Status       = 'In Progress',
                Origin       = caseOrigin,
                RecordTypeId = rtId,
                Type         = caseType,
                Label__c     = caseLabel
            );

            // FLS sanitize (CREATE)
            draft = (Case) WoonstadCrudFlsGuard.sanitizeForCreate(
                draft,
                'woonstadKCCaseCreationFormController',
                'createCase',
                accountId
            );

            insert draft;
            return draft.Id;

        } catch (AuraHandledException ahx) {
            ApexFaultHandler.publishError(ahx, 'woonstadKCCaseCreationFormController', 'createCase', accountId);
            throw ahx;
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadKCCaseCreationFormController', 'createCase', accountId);
            throw new AuraHandledException('Kon zaak niet aanmaken: ' + ex.getMessage());
        }
    }

    // ------------------------------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------------------------------

    /**
     * Resolves an Account Id from a context Id that may be Account or Contact.
     */
    private static Id resolveAccountId(Id contextId) {
        try {
            String apiName = contextId.getSObjectType().getDescribe().getName();

            if (apiName == Account.SObjectType.getDescribe().getName()) {
                return contextId;
            }
            if (apiName == Contact.SObjectType.getDescribe().getName()) {
                // CRUD gate for Contact read
                WoonstadCrudFlsGuard.requireRead(Contact.SObjectType, 'woonstadKCCaseCreationFormController', 'resolveAccountId');

                Contact c = [
                    SELECT AccountId
                    FROM Contact
                    WHERE Id = :contextId
                    LIMIT 1
                ];
                // Sanitize READ for the Contact before using its fields
                List<SObject> sanitized = WoonstadCrudFlsGuard.sanitizeForRead(
                    new List<SObject>{ c },
                    'woonstadKCCaseCreationFormController',
                    'resolveAccountId',
                    contextId
                );
                Contact safeC = (Contact) sanitized[0];

                if (safeC.AccountId == null) {
                    throw new AuraHandledException('Contact is niet gekoppeld aan een Account.');
                }
                return safeC.AccountId;
            }
            throw new AuraHandledException('Dit object wordt niet ondersteund voor deze actie.');

        } catch (AuraHandledException ahx) {
            ApexFaultHandler.publishError(ahx, 'woonstadKCCaseCreationFormController', 'resolveAccountId', contextId);
            throw ahx;
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadKCCaseCreationFormController', 'resolveAccountId', contextId);
            throw new AuraHandledException('Kon Account-context niet bepalen.');
        }
    }

    /**
     * RecordType Id lookup with simple cache by SObjectType+DeveloperName.
     */
    private static Id getRecordTypeId(String sobjectApiName, String developerName) {
        String key = sobjectApiName + '::' + developerName;
        if (RECORD_TYPE_CACHE.containsKey(key)) {
            return RECORD_TYPE_CACHE.get(key);
        }

        try {
            List<RecordType> rts = [
                SELECT Id
                FROM RecordType
                WHERE SObjectType  = :sobjectApiName
                  AND DeveloperName = :developerName
                LIMIT 1
            ];
            Id rtId = (rts.isEmpty() ? null : rts[0].Id);
            RECORD_TYPE_CACHE.put(key, rtId);
            return rtId;

        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadKCCaseCreationFormController', 'getRecordTypeId');
            return null;
        }
    }
}