//
// Holds the model for person details (private person or legal entity ("rechtspersoon"), used to (de)serialize in integrations and use in flows
global class PersoonModel {
    //
    // Base relation
    @AuraEnabled @InvocableVariable
    global String id;
    @AuraEnabled @InvocableVariable
    global String idExtern;
    @AuraEnabled @InvocableVariable
    global String idAdministratie;
    @AuraEnabled @InvocableVariable
    global String code;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel soort;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel detailSoort;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel status;
    @AuraEnabled @InvocableVariable
    global PersoonAdresModel woonadres;
    @AuraEnabled @InvocableVariable
    global PersoonAdresModel postadres;
    @AuraEnabled @InvocableVariable
    global ContactGegevensModel contactgegevens;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel communicatievoorkeur;

    //
    // Specific for "natuurlijk persoon"
    @AuraEnabled @InvocableVariable
    global String bsn;
    @AuraEnabled @InvocableVariable
    global Date geboortedatum;
    @AuraEnabled @InvocableVariable
    global Date overlijdensdatum;
    @AuraEnabled @InvocableVariable
    global String aanhef;
    @AuraEnabled @InvocableVariable
    global String aanschrijfnaam;
    @AuraEnabled @InvocableVariable
    global String achternaam;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel burgerlijkeStaat;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel geslacht;
    @AuraEnabled @InvocableVariable
    global String geslachtsnaam;
    @AuraEnabled @InvocableVariable
    global String initialen;
    @AuraEnabled @InvocableVariable
    global String nationaliteit;
    @AuraEnabled @InvocableVariable
    global String roepnaam;
    @AuraEnabled @InvocableVariable
    global String tussenvoegsels;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel voorkeurstaal;
    @AuraEnabled @InvocableVariable
    global String voorletters;
    @AuraEnabled @InvocableVariable
    global String voornaam;
    @AuraEnabled @InvocableVariable
    global List<BetaalgegevenModel> betaalgegevens;
    @AuraEnabled @InvocableVariable
    global List<PersoonRelatieModel> persoonRelaties;
    //
    // Specific for "rechtspersoon"
    @AuraEnabled @InvocableVariable
    global String naam;
    @AuraEnabled @InvocableVariable
    global String btwNummer;
    @AuraEnabled @InvocableVariable
    global String globaalLocatienummer;
    @AuraEnabled @InvocableVariable
    global String kvkNummer;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel organisatievorm;
    @AuraEnabled @InvocableVariable
    global Boolean isCrediteur;

    public static PersoonModel getMock() {
        PersoonModel model = new PersoonModel();
        model.id = '';
        model.soort = ReferentieCodeModel.getMock('relatie-soort');
        model.soort.code = 'NAT';
        model.soort.naam = 'Natuurlijk Persoon';
        model.idExtern = 'extid';
        model.idAdministratie = 'Salesforce';
        model.voornaam = 'Rikkert';
        model.isCrediteur = false;
        model.geslacht = ReferentieCodeModel.getMock('persoon-geslacht');
        model.geslacht.code = 'V';
        model.detailSoort = ReferentieCodeModel.getMock('relatie-detailsoort');
        model.achternaam = 'Batsbak';
        model.status = ReferentieCodeModel.getMock('persoon-status');
        model.betaalgegevens = new List<BetaalgegevenModel> { BetaalgegevenModel.getMock() };
        model.aanschrijfnaam = 'Meester';
        model.bsn = '10101010101';
        model.burgerlijkeStaat = ReferentieCodeModel.getMock('persoon-burgstaat');
        model.contactGegevens = ContactGegevensModel.getMock();
        model.persoonRelaties = new List<PersoonRelatieModel> { PersoonRelatieModel.getMock('mock-id') };
        model.postadres = PersoonAdresModel.getMock('mock-id');
        model.postadres.adres = new AdresModel();
        model.postadres.adres.straatnaam = 'BErglaan';
        model.postadres.adres.woonplaats = 'Zwollywood';
        model.postadres.adres.postcode = '4222UU';
        model.postadres.adres.huisnummer = '55';
        model.postadres.adres.land = new ReferentieCodeModel();
        model.postadres.adres.land.code = 'NL';

        model.woonadres = PersoonAdresModel.getMock('mock-id');
        model.woonadres.adres.straatnaam = 'Hoofdlaan';
        model.woonadres.adres.woonplaats = 'Ljouwert';
        model.woonadres.adres.postcode = '5325XX';
        model.woonadres.adres.huisnummer = '111';
        model.woonadres.adres.land = new ReferentieCodeModel();
        model.woonadres.adres.land.code = 'NL';
        model.voorkeurstaal = ReferentieCodeModel.getMock('persoon-voorkeurstaal');
        model.organisatievorm = ReferentieCodeModel.getMock('persoon-orgvorm');
        model.kvkNummer = 'kvknr-mock1234';
        model.communicatievoorkeur = ReferentieCodeModel.getMock('EMA');
        return model;
    }

}