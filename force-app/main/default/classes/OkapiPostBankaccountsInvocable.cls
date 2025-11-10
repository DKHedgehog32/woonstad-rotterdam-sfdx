/**
 * Invocable for the POST Bankgegevens
 */

public with sharing class OkapiPostBankaccountsInvocable {
    @InvocableMethod(Description='Create bank accounts on the Okapi service' Label='Post Bank Accounts')
    public static void postBankAccounts(List<BetaalgegevenModel> bankAccounts) {
        try {
            OkapiClient.upsertBankGegevens(bankAccounts, 'POST');
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'OkapiPostBankaccountsInvocable' ,'postBankAccounts');
        }
    }
}