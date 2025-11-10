//
// Represents the properties node of a request to injixo for a contact-event
public inherited sharing class InjixoContactEventProperty {
    @InvocableVariable @AuraEnabled
    public Boolean offered;
    @InvocableVariable @AuraEnabled
    public Boolean handled;
    @InvocableVariable @AuraEnabled
    public Double duration;
}