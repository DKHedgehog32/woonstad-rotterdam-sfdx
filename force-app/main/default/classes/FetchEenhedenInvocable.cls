/**
 * Invocable to have units pushed to SF
 */

public with sharing class FetchEenhedenInvocable {
    @InvocableMethod(label='Request a Contract Unit from Okapi' description='Requests Okapi to push a contract unit to Salesforce based on their External or UUID')
    public static List<OkapiResponseModel> fetchEenheden(List<ContractEenheidModel> eenheden) {
        return OkapiClient.requestContractUnitPush(eenheden);
    }
}