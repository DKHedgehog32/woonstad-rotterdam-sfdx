//
// Contains the API client for Injixo
public inherited sharing class InjixoClient {

    //
    // Fetch the config. It contains details to connect to the API
    public static Injixo_Config__c config = Injixo_Config__c.getInstance();

    //
    // InjixoAgentStatusRequest is implicitly bulkified as it contains
    // a list of agent statuses. Hence, it can handle 200 per go, hence
    // no need for load balancing the callee
    public static void sendAgentStatusRequest(List<InjixoAgentStatusModel> statusesToSend) {
        try {
            if(String.isBlank(config.Use_Named_Credential__c)) {
                throw new InjixoClientException('Named credential not configured. Please check the Injixo_Config__c custom setting');
            }
            if(String.isBlank(config.Integration_Configuration_Id__c)) {
                throw new InjixoClientException('Integration configuration id not configured. Please check the Injixo_Config__c custom setting');
            }
            if(String.isBlank(config.External_System__c)) {
                throw new InjixoClientException('External system not configured. Please check the Injixo_Config__c custom setting');
            }
            if(statusesToSend == null || statusesToSend.isEmpty()) {
                throw new InjixoClientException('Nothing to send!');
            }

            //
            // Construct the request structure
            InjixoAgentStatusRequest request = new InjixoAgentStatusRequest();
            request.meta = new InjixoMeta();
            request.meta.integrationConfigurationId = Integer.valueOf(config.Integration_Configuration_Id__c);
            request.meta.externalSystem = config.External_System__c;

            //
            // Convert the datetime properties to strings
            convertStatusesListByReference(statusesToSend);
            request.data = statusesToSend;

            //
            // Set the params
            String requestBody = JSON.serializePretty(request, true);
            String namedCredential = config.Use_Named_Credential__c;

            //
            // Construct the HTTP request
            Http client = new Http();
            HttpRequest injixoRequest = new HttpRequest();
            injixoRequest.setMethod('POST');
            injixoRequest.setEndpoint('callout:' + namedCredential + '/agent-statuses');
            injixoRequest.setHeader('Content-Type','application/json');
            System.debug('### Sending to Injixo ' + requestBody);
            injixoRequest.setBody(requestBody);

            //
            // Send response
            HttpResponse response = client.send(injixoRequest);
            if(response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                //
                // Success, No body. Finish here
                System.debug('### Success');
            } else {
                //
                // Handle errors. Docs say there's no body, in practice errors appear to have a body
                InjixoAgentStatusResponse resp = (InjixoAgentStatusResponse) JSON.deserialize(response.getBody(),InjixoAgentStatusResponse.class);
                throw new InjixoClientException(JSON.serializePretty(resp.errors));
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'InjixoClient', 'sendAgentStatusRequest');
            throw ex;
        }
    }

    public static void sendContactEventRequest(List<InjixoContactEventModel> eventsToSend) {
        try {
            if(String.isBlank(config.Use_Named_Credential__c)) {
                throw new InjixoClientException('Named credential not configured. Please check the Injixo_Config__c custom setting');
            }
            if(String.isBlank(config.Integration_Configuration_Id__c)) {
                throw new InjixoClientException('Integration configuration id not configured. Please check the Injixo_Config__c custom setting');
            }
            if(String.isBlank(config.External_System__c)) {
                throw new InjixoClientException('External system not configured. Please check the Injixo_Config__c custom setting');
            }
            if(eventsToSend == null || eventsToSend.isEmpty()) {
                throw new InjixoClientException('Nothing to send!');
            }

            //
            // Construct the request structure
            InjixoContactEventRequest request = new InjixoContactEventRequest();
            request.meta = new InjixoMeta();
            request.meta.integrationConfigurationId = Integer.valueOf(config.Integration_Configuration_Id__c);
            request.meta.externalSystem = config.External_System__c;
            request.data = eventsToSend;

            //
            // Set the params
            String requestBody = JSON.serializePretty(request, true);
            String namedCredential = config.Use_Named_Credential__c;

            //
            // Construct the HTTP request
            Http client = new Http();
            HttpRequest injixoRequest = new HttpRequest();
            injixoRequest.setMethod('POST');
            injixoRequest.setEndpoint('callout:' + namedCredential + '/contact-events');
            injixoRequest.setHeader('Content-Type','application/json');
            System.debug('### Sending to Injixo ' + requestBody);
            injixoRequest.setBody(requestBody);

            HttpResponse response = client.send(injixoRequest);
            System.debug('### Response ' + response.getBody());
            if(response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                //
                // Success, No body. Finish here
                System.debug('### Success');
            } else {
                //
                // Handle errors
                InjixoAgentStatusResponse resp = (InjixoAgentStatusResponse) JSON.deserialize(response.getBody(),InjixoAgentStatusResponse.class);
                throw new InjixoClientException(JSON.serializePretty(resp.errors));
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'InjixoClient', 'sendContactEventRequest');
            throw ex;
        }
    }

    public class InjixoClientException extends Exception {}

    public static void convertStatusesListByReference(List<InjixoAgentStatusModel> statusesToSend) {
        for(InjixoAgentStatusModel status : statusesToSend) {
            status.startTime = dateTimeToInjixoString(status.begins);
            status.endTime = dateTimeToInjixoString(status.ends);
            //
            // Clear the originals to allow them to be stripped from the body
            status.begins = null;
            status.ends = null;
        }
    }

    public static String dateTimeToInjixoString(DateTime dateTimeValueIn) {
        //
        // Creates the string format required by Injixo "2025-06-19T14:30:00Z"
        if(dateTimeValueIn == null) {
            return null;
        }
        String yearComponent = dateTimeValueIn.year().toString();
        String monthComponent = dateTimeValueIn.month().toString();
        String dayComponent = dateTimeValueIn.day().toString();
        String hourComponent = dateTimeValueIn.hour().toString();
        String minuteComponent = dateTimeValueIn.minute().toString();
        String secondComponent = dateTimeValueIn.second().toString();
        String output = yearComponent+'-'+monthComponent.leftPad(2,'0')+'-'+dayComponent.leftPad(2,'0')+'T'+hourComponent.leftPad(2,'0')+':'+minuteComponent.leftPad(2,'0')+':'+secondComponent.leftPad(2,'0')+'Z';
        return output;
    }

    /*
    Test anonymous
    InjixoAgentStatusRequest rq = InjixoAgentStatusRequest.getMock(2);
    List<InjixoAgentStatusModel> models = rq.data;
    InjixoClient.sendAgentStatusRequest(models);

    InjixoContactEventRequest rq = InjixoContactEventRequest.getMock(2);
    List<InjixoContactEventModel> models = rq.data;
    InjixoClient.sendContactEventRequest(models);
    */
}