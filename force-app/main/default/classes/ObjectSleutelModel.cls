/**
 * Model for https://github.com/woonstadrotterdam/woonstad-openapi/blob/main/models/Generiek/Object-sleutels.yaml
 */

global class ObjectSleutelModel {
    @AuraEnabled @InvocableVariable
    global String id;
    @AuraEnabled @InvocableVariable
    global String idExtern;
    @AuraEnabled @InvocableVariable
    global String idAdministratie;
    @AuraEnabled @InvocableVariable
    global String code;

    public static ObjectSleutelModel getMock(String idValue) {
        ObjectSleutelModel model = new ObjectSleutelModel();
        model.code = idValue;
        model.idExtern = 'extid';
        model.idAdministratie = 'WOCAS';
        model.id = idValue;
        return model;
    }
}