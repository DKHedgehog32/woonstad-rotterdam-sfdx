/*************************************************************************************************
 * Class           : woonstadCreateBussRecordTypeUtil
 * Layer           : Utility
 * Purpose         : Resolve Account RecordType Ids for Business Accounts (by DeveloperName + fallback).
 *
 * Key Changes     : Modified for Business Account Record Type resolution
 *                   - Primary fallback looks for 'Business_Account' Record Type
 *                   - Secondary fallback includes business-related Record Type names
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-29
 * Last Modified   : 2025-08-29
 *************************************************************************************************/
public with sharing class woonstadCreateBussRecordTypeUtil {

    /**
     * Resolves Account Record Type IDs by Developer Name
     * @param devNames Set of Developer Names to resolve
     * @return Map of Developer Name to Record Type ID
     */
    public static Map<String, Id> resolveAccountByDevName(Set<String> devNames) {
        Map<String, Id> out = new Map<String, Id>();
        if (devNames == null || devNames.isEmpty()) return out;
        
        for (RecordType rt : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsActive = true
            AND DeveloperName IN :devNames
        ]) {
            out.put(rt.DeveloperName, rt.Id);
        }
        
        return out;
    }

    /**
     * Resolves fallback Business Account Record Type ID
     * Primary: Looks for 'Business_Account' Record Type
     * Fallback: Tries various business-related Record Type names
     * @return Id of suitable Business Account Record Type, or null if none found
     */
    public static Id resolveFallbackBusinessRtId() {
        // Primary candidate: Business_Account (as specified in requirements)
        List<RecordType> primaryRts = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsActive = true
            AND Name = 'Business_Account'
            LIMIT 1
        ];
        if (!primaryRts.isEmpty()) return primaryRts[0].Id;
        
        // Fallback candidates: Various business-related Record Type names
        List<String> candidates = new List<String>{ 
            'Business_Account',     // Primary requirement
            'BusinessAccount',      // Alternative naming
            'Business',             // Simple naming
            'B2B',                  // Business-to-business
            'Corporate',            // Corporate accounts
            'Company',              // Company accounts
            'Organization',         // Organization accounts
            'Bedrijf',              // Dutch for business
            'Zakelijk'              // Dutch for business/commercial
        };
        
        List<RecordType> fallbackRts = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsActive = true
            AND DeveloperName IN :candidates
            LIMIT 1
        ];
        if (!fallbackRts.isEmpty()) return fallbackRts[0].Id;

        // Last resort: Any active Account Record Type
        List<RecordType> anyRt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsActive = true
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        
        return (anyRt != null && !anyRt.isEmpty()) ? anyRt[0].Id : null;
    }
}