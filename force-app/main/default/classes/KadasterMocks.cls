//
// Mock response for the KadasterClient
public with sharing class KadasterMocks {
    public class GetAddressSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {


            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(200);
            resp.setBody(getJsonResponse());
            resp.setStatus('OK');
            return resp;
        }
    }
    public class GetAddressSuccessNoAddress implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {


            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(200);
            resp.setBody(getJsonResponseNoAddress());
            resp.setStatus('OK');
            return resp;
        }
    }
    public class GetAddressError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HTTPResponse resp = new HTTPResponse();
            resp.setStatusCode(400);
            resp.setBody(getErrorJson());
            resp.setStatus('ERROR');
            return resp;
        }
    }
    private static String getJsonResponse() {
        String jsonValue = '{';
        jsonValue += '  "_links": {';
        jsonValue += '    "self": {';
        jsonValue += '      "href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/adressen?postcode=8931%20CL&huisnummer=75&exacteMatch=true&pageSize=20&inclusiefEindStatus=true"';
        jsonValue += '    }';
        jsonValue += '  },';
        jsonValue += '  "_embedded": {';
        jsonValue += '    "adressen": [';
        jsonValue += '      {';
        jsonValue += '        "openbareRuimteNaam": "Curaçaostraat",';
        jsonValue += '        "korteNaam": "Curaçaostraat",';
        jsonValue += '        "huisnummer": 75,';
        jsonValue += '        "postcode": "8931CL",';
        jsonValue += '        "woonplaatsNaam": "Leeuwarden",';
        jsonValue += '        "nummeraanduidingIdentificatie": "0080200000448477",';
        jsonValue += '        "openbareRuimteIdentificatie": "0080300000334948",';
        jsonValue += '        "woonplaatsIdentificatie": "3615",';
        jsonValue += '        "adresseerbaarObjectIdentificatie": "0080010000448478",';
        jsonValue += '        "pandIdentificaties": [';
        jsonValue += '          "0080100000364095"';
        jsonValue += '        ],';
        jsonValue += '        "adresregel5": "Curaçaostraat 75",';
        jsonValue += '        "adresregel6": "8931 CL  LEEUWARDEN",';
        jsonValue += '        "_links": {';
        jsonValue += '          "self": {';
        jsonValue += '            "href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/adressen/0080200000448477"';
        jsonValue += '          },';
        jsonValue += '          "openbareRuimte": {';
        jsonValue += '            "href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/openbareruimten/0080300000334948"';
        jsonValue += '          },';
        jsonValue += '          "nummeraanduiding": {';
        jsonValue += '            "href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/nummeraanduidingen/0080200000448477"';
        jsonValue += '          },';
        jsonValue += '          "woonplaats": {';
        jsonValue += '            "href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/woonplaatsen/3615"';
        jsonValue += '          },';
        jsonValue += '          "adresseerbaarObject": {';
        jsonValue += '            "href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/verblijfsobjecten/0080010000448478"';
        jsonValue += '          },';
        jsonValue += '          "panden": [';
        jsonValue += '            {';
        jsonValue += '              "href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/panden/0080100000364095"';
        jsonValue += '            }';
        jsonValue += '          ]';
        jsonValue += '        }';
        jsonValue += '      }';
        jsonValue += '    ]';
        jsonValue += '  }';
        jsonValue += '}';
        return jsonValue;
    }
    private static String getJsonResponseNoAddress() {
        String jsonValue = '{';
        jsonValue += '  "_links": {';
        jsonValue += '    "self": {';
        jsonValue += '      "href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/adressen?postcode=8931%20CL&huisnummer=75&exacteMatch=true&pageSize=20&inclusiefEindStatus=true"';
        jsonValue += '    }';
        jsonValue += '  },';
        jsonValue += '  "_embedded": {';
        jsonValue += '  }';
        jsonValue += '}';
        return jsonValue;
    }
    private static String getErrorJson() {
        return '{"status":400,"title":"Een of meerdere parameters zijn niet correct.","type":"https://tools.ietf.org/html/rfc7231#section-6.5.1","detail":"Bad request.","instance":"https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/adressen?exacteMatch=true&postcode=89e9&huisnummer=2","code":"paramsValidation","invalidParams":[{"name":"postcode","code":"pattern","reason":"Waarde voldoet niet aan patroon ^[1-9]{1}[0-9]{3}[ ]{0,1}[a-zA-Z]{2}$."}]}';
    }
}