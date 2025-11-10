//
// Wrapper for the /external-systems/agent-statuses API
public inherited sharing class InjixoAgentStatusRequest {
    @InvocableVariable @AuraEnabled
    public List<InjixoAgentStatusModel> data;
    //
    // Implicitly set based on custom setting config
    public InjixoMeta meta;


    public static InjixoAgentStatusRequest getMock(Integer numRecs) {
        InjixoAgentStatusRequest req = new InjixoAgentStatusRequest();
        req.meta = new InjixoMeta();
        req.meta.externalSystem = 'SalesForce';
        req.meta.integrationConfigurationId = 12345;
        req.data = new List<InjixoAgentStatusModel>();
        for(Integer x=0; x<numRecs; x++) {
            req.data.add(InjixoAgentStatusModel.getMock(x));
        }
        return req;
    }
}