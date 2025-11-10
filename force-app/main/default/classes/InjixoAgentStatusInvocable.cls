public with sharing class InjixoAgentStatusInvocable {
    @InvocableMethod(label='Injixo Agent Status' description='Sends the agent status to Injixo')
    public static void sendAgentStatuses(List<List<InjixoAgentStatusModel>> statuses) {
        List<InjixoAgentStatusModel> allStatuses = new List<InjixoAgentStatusModel>();
        for(List<InjixoAgentStatusModel> oneList : statuses) {
            allStatuses.addAll(oneList);
        }
        sendStatusesFuture(JSON.serialize(allStatuses));
    }

    @Future(callout=true) @TestVisible
    private static void sendStatusesFuture(String statusJson) {
        try {
            List<InjixoAgentStatusModel> statuses = (List<InjixoAgentStatusModel>) JSON.deserialize(statusJson, List<InjixoAgentStatusModel>.class);
            InjixoClient.sendAgentStatusRequest(statuses);
        } catch (Exception e) {
            ApexFaultHandler.publishError(e, 'InjixoAgentStatusInvocable', 'sendStatusesFuture');
        }
    }
}