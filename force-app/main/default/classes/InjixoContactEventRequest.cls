//
// Wrapper for the /external-systems/contact-event API
public inherited sharing class InjixoContactEventRequest {
    @InvocableVariable @AuraEnabled
    public List<InjixoContactEventModel> data;
    //
    // Implicitly set based on custom setting config
    public InjixoMeta meta;

    public static InjixoContactEventRequest getMock(Integer numRecs) {
        InjixoContactEventRequest req = new InjixoContactEventRequest();
        req.meta = new InjixoMeta();
        req.meta.externalSystem = 'Salesforce';
        req.meta.integrationConfigurationId = 12345;
        req.data = new List<InjixoContactEventModel>();
        for(Integer x=0; x<numRecs; x++) {
            req.data.add(InjixoContactEventModel.getMock(x));
        }
        return req;
    }
}