//
// Holds the model for person relations, used to (de)serialize in integrations and use in flows
global class PersoonRelatieModel {
    @AuraEnabled @InvocableVariable
    global String id;
    @AuraEnabled @InvocableVariable
    global String idExtern;
    @AuraEnabled @InvocableVariable
    global String idAdministratie;
    @AuraEnabled @InvocableVariable
    global String persoonId;
    @AuraEnabled @InvocableVariable
    global String relatieId;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel persoonRol;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel relatieRol;
    @AuraEnabled @InvocableVariable
    global Date begindatum;
    @AuraEnabled @InvocableVariable
    global Date einddatum;

    public static PersoonRelatieModel getMock(String uuid) {
        PersoonRelatieModel model = new PersoonRelatieModel();
        model.id = 'relid';
        model.idExtern = 'extid';
        model.idAdministratie = 'Salesforce';
        model.persoonId = uuid;
        model.relatieId = 'mock-id-ander';
        model.persoonRol = ReferentieCodeModel.getMock('persoonrol');
        model.relatieRol = ReferentieCodeModel.getMock('relatierol');
        model.begindatum = System.today();
        model.einddatum = System.today().addYears(10);
        return model;
    }
}