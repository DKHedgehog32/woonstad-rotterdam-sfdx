/**
 * Utility methods for the persoon relaties
 */
public with sharing class PersonRelationService {
    public static List<PersoonRelatieModel> getRelationsByUuid(String personUuid) {
        try {
            List<PersoonRelatieModel> output = new List<PersoonRelatieModel>();
            List<Account> theAccounts = [SELECT Id, UUID__c,
                (SELECT Id, Type__c, Start_Date__c, End_Date__c, Primary_Relation__r.UUID__c, Subsidiary_Relation__r.UUID__c FROM Primary_Account_In_Relationships__r),
                (SELECT Id, Type__c, Start_Date__c, End_Date__c, Primary_Relation__r.UUID__c, Subsidiary_Relation__r.UUID__c FROM Subsidiary_Account_In_Relationships__r),
                (SELECT Id, Roles, StartDate, EndDate, Account.UUID__c, Contact.Contact_UUID__c FROM AccountContactRelations)
                FROM Account
                WHERE UUID__c = :personUuid
                LIMIT 1];
            if(theAccounts <> null && theAccounts.size() == 1) {
                Account theAccount = theAccounts[0];
                //
                // Add relations between accounts/persons
                output = new List<PersoonRelatieModel>();

                //
                // Add relationship data for primary side
                if(theAccount.Primary_Account_In_Relationships__r?.size() > 0) {
                    for(Relationship__c rel : theAccount.Primary_Account_In_Relationships__r) {
                        PersoonRelatieModel prModel = DataMapper.mapRelationShipToPersoonRelatieModel(rel);
                        output.add(prModel);
                    }
                }
                //
                // Add relationship data for subsidiary side
                if(theAccount.Subsidiary_Account_In_Relationships__r?.size() > 0) {
                    for(Relationship__c rel : theAccount.Subsidiary_Account_In_Relationships__r) {
                        PersoonRelatieModel prModel = DataMapper.mapRelationShipToPersoonRelatieModel(rel);
                        output.add(prModel);
                    }
                }

                //
                // Add relationship data for other types of relations
                if(theAccount.AccountContactRelations?.size() > 0) {
                    for(AccountContactRelation rel : theAccount.AccountContactRelations) {
                        PersoonRelatieModel prModel = DataMapper.mapRelationShipToPersoonRelatieModel(rel);
                        output.add(prModel);
                    }
                }

                return output;
            } else {
                //
                // Not found
                return null;
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'PersonRelationService' ,'getRelationsByUuid');
            return new List<PersoonRelatieModel>(); 
        }
    }


    //
    // Prepares a collection of Relationships for upsert
    // Constructs the composite key and anchors the keys
    public static List<Relationship__c> getRelationshipRecordsForUpsert(PersoonModel pm, String personUuid) {
        try {
            // This object stores only a subset of possible relations
            Set<String> validRelations = SharedUtils.convertPicklistValuesToSet(Relationship__c.Type__c.getDescribe());
            List<Relationship__c> output = new List<Relationship__c>();

            if (pm.persoonRelaties?.size() > 0) {
                for (PersoonRelatieModel prm : pm.persoonRelaties) {
                    if (!validRelations.contains(prm.relatieRol.code)) {
                        continue;
                    }

                    Relationship__c relRecord = DataMapper.mapPersoonRelatieModelToRelationship(prm);

                    // Overwrite with passed in uuid
                    relRecord.Primary_Relation__r = new Account(UUID__c = prm.relatieId); // persoonId = secundair
                    relRecord.Subsidiary_Relation__r = new Account(UUID__c = personUuid); // persoonId = secundair
                    relRecord.Deduplication_Key__c = createCompositeKey(relRecord, personUuid, prm.relatieId);
                    output.add(relRecord);
                }
            }

            return output;

        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'PersonRelationService' ,'getRelationshipRecordsForUpsert');
            return new List<Relationship__c>();
        }
    }

    //
    // Prepares a collection of Account contact relations for upsert
    // Constructs the composite key
    public static List<AccountContactRelation> getAccountContactRelationRecordsForUpsert(PersoonModel pm, String personUuid) {
        try {
            // This object stores only a subset of possible relations
            Set<String> validRelations = SharedUtils.convertPicklistValuesToSet(AccountContactRelation.Role_2__c.getDescribe());

            List<AccountContactRelation> output = new List<AccountContactRelation>();

            if (pm.persoonRelaties?.size() > 0) {
                for (PersoonRelatieModel prm : pm.persoonRelaties) {
                    if (!validRelations.contains(prm.relatieRol.code)) {
                        continue;
                    }

                    // Skip relations that miss 1 part of the relation
                    if (personUuid == null || prm.relatieId == null) {
                        continue;
                    }

                    AccountContactRelation relRecord = DataMapper.mapPersoonRelatieModelToAccountContactRelation(prm);
                    relRecord.Account = new Account(UUID__c = personUuid);
                    relRecord.Contact = new Contact(Contact_UUID__c = prm.relatieId);
                    relRecord.Deduplication_Key__c = createCompositeKey(prm.relatieId, personUuid);
                    output.add(relRecord);
                }
            }

            return output;

        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'PersonRelationService', 'getAccountContactRelationRecordsForUpsert');
            return new List<AccountContactRelation>(); 
        }
    }

    //
    // For use in before trigger
    // Works by reference by modifying the provided Relationship__c directly, enriches record with the Dedupe key
    public static void fillCompositeKeys(List<AccountContactRelation> rels) {
        try {
            Set<ID> accIds = new Set<ID>();
            for(AccountContactRelation rel : rels) {
                accIds.add(rel.AccountId);
            }
            Set<ID> conIds = new Set<ID>();
            for(AccountContactRelation rel : rels) {
                conIds.add(rel.ContactId);
            }
            Map<ID, Account> accMap = new Map<ID, Account>([SELECT Id, UUID__c FROM Account WHERE Id IN :accIds]);
            Map<ID, Contact> conMap = new Map<ID, Contact>([SELECT Id, Contact_UUID__c FROM Contact WHERE Id IN :conIds]);
            for(AccountContactRelation rel : rels) {
                if(String.isEmpty(rel.Deduplication_Key__c)) {
                    String uuid = accMap.get(rel.AccountId)?.UUID__c;
                    String conUuid = conMap.get(rel.ContactId)?.Contact_UUID__c;
                    rel.Deduplication_Key__c = createCompositeKey(uuid, conUuid);
                }
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'PersonRelationService', 'fillCompositeKeys (AccountContactRelation)');
        }
    }

    //
    // For use in before trigger
    // Works by reference by modifying the provided Relationship__c directly, enriches record with the Dedupe key
    public static void fillCompositeKeys(List<Relationship__c> rels) {
        try {
            Set<ID> accIds = new Set<ID>();
            for(Relationship__c rel : rels) {
                accIds.add(rel.Primary_Relation__c);
                accIds.add(rel.Subsidiary_Relation__c);
            }
            Map<ID, Account> accMap = new Map<ID, Account>([SELECT Id, UUID__c FROM Account WHERE Id IN :accIds]);
            for(Relationship__c rel : rels) {
                if(String.isEmpty(rel.Deduplication_Key__c)) {
                    String uuid = accMap.get(rel.Primary_Relation__c)?.UUID__c;
                    String relUuid = accMap.get(rel.Subsidiary_Relation__c)?.UUID__c;
                    rel.Deduplication_Key__c = createCompositeKey(rel, uuid, relUuid);
                }
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'PersonRelationService', 'fillCompositeKeys (Relationship__c)');
        }
    }
    private static String createCompositeKey(Relationship__c input, String personUuid, String relationUuid) {
        String output = personUuid+'-'+relationUuid+'-'+input.Type__c+'-'+IdentifierService.getDateStamp(input.Start_Date__c);
        return output;
    }
    private static String createCompositeKey(String personUuid, String relationId) {
        String output = personUuid+'-'+relationId;
        return output;
    }
}