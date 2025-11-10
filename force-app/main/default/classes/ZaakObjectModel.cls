/**
 * Created by harm on 10/02/2025.
 */

global class ZaakObjectModel {
    @AuraEnabled @InvocableVariable
    global String id;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel soort;
    public static ZaakObjectModel getMock() {
        ZaakObjectModel model = new ZaakObjectModel();
        return model;
    }
}