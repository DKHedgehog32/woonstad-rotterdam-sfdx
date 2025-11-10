/**
 * Represents the contract-eenheid model in Apex
 * https://github.com/woonstadrotterdam/woonstad-openapi/blob/main/apis/Process/wr-contracten.yaml
 */

global class ContractEenheidModel {

    @AuraEnabled @InvocableVariable
    global String id;
    @AuraEnabled @InvocableVariable
    global String idExtern;
    @AuraEnabled @InvocableVariable
    global String idAdministratie;
    /* Category?
        Business Area	BED
        Intramural Care Property	INT
        Social Property	MOG
        Other	OVE
        Parking	PAR
        Recreational	REC
        Residential	WOO
     */
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel soort;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel detailSoort;
    @AuraEnabled @InvocableVariable
    global String naam;
    @AuraEnabled @InvocableVariable
    global String omschrijving;
    /*
    Administrative	ADM
    Vacant	LEE
    Under development	ONT
    Out of exploitation	UIT
    Rented	VEH
     */
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel status;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel detailStatus;
    @AuraEnabled @InvocableVariable
    global AdresModel adres;
    @AuraEnabled @InvocableVariable
    global String volgnummer;
    /*
Outside urban area	BBK
Sheltered location	BES
In wooded area	BOS
At the edge of forest	BRA
In town center	CEN
On busy road	DRU
Rural location	LAN
Open location	OPE
Near park	PAR
On quiet road	RUS
Near waterways	VAA
Open view	VRI
Near water	WAT
In residential area	WOO
     */
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel vestiging;
    @AuraEnabled @InvocableVariable
    global ReferentieCodeModel rayon;
    @AuraEnabled @InvocableVariable
    global List<ClusterModel> clusters;

    public static ContractEenheidModel getMock(String persoonId) {
        ContractEenheidModel model = new ContractEenheidModel();
        model.id = 'mock-eh-id';
        model.idAdministratie = 'Salesforce';
        model.idExtern = 'abaa122eh';
        model.omschrijving = 'HUIS in straat';
        model.naam = 'HUIS';
        model.volgnummer = '1';
        model.soort = new ReferentieCodeModel();
        model.soort.code = 'BED';
        model.vestiging = new ReferentieCodeModel();
        model.vestiging.code = 'CEN';
        model.status = new ReferentieCodeModel();
        model.status.code = 'LEE';
        model.clusters = new List<ClusterModel>();
        model.clusters.add(ClusterModel.getMock(persoonId));
        model.adres = AdresModel.getMock();
        return model;
    }
}