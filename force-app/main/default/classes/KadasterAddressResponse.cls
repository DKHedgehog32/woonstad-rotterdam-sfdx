/**
 *
 * {
	"_links": {
		"self": {
			"href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/adressen?postcode=8939ER&huisnummer=85"
		}
	},
	"_embedded": {
		"adressen": [
			{
				"openbareRuimteNaam": "Frouwesân",
				"korteNaam": "Frouwesân",
				"huisnummer": 85,
				"postcode": "8939ER",
				"woonplaatsNaam": "Leeuwarden",
				"nummeraanduidingIdentificatie": "0080200000459311",
				"openbareRuimteIdentificatie": "0080300000335794",
				"woonplaatsIdentificatie": "3615",
				"adresseerbaarObjectIdentificatie": "0080010000459312",
				"pandIdentificaties": [
					"0080100000349864"
				],
				"adresregel5": "Frouwesân 85",
				"adresregel6": "8939 ER  LEEUWARDEN",
				"_links": {
					"self": {
						"href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/adressen/0080200000459311"
					},
					"openbareRuimte": {
						"href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/openbareruimten/0080300000335794"
					},
					"nummeraanduiding": {
						"href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/nummeraanduidingen/0080200000459311"
					},
					"woonplaats": {
						"href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/woonplaatsen/3615"
					},
					"adresseerbaarObject": {
						"href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/verblijfsobjecten/0080010000459312"
					},
					"panden": [
						{
							"href": "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/panden/0080100000349864"
						}
					]
				}
			}
		]
	}
}

 */

public class KadasterAddressResponse {
    @AuraEnabled
    public String openbareRuimteNaam;
    @AuraEnabled
    public String korteNaam;
    @AuraEnabled
    public Integer huisnummer;
    @AuraEnabled
    public String postcode;
    @AuraEnabled
    public String woonplaatsNaam;
    @AuraEnabled
    public String nummeraanduidingIdentificatie;
    @AuraEnabled
    public String openbareRuimteIdentificatie;
    @AuraEnabled
    public String woonplaatsIdentificatie;
    @AuraEnabled
    public String adresseerbaarObjectIdentificatie;
    @AuraEnabled
    public List<String> pandIdentificaties;
    @AuraEnabled
    public String adresregel5;
    @AuraEnabled
    public String adresregel6;
    @AuraEnabled
    public Integer status; // Only filled on error
    @AuraEnabled
    public String title; // Holds error message in case of problems
}