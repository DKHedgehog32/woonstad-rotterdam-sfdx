/**
 * Represents the cluster model in Apex
 * https://github.com/woonstadrotterdam/woonstad-openapi/blob/main/apis/Experience/app-salesforce.yaml
 *
 *     Cluster:
      title: Cluster
      x-stoplight:
        id: xtvnr2byeutnf
      type: object
      properties:
        id:
          type: string
          description: De primaire sleutel van het gegeven in het bronsysteem.
        idExtern:
          type: string
          description: De primaire sleutel van het gegeven in het doelsysteem. .
        idAdministratie:
          type: string
          description: Dit verwijst naar de administratie waar het gegeven onderdeel van is. Horende bij de idExtern.
        code:
          type: string
          description: De unieke code (Bijvoorbeeld om te tonen of te zoeken)
        soort:
          allOf:
            - $ref: '#/components/schemas/Referentiedata'
          description: 'Het soort cluster. Bijvoorbeeld, nieuwbouwcluster, onderhoudscluster, financieel cluster. Referentiedatasoort CLUSTERSOORT.'
        naam:
          type: string
          description: De naam van de cluster.
        omschrijving:
          type: string
          description: De omschrijving van de cluster.
        begindatum:
          type: string
          description: De begindatum van de cluster.
        einddatum:
          type: string
          description: De einddatum van de cluster.
        rollen:
          type: array
          x-stoplight:
            id: iy1p52agyqeog
          items:
            $ref: '#/components/schemas/Clusterrol'

 */

global class ClusterModel {
    @AuraEnabled @InvocableVariable
    global String id;
    @AuraEnabled @InvocableVariable
    global String idExtern;
    @AuraEnabled @InvocableVariable
    global String idAdministratie;
    @AuraEnabled @InvocableVariable
    global String code;

    /*
    Soort:
District	BUU
Financial	FIN
Market	MAR
Maintenance	OND
Project	PRO
Rayon	RAY
Service Charges	SER
Consumption Costs	STO
Strategic	STR
Owners Association	VVE
Neighborhood	WIJ
Valuation	WRD
     */
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel soort;
    @AuraEnabled @InvocableVariable
    global String naam;
    @AuraEnabled @InvocableVariable
    global String omschrijving;
    @AuraEnabled @InvocableVariable
    global Date begindatum;
    @AuraEnabled @InvocableVariable
    global Date einddatum;
    @AuraEnabled @InvocableVariable
    global List<ClusterrolModel> rollen;

    public static ClusterModel getMock(String persoonId) {
        ClusterModel model = new ClusterModel();
        model.id = 'mock-cluster-id';
        model.idAdministratie = 'Salesforce';
        model.idExtern = 'clust1312';
        model.omschrijving = 'een cluster';
        model.naam = 'cluster x';
        model.begindatum = System.today();
        model.soort = new ReferentieCodeModel();
        model.soort.code = 'STR';
        model.rollen = new List<ClusterrolModel>();
        model.rollen.add(ClusterrolModel.getMock(persoonId));
        return model;
    }
}