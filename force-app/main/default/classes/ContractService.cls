/**
 * Service class for contracts
 */
public with sharing class ContractService {
    public static ContractModel patchContract(String contractId, ContractModel contract) {
        contract.idExtern = contractId;
        return postContract(contract);
    }
    public static ContractModel postContract(ContractModel contract) {
        //
        // Create and upsert contract first, the payload will mostly end up
        // in the Contract_Line__c object, grouped under a thin Real_Estate_Contract__c
        Real_Estate_Contract__c con = DataMapper.mapContractModelToRealEstateContract(contract);
        upsert con Schema.Real_Estate_Contract__c.Parent_Contract_Number__c;
        //
        // Map the "deelcontract" to a line
        Contract_Line__c line = DataMapper.mapContractModelToContractLine(contract);
        upsert line Schema.Contract_Line__c.External_Id__c;
        //
        // Check rollen
        if(contract.rollen.isEmpty() == false) {
            List<Contract_Contact_Role__c> contractContactRoleRecords = new List<Contract_Contact_Role__c>();
            for(ContractRolModel rolModel : contract.rollen) {
                Contract_Contact_Role__c roleRec = DataMapper.mapContractRoleToContractContactRole(rolModel);
                roleRec.Real_Estate_Contract__c = con.Id;
                roleRec.Contract_Line__c = line.Id;
                roleRec.Contact_Account__r = new Account(UUID__c=rolModel.idPersoon);
                roleRec.Deduplication_Key__c = getContractContactRoleCompositeId(con.Contract_Number__c, rolModel.idPersoon, roleRec);
                contractContactRoleRecords.add(roleRec);
            }
            upsert contractContactRoleRecords Schema.Contract_Contact_Role__c.Deduplication_Key__c;
        }
        contract.id = con.id;
        return contract;
    }

    //
    // Generate composite keys
    public static String getLineCompositeId(String contractId, String unitId, Contract_Line__c lineItem) {
        return contractId+'-'+unitId+'-'+IdentifierService.getDateStamp(lineItem.Active_from_Date__c);
    }
    public static String getContractContactRoleCompositeId(String contractId, String persoonUuid, Contract_Contact_Role__c roleRecord) {
        return contractId+'-'+persoonUuid+'-'+roleRecord.Role__c+'-'+IdentifierService.getDateStamp(roleRecord.Start_Date__c);
    }
    public static String getClusterRoleCompositeId(String contractId, String persoonUuid, Cluster_Role__c roleRecord) {
        return contractId+'-'+persoonUuid+'-'+roleRecord.Role__c+'-'+IdentifierService.getDateStamp(roleRecord.Start_Date__c);
    }

    public class ContractServiceException extends Exception {

    }
}