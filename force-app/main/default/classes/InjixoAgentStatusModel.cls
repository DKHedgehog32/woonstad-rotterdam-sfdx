//
// API blueprint for an Agent status request to injixo
// /external-systems/agent-statuses
public inherited sharing class InjixoAgentStatusModel {
    @InvocableVariable @AuraEnabled
    public String agentIdentifier;
    @InvocableVariable @AuraEnabled
    public String activityIdentifier;
    @InvocableVariable @AuraEnabled
    public Datetime begins; // Mapped in flow builder, converted to startTime string for API in InjixoClient
    public String startTime;
    @InvocableVariable @AuraEnabled
    public Datetime ends; // Mapped in flow builder, converted to endTime string for API in InjixoClient
    public String endTime;

    public static InjixoAgentStatusModel getMock(Integer salt) {
        InjixoAgentStatusModel ism = new InjixoAgentStatusModel();
        ism.activityIdentifier = 'Storing';
        ism.begins = System.now().addMinutes(-1).addHours(salt);
        //ism.begins = Datetime.newInstance(2025, 6, 20, 9, 1, 0);
        //ism.ends = Datetime.newInstance(2025, 6, 20, 12, 1, 0);
        ism.ends = (salt == 0 || salt == null) ? null : System.now().addHours(salt+2); // Total duration 2 hours
        ism.agentIdentifier = 'dave.godlieb@woonstadrotterdam.nl';
        return ism;
    }
}