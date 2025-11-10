/**
 * Represents the clusterrol model in Apex
 * https://github.com/woonstadrotterdam/woonstad-openapi/blob/main/apis/Experience/app-salesforce.yaml
 *     Clusterrol:
      title: Clusterrol
      x-stoplight:
        id: ijmw76r2nl67u
      type: object
      properties:
        id:
        idCluster:
        rol:
        idPersoon:
        begindatum:

        einddatum:

      description: Beschrijft een rol behorende bij een cluster. Bv de beheerder.
 */

global class ClusterrolModel {
    @AuraEnabled @InvocableVariable
    global String id;
    @AuraEnabled @InvocableVariable
    global String idCluster;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel rol;
    @AuraEnabled @InvocableVariable
    global String idPersoon;
    @AuraEnabled @InvocableVariable
    global Date begindatum;
    @AuraEnabled @InvocableVariable
    global Date einddatum;

    public static ClusterrolModel getMock(String persoonId) {
        ClusterrolModel model = new ClusterrolModel();
        model.begindatum = System.today().addDays(1);
        model.einddatum =  System.today().addDays(1).addYears(1);
        model.id = 'abcd1234';
        model.rol = new ReferentieCodeModel();
        model.rol.code = 'Placeholder';
        model.idPersoon = persoonId;
        return model;
    }
}