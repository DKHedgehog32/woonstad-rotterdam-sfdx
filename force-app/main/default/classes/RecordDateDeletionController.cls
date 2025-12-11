/**
 * @description Controller class for deleting records by creation date
 * @author Dylan Pluk
 * @date 2025
 * @group Data Management
 */
public with sharing class RecordDateDeletionController {
    
    /**
     * @description Wrapper class for deletion result with errors
     */
    public class DeletionResult {
        @AuraEnabled public String message;
        @AuraEnabled public List<DeletionError> errors;
        
        public DeletionResult() {
            this.errors = new List<DeletionError>();
        }
    }
    
    /**
     * @description Wrapper class for individual deletion errors
     */
    public class DeletionError {
        @AuraEnabled public String id;
        @AuraEnabled public String objectType;
        @AuraEnabled public String recordName;
        @AuraEnabled public String errorMessage;
        
        public DeletionError(String objectType, String recordName, String errorMessage) {
            this.id = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(objectType + recordName + errorMessage)));
            this.objectType = objectType;
            this.recordName = recordName;
            this.errorMessage = errorMessage;
        }
    }
    
    /**
     * @description Wrapper class for available objects from configuration
     */
    public class AvailableObject {
        @AuraEnabled public String apiName;
        @AuraEnabled public String displayLabel;
        @AuraEnabled public Integer deletionOrder;
        
        public AvailableObject(String apiName, String displayLabel, Integer deletionOrder) {
            this.apiName = apiName;
            this.displayLabel = displayLabel;
            this.deletionOrder = deletionOrder;
        }
    }
    
    /**
     * @description Get list of available objects from Custom Metadata configuration
     * @return List<AvailableObject> List of configured objects for deletion
     * @example
     * List<AvailableObject> objects = RecordDateDeletionController.getAvailableObjects();
     */
    @AuraEnabled(cacheable=true)
    public static List<AvailableObject> getAvailableObjects() {
        List<AvailableObject> availableObjects = new List<AvailableObject>();
        
        try {
            // Query active configurations from Custom Metadata
            List<Record_Date_Deletion_Configuration__mdt> configs = [
                SELECT Object_API_Name__c, Display_Label__c, Deletion_Order__c
                FROM Record_Date_Deletion_Configuration__mdt
                WHERE Is_Active__c = true
                ORDER BY Display_Label__c ASC
            ];
            
            for (Record_Date_Deletion_Configuration__mdt config : configs) {
                availableObjects.add(new AvailableObject(
                    config.Object_API_Name__c,
                    config.Display_Label__c,
                    Integer.valueOf(config.Deletion_Order__c)
                ));
            }
            
            return availableObjects;
            
        } catch (Exception e) {
            // Log technical error to platform event
            ApexFaultHandler.publishError(e, 'RecordDateDeletionController', 'getAvailableObjects');
            throw new AuraHandledException('Fout bij het ophalen van beschikbare objecten: ' + e.getMessage());
        }
    }
    
    /**
     * @description Preview records that would be deleted for the selected datetime range and objects
     * @param startDateTime The start datetime to filter records by CreatedDate (in user's local timezone)
     * @param endDateTime The end datetime to filter records by CreatedDate (in user's local timezone)
     * @param objectNames List of object API names to query
     * @return Map<String, Integer> Map of object names to record counts
     * @example
     * Map<String, Integer> counts = RecordDateDeletionController.previewRecords(
     *     '2025-12-10T15:39:00.000Z',
     *     '2025-12-10T23:59:59.999Z',
     *     new List<String>{'Account', 'Contact'}
     * );
     */
    @AuraEnabled
    public static Map<String, Integer> previewRecords(String startDateTime, String endDateTime, List<String> objectNames) {
        Map<String, Integer> recordCounts = new Map<String, Integer>();
        
        try {
            // Validate input parameters - customer error, no fault handler
            if (String.isBlank(startDateTime) || String.isBlank(endDateTime) || objectNames == null || objectNames.isEmpty()) {
                throw new AuraHandledException('Ongeldige parameters opgegeven.');
            }
            
            // Parse ISO datetime strings - they come in user's timezone but as ISO format
            // LWC sends: "2025-12-10T15:39:00.000" (user's local time)
            // We need to treat this as-is since Salesforce will query in UTC
            DateTime startDT = DateTime.valueOfGmt(startDateTime.replace('T', ' ').replace('Z', ''));
            DateTime endDT = DateTime.valueOfGmt(endDateTime.replace('T', ' ').replace('Z', ''));
            
            // Validate date range - customer error, no fault handler
            if (startDT > endDT) {
                throw new AuraHandledException('Startdatum moet voor einddatum liggen.');
            }
            
            System.debug('Start DateTime (GMT): ' + startDT);
            System.debug('End DateTime (GMT): ' + endDT);
            
            // Query each object in the proper deletion order
            List<String> deletionOrder = getDeletionOrder(objectNames);
            
            for (String objectName : deletionOrder) {
                Integer count = getRecordCount(objectName, startDT, endDT);
                if (count > 0) {
                    recordCounts.put(objectName, count);
                }
            }
            
            return recordCounts;
            
        } catch (AuraHandledException e) {
            // Re-throw validation errors without logging (these are customer errors)
            throw e;
        } catch (Exception e) {
            // Log technical errors to platform event
            ApexFaultHandler.publishError(e, 'RecordDateDeletionController', 'previewRecords');
            throw new AuraHandledException('Technische fout bij het voorvertonen van records: ' + e.getMessage());
        }
    }
    
    /**
     * @description Delete records created within the selected datetime range for the specified objects
     * @param startDateTime The start datetime to filter records by CreatedDate (in user's local timezone)
     * @param endDateTime The end datetime to filter records by CreatedDate (in user's local timezone)
     * @param objectNames List of object API names to delete
     * @return DeletionResult Success message with deletion summary and any errors
     * @example
     * DeletionResult result = RecordDateDeletionController.deleteRecordsByDate(
     *     '2025-12-10T15:39:00.000Z',
     *     '2025-12-10T23:59:59.999Z',
     *     new List<String>{'Account', 'Contact'}
     * );
     */
    @AuraEnabled
    public static DeletionResult deleteRecordsByDate(String startDateTime, String endDateTime, List<String> objectNames) {
        DeletionResult result = new DeletionResult();
        Integer totalDeleted = 0;
        Map<String, Integer> deletedCounts = new Map<String, Integer>();
        
        try {
            // Validate input parameters - customer error, no fault handler
            if (String.isBlank(startDateTime) || String.isBlank(endDateTime) || objectNames == null || objectNames.isEmpty()) {
                throw new AuraHandledException('Ongeldige parameters opgegeven.');
            }
            
            // Parse ISO datetime strings - they come in user's timezone but as ISO format
            // LWC sends: "2025-12-10T15:39:00.000" (user's local time)
            // We need to treat this as-is since Salesforce will query in UTC
            DateTime startDT = DateTime.valueOfGmt(startDateTime.replace('T', ' ').replace('Z', ''));
            DateTime endDT = DateTime.valueOfGmt(endDateTime.replace('T', ' ').replace('Z', ''));
            
            // Validate date range - customer error, no fault handler
            if (startDT > endDT) {
                throw new AuraHandledException('Startdatum moet voor einddatum liggen.');
            }
            
            System.debug('Start DateTime (GMT): ' + startDT);
            System.debug('End DateTime (GMT): ' + endDT);
            
            // Get objects in proper deletion order (junction -> child -> parent)
            List<String> deletionOrder = getDeletionOrder(objectNames);
            
            // Delete records in order
            for (String objectName : deletionOrder) {
                List<SObject> recordsToDelete = getRecordsToDelete(objectName, startDT, endDT);
                
                if (!recordsToDelete.isEmpty()) {
                    // Create a map of Id to Name for error reporting
                    Map<Id, String> recordIdToName = getRecordNames(recordsToDelete, objectName);
                    
                    Database.DeleteResult[] deleteResults = Database.delete(recordsToDelete, false);
                    
                    Integer successCount = 0;
                    for (Database.DeleteResult dr : deleteResults) {
                        if (dr.isSuccess()) {
                            successCount++;
                        } else {
                            // Capture detailed error information
                            // Note: Individual record deletion failures are business errors, not technical faults
                            String recordName = recordIdToName.get(dr.getId());
                            for (Database.Error err : dr.getErrors()) {
                                String errorMsg = err.getMessage();
                                result.errors.add(new DeletionError(objectName, recordName, errorMsg));
                                System.debug('Error deleting ' + objectName + ': ' + errorMsg);
                            }
                        }
                    }
                    
                    deletedCounts.put(objectName, successCount);
                    totalDeleted += successCount;
                }
            }
            
            // Build success message
            result.message = buildSuccessMessage(deletedCounts, totalDeleted, result.errors.size());
            
            return result;
            
        } catch (AuraHandledException e) {
            // Re-throw validation errors without logging (these are customer errors)
            throw e;
        } catch (Exception e) {
            // Log technical errors to platform event
            ApexFaultHandler.publishError(e, 'RecordDateDeletionController', 'deleteRecordsByDate');
            throw new AuraHandledException('Technische fout bij het verwijderen van records: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get the count of records for a specific object and date range
     * @param objectName The API name of the object
     * @param startDateTime Start of the date range
     * @param endDateTime End of the date range
     * @return Integer Count of records found
     */
    private static Integer getRecordCount(String objectName, DateTime startDateTime, DateTime endDateTime) {
        String query = 'SELECT COUNT() FROM ' + String.escapeSingleQuotes(objectName) + 
                      ' WHERE CreatedDate >= :startDateTime AND CreatedDate <= :endDateTime';
        
        return Database.countQuery(query);
    }
    
    /**
     * @description Get records to delete for a specific object and date range
     * @param objectName The API name of the object
     * @param startDateTime Start of the date range
     * @param endDateTime End of the date range
     * @return List<SObject> List of records to delete
     */
    private static List<SObject> getRecordsToDelete(String objectName, DateTime startDateTime, DateTime endDateTime) {
        String query = 'SELECT Id FROM ' + String.escapeSingleQuotes(objectName) + 
                      ' WHERE CreatedDate >= :startDateTime AND CreatedDate <= :endDateTime';
        
        return Database.query(query);
    }
    
    /**
     * @description Get record names for error reporting
     * @param records List of records to get names for
     * @param objectName The API name of the object
     * @return Map<Id, String> Map of record Id to record name
     */
    private static Map<Id, String> getRecordNames(List<SObject> records, String objectName) {
        Map<Id, String> recordIdToName = new Map<Id, String>();
        
        if (records.isEmpty()) {
            return recordIdToName;
        }
        
        // Build list of Ids
        Set<Id> recordIds = new Set<Id>();
        for (SObject record : records) {
            recordIds.add(record.Id);
        }
        
        // Determine name field based on object type
        String nameField = getNameField(objectName);
        
        // Query for names
        String query = 'SELECT Id, ' + nameField + ' FROM ' + String.escapeSingleQuotes(objectName) + 
                      ' WHERE Id IN :recordIds';
        
        List<SObject> recordsWithNames = Database.query(query);
        
        for (SObject record : recordsWithNames) {
            String name = String.valueOf(record.get(nameField));
            recordIdToName.put(record.Id, name != null ? name : 'Unknown');
        }
        
        return recordIdToName;
    }
    
    /**
     * @description Get the appropriate name field for an object
     * Uses Custom Metadata Name_Field__c if specified, otherwise uses dynamic schema describe
     * @param objectName The API name of the object
     * @return String The name field to use
     */
    private static String getNameField(String objectName) {
        // First, check Custom Metadata for configured name field
        List<Record_Date_Deletion_Configuration__mdt> configs = [
            SELECT Name_Field__c
            FROM Record_Date_Deletion_Configuration__mdt
            WHERE Object_API_Name__c = :objectName
            AND Is_Active__c = true
            LIMIT 1
        ];
        
        if (!configs.isEmpty() && String.isNotBlank(configs[0].Name_Field__c)) {
            return configs[0].Name_Field__c;
        }
        
        // Fallback to dynamic schema describe
        try {
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            if (objectType != null) {
                Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
                Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
                
                // Check for common name fields in order of preference
                List<String> commonNameFields = new List<String>{
                    'Name', 'CaseNumber', 'Subject', 'Title', 'AssetRelationshipNumber'
                };
                
                for (String fieldName : commonNameFields) {
                    if (fieldsMap.containsKey(fieldName.toLowerCase())) {
                        return fieldName;
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error describing object ' + objectName + ': ' + e.getMessage());
        }
        
        // Final fallback to Id
        return 'Id';
    }
    
    /**
     * @description Order objects for deletion based on Custom Metadata configuration
     * Junction objects first, then children, then parents based on Deletion_Order__c
     * @param objectNames List of object API names
     * @return List<String> Ordered list of object names for deletion
     */
    private static List<String> getDeletionOrder(List<String> objectNames) {
        List<String> orderedList = new List<String>();
        
        // Query Custom Metadata for deletion order
        Map<String, Decimal> objectToOrder = new Map<String, Decimal>();
        
        List<Record_Date_Deletion_Configuration__mdt> configs = [
            SELECT Object_API_Name__c, Deletion_Order__c
            FROM Record_Date_Deletion_Configuration__mdt
            WHERE Is_Active__c = true
        ];
        
        for (Record_Date_Deletion_Configuration__mdt config : configs) {
            objectToOrder.put(config.Object_API_Name__c, config.Deletion_Order__c);
        }
        
        // Create a list of objects with their order for sorting
        List<ObjectWithOrder> objectsWithOrder = new List<ObjectWithOrder>();
        
        for (String objectName : objectNames) {
            Decimal order = objectToOrder.containsKey(objectName) 
                ? objectToOrder.get(objectName) 
                : 999; // Objects not in config go last
            objectsWithOrder.add(new ObjectWithOrder(objectName, order));
        }
        
        // Sort by deletion order
        objectsWithOrder.sort();
        
        // Extract sorted object names
        for (ObjectWithOrder obj : objectsWithOrder) {
            orderedList.add(obj.objectName);
        }
        
        return orderedList;
    }
    
    /**
     * @description Helper class for sorting objects by deletion order
     */
    private class ObjectWithOrder implements Comparable {
        public String objectName;
        public Decimal deletionOrder;
        
        public ObjectWithOrder(String objectName, Decimal deletionOrder) {
            this.objectName = objectName;
            this.deletionOrder = deletionOrder;
        }
        
        public Integer compareTo(Object compareTo) {
            ObjectWithOrder other = (ObjectWithOrder) compareTo;
            
            if (this.deletionOrder == other.deletionOrder) {
                return 0;
            }
            if (this.deletionOrder > other.deletionOrder) {
                return 1;
            }
            return -1;
        }
    }
    
    /**
     * @description Build a success message with deletion summary
     * @param deletedCounts Map of object names to deleted counts
     * @param totalDeleted Total number of records deleted
     * @param errorCount Number of records that failed to delete
     * @return String Formatted success message
     */
    private static String buildSuccessMessage(Map<String, Integer> deletedCounts, Integer totalDeleted, Integer errorCount) {
        if (totalDeleted == 0 && errorCount == 0) {
            return 'Er zijn geen records verwijderd.';
        }
        
        if (totalDeleted == 0 && errorCount > 0) {
            return 'Er zijn geen records verwijderd. ' + errorCount + ' record(s) konden niet worden verwijderd. Zie details hieronder.';
        }
        
        List<String> messages = new List<String>();
        
        // Get deletion order from Custom Metadata
        List<Record_Date_Deletion_Configuration__mdt> configs = [
            SELECT Object_API_Name__c, Display_Label__c
            FROM Record_Date_Deletion_Configuration__mdt
            WHERE Is_Active__c = true
            ORDER BY Deletion_Order__c ASC
        ];
        
        // Build message in deletion order using display labels
        for (Record_Date_Deletion_Configuration__mdt config : configs) {
            String objectName = config.Object_API_Name__c;
            if (deletedCounts.containsKey(objectName) && deletedCounts.get(objectName) > 0) {
                String label = String.isNotBlank(config.Display_Label__c) 
                    ? config.Display_Label__c 
                    : objectName;
                messages.add(deletedCounts.get(objectName) + ' ' + label + ' record(s)');
            }
        }
        
        String result = 'Succesvol verwijderd: ' + String.join(messages, ', ') + '. Totaal: ' + totalDeleted + ' record(s).';
        
        if (errorCount > 0) {
            result += ' Record(s) die niet verwijderd konden worden: ' + errorCount + '.';
        }
        
        return result;
    }
}