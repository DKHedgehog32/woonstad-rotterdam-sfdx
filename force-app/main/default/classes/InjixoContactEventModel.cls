//
// Represents a request to injixo for a contact-event
public inherited sharing class InjixoContactEventModel {
    @InvocableVariable @AuraEnabled
    public String uniqueId;
    @InvocableVariable @AuraEnabled
    public InjixoContactEventProperty properties;
    @InvocableVariable @AuraEnabled
    public String queueName;
    @InvocableVariable @AuraEnabled
    public String queueIdentifier;
    @InvocableVariable @AuraEnabled
    public DateTime timestamp;
    @InvocableVariable @AuraEnabled
    public String channel;

    public static InjixoContactEventModel getMock(Integer salt) {
        InjixoContactEventModel icm = new InjixoContactEventModel();
        icm.properties = new InjixoContactEventProperty();
        icm.properties.duration = 300;
        icm.properties.handled = true;
        icm.properties.offered = true;
        icm.queueName = 'Apexq';
        icm.queueIdentifier = 'Apexqid';
        icm.timestamp = System.now().addDays(-3);
        icm.channel = 'calls';
        icm.uniqueId = '123456781234567890';
        return icm;
    }

}