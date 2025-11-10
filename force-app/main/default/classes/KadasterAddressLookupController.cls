/**
 * Apex controller to retrieve address suggestions from the Kadaster BAG API based on postcode and house number.
 * 
 * Uses a GET request to the public "bevraagAdressen" endpoint via named credential: Kadaster_BAG_Adressen_NC
 * 
 * @see https://lvbag.github.io/BAG-API/Technische%20specificatie/#/Adres/bevraagAdressen
 */
public with sharing class KadasterAddressLookupController {

    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> fetchAddresses(String postalCode, String houseNumber) {
        try {
            // Build request URL with parameters
            String endpoint = '?postcode=' + EncodingUtil.urlEncode(postalCode, 'UTF-8') +
                              '&huisnummer=' + EncodingUtil.urlEncode(houseNumber, 'UTF-8');

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Kadaster_BAG_Adressen_NC' + endpoint);
            req.setMethod('GET');
            req.setHeader('Accept', 'application/hal+json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            // Log callout details
            System.debug('👉 Callout to: ' + req.getEndpoint());
            System.debug('👉 Status code: ' + res.getStatusCode());
            System.debug('👉 Response body: ' + res.getBody());

            if (res.getStatusCode() != 200) {
                throw new AuraHandledException('Error retrieving address: ' + res.getStatus());
            }

            // Parse the JSON response
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            // Return empty list if no _embedded section
            if (!response.containsKey('_embedded')) {
                return new List<Map<String, Object>>();
            }

            Map<String, Object> embedded = (Map<String, Object>) response.get('_embedded');
            List<Object> addresses = (List<Object>) embedded.get('adressen');

            List<Map<String, Object>> simplifiedAddresses = new List<Map<String, Object>>();

            for (Object a : addresses) {
                Map<String, Object> address = (Map<String, Object>) a;

                Map<String, Object> simplified = new Map<String, Object>{
                    'streetName' => address.get('openbareRuimteNaam'),
                    'houseNumber' => String.valueOf(address.get('huisnummer')),
                    'houseLetter' => (String)(address.containsKey('huisletter') ? address.get('huisletter') : null),
                    'houseNumberAddition' => (String)(address.containsKey('huisnummertoevoeging') ? address.get('huisnummertoevoeging') : null),
                    'postalCode' => address.get('postcode'),
                    'city' => address.get('woonplaatsNaam'),
                    'addressableObjectIdentification' => address.get('adresseerbaarObjectIdentificatie'),
                    'addressLabel' => (String)address.get('adresregel5')
                };

                simplifiedAddresses.add(simplified);
            }

            return simplifiedAddresses;

        } catch (Exception ex) {
            // Log the error using the ApexFaultHandler for monitoring/troubleshooting
            ApexFaultHandler.publishError(ex, 'KadasterAddressLookupController', 'fetchAddresses');
            throw new AuraHandledException('Unexpected error while retrieving address data. Please contact support.');
        }
    }
}