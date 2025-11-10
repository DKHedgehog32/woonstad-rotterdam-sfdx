/**
 * Created by harm on 16/09/2024.
 */

public with sharing class OkapiPatchPersonRelationsInvocable {
    @InvocableMethod(Description='Updates person relations on the Okapi service' Label='Update Person Relations')
    public static void patchPersonRelations(List<PersoonRelatieModel> relaties) {
        OkapiClient.upsertPersoonRelaties(relaties, 'PATCH');
    }
}