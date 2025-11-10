//
// Webservice definition for adresses
/*

String jsonValue = '{';
jsonValue += '    "idExtern": "1158603",';
jsonValue += '    "idAdministratie": "WOCAS",';
jsonValue += '    "idPersoon": "f4b5422c-6edb-4e44-9048-a5becfa36b88",';
jsonValue += '    "begindatum": "2026-01-01",';
jsonValue += '    "soort": { "code": "WOO", "naam": "Woonadres" },';
jsonValue += '    "adres": { "woonplaats": "HOOGVLIET ROTTERDAM", "straatnaam": " Laafnet", "provincie": {}, "postcode": "3192 DC", "land": { "code": "NL" }, "huisnummerToevoeging": null, "huisnummer": "16" }';
jsonValue += '}';
PersoonAdressenRestService.testPostCall((PersoonAdresModel)JSON.deserialize(jsonValue, PersoonAdresModel.class));
 */
@RestResource(urlMapping='/relations/persoon-adressen/*')
global without sharing class PersoonAdressenRestService {
    @HttpGet
    global static void getPersoonAdressen() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        System.debug('### PARAMS '+req.params);
        //
        // Holds the response that will be serialized into the body of the response
        RestServiceResponse responseBodyStructure = new RestServiceResponse();
        responseBodyStructure.errors = new List<String>();
        //
        // Pick up the requested UUID from the request. May result in a string value of 'null'
        String relationUuid = req.params?.get('persoon-id');
        System.debug('### relationUuid '+relationUuid);
        if (relationUuid == null || relationUuid == 'null' || String.isEmpty(relationUuid)) {
            //
            // JSON body response
            responseBodyStructure.isSuccess = false;
            responseBodyStructure.errors.add('No resource requested; uuid parameter is mandatory');
            //
            // Http level response
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
        } else {
            try {
                List<PersoonAdresModel> addresses = AddressService.getPersoonAddressen(relationUuid);
                if(addresses <> null && addresses.size() > 0) {
                    responseBodyStructure.addresses = addresses;
                    responseBodyStructure.isSuccess = true;
                    //
                    // Http level response
                    res.statusCode = 200;
                    res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));

                } else {
                    responseBodyStructure.errors.add('Not Found');
                    responseBodyStructure.isSuccess = false;
                    res.statusCode = 404;
                    res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
                }

            } catch (Exception e) {
                responseBodyStructure.errors.add(e.getMessage());
                responseBodyStructure.isSuccess = false;
                res.statusCode = 500;
                res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
                ApexFaultHandler.publishError(e, 'PersoonAdressenRestService', 'PersoonAdressenRestService');
            }
        }
    }

    @HttpPost
    global static void postPersoonAdres() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        System.debug('### PARAMS '+req.params);
        //
        // Holds the response that will be serialized into the body of the response
        RestServiceResponse responseBodyStructure = new RestServiceResponse();
        responseBodyStructure.errors = new List<String>();

        try {
            System.debug('## INCOMING POST '+req.requestBody.toString());
            PersoonAdresModel persoonAddresInput = (PersoonAdresModel) JSON.deserialize(req.requestBody.toString(), PersoonAdresModel.class);
            Account_Address__c accAddress = AddressService.convertPersoonAddress(persoonAddresInput, persoonAddresInput.idPersoon);
            upsert accAddress Schema.Account_Address__c.Deduplication_Key__c;
            persoonAddresInput.id = accAddress.Id; // Map Id back
            //
            // JSON body response
            responseBodyStructure.isSuccess = true;
            responseBodyStructure.addresses = new List<PersoonAdresModel>();
            responseBodyStructure.addresses.add(persoonAddresInput);

            //
            // Http level response
            res.statusCode = 201; // Created
            res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));

        } catch (Exception e) {
            responseBodyStructure.errors.add(e.getMessage());
            responseBodyStructure.isSuccess = false;
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
            ApexFaultHandler.publishError(e, 'PersoonAdressenRestService', 'postPersoonAdres');
        }
    }
    //
    // Test methods for both unit and ad hoc testing
    /*
    PersoonAdresModel cm = PersoonAdresModel.getMock('88772362-45e1-4b06-8a99-5884e0003c35');
    OkapiPostPersonAddressesInvocable.postPersonAddresses(new List<PersoonAdresModel> { cm });
     */

    public static RestResponse testGetCall(String uuid) {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/relations/persoon-adressen';
        req.params.put('persoon-id',uuid);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response= res;

        PersoonAdressenRestService.getPersoonAdressen();
        String JSONval = res.responseBody.toString().unescapeJava();
        System.debug(res.statusCode+' ## RES '+JSONval);
        return res;
    }
    public static RestResponse testPostCall(PersoonAdresModel pma) {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/relations/persoon-adressen';
        req.requestBody = Blob.valueOf(JSON.serialize(pma));

        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response= res;
        PersoonAdressenRestService.postPersoonAdres();
        String JSONval = res.responseBody.toString().unescapeJava();
        System.debug(res.statusCode+' ## RES '+JSONval);
        return res;
    }
}