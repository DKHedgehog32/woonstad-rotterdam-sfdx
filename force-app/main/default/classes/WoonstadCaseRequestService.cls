/*************************************************************************************************
 * Class            : WoonstadCaseRequestService
 * Layer            : Service
 * Purpose          : Create/update Case + Request__c with CRUD/FLS gates and sanitization.
 *
 * Hardening        :
 *  - Validates restricted picklists BEFORE DML (Case.Origin, Case_Reason__c,
 *    Request__c.Type__c, Request__c.Request_Status__c, and Supplier_Name_Plate__c).
 *  - If a desired value isn’t present, we log WARN and set NULL to avoid FIELD_INTEGRITY errors.
 *
 * Owner            : Woonstad
 * Author           : Dennis van Musschenbroek
 * Created          : 2025-08-25
 * Last Modified    : 2025-08-25
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-08-25 | DvM | Picklist validation incl. Supplier_Name_Plate__c; Origin made picklist-safe.
 * 2025-08-25 | DvM | CRUD via require*; FLS via Security.stripInaccessible.
 *************************************************************************************************/


public with sharing class WoonstadCaseRequestService {
/**
    // ------------ DTOs ------------
    public class Input {
        public Account account;
        public Id accountId;
        public Id contactId;
        public String caseOrigin;
        public String nameplateText;
        public String caseReasonValue;
        public String supplierNote;
        public Integer processMinutes;
    }

    public class Result {
        public Case caseRecord;
        public Request__c requestRecord;
    }

    // ------------ API ------------
    public static Result createCaseAndRequest(Input inData, WoonstadSupplierService.SupplierContext supplierCtx) {
        if (inData == null || inData.account == null) {
            throw new AuraHandledException('Account is required.');
        }

        Id runningUserId = UserInfo.getUserId();

        // --- Validate/normalize picklists before DML ---
        String safeCaseReason  = ensureCaseReason(inData.caseReasonValue);
        String safeCaseOrigin  = ensurePicklistValue(Case.Origin, inData.caseOrigin, 'Case.Origin');

        // --- Build Case ---
        Case cDraft = new Case(
            OwnerId = runningUserId,
            AccountId = inData.accountId,
            Origin = safeCaseOrigin,
            Subject = 'Aanvraag naamplaatje voor ' + (inData.account.Full_Shipping_Street__c != null ? inData.account.Full_Shipping_Street__c : inData.account.Name),
            Description = buildCaseDescription(inData.account),
            Nameplate_Text__c = inData.nameplateText,
            Label__c = inData.account.Label__c,
            Case_Reason__c = safeCaseReason,
            Supplier_Information__c = inData.supplierNote,
            Status = 'New'
        );

        // CREATE Case
        WoonstadCrudFlsGuard.requireCreate(Case.SObjectType, 'WoonstadCaseRequestService', 'createCaseAndRequest');
        cDraft = (Case)Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{ cDraft }).getRecords()[0];
        insert cDraft;

        // --- Validate Request__c picklists ---
        String safeRequestType   = ensureRequestType('Name Plate');
        String safeRequestStatus = ensureRequestStatus('Completed');
        String safeSupplierApi   = ensurePicklistValue(Request__c.Supplier_Name_Plate__c, supplierCtx != null ? supplierCtx.apiName : null, 'Request__c.Supplier_Name_Plate__c');

        // --- Build Request__c ---
        Request__c rDraft = new Request__c(
            Account__c = inData.accountId,
            Case__c = cDraft.Id,
            Name_Plate_Text__c = inData.nameplateText,
            OwnerId = runningUserId,
            Process_Time__c = inData.processMinutes,
            Request_Origin__c = 'Case',
            Request_Status__c = safeRequestStatus,
            Type__c = safeRequestType,
            Supplier_Name_Plate__c = safeSupplierApi, // may be NULL if invalid/missing (safe)
            Supplier_Information__c = inData.supplierNote
        );

        // CREATE Request__c
        WoonstadCrudFlsGuard.requireCreate(Request__c.SObjectType, 'WoonstadCaseRequestService', 'createCaseAndRequest');
        rDraft = (Request__c)Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{ rDraft }).getRecords()[0];
        insert rDraft;

        // Link back on Case
        Case cLink = new Case(Id = cDraft.Id, Request__c = rDraft.Id);
        WoonstadCrudFlsGuard.requireUpdate(Case.SObjectType, 'WoonstadCaseRequestService', 'createCaseAndRequest');
        cLink = (Case)Security.stripInaccessible(AccessType.UPDATABLE, new List<SObject>{ cLink }).getRecords()[0];
        update cLink;

        // Reload filtered records (READ)
        WoonstadCrudFlsGuard.requireRead(Case.SObjectType, 'WoonstadCaseRequestService', 'createCaseAndRequest');
        Case cFull = WoonstadSelectors.caseByIdRequired(cDraft.Id);

        WoonstadCrudFlsGuard.requireRead(Request__c.SObjectType, 'WoonstadCaseRequestService', 'createCaseAndRequest');
        Request__c rFull = WoonstadSelectors.requestByIdRequired(rDraft.Id);

        Result res = new Result();
        res.caseRecord = cFull;
        res.requestRecord = rFull;
        return res;
    }

    public static void closeCase(Case cExisting) {
        if (cExisting == null || cExisting.Id == null) return;
        Case upd = new Case(Id = cExisting.Id, Status = 'Closed');
        WoonstadCrudFlsGuard.requireUpdate(Case.SObjectType, 'WoonstadCaseRequestService', 'closeCase');
        upd = (Case)Security.stripInaccessible(AccessType.UPDATABLE, new List<SObject>{ upd }).getRecords()[0];
        update upd;
    }

    // ------------ helpers ------------
    private static String buildCaseDescription(Account acc) {
        List<String> lines = new List<String>();
        lines.add('Aanvraag naamplaatje voor:');
        if (acc.Full_Shipping_Street__c != null)       lines.add(acc.Full_Shipping_Street__c);
        if (acc.Full_Shipping_Postal_Code__c != null)  lines.add(acc.Full_Shipping_Postal_Code__c);
        if (acc.Full_Shipping_City__c != null)         lines.add(acc.Full_Shipping_City__c);
        if (acc.Full_Shipping_Country__c != null)      lines.add(acc.Full_Shipping_Country__c);
        lines.add('Aangevraagd door ' + acc.Name);
        return String.join(lines, '\n');
    }

    // Picklist guards (case-insensitive; return canonical value or NULL if not found)
    private static String ensureCaseReason(String desired) {
        return ensurePicklistValue(Case.Case_Reason__c, desired, 'Case.Case_Reason__c');
    }
    private static String ensureRequestType(String desired) {
        return ensurePicklistValue(Request__c.Type__c, desired, 'Request__c.Type__c');
    }
    private static String ensureRequestStatus(String desired) {
        return ensurePicklistValue(Request__c.Request_Status__c, desired, 'Request__c.Request_Status__c');
    }

    private static String ensurePicklistValue(Schema.SObjectField fieldToken, String desired, String debugName) {
        if (String.isBlank(desired)) return null;
        Schema.DescribeFieldResult dfr = fieldToken.getDescribe();
        if (!dfr.isRestrictedPicklist()) {
            return desired; // Not restricted: platform will accept
        }
        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            if (pe == null || !pe.isActive()) continue;
            String val = pe.getValue();
            if (val != null && val.trim().toLowerCase() == desired.trim().toLowerCase()) {
                return val; // return canonical casing from metadata
            }
        }
        System.debug(LoggingLevel.WARN, 'Picklist value not found for ' + debugName + ' -> "' + desired + '". Setting NULL to avoid DML failure.');
        return null;
    }
    **/
}