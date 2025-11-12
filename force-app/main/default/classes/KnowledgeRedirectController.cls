/**
 * ===============================================================================================
 * Class            : KnowledgeRedirectController
 * Layer            : Service (Apex Controller for LWC)
 * Purpose          : Returns the Online version for a draft knowledge article. 
 * Author           : Dylan Pluk
 * Created          : 2025-11-06
 * -----------------------------------------------------------------------------------------------
 * Change Log
 * 2025-11-06 | DP | Initial creation.
 * ===============================================================================================
 */

public with sharing class KnowledgeRedirectController {

    public class ResolveResult {
        @AuraEnabled public Boolean ok;            
        @AuraEnabled public String errorMessage;   
        @AuraEnabled public Boolean isOnline;      
        @AuraEnabled public Id onlineId;           
    }

    @AuraEnabled
    public static ResolveResult resolve(Id kavId) {
        ResolveResult res = new ResolveResult();
        res.ok = true;
        res.isOnline = false;

        try {
            if (kavId == null) {
                res.ok = false;
                res.errorMessage = 'No article id provided.';
                return res;
            }

            // Get current version (defensive: handle FLS/share gracefully)
            Knowledge__kav cur;
            try {
                cur = [
                    SELECT Id, KnowledgeArticleId, Language, PublishStatus
                    FROM Knowledge__kav
                    WHERE Id = :kavId
                    LIMIT 1
                ];
            } catch (Exception qe) {
                // Not found or no access
                res.ok = false;
                res.errorMessage = 'Article version not accessible.';
                return res;
            }

            // FLS sanitize — if stripped out, treat as not accessible
            List<Knowledge__kav> sanitized = (List<Knowledge__kav>) Security.stripInaccessible(
                AccessType.READABLE, new List<Knowledge__kav>{ cur }
            ).getRecords();
            if (sanitized.isEmpty()) {
                res.ok = false;
                res.errorMessage = 'Article fields not accessible for this user.';
                return res;
            }
            cur = sanitized[0];

            // 'Online' means published
            if (cur.PublishStatus == 'Online') {
                res.isOnline = true;
                return res;
            }

            // Find Online sibling (same article + language)
            List<Knowledge__kav> online = [
                SELECT Id
                FROM Knowledge__kav
                WHERE KnowledgeArticleId = :cur.KnowledgeArticleId
                  AND Language = :cur.Language
                  AND PublishStatus = 'Online'
                ORDER BY VersionNumber DESC
                LIMIT 1
            ];
            res.onlineId = online.isEmpty() ? null : online[0].Id;
            return res;

        } catch (Exception e) {
            // Unexpected fault → publish & report cleanly
            //try { ApexFaultHandler.publish('KnowledgeRedirectController.resolve', e); } catch (Exception ignore) {}
            res.ok = false;
            res.errorMessage = 'Unexpected error while resolving Online version.';
            return res;
        }
    }
}