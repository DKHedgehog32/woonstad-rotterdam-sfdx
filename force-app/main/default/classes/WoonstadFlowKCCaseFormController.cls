/**
 * ===============================================================================================
 * Class            : WoonstadFlowKCCaseFormController
 * Layer            : Service (Apex Controller for LWC)
 * Purpose          : Returns Cases for a given Account (recordId) split into Open/Closed buckets.
 *
 * Responsibilities :
 *  - Validate context (Account Id)
 *  - Query recent open & closed Cases for the Account
 *  - Enforce CRUD/FLS on READ before returning data to UI
 *
 * Security         :
 *  - with sharing (respects sharing)
 *  - CRUD/FLS enforced via WoonstadCrudFlsGuard (stripInaccessible READ)
 *  - User-facing errors via AuraHandledException
 *
 * Fault Handling   :
 *  - Publishes Apex_Fault__e via ApexFaultHandler on violations/exceptions
 *
 * Author           : Dennis van Musschenbroek
 * Last Modified By : Dennis van Musschenbroek
 * Created          : 2025-08-13
 * Last Modified    : 2025-08-25
 * -----------------------------------------------------------------------------------------------
 * Change Log
 * 2025-08-25 | DvM | Added CRUD/FLS guards + sanitizeForRead; fault publishing; defensive limits.
 * 2025-08-13 | DvM | Initial creation.
 * ===============================================================================================
 */
public with sharing class WoonstadFlowKCCaseFormController {

    public class CaseBuckets {
        @AuraEnabled public List<Case> openCases   { get; set; }
        @AuraEnabled public List<Case> closedCases { get; set; }
    }

    /**
     * @description Returns open/closed Case buckets for an Account.
     * @param recordId  Expected Account Id (starts with '001'); returns empty buckets if null/invalid.
     * @param limitSize Optional max rows per bucket (default 200, max 1000).
     */
    @AuraEnabled(cacheable=true)
    public static CaseBuckets getCases(Id recordId, Integer limitSize) {
        CaseBuckets resp = new CaseBuckets();
        resp.openCases   = new List<Case>();
        resp.closedCases = new List<Case>();

        // Validate Account Id prefix early (lightweight)
        if (recordId == null || !String.valueOf(recordId).startsWith('001')) {
            return resp;
        }

        Integer rows = (limitSize == null || limitSize <= 0) ? 200 : Math.min(limitSize, 1000);

        try {
            // CRUD gate for Case READ
            WoonstadCrudFlsGuard.requireRead(Case.SObjectType, 'WoonstadFlowKCCaseFormController', 'getCases');

            // --- Query open cases
            List<Case> openCasesQ = [
                SELECT Id, Subject, CaseNumber, Description, Type, CreatedDate, Status
                FROM Case
                WHERE IsDeleted = false
                  AND AccountId = :recordId
                  AND IsClosed = false
                ORDER BY CreatedDate DESC
                LIMIT :rows
            ];

            // --- Query closed cases
            List<Case> closedCasesQ = [
                SELECT Id, Subject, CaseNumber, Description, Type, CreatedDate, Status
                FROM Case
                WHERE IsDeleted = false
                  AND AccountId = :recordId
                  AND IsClosed = true
                ORDER BY CreatedDate DESC
                LIMIT :rows
            ];

            // Sanitize for READ before returning to UI
            List<SObject> openAsSObj = new List<SObject>();
            for (Case c : openCasesQ)  openAsSObj.add(c);
            List<SObject> closedAsSObj = new List<SObject>();
            for (Case c : closedCasesQ) closedAsSObj.add(c);

            List<SObject> openSanitized = WoonstadCrudFlsGuard.sanitizeForRead(
                openAsSObj, 'WoonstadFlowKCCaseFormController', 'getCases', recordId
            );
            List<SObject> closedSanitized = WoonstadCrudFlsGuard.sanitizeForRead(
                closedAsSObj, 'WoonstadFlowKCCaseFormController', 'getCases', recordId
            );

            // Cast back to Case
            for (SObject so : openSanitized)  resp.openCases.add((Case) so);
            for (SObject so : closedSanitized) resp.closedCases.add((Case) so);

            return resp;

        } catch (AuraHandledException ahx) {
            ApexFaultHandler.publishError(ahx, 'WoonstadFlowKCCaseFormController', 'getCases', recordId);
            throw ahx;
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'WoonstadFlowKCCaseFormController', 'getCases', recordId);
            throw new AuraHandledException('Kon zaken niet ophalen.');
        }
    }
}