/**
 * Invocable for the POST Personen
 */
public with sharing class OkapiPostPersoonInvocable {
    @InvocableMethod(Description='Create new persons on the Okapi service' Label='Post Persons')
    public static void postPersons(List<PersoonModel> personen) {
        try {
            sendToOkapiText(JSON.serialize(personen));
            //OkapiClient.upsertPersons(personen, 'POST');
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiPostPersoonInvocable' ,'postPersons');
        }
    }

    @Future(Callout=true)
    public static void sendToOkapiText(String personenJson) {
        try {
            List<PersoonModel> personen = (List<PersoonModel>)JSON.deserialize(personenJson, List<PersoonModel>.class);
            OkapiClient.upsertPersons(personen, 'POST');
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiPostPersoonInvocable' ,'sendToOkapiText');
        }
    }
}