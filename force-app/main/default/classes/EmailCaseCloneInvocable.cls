// 
public with sharing class EmailCaseCloneInvocable {
    @InvocableMethod(Description='Create clone of Case, EmailMessage and ContentDocumentLinks' Label='Clone Email Case')
    public static void cloneEmailCase(List<EmailCaseCloneRequest> requests) {
        EmailCaseService.cloneCaseAndEmailMessage(JSON.serialize(requests));
    }
}