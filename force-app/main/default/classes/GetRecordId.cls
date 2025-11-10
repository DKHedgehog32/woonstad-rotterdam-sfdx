public with sharing class GetRecordId {
    public GetRecordId() {}

    @AuraEnabled(cacheable = true)
    public static List<Report> getReport() {
        try {
            return [
                SELECT Id, Name 
                FROM Report 
                WHERE Name = 'Program Enrollments by Program' 
                ORDER BY LastModifiedDate DESC NULLS LAST 
                LIMIT 1
            ];
        } catch (Exception e) {
            ApexFaultHandler.publishError(e, 'GetRecordId', 'getReport');
            return new List<Report>();
        }
    }

    @AuraEnabled(cacheable = true)
    public static List<Referral> getReferral() {
        try {
            return [
                SELECT Id, Name 
                FROM Referral 
                WHERE Name = 'REF-0000000011' 
                ORDER BY LastModifiedDate DESC NULLS LAST 
                LIMIT 1
            ];
        } catch (Exception e) {
            ApexFaultHandler.publishError(e, 'GetRecordId', 'getReferral');
            return new List<Referral>();
        }
    }

    @AuraEnabled(cacheable = true)
    public static List<Case> getCase() {
        try {
            return [
                SELECT Id, CaseNumber 
                FROM Case 
                WHERE CaseNumber = '00001022' 
                ORDER BY LastModifiedDate DESC NULLS LAST 
                LIMIT 1
            ];
        } catch (Exception e) {
            ApexFaultHandler.publishError(e, 'GetRecordId', 'getCase');
            return new List<Case>();
        }
    }
}