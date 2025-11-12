/*************************************************************************************************
 * Class           : KnowledgeApprovalProcessController
 * Layer           : Service (Apex for LWC)
 * Purpose         : Updates the Knowledge article version with the approval/validation comment
 *                   and sets ValidationStatus to 'Waiting For Validation'.
 *
 * Security        :
 *  - with sharing
 *  - Keep DML minimal (single update)
 *
 * Author          : Dylan Pluk
 * Created         : 2025-10-30
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
        if (articleVersionId == null) {
            throw new AuraHandledException('No article version Id was provided.');
        }

        // NOTE:
        // If your org uses the standard KnowledgeArticleVersion, change the sObject below.
        // Current example uses a custom Knowledge object name "Knowledge__kav".
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
}