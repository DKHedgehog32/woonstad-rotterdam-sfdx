/**
 * ===============================================================================================
 * Class            : KnowledgeApprovalProcessController
 * Layer            : Service (Apex Controller for LWC)
 * Purpose          : Updates the Knowledge article version with the approval/validation comment
 *                   and sets ValidationStatus to 'Waiting For Validation'.
 * Author           : Dylan Pluk
 * Created          : 2025-11-06
 * -----------------------------------------------------------------------------------------------
 * Change Log
 * 2025-11-06 | DP | Initial creation.
 * 2025-11-13 | DP | Added CRUD/FLS checks, input validation, safer query and magic string constant.
 * ===============================================================================================
 */
public with sharing class KnowledgeApprovalProcessController {

    // ======= CONSTANTS =========================================================================
    private static final String CLS                             = 'KnowledgeApprovalProcessController';
    private static final String FN_UPDATE_KNOWLEDGE_VERSION     = 'updateKnowledgeVersion';
    private static final String STATUS_WAITING_FOR_VALIDATION   = 'Waiting For Validation';

    /**
     * Updates the given Knowledge article version.
     *
     * @param articleVersionId  Id of the Knowledge article version (e.g. Knowledge__kav or KnowledgeArticleVersion)
     * @param approvalComment   Text to store in Approval_Comment__c
     */
    @AuraEnabled
    public static void updateKnowledgeVersion(Id articleVersionId, String approvalComment) {
        try {
            // ======= INPUT VALIDATION ==========================================================
            if (articleVersionId == null) {
                throw new AuraHandledException('Er is geen artikelversie id aangeleverd.');
            }

            if (String.isBlank(approvalComment)) {
                throw new AuraHandledException('Vul eerst in wat je wilt vertellen over de wijziging.');
            }

            approvalComment = approvalComment.trim();

            // Validate length using field describe.
            Integer maxLength = Knowledge__kav.Approval_Comment__c.getDescribe().getLength();

            if (maxLength != null && maxLength > 0 && approvalComment.length() > maxLength) {
                throw new AuraHandledException(
                    'De toelichting is te lang. De maximale lengte is ' + maxLength + ' tekens.'
                );
            }

            // Ensure user is allowed to READ and UPDATE Knowledge__kav records.
            WoonstadCrudFlsGuard.requireRead(Knowledge__kav.SObjectType, CLS, FN_UPDATE_KNOWLEDGE_VERSION);
            WoonstadCrudFlsGuard.requireUpdate(Knowledge__kav.SObjectType, CLS, FN_UPDATE_KNOWLEDGE_VERSION);

            List<Knowledge__kav> kavList = [
                SELECT Id, Approval_Comment__c, ValidationStatus
                FROM Knowledge__kav
                WHERE Id = :articleVersionId
                LIMIT 1
            ];

            if (kavList.isEmpty()) {
                // Avoid QueryException by handling "not found" explicitly.
                throw new AuraHandledException('Het opgevraagde artikel is niet gevonden.');
            }

            // Enforce FLS for READ (in case some fields are not accessible).
            List<SObject> sanitizedRead = WoonstadCrudFlsGuard.sanitizeForRead(
                new List<SObject>{ kavList[0] },
                CLS,
                FN_UPDATE_KNOWLEDGE_VERSION,
                articleVersionId
            );

            Knowledge__kav kav = (Knowledge__kav) sanitizedRead[0];

            // Update Knowledge Article after submit. 
            kav.Approval_Comment__c = approvalComment;
            kav.ValidationStatus    = STATUS_WAITING_FOR_VALIDATION;

            // Enforce FLS for UPDATE (will block if user cannot update the fields).
            kav = (Knowledge__kav) WoonstadCrudFlsGuard.sanitizeForUpdate(
                kav,
                CLS,
                FN_UPDATE_KNOWLEDGE_VERSION,
                articleVersionId
            );

            update kav;
        }
        catch (Exception e) {

            // If it is already an AuraHandledException, it is a specific, user-friendly message.
            // Do NOT double-log (WoonstadCrudFlsGuard and security policy may already have logged).
            if (e instanceof AuraHandledException) {
                throw (AuraHandledException) e;
            }

            // Unexpected technical error: log via ApexFaultHandler and return a generic message.
            ApexFaultHandler.publishError(e, CLS, FN_UPDATE_KNOWLEDGE_VERSION, articleVersionId);
            throw new AuraHandledException(
                'An unexpected error occurred while updating the Knowledge article. Please contact your system administrator.'
            );
        }
    }
}