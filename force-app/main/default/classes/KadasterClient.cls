public with sharing class KadasterClient {
    public static KadasterAddressResponse getAddress(String postalCode, String houseNumber, String houseLetter, String houseNumberAddition) {
        String urlSuffix = '?exacteMatch=true&postcode=' + EncodingUtil.urlEncode(postalCode, 'UTF-8') +
                           '&huisnummer=' + EncodingUtil.urlEncode(houseNumber, 'UTF-8');

        if (houseLetter <> null && !String.isBlank(houseLetter)) {
            urlSuffix += '&huisletter=' + EncodingUtil.urlEncode(houseLetter, 'UTF-8');
        }
        if (houseNumberAddition <> null && !String.isBlank(houseNumberAddition)) {
            urlSuffix += '&huisnummertoevoeging=' + EncodingUtil.urlEncode(houseNumberAddition, 'UTF-8');
        }

        KadasterAddressResponse output;

        try {
            Http client = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setHeader('Accept', 'application/hal+json');
            request.setEndpoint('callout:Kadaster_BAG_Adressen_NC' + urlSuffix);

            HttpResponse response = client.send(request);
            System.debug('###' + response.getBody());

            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if (responseMap.containsKey('_embedded')) {
                    Map<String, Object> embeddedMap = (Map<String, Object>) responseMap.get('_embedded');
                    if (embeddedMap.containsKey('adressen')) {
                        List<Object> adressenArray = (List<Object>) embeddedMap.get('adressen');
                        if (adressenArray?.size() == 1) {
                            String jsonAddress = JSON.serialize(adressenArray[0]);
                            output = (KadasterAddressResponse) JSON.deserialize(jsonAddress, KadasterAddressResponse.class);
                        }
                    } else {
                        output = new KadasterAddressResponse();
                        output.status = 404;
                        output.title = System.Label.No_Results;
                    }
                }
            } else {
                System.debug('## ERROR calling Kadaster:' + response.getBody());
                output = (KadasterAddressResponse) JSON.deserialize(response.getBody(), KadasterAddressResponse.class);
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'KadasterClient', 'getAddress');
        }

        System.debug('### Kadaster client returning ' + JSON.serializePretty(output));
        return output;
    }
}