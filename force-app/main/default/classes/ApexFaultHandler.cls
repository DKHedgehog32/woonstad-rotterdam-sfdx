//
// Utility to publish error events in apex
public inherited sharing class ApexFaultHandler {

    public static void publishError(Exception ex, String className, String functionName, Id recordId) {
        try {
            String stackTrace = ex.getStackTraceString();

            Apex_Fault__e fault = new Apex_Fault__e(
                Class_Name__c     = className,
                Function_Name__c  = functionName,
                Error_Message__c  = ex.getMessage(),
                Stack_Trace__c    = stackTrace,
                Record_Id__c      = recordId
            );

            EventBus.publish(fault);
        } catch (Exception logEx) {
            System.debug('Failed to publish Apex_Fault__e: ' + logEx.getMessage());
        }
    }

    // Overload: without recordId
    public static void publishError(Exception ex, String className, String functionName) {
        publishError(ex, className, functionName, null);
    }

    // ✅ New overload: supports error message directly without wrapping in Exception
    public static void publishError(String errorMessage, String className, String functionName) {
        try {
            Apex_Fault__e fault = new Apex_Fault__e(
                Class_Name__c     = className,
                Function_Name__c  = functionName,
                Error_Message__c  = errorMessage,
                Stack_Trace__c    = '', // No stack trace from plain message
                Record_Id__c      = null
            );

            EventBus.publish(fault);
        } catch (Exception logEx) {
            System.debug('Failed to publish Apex_Fault__e (string version): ' + logEx.getMessage());
        }
    }
}