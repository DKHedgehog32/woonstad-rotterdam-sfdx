/**
 * =============================================
 * WoonstadFlowBussDataFormController
 * =============================================
 * Date: 2025-09-01
 * Last Changed: 2025-09-01
 * Description:
 * - Apex controller for woonstadFlowBussDataForm LWC
 * - Fetches Account.Type picklist values for Business Account record type
 * - Returns API values for database storage
 * =============================================
 * Changelog:
 * 2025-09-01 | Initial creation - fetch Type field for Business Account RT
 * =============================================
 */
public with sharing class WoonstadFlowBussDataFormController {
    
    /**
     * Retrieves Account.Type picklist values for Business Account record type
     * 
     * @return List<Map<String, String>> Picklist options with label and API value
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAccountTypeOptions() {
        try {
            // Get Business Account record type ID
            Id businessRecordTypeId;
            List<RecordType> businessRT = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Account' 
                AND DeveloperName = 'Business_Account' 
                AND IsActive = true 
                LIMIT 1
            ];
            
            if (businessRT.isEmpty()) {
                throw new AuraHandledException('Business Account record type not found');
            }
            
            businessRecordTypeId = businessRT[0].Id;
            
            // Get Account.Type picklist values for this record type
            Schema.DescribeFieldResult fieldResult = Schema.Account.Type.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            
            // Convert to lightning-combobox format
            List<Map<String, String>> options = new List<Map<String, String>>();
            
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    Map<String, String> option = new Map<String, String>();
                    option.put('label', entry.getLabel());
                    option.put('value', entry.getValue());
                    options.add(option);
                }
            }
            
            return options;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving Account Type options: ' + e.getMessage());
            throw new AuraHandledException('Er is een fout opgetreden bij het ophalen van de account types.');
        }
    }
}