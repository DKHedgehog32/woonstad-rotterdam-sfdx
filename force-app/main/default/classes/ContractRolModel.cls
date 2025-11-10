/**
 * Models a contractrol.
 *     {
        "id": "string",
    "idContract": "string",
    "rol": "string",
    "idPersoon": "string",
    "begindatum": "2024-09-16",
    "einddatum": "2024-09-16"
    }
 */
global class ContractRolModel {
    @AuraEnabled @InvocableVariable
    global String id;
    @AuraEnabled @InvocableVariable
    global String idContract;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel rol;
    @AuraEnabled @InvocableVariable
    global String idPersoon;
    @AuraEnabled @InvocableVariable
    global Date begindatum;
    @AuraEnabled @InvocableVariable
    global Date einddatum;

    public static ContractRolModel getMock(String contractId, String persoonId) {
        ContractRolModel model = new ContractRolModel();
        model.id = 'mock-id';
        model.begindatum = System.today().addDays(1);
        model.einddatum =  System.today().addDays(1).addYears(1);
        model.idContract = contractId;
        model.idPersoon = persoonId;
        model.rol = new ReferentieCodeModel();
        model.rol.code = 'HUU';
        return model;
    }
}