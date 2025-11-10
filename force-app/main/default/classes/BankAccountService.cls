/**
 * Created by harm on 27/08/2024.
 */
public with sharing class BankAccountService  {
    public static List<Bank_Account__c> getBankAccountRecordsForUpsert(PersoonModel pm, String personUuid) {
        List<Bank_Account__c> output = new List<Bank_Account__c>();
        if(pm.betaalgegevens?.size() > 0) {
            for(BetaalgegevenModel bm : pm.betaalgegevens) {
                Bank_Account__c baRecord = DataMapper.mapBetaalGegevenModelToBankAccount(bm);
                baRecord.Account__r = new Account(UUID__c=personUuid);
                baRecord.Integration_Key__c = personUuid+'-'+baRecord.Administration_Id__c+'-'+baRecord.External_Id__c;
                output.add(baRecord);
            }
        }
        return output;
    }
}