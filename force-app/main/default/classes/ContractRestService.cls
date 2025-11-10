//
// Webservice definition for Relations
/*
ContractModel cm = ContractModel.getMock('88772362-45e1-4b06-8a99-5884e0003c35');
cm.rollen[0].idPersoon = '88772362-45e1-4b06-8a99-5884e0003c35';
cm.eenheden[0].clusters[0].rollen[0].idPersoon = '88772362-45e1-4b06-8a99-5884e0003c35';
ContractRestService.testPatchCall(cm);
 */

@RestResource(urlMapping='/contracten/contracten/*')
global with sharing class ContractRestService {

    @HttpPatch
    global static void patchContract() {
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
            String ctrId = String.escapeSingleQuotes(req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1));
            System.debug('## INCOMING PATCH CONTRACT ID '+ctrId);
            System.debug('## INCOMING PATCH CONTRACT SERVICE '+req.requestBody.toString());
            ContractModel contractInput = (ContractModel) JSON.deserialize(req.requestBody.toString(), ContractModel.class);
            ContractModel contractOutput = ContractService.patchContract(ctrId, contractInput);
            responseBodyStructure.contract = contractOutput;
            responseBodyStructure.isSuccess = true;

            res.statusCode = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));

        } catch(Exception e) {

            ApexFaultHandler.publishError(e, 'ContractRestService', 'patchContract');

            //
            // JSON body response
            responseBodyStructure.isSuccess = false;
            responseBodyStructure.errors.add(e.getMessage());
            Database.rollback(sp);

            //
            // Http level response
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
        }
    }

    @HttpPost
    global static void postContract() {
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
            System.debug('## INCOMING POST CONTRACT SERVICE '+req.requestBody.toString());
            ContractModel contractInput = (ContractModel) JSON.deserialize(req.requestBody.toString(), ContractModel.class);
            ContractModel contractOutput = ContractService.postContract(contractInput);
            responseBodyStructure.contract = contractOutput;
            responseBodyStructure.isSuccess = true;

            res.statusCode = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));

        } catch(Exception e) {

            ApexFaultHandler.publishError(e, 'ContractRestService', 'postContract');

            //
            // JSON body response
            responseBodyStructure.isSuccess = false;
            responseBodyStructure.errors.add(e.getMessage());
            Database.rollback(sp);

            //
            // Http level response
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(responseBodyStructure, true));
        }
        //System.debug('### Service getRelation returning '+JSON.serializePretty(responseBodyStructure));
    }

    public static RestResponse testPostCall(ContractModel contr) {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/contracten/contracten';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(contr));
        RestContext.request = req;
        RestContext.response= res;
        ContractRestService.postContract();
        String JSONval = res.responseBody.toString().unescapeJava();
        System.debug(res.statusCode+' ## RES '+JSONval);
        return res;
    }

    public static RestResponse testPatchCall(ContractModel contr) {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/contracten/contracten/'+contr.idExtern;
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(JSON.serialize(contr));
        RestContext.request = req;
        RestContext.response= res;
        ContractRestService.patchContract();
        String JSONval = res.responseBody.toString().unescapeJava();
        System.debug(res.statusCode+' ## RES '+JSONval);
        return res;
    }
}