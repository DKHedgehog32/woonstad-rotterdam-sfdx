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
 * ===============================================================================================
 */


public with sharing class KnowledgeApprovalProcessController {

    /**
     * Updates the given Knowledge article version.
     *
     * @param articleVersionId  Id of the Knowledge article version (e.g. Knowledge__kav or KnowledgeArticleVersion)
     * @param approvalComment   Text to store in Approval_Comment__c
     */
    @AuraEnabled
    public static void updateKnowledgeVersion(Id articleVersionId, String approvalComment) {
        try {
            if (articleVersionId == null) {
                throw new AuraHandledException('No article version Id was provided.');
            }

            Knowledge__kav kav = [
                SELECT Id, Approval_Comment__c, ValidationStatus
                FROM Knowledge__kav
                WHERE Id = :articleVersionId
                LIMIT 1
            ];

            kav.Approval_Comment__c = approvalComment;
            kav.ValidationStatus    = 'Waiting For Validation';

            update kav;
        }
        catch (Exception e) {
            // Publish error to the platform event via ApexFaultHandler (AWAF-style centralized logging).
            ApexFaultHandler.publishError(e, 'KnowledgeApprovalProcessController', 'updateKnowledgeVersion', articleVersionId);
            throw new AuraHandledException('An unexpected error occurred while updating the Knowledge article. Please contact your system administrator.');
        }
    }
}