//
// Holds the model for reference data, used to (de)serialize in integrations and use in flows
global class ReferentieDataModel {
    @AuraEnabled @InvocableVariable
    global String code;
    @AuraEnabled @InvocableVariable
    global String naam;
    @AuraEnabled @InvocableVariable
    global String omschrijving;

    public static ReferentieDataModel getMock(String typeName) {
        ReferentieDataModel model = new ReferentieDataModel();
        model.code = typeName+'mock-code';
        model.naam = typeName+'mock-naam';
        model.omschrijving = typeName+'mock-omschrijving';
        return model;
    }
}