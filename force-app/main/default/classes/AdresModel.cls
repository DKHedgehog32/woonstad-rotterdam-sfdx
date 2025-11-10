//
// Holds the model for addresses, used to (de)serialize in integrations and use in flows
global class AdresModel {
    //
    // Adres
    @AuraEnabled @InvocableVariable
    global String adres;
    @AuraEnabled @InvocableVariable
    global String straatnaam;
    @AuraEnabled @InvocableVariable
    global String huisnummer;
    @AuraEnabled @InvocableVariable
    global String huisletter;
    @AuraEnabled @InvocableVariable
    global String huisnummerToevoeging;
    @AuraEnabled @InvocableVariable
    global String postcode;
    @AuraEnabled @InvocableVariable
    global String woonplaats;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel provincie;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel land;
    @AuraEnabled @InvocableVariable
    global String adresregel1;
    @AuraEnabled @InvocableVariable
    global String adresregel2;
    @AuraEnabled @InvocableVariable
    global String postbusnummer;
    @AuraEnabled @InvocableVariable
    global String antwoordnummer;
    @AuraEnabled @InvocableVariable
    global String aanduiding;

    public static AdresModel getMock() {
        AdresModel model = new AdresModel();
        model.adres = 'street 1';
        //model.antwoordnummer = '12345';
        model.huisletter = 'a';
        model.huisnummer = '1';
        model.huisnummerToevoeging = 'AB';
        model.land = ReferentieCodeModel.getMock('adres-land');
        model.land.code = 'NL';
        model.straatnaam = 'Hoofdstraat';
        //model.postbusnummer = '110';
        model.postcode = '1111AA';
        model.provincie = ReferentieCodeModel.getMock('adres-provincie');
        model.provincie.code = 'FR';
        model.woonplaats = 'Stadburgerdam';
        return model;
    }
}