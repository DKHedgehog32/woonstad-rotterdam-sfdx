//
// Holds the model for case details, used to (de)serialize in integrations and use in flows
// Partial implementation of Zaak in https://github.com/woonstadrotterdam/woonstad-openapi/blob/main/apis/Process/wr-dossier.yaml
global class ZaakModel {
    @AuraEnabled @InvocableVariable
    global String id;
    @AuraEnabled @InvocableVariable
    global String idExtern;
    @AuraEnabled @InvocableVariable
    global String idAdministratie;
    @AuraEnabled @InvocableVariable
    global String code;
    @AuraEnabled @InvocableVariable
    global String idPersoon;

    @AuraEnabled @InvocableVariable
    global Date begindatum;
    @AuraEnabled @InvocableVariable
    global Date einddatum;
    @AuraEnabled @InvocableVariable
    global Date registratiedatum; // INCLUSIEF TZ?
    @AuraEnabled @InvocableVariable
    global Date publicatiedatum;
    @AuraEnabled @InvocableVariable
    global Date geplandeEinddatum;
    @AuraEnabled @InvocableVariable
    global Date uiterlijkeEinddatum;

    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel soort;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel detailSoort;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel status;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel oorsprong;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel reden;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel prioriteit;

    @AuraEnabled @InvocableVariable
    global String onderwerp;
    @AuraEnabled @InvocableVariable
    global String omschrijving;
    @AuraEnabled @InvocableVariable
    global String toelichting;
    @AuraEnabled @InvocableVariable
    global ObjectSleutelModel bovenliggendeZaak;
    @AuraEnabled @InvocableVariable
    global List<ZaakRolModel> rollen;

    //
    // Eigenaar als extra attribuut met naam federationIdEigenaar en waarde username/federation id
    @AuraEnabled @InvocableVariable
    global List<ExtraAttribuutModel> extraAttributen;
    @AuraEnabled @InvocableVariable
    global List<InformatieObjectModel> informatieobjecten;
    @AuraEnabled @InvocableVariable
    global List<ZaakObjectModel> objecten;
    //@AuraEnabled @InvocableVariable
    //global List<ZaakSoortAttribuutModel> soortAttributen;
    @AuraEnabled @InvocableVariable
    global List<Id> contentVersionIds;
    @AuraEnabled @InvocableVariable
    global List<Id> contentDocumentIds;

    public static ZaakModel getMock(String persoonId) {
        ZaakModel model = new ZaakModel();
        model.id = 'mock-id';
        model.begindatum = System.today().addDays(1);
        model.einddatum =  System.today().addDays(1).addYears(1);
        model.registratiedatum = System.today();
        model.publicatiedatum = System.today();
        model.geplandeEinddatum = System.today().addDays(1).addYears(1);
        model.uiterlijkeEinddatum = System.today().addDays(1).addYears(10); // Tijd zat!
        model.idPersoon = persoonId;
        model.idAdministratie = 'Salesforce';
        model.idExtern = 'abaa12';
        model.onderwerp = 'test zaak';
        model.omschrijving = 'gemockede zaak omschrijving';
        model.code = 'code12';
        return model;
    }
}