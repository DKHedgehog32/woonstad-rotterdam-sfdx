//
// Holds response for a webservice
global class RestServiceResponse {
    @AuraEnabled @InvocableVariable
    global List<PersoonAdresModel> addresses;
    @AuraEnabled @InvocableVariable
    global ContractModel contract;
    @AuraEnabled @InvocableVariable
    global PersoonModel persoon;
    @AuraEnabled @InvocableVariable
    global List<PersoonRelatieModel> relaties;
    @AuraEnabled @InvocableVariable
    global List<String> errors;
    @AuraEnabled @InvocableVariable
    global Boolean isSuccess;
}