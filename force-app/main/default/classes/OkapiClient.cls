/*
Client to the Okapi (webmethods) API's
TODO:
 - Logging? (reuse for inbound)
 - Split code into multiple classes
 - Load balancing
 */
public class OkapiClient {
    private static Okapi_Settings__c setting = Okapi_Settings__c.getInstance();

    //
    // Performs GET's. Max 100 per go (150 is callout limit)
    public static List<PersoonModel> getPersons(List<String> uuids) {
        if(uuids == null || uuids.size() > 100) {
            throw new OkapiClientException('Max 100 UUIDs are allowed for this method');
        }
        List<PersoonModel> output = new List<PersoonModel>();
        Http client = new Http();
        try {
            for(String oneUuid : uuids) {
                System.debug('## Getting person ' + oneUuid);

                HttpRequest request = new HttpRequest();
                request.setHeader('Accept', 'application/json');
                request.setMethod('GET');
                request.setEndpoint('callout:' + setting.Use_Named_Credential__c + '/gateway/wr-relaties/1.0/personen/' + oneUuid);

                HttpResponse response = client.send(request);

                if(response.getStatusCode() == 200) {
                    PersoonModel onePerson = (PersoonModel) JSON.deserialize(response.getBody(), PersoonModel.class);
                    output.add(onePerson);
                } else {
                    ApexFaultHandler.publishError(response.getBody(), 'OkapiClient', 'getPersons (UUID: ' + oneUuid + ')');
                    System.debug('## ERROR calling GET Okapi:' + response.getBody());
                    throw new OkapiClientException('Okapi error in getPersons: ' + response.getStatus());
                }
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiClient', 'getPersons');
            throw ex;
        }
        
        return output;
    }
    //
    // Performs POST's, PUT's or PATCH'es on the okapi API
    public static void upsertPersons(List<PersoonModel> relations, String httpMethod) {
        if (relations == null) {
            throw new OkapiClientException('PersoonModel input empty');
        }
        if (relations.size() > 100) {
            throw new OkapiClientException('Max 100 relations are allowed for this method');
        }

        Http client = new Http();
        String endpointSuffix = '/gateway/wr-relaties/1.0/personen';

        try {
            for (PersoonModel onePerson : relations) {
                System.debug('## SENDING PERSON TO OKAPI USING ' + httpMethod + ': ' + JSON.serializePretty(onePerson));

                if (onePerson == null) {
                    throw new OkapiClientException('Null input not allowed');
                }

                if (httpMethod.toLowerCase() == 'patch') {
                    endpointSuffix += '/' + onePerson.id;
                }

                HttpRequest request = new HttpRequest();
                request.setHeader('Accept', 'application/json');
                request.setMethod(httpMethod);
                request.setBody(JSON.serialize(onePerson));
                request.setEndpoint('callout:' + setting.Use_Named_Credential__c + endpointSuffix);

                HttpResponse response = client.send(request);

                if (response.getStatusCode() >= 200 && response.getStatusCode() <= 202) {
                    // Logging?
                    System.debug('## SUCCESS calling Okapi:' + JSON.serializePretty(response.getBody()));
                } else {
                    String logContext = 'upsertPersons (UUID: ' + onePerson.id + ')';
                    ApexFaultHandler.publishError(response.getBody(), 'OkapiClient', logContext);
                    System.debug('## ERROR calling POST Okapi:' + JSON.serializePretty(response.getBody().unescapeJava()));
                    throw new OkapiClientException('Okapi error in upsertPersons: ' + response.getStatus());
                }
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiClient', 'upsertPersons');
            throw ex;
        }
    }
    //
    // Pushes a set of personen to Okapi that will be fetched from their external system
    // and pushed into Salesforce.
    // Request format
    /*
    [{
        "id": "1023508",
        "idAdministratie": "WOCAS"
    },
    {
        "id": "3885",
        "idAdministratie": "WOCAS"
    },
    {
        "id": "e3f7de17-4400-42b8-9075-a11881fcb917",
        "idAdministratie": "SALESFORCE"
    }]
     */
    public static List<OkapiResponseModel> requestPersonsPush(List<PersoonModel> personenToRequest) {
        if (personenToRequest == null || personenToRequest.size() > 100) {
            throw new OkapiClientException('Max 100 relations are allowed for this method');
        }

        System.debug('## Requesting person from Okapi, sending ' + JSON.serializePretty(personenToRequest, true));
        List<OkapiResponseModel> output = new List<OkapiResponseModel>();
        Http client = new Http();
        HttpRequest request = new HttpRequest();
        request.setHeader('Accept', 'application/json');
        request.setMethod('POST');
        request.setBody(JSON.serialize(personenToRequest, true));
        request.setEndpoint('callout:' + setting.Use_Named_Credential__c + '/gateway/app-salesforce/relaties/personen/event');

        try {
            HttpResponse response = client.send(request);

            if (response.getStatusCode() >= 200 && response.getStatusCode() <= 202) {
                System.debug('## requestPersonsPush succeeded');
                for (PersoonModel pm : personenToRequest) {
                    OkapiResponseModel r = new OkapiResponseModel();
                    r.isSuccess = true;
                    output.add(r);
                }
            } else {
                ApexFaultHandler.publishError(response.getBody(), 'OkapiClient', 'requestPersonsPush');
                System.debug('## requestPersonsPush failed');
                for (PersoonModel pm : personenToRequest) {
                    OkapiResponseModel r = new OkapiResponseModel();
                    r.isSuccess = false;
                    r.errors = new List<String>();
                    r.errors.add('Code ' + response.getStatusCode() + ': ' + response.getStatus());
                    output.add(r);
                }
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiClient', 'requestPersonsPush');
            throw ex;
        }

        return output;
    }
    //--------------
    // Bankgegevens
    // POST/PATCH, GET goes through the relation GET API
    //--------------
    public static void upsertBankGegevens(List<BetaalgegevenModel> bankAccounts, String httpMethod) {
        if (bankAccounts == null || bankAccounts.size() > 100) {
            throw new OkapiClientException('Max 100 bankaccounts are allowed for this method');
        }

        Http client = new Http();

        try {
            for (BetaalgegevenModel oneAccount : bankAccounts) {
                HttpRequest request = new HttpRequest();
                request.setHeader('Accept', 'application/json');
                request.setMethod(httpMethod);
                request.setBody(JSON.serialize(oneAccount));
                request.setEndpoint('callout:' + setting.Use_Named_Credential__c + '/gateway/wr-relaties/1.0/betaalgegevens');

                HttpResponse response = client.send(request);

                if (response.getStatusCode() >= 200 && response.getStatusCode() <= 202) {
                    System.Debug('## SUCCESS calling Okapi:' + JSON.serializePretty(response.getBody()));
                } else {
                    ApexFaultHandler.publishError(
                        response.getBody(),
                        'OkapiClient',
                        'upsertBankGegevens (IBAN: ' + oneAccount?.iban + ')'
                    );
                    System.Debug('## ERROR calling POST Okapi:' + JSON.serializePretty(response.getBody().unescapeJava()));
                    throw new OkapiClientException('Okapi error in upsertBankGegevens: ' + response.getStatus());
                }
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiClient', 'upsertBankGegevens');
            throw ex;
        }
    }

    //--------------
    // Persoonrelaties
    // POST/PATCH, GET goes through the relation GET API
    //--------------
    public static void upsertPersoonRelaties(List<PersoonRelatieModel> relations, String httpMethod) {
        if (relations == null || relations.size() > 100) {
            throw new OkapiClientException('Max 100 relations are allowed for this method');
        }

        Http client = new Http();

        try {
            for (PersoonRelatieModel oneRelation : relations) {
                System.debug('## SENDING PersoonRelatie TO OKAPI USING ' + httpMethod + ': ' + JSON.serializePretty(oneRelation));
                HttpRequest request = new HttpRequest();
                request.setHeader('Accept', 'application/json');
                request.setMethod(httpMethod);
                request.setBody(JSON.serialize(oneRelation));

                if (httpMethod.toLowerCase() == 'patch') {
                    request.setEndpoint('callout:' + setting.Use_Named_Credential__c + '/gateway/wr-relaties/1.0/persoon-relaties/' + oneRelation.id);
                } else {
                    request.setEndpoint('callout:' + setting.Use_Named_Credential__c + '/gateway/wr-relaties/1.0/persoon-relaties');
                }

                HttpResponse response = client.send(request);

                if (response.getStatusCode() >= 200 && response.getStatusCode() <= 202) {
                    //
                    // Logging?
                    System.Debug('## SUCCESS calling Okapi:' + JSON.serializePretty(response.getBody()));

                } else {
                    //
                    // Logging?
                    ApexFaultHandler.publishError(response.getBody(),'OkapiClient','upsertPersoonRelaties (Relatie ID: ' + oneRelation?.id + ')');
                    System.Debug('## ERROR calling POST Okapi:' + JSON.serializePretty(response.getBody().unescapeJava()));
                    throw new OkapiClientException('Okapi error in upsertPersoonRelaties: ' + response.getStatus());
                }
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiClient', 'upsertPersoonRelaties');
            throw ex;
        }
    }
    //
    // Performs POST's, PUT's or PATCH'es on the okapi API
    public static void upsertPersonAddresses(List<PersoonAdresModel> addresses, String httpMethod) {
        if(addresses == null) {
            throw new OkapiClientException('PersoonModel input empty');
        }
        if(addresses.size() > 100) {
            throw new OkapiClientException('Max 100 relations are allowed for this method');
        }

        Http client = new Http();

        try {
            for(PersoonAdresModel onePersonAddress : addresses) {
                System.debug('## SENDING PERSON ADDRESS TO OKAPI USING ' + httpMethod + ': ' + JSON.serializePretty(onePersonAddress));
                if(onePersonAddress == null) {
                    throw new OkapiClientException('Null input not allowed');
                }

                HttpRequest request = new HttpRequest();
                request.setHeader('Accept','application/json');
                request.setMethod(httpMethod);
                request.setBody(JSON.serialize(onePersonAddress));
                request.setEndpoint('callout:' + setting.Use_Named_Credential__c + '/gateway/wr-relaties/1.0/persoon-adressen');

                HttpResponse response = client.send(request);

                if(response.getStatusCode() >= 200 && response.getStatusCode() <= 202) {
                    System.debug('## SUCCESS calling Okapi:' + JSON.serializePretty(response.getBody()));
                } else {
                    ApexFaultHandler.publishError(response.getBody(),'OkapiClient','upsertPersonAddresses (ID: ' + onePersonAddress.id + ')');
                    System.debug('## ERROR calling POST Okapi:' + JSON.serializePretty(response.getBody().unescapeJava()));
                    throw new OkapiClientException('Okapi error in upsertPersonAddresses: ' + response.getStatus());
                }
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiClient', 'upsertPersonAddresses');
            throw ex;
        }
    }

    //
    // CASES/ZAKEN
    public static void upsertZaken(List<ZaakModel> zaken, String httpMethod) {
        if(zaken == null) {
            throw new OkapiClientException('ZaakModel input empty');
        }
        if(zaken.size() > 100) {
            throw new OkapiClientException('Max 100 zaken are allowed for this method');
        }

        Http client = new Http();
        String endpointSuffix = '/gateway/app-salesforce/dossier';

        try {
            for(ZaakModel zaak : zaken) {
                System.debug('## Sending zaak to Okapi using: ' + httpMethod + ': ' + JSON.serializePretty(zaak));
                if(zaak == null) {
                    throw new OkapiClientException('Null input not allowed');
                }

                String finalEndpoint = endpointSuffix;
                if(httpMethod.toLowerCase() == 'patch') {
                    finalEndpoint += '/' + zaak.id;
                }

                HttpRequest request = new HttpRequest();
                request.setHeader('Accept', 'application/json');
                request.setMethod(httpMethod);
                request.setBody(JSON.serialize(zaak));
                request.setEndpoint('callout:' + setting.Use_Named_Credential__c + finalEndpoint);

                HttpResponse response = client.send(request);

                if(response.getStatusCode() >= 200 && response.getStatusCode() <= 202) {
                    System.Debug('## SUCCESS calling Okapi:' + JSON.serializePretty(response.getBody()));
                } else {
                    ApexFaultHandler.publishError(response.getBody(),'OkapiClient','upsertZaken (ID: ' + zaak.id + ')');
                    System.Debug('## ERROR calling POST Okapi:' + JSON.serializePretty(response.getBody().unescapeJava()));
                    throw new OkapiClientException('Okapi error in upsertZaken: ' + response.getStatus());
                }
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiClient', 'upsertZaken');
            throw ex;
        }
    }
    //
    // Request Contract Unit Push
    /*
    GET /app-salesforce/vastgoed/eenheden/event
        [
          {
              "id": "45951000048",
              "idAdministratie": "WOCAS"
          }
        ]

     */
    public static List<OkapiResponseModel> requestContractUnitPush(List<ContractEenheidModel> eenhedenToRequest) {
        if(eenhedenToRequest == null || eenhedenToRequest.size() > 100) {
            throw new OkapiClientException('Max 100 units are allowed for this method');
        }
        System.debug('## Requesting contract unit from Okapi, sending '+JSON.serializePretty(eenhedenToRequest, true));
        List<OkapiResponseModel> output = new List<OkapiResponseModel>();
        Http client = new Http();
        HttpRequest request = new HttpRequest();
        request.setHeader('Accept','application/json');
        request.setMethod('POST');
        request.setBody(JSON.serialize(eenhedenToRequest, true));
        request.setEndpoint('callout:'+setting.Use_Named_Credential__c+'/gateway/app-salesforce/vastgoed/eenheden/event');
        HttpResponse response  = client.send(request);
        if(response.getStatusCode() >= 200 && response.getStatusCode() <= 202) {
            System.debug('## requestContractUnitPush succeeded');
            for(ContractEenheidModel cem : eenhedenToRequest) {
                OkapiResponseModel r = new OkapiResponseModel();
                r.isSuccess = true;
                output.add(r);
            }
        } else {
            System.debug('## requestPersonsPush failed');
            for(ContractEenheidModel pm : eenhedenToRequest) {
                OkapiResponseModel r = new OkapiResponseModel();
                r.isSuccess = false;
                r.errors = new List<String>();
                r.errors.add('Code '+response.getStatusCode()+': '+response.getStatus());
                output.add(r);
            }
        }
        return output;
    }
    public class OkapiClientException extends Exception {

    }
}