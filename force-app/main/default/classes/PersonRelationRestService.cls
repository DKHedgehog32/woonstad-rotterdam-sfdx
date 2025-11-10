//
// Webservice definition for Relations
@RestResource(urlMapping='/relations/personen/persoon-relaties/*')
global with sharing class PersonRelationRestService {

    @HttpGet
    global static void getPersonRelations() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        //
        // Holds the response that will be serialized into the body of the response
        RestServiceResponse responseBodyStructure = new RestServiceResponse();
        responseBodyStructure.errors = new List<String>();

        try {

            //
            // Pick up the requested UUID from the request. May result in a string value of 'null'
            String relationUuid = String.escapeSingleQuotes(req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1));
            System.debug('## Incoming GET PersonRelations '+relationUuid);

            //
            // UUID is mandatory for the get
            if (relationUuid == null || relationUuid == 'null' || String.isEmpty(relationUuid)) {
                //
                // JSON body response
                responseBodyStructure.isSuccess = false;
                responseBodyStructure.errors.add('No resource requested; person uuid parameter is mandatory');
                //
                // Http level response
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
            } else {
                // Returns null if nothing found
                try {
                    List<PersoonRelatieModel> pmr = PersonRelationService.getRelationsByUuid(relationUuid);
                    if(pmr <> null) {
                        responseBodyStructure.relaties = pmr;
                        responseBodyStructure.isSuccess = true;
                        res.statusCode = 200;
                        res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
                    } else {
                        responseBodyStructure.errors.add('Not Found');
                        responseBodyStructure.isSuccess = false;
                        res.statusCode = 404;
                        res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
                    }
                } catch(Exception e) {
                    ApexFaultHandler.publishError(e, 'PersonRelationRestService' ,'getRelationsByUuid');
                    responseBodyStructure.errors.add(e.getMessage());
                    responseBodyStructure.isSuccess = false;
                    res.statusCode = 500;
                    res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
                }
            }
        } catch(Exception e) {
            ApexFaultHandler.publishError(e, 'PersonRelationRestService' ,'getPersonRelations');
            //
            // JSON body response
            responseBodyStructure.isSuccess = false;
            responseBodyStructure.errors.add(e.getMessage());

            //
            // Http level response
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
        }
        System.debug('### Service get person relations returning '+JSON.serializePretty(responseBodyStructure));

    }

    public static RestResponse testGetCall(String uuid) {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/relations/personen/persoon-relaties/'+uuid;
        req.params.put('uuid',uuid);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response= res;
        PersonRelationRestService.getPersonRelations();
        String JSONval = res.responseBody.toString().unescapeJava();
        System.debug(res.statusCode+' ## RES '+JSONval);
        return res;
    }
}