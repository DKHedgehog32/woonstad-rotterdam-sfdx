/**
 * Created by harm on 14/10/2024.
 */

public with sharing class OkapiPatchPersoonInvocable {
    @InvocableMethod(Description='Update persons on the Okapi service' Label='Update Persons')
    public static void patchPersons(List<PersoonModel> personen) {
        sendToOkapiText(JSON.serialize(personen));
        //OkapiClient.upsertPersons(personen, 'PATCH');
    }

    @Future(Callout=true)
    public static void sendToOkapiText(String personenJson) {
        try {
            List<PersoonModel> personen = (List<PersoonModel>)JSON.deserialize(personenJson, List<PersoonModel>.class);
            OkapiClient.upsertPersons(personen, 'PATCH');
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiPatchPersoonInvocable' ,'sendToOkapiText');
        }
    }
}