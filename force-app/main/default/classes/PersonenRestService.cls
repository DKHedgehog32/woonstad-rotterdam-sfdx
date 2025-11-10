//
// Webservice definition for Relations
@RestResource(urlMapping='/relations/personen/*')
global with sharing class PersonenRestService {

    @HttpGet
    global static void getRelation() {
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
            System.debug('## INCOMING GET '+relationUuid);

            //
            // UUID is mandatory for the get
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
                // Returns null if nothing found
                try {
                    PersoonModel pm = PersoonService.getPersoonByUuid(relationUuid);
                    if(pm <> null) {
                        responseBodyStructure.persoon = pm;
                        responseBodyStructure.isSuccess = true;
                        res.statusCode = 200;
                        res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
                    } else {
                        responseBodyStructure.errors.add('Not Found');
                        responseBodyStructure.isSuccess = false;
                        res.statusCode = 404;
                        res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
                    }
                } catch(Exception ex) {
                    ApexFaultHandler.publishError(ex, 'PersonenRestService' ,'getRelation');
                }
            }
        } catch(Exception e) {
            //
            // JSON body response
            responseBodyStructure.isSuccess = false;
            responseBodyStructure.errors.add(e.getMessage());
            ApexFaultHandler.publishError(e, 'PersonenRestService' ,'getRelation');

            //
            // Http level response
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
        }
        System.debug('### Service getRelation returning '+JSON.serializePretty(responseBodyStructure));

    }
    @HttpPost
    global static void postRelation() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        //
        // Holds the response that will be serialized into the body of the response
        RestServiceResponse responseBodyStructure = new RestServiceResponse();
        responseBodyStructure.errors = new List<String>();
        //
        // Rollback in case of errors
        Savepoint sp = Database.setSavepoint();
        try {
            System.debug('## INCOMING POST '+req.requestBody.toString());
            PersoonModel persoonInput = (PersoonModel) JSON.deserialize(req.requestBody.toString(), PersoonModel.class);
            System.debug('## Converted to persoon '+JSON.serializePretty(persoonInput));
            //
            // Validate the POST request
            PersoonService.PersoonRequestValidationResult validationResult = PersoonService.validatePostRequest(persoonInput);
            if(validationResult.isValid) {
                PersoonModel persoonOutput = PersoonService.postPersoon(persoonInput);
                responseBodyStructure.persoon = persoonOutput;
                responseBodyStructure.isSuccess = true;
                res.statusCode = 201;
                res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
            } else {
                //
                // Return validation errors in case the post was invalid
                responseBodyStructure.isSuccess = false;
                responseBodyStructure.errors.addAll(validationResult.validationErrors);
                Database.rollback(sp);
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));

            }

        } catch(Exception e) {
            //
            // JSON body response
            responseBodyStructure.isSuccess = false;
            responseBodyStructure.errors.add(e.getMessage());
            Database.rollback(sp);
            ApexFaultHandler.publishError(e, 'PersonenRestService' ,'postRelation');
            //
            // Http level response
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
        }
        System.debug('### Service POST relation returning '+JSON.serializePretty(responseBodyStructure));

    }
    @HttpPatch
    global static void patchRelation() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        //
        // Holds the response that will be serialized into the body of the response
        RestServiceResponse responseBodyStructure = new RestServiceResponse();
        responseBodyStructure.errors = new List<String>();
        //
        // Rollback in case of errors
        Savepoint sp = Database.setSavepoint();
        try {
            //
            // Pick up the requested UUID from the request. May result in a string value of 'null'
            String relationUuid = String.escapeSingleQuotes(req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1));
            System.debug('## INCOMING PATCH UUID '+relationUuid);
            System.debug('## INCOMING PATCH BODY '+req.requestBody.toString());

            PersoonModel persoonInput = (PersoonModel) JSON.deserialize(req.requestBody.toString(), PersoonModel.class);
            //
            // Validate the PATCH request
            PersoonService.PersoonRequestValidationResult validationResult = PersoonService.validatePatchRequest(persoonInput);
            if(validationResult.isValid) {
                responseBodyStructure.persoon = PersoonService.patchPersoon(relationUuid, persoonInput);
                responseBodyStructure.isSuccess = true;
                res.statusCode = 201;
                res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));

            } else {
                //
                // Return validation errors in case the post was invalid
                responseBodyStructure.isSuccess = false;
                responseBodyStructure.errors.addAll(validationResult.validationErrors);
                Database.rollback(sp);
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));

            }

        } catch(Exception e) {
            //
            // JSON body response
            responseBodyStructure.isSuccess = false;
            responseBodyStructure.errors.add(e.getMessage());
            Database.rollback(sp);
            ApexFaultHandler.publishError(e, 'PersonenRestService' ,'patchRelation');

            //
            // Http level response
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
        }
        System.debug('### Service Patch relation returning '+JSON.serializePretty(responseBodyStructure));
    }
    public class RelationRestServiceException extends Exception {

    }
    //
    // Test methods for both unit and ad hoc testing
    public static RestResponse testGetCall(String uuid) {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/relations/personen/'+uuid;
        req.params.put('uuid',uuid);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response= res;
        PersonenRestService.getRelation();
        String JSONval = res.responseBody.toString().unescapeJava();
        System.debug(res.statusCode+' ## RES '+JSONval);
        return res;
    }
    public static RestResponse testPostCall(PersoonModel pers) {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/relations/personen';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(pers));
        RestContext.request = req;
        RestContext.response= res;
        PersonenRestService.postRelation();
        String JSONval = res.responseBody.toString().unescapeJava();
        System.debug(res.statusCode+' ## RES '+JSONval);
        return res;
    }

    public static RestResponse testPatchCall(PersoonModel pers, String uuid) {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/relations/personen/'+uuid;
        req.httpMethod = 'PUT';
        req.requestBody = Blob.valueOf(JSON.serialize(pers));
        RestContext.request = req;
        RestContext.response= res;
        PersonenRestService.patchRelation();
        String JSONval = res.responseBody.toString().unescapeJava();
        System.debug(res.statusCode+' ## RES '+JSONval);
        return res;
    }

}