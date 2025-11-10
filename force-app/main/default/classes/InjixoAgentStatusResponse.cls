/*
{"errors":[
{"status":400,"title":"Bad request","detail":"#/components/schemas/AgentStatusRequestBody/properties/data/items/properties/startTime Value: \"2025-06-19 14:33:43\" is not conformant with date-time format"}
]}
 */
public inherited sharing class InjixoAgentStatusResponse {
    //
    // Only an error response has a body
    public List<InjixoError> errors;

    public class InjixoError {
        public Integer status;
        public String title;
        public String detail;
    }

}