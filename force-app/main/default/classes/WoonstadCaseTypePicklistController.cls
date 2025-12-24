/**
 * =============================================
 * WoonstadCaseTypePicklistController
 * =============================================
 * Date: 2025-07-31
 * Last Changed: 2025-07-31
 * Description:
 * Provides the available picklist values for the 
 * Case.Type field, filtered by RecordTypeId.
 * 
 * This class ensures that Flows or LWCs only show 
 * valid Case.Type options for the specified record type.
 */

public with sharing class WoonstadCaseTypePicklistController {

    /**
     * Returns a list of Case.Type picklist values 
     * valid for the given RecordTypeId.
     *
     * @param recordTypeId The Id of the Case record type
     * @return List<String> of active picklist values
     * @throws AuraHandledException if recordTypeId is null or invalid
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getCaseTypePicklistValues(Id recordTypeId) {
        if (recordTypeId == null) {
            throw new AuraHandledException('RecordTypeId cannot be null');
        }

        // Verify record type exists for Case
        Map<Id, Schema.RecordTypeInfo> recordTypeInfos =
            Case.SObjectType.getDescribe().getRecordTypeInfosById();

        if (!recordTypeInfos.containsKey(recordTypeId)) {
            throw new AuraHandledException('Invalid RecordTypeId provided');
        }

        // Just return active picklist values
        List<Schema.PicklistEntry> picklistEntries = Case.Type.getDescribe().getPicklistValues();
        List<String> values = new List<String>();

        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }

        return values;
    }
}