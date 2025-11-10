//
// Mocks for injixo
public class InjixoMocks {
    public class InjixoSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(200);
            resp.setBody('OK');
            resp.setStatus('OK');
            return resp;
        }
    }
    public class InjixoError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(400);
            resp.setBody('ERROR');
            resp.setStatus('Bad Request');
            return resp;
        }
    }
}