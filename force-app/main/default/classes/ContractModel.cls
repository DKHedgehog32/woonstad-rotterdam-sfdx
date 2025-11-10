/**
 * Represents the contract model in Apex
 * https://github.com/woonstadrotterdam/woonstad-openapi/blob/main/apis/Process/wr-contracten.yaml
 *
        id:
        idExtern:
        idAdministratie:
        code:
        soort:
        detailSoort:
        bovenliggendeOvereenkomst:
        idPersoon:
        idContractPartij:
        status:
        begindatum:
        einddatum:
        brutoHuurprijs:
        eenheden:
        rollen:
*/
global class ContractModel {
    //
    // Specifiek voor Wocas handling
    @AuraEnabled @InvocableVariable
    global Date huurprijsWijzigingVanafDatum;
    @AuraEnabled @InvocableVariable
    global String bronSysteem;

    //
    // Vera/Cora "light"
    // Base contract
    @AuraEnabled @InvocableVariable
    global String idPersoon;
    @AuraEnabled @InvocableVariable
    global String idContractPartij;
    @AuraEnabled @InvocableVariable
    global Decimal brutoContractprijs; // Dit word uiteindelijke generieke naam?
    @AuraEnabled @InvocableVariable
    global String id;
    @AuraEnabled @InvocableVariable
    global String idExtern; // (object id)
    @AuraEnabled @InvocableVariable
    global String idAdministratie;
    @AuraEnabled @InvocableVariable
    global String code;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel soort;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel detailSoort;
    @AuraEnabled @InvocableVariable
    global String bovenliggendeOvereenkomst;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel status;
    @AuraEnabled @InvocableVariable
    global Date begindatum;
    @AuraEnabled @InvocableVariable
    global Date einddatum;
    @AuraEnabled @InvocableVariable
    global DateTime geldigVanafDatumTijd;
    @AuraEnabled @InvocableVariable
    global String idBetaalgegeven;
    @AuraEnabled @InvocableVariable
    global List<ObjectSleutelModel> eenheden; // Altijd 1
    @AuraEnabled @InvocableVariable
    global List<ContractRolModel> rollen;
    @AuraEnabled @InvocableVariable
    global String feitelijkGebruik;

    public static ContractModel getMock(String persoonId) {
        ContractModel model = new ContractModel();
        model.idPersoon = persoonId;
        model.begindatum = System.today().addDays(1);
        model.einddatum =  System.today().addDays(1).addYears(1);
        model.id = 'abcd1234';
        model.idContractPartij = persoonId;
        model.idAdministratie = 'Salesforce';
        model.idExtern = 'abaa12';
        model.code = 'code123';
        model.brutoContractprijs = 123;
        model.soort = new ReferentieCodeModel();
        model.soort.code = 'HUU';
        model.detailSoort = new ReferentieCodeModel();
        model.detailSoort.code = 'ONB';
        model.status = new ReferentieCodeModel();
        model.status.code = 'LOP';
        model.rollen = new List<ContractRolModel>();
        model.rollen.add(ContractRolModel.getMock('abaa12',persoonId));
        model.eenheden = new List<ObjectSleutelModel>();
        model.eenheden.add(ObjectSleutelModel.getMock('12345669'));
        model.bovenliggendeOvereenkomst = '1234';
        return model;
    }
}