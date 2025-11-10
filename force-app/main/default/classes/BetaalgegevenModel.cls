//
// Holds the model for payment details, used to (de)serialize in integrations and use in flows
global class BetaalgegevenModel {
    @AuraEnabled @InvocableVariable
    global String id;
    @AuraEnabled @InvocableVariable
    global String idExtern;
    @AuraEnabled @InvocableVariable
    global String idAdministratie;
    @AuraEnabled @InvocableVariable
    global String code;
    @AuraEnabled @InvocableVariable
    global Date begindatum;
    @AuraEnabled @InvocableVariable
    global Date einddatum;
    @AuraEnabled @InvocableVariable
    global String bic;
    @AuraEnabled @InvocableVariable
    global String iban;
    @AuraEnabled @InvocableVariable
    global Boolean primair;
    @AuraEnabled @InvocableVariable
    global String rekeninghouder;
    @AuraEnabled @InvocableVariable
    global String rekeningPlaats;
    @AuraEnabled @InvocableVariable
    global String land;
    @AuraEnabled @InvocableVariable
    global Boolean actief;


    //
    // For bank accounts outside a person structure
    @AuraEnabled @InvocableVariable
    global String idPersoon;

    public static BetaalgegevenModel getMock() {
        BetaalgegevenModel model = new BetaalgegevenModel();
        model.id = 'mock-id';
        model.begindatum = System.today().addDays(1);
        model.einddatum =  System.today().addDays(1).addYears(1);
        model.land = 'NL';
        model.id = 'abcd1234';
        model.iban = 'NL39INGB0961695730';
        model.primair = true;
        model.idAdministratie = 'Salesforce';
        model.idExtern = 'abaa12';
        model.bic = 'INGBNL2A';
        model.rekeninghouder = 'Moneyman';
        model.rekeningPlaats = 'Citystad';
        model.idPersoon = 'mock-id';
        model.actief = true;
        return model;
    }
}