/**
 * Invocable for the GET Personen
 */
public with sharing class OkapiGetPersoonInvocable {
    @InvocableMethod(Description='Get persons from the Okapi service based on UUID' Label='Get Persons')
    public static List<PersoonModel> getPersons(List<String> uuids) {
        try {
            List<PersoonModel> persons = OkapiClient.getPersons(uuids);
            return persons;
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiGetPersoonInvocable', 'getPersons');
            return new List<PersoonModel>();
        }
    }
}