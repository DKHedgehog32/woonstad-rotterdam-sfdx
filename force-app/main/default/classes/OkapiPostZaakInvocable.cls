/**
 * Invocable to call the zaak api on okapi
 */
public with sharing class OkapiPostZaakInvocable {
    @InvocableMethod(Description='Create a new zaak on the Okapi service (async)' Label='Post Zaken')
    public static void postZaken(List<ZaakModel> zaken) {
        try {
            ZaakService.enrichZaakWithFilesByReference(zaken);
            //OkapiClient.upsertZaken(zaken, 'POST');
            sendAsync(JSON.serialize(zaken));
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiPostZaakInvocable' ,'postZaken');
        }
    }

    @Future(Callout=true)
    private static void sendAsync(String serializedZaken) {
        try {
            List<ZaakModel> zaken = (List<ZaakModel>) JSON.deserialize(serializedZaken, List<ZaakModel>.class);
            OkapiClient.upsertZaken(zaken, 'POST');
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiPostZaakInvocable' ,'sendAsync');
        }
    }
}