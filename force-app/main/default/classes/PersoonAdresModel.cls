//
// Holds the model for person address, used to (de)serialize in integrations and use in flows
global class PersoonAdresModel {
    @AuraEnabled @InvocableVariable
    global String id; // SF ID

    @AuraEnabled @InvocableVariable
    global String idPersoon; // SF Persoon UUID

    //
    // Adres Soort: https://www.coraveraonline.nl/index.php/Referentiedata:ADRESSOORT
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel soort;
    @AuraEnabled @InvocableVariable
    global Date begindatum;
    @AuraEnabled @InvocableVariable
    global Date einddatum;
    @AuraEnabled @InvocableVariable
    global AdresModel adres;

    public static PersoonAdresModel getMock(String persoonId) {
        PersoonAdresModel model = new PersoonAdresModel();
        model.id = 'mock-id';
        model.begindatum = System.today().addDays(-1);
        model.einddatum =  System.today().addDays(-1).addYears(1);
        model.soort = ReferentieCodeModel.getMock('adres-soort');
        model.soort.code = 'EEN'; // Valid code
        model.adres = AdresModel.getMock();
        model.idPersoon = persoonId;
        return model;
    }
}