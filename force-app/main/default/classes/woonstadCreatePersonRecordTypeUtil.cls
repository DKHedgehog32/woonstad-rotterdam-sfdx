/*************************************************************************************************
 * Class           : woonstadCreatePersonRecordTypeUtil
 * Layer           : Utility
 * Purpose         : Resolve Account RecordType Ids (by DeveloperName + fallback Person RT).
 * Owner           : Woonstad KC
 * Last Modified   : 2025-08-27
 *************************************************************************************************/
public with sharing class woonstadCreatePersonRecordTypeUtil {

    public static Map<String, Id> resolveAccountByDevName(Set<String> devNames) {
        Map<String, Id> out = new Map<String, Id>();
        if (devNames == null || devNames.isEmpty()) return out;
        for (RecordType rt : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsActive = true
            AND DeveloperName IN :devNames
        ]) out.put(rt.DeveloperName, rt.Id);
        return out;
    }

    public static Id resolveFallbackPersonRtId() {
        List<String> candidates = new List<String>{ 'PersonAccount','Person_Account','Person','Consumer','B2C','Private','Klant','Particulier' };
        List<RecordType> rts = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsActive = true
            AND DeveloperName IN :candidates
            LIMIT 1
        ];
        if (!rts.isEmpty()) return rts[0].Id;

        RecordType anyRt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsActive = true
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        return (anyRt != null) ? anyRt.Id : null;
    }
}