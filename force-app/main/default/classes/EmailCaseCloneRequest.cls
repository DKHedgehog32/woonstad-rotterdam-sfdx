// Define input variables for invocable
public class EmailCaseCloneRequest {
    @InvocableVariable @AuraEnabled
    public Id caseId;

    @InvocableVariable @AuraEnabled
    public Id emailMessageId;
 
}