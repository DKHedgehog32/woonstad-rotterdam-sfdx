/**
 * Mocks for the tests of Okapi
 */
public class OkapiMocks {
    public class GetRelationSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            PersoonModel output = new PersoonModel();
            output.voornaam = 'Piet';
            output.achternaam = 'Paulusma';
            output.id = 'abcd-efgh-0987';

            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(200);
            resp.setBody(JSON.serialize(output));
            resp.setStatus('OK');
            return resp;
        }
    }
    public class GetRelationError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(400);
            resp.setStatus('ERROR');
            return resp;
        }
    }
    public class UpsertRelationSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(202);
            resp.setStatus('OK');
            resp.setBody('{}'); // Async service, responds just with code
            return resp;
        }
    }
    public class UpsertRelationError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(400);
            resp.setStatus('ERROR');
            //
            // Error message may look like this
            resp.setBody('{"Exception": "API Gateway encountered an error. Error Message:  Native service provider error. Code : 500. Request Details: Service - wr-relaties, Operation - /personen, Invocation Time:8:56:15 AM, Date:Jul 23, 2024,  Client IP - 85.222.158.8, User - Default and Application:SalesForceDev"}');
            return resp;
        }
    }
    public class RequestPersonPushSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(202);
            resp.setStatus('OK');
            resp.setBody('{}'); // Async service, responds just with code
            return resp;
        }
    }
    public class RequestPersonPushError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(400);
            resp.setStatus('ERROR');
            return resp;
        }
    }
    //
    // Most services appear to return the same
    public class GenericSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(202);
            resp.setStatus('OK');
            resp.setBody('{}'); // Async service, responds just with code
            return resp;
        }
    }
    /*public class GenericError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(400);
            resp.setStatus('ERROR');
            //
            // Error message may look like this
            resp.setBody('{"Exception": "API Gateway encountered an error. Error Message:  Native service provider error. Code : 500. Request Details: Service - wr-relaties, Operation - /personen, Invocation Time:8:56:15 AM, Date:Jul 23, 2024,  Client IP - 85.222.158.8, User - Default and Application:SalesForceDev"}');
            return resp;
        }
    }*/
}