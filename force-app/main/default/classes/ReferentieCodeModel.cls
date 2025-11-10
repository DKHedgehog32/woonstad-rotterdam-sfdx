//
// Holds the model for reference codes, used to (de)serialize in integrations and use in flows
global class ReferentieCodeModel {
    @AuraEnabled @InvocableVariable
    global String code;
    @AuraEnabled @InvocableVariable
    global String naam;

    public static ReferentieCodeModel getMock(String typeName) {
        ReferentieCodeModel model = new ReferentieCodeModel();
        model.code = typeName;
        model.naam = typeName+'mock-naam';
        return model;
    }
}