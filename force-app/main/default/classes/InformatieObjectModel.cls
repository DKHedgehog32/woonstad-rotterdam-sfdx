/**
 * Created by harm on 07/02/2025.
 */

global class InformatieObjectModel {
    @AuraEnabled @InvocableVariable
    global String id;
    @AuraEnabled @InvocableVariable
    global String beschrijving;
    @AuraEnabled @InvocableVariable
    global String bestand; // base-64
    @AuraEnabled @InvocableVariable
    global String bestandslocatie; //URI voor het opvragen van de bijlage inclusief data als 'bestand' niet gevuld is.
    @AuraEnabled @InvocableVariable
    global String formaat; // Zie https://www.iana.org/assignments/media-types/media-types.xhtml
}