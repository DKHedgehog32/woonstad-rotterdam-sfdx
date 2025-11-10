/**
 * Service class to convert SObject data to the PersoonModel structs
 */
public with sharing class PersoonService {
    public static PersoonModel getPersoonByUuid(String uuid) {
        //
        // Query the requested person + all additional data and return it
        List<Account> theAccounts = [SELECT Id, Name, Administration_Id__c, RecordType.DeveloperName, IsPersonAccount, UUID__c, External_Id__c,
                Type, Preferred_Communication_Channel__pc,
                LastName, FirstName, PersonBirthdate, PersonGenderIdentity, Salutation, Death_Date__pc, MiddleName, Initials__pc,
                PersonEmail, PersonMobilePhone, Phone, Preferred_Phone__pc,
                VAT_Number__c, Chamber_Of_Commerce_Number__c, Organisation_Type__c,
                Primary_Billing_Address__c, Primary_Shipping_Address__c,
                Primary_Shipping_Address__r.Province__c, Primary_Billing_Address__r.Province__c, Primary_Billing_Address__r.Denotation__c,
                Primary_Billing_Address__r.Unique_Key__c, Primary_Billing_Address__r.Name, Primary_Billing_Address__r.PO_Box_Number__c, Primary_Billing_Address__r.Postal_Code__c,
                Primary_Billing_Address__r.Freepost_number__c, Primary_Billing_Address__r.Street__c, Primary_Billing_Address__r.Country__c, Primary_Billing_Address__r.House_Letter__c, Primary_Billing_Address__r.Address_Line_2__c,
                Primary_Billing_Address__r.House_Number_Addition__c, Primary_Billing_Address__r.House_Number__c, Primary_Billing_Address__r.City__c, Primary_Billing_Address__r.Address_Line_1__c,
                Primary_Shipping_Address__r.Denotation__c, Primary_Shipping_Address__r.Unique_Key__c, Primary_Shipping_Address__r.Name, Primary_Shipping_Address__r.PO_Box_Number__c, Primary_Shipping_Address__r.Postal_Code__c,
                Primary_Shipping_Address__r.Freepost_number__c, Primary_Shipping_Address__r.Street__c, Primary_Shipping_Address__r.Country__c, Primary_Shipping_Address__r.House_Letter__c, Primary_Shipping_Address__r.Address_Line_2__c,
                Primary_Shipping_Address__r.House_Number_Addition__c, Primary_Shipping_Address__r.House_Number__c, Primary_Shipping_Address__r.City__c, Primary_Shipping_Address__r.Address_Line_1__c,
                (SELECT Id, IBAN__c, Valid_To__c, Valid_From__c, Bic__c, Default__c, External_Id__c, Administration_Id__c, Account__r.UUID__c, Active__c FROM Bank_Accounts__r),
                (SELECT Id, Type__c, Start_Date__c, End_Date__c, Primary_Relation__r.UUID__c, Subsidiary_Relation__r.UUID__c FROM Primary_Account_In_Relationships__r),
                (SELECT Id, Type__c, Start_Date__c, End_Date__c, Primary_Relation__r.UUID__c, Subsidiary_Relation__r.UUID__c FROM Subsidiary_Account_In_Relationships__r),
                (SELECT Id, Roles, StartDate, EndDate, Account.UUID__c, Contact.Contact_UUID__c FROM AccountContactRelations)
        FROM Account
        WHERE UUID__c = :uuid
        LIMIT 1];
        if(theAccounts <> null && theAccounts.size() == 1) {
            Account theAccount = theAccounts[0];
            PersoonModel pm = DataMapper.accountToPersoon(theAccount);
            //
            // Add the address data
            if(theAccount.Primary_Billing_Address__c <> null) {
                pm.postadres = new PersoonAdresModel();
                pm.postadres.soort = new ReferentieCodeModel();
                pm.postadres.soort.code = 'POS';
                pm.postadres.adres = DataMapper.mapAddressToAdresModel(theAccount.Primary_Billing_Address__r);
            }
            if(theAccount.Primary_Shipping_Address__c <> null) {
                pm.woonadres = new PersoonAdresModel();
                pm.woonadres.soort = new ReferentieCodeModel();
                pm.woonadres.soort.code = 'WOO';
                pm.woonadres.adres = DataMapper.mapAddressToAdresModel(theAccount.Primary_Shipping_Address__r);
            }
            //
            // Add bank account data
            if(theAccount.Bank_Accounts__r?.size() > 0) {
                pm.betaalgegevens = new List<BetaalgegevenModel>();
                for(Bank_Account__c ba : theAccount.Bank_Accounts__r) {
                    BetaalgegevenModel bmodel = DataMapper.mapBankAccountToBetaalGegevenModel(ba);
                    pm.betaalgegevens.add(bmodel);
                }
            }

            //
            // Add relations between accounts/persons
            pm.persoonRelaties = new List<PersoonRelatieModel>();

            //
            // Add relationship data for primary side
            if(theAccount.Primary_Account_In_Relationships__r?.size() > 0) {
                for(Relationship__c rel : theAccount.Primary_Account_In_Relationships__r) {
                    PersoonRelatieModel prModel = DataMapper.mapRelationShipToPersoonRelatieModel(rel);
                    pm.persoonRelaties.add(prModel);
                }
            }
            //
            // Add relationship data for subsidiary side
            if(theAccount.Subsidiary_Account_In_Relationships__r?.size() > 0) {
                for(Relationship__c rel : theAccount.Subsidiary_Account_In_Relationships__r) {
                    PersoonRelatieModel prModel = DataMapper.mapRelationShipToPersoonRelatieModel(rel);
                    pm.persoonRelaties.add(prModel);
                }
            }

            //
            // Add relationship data for other types of relations
            if(theAccount.AccountContactRelations?.size() > 0) {
                for(AccountContactRelation rel : theAccount.AccountContactRelations) {
                    PersoonRelatieModel prModel = DataMapper.mapRelationShipToPersoonRelatieModel(rel);
                    pm.persoonRelaties.add(prModel);
                }
            }

            return pm;
        } else {
            //
            // Not found
            return null;
        }
    }
    public static PersoonModel postPersoon(PersoonModel persoon) {
        try {
            //
            // Post always used for new accounts
            Account acc = DataMapper.persoonToAccount(persoon);

            //
            // Assign the UUID here, if empty
            if (String.isEmpty(acc.UUID__c)) {
                acc.UUID__c = IdentifierService.getUUID();
            }

            //
            // Ignore duplicate rules
            System.debug('### Saving account: ' + JSON.serializePretty(acc));
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true;
            Database.SaveResult sr = Database.insert(acc, dml);

            if (sr.isSuccess()) {

                //
                // Create the addresses
                List<Account_Address__c> accAddresses = AddressService.convertPersoonAddresses(persoon, acc.UUID__c);
                upsert accAddresses Schema.Account_Address__c.Deduplication_Key__c;

                //
                // Bank accounts
                List<Bank_Account__c> bas = BankAccountService.getBankAccountRecordsForUpsert(persoon, acc.UUID__c);
                //System.debug('### UPSERTING BANK ACCOUNTS '+JSON.serializePretty(bas));
                upsert bas Schema.Bank_Account__c.Integration_Key__c;

                //
                // Relations
                List<AccountContactRelation> accContactRelations = PersonRelationService.getAccountContactRelationRecordsForUpsert(persoon, acc.UUID__c);
                System.debug('### Upserting accContactRelations ' + JSON.serializePretty(accContactRelations));
                upsert accContactRelations Schema.AccountContactRelation.Deduplication_Key__c;

                List<Relationship__c> relationships = PersonRelationService.getRelationshipRecordsForUpsert(persoon, acc.UUID__c);
                System.debug('### Upserting relationships ' + JSON.serializePretty(relationships));
                upsert relationships Schema.Relationship__c.Deduplication_Key__c;

                //
                // Enrich input for output
                persoon.id = acc.UUID__c;
                return persoon;

            } else {
                ApexFaultHandler.publishError(JSON.serialize(sr.getErrors()), 'PersoonService', 'postPersoon');
                throw new PersoonServiceException(JSON.serialize(sr.getErrors()));
            }

        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'PersoonService', 'postPersoon');
            throw ex;
        }
    }
    public static PersoonModel patchPersoon(String uuid, PersoonModel persoon) {
        try {
            Account acc = DataMapper.persoonToAccount(persoon);
            acc.UUID__c = uuid;
            Database.UpsertResult sr = Database.upsert(acc, Account.fields.UUID__c);

            if(sr.isSuccess()) {
                List<Account_Address__c> accAddresses = AddressService.convertPersoonAddresses(persoon, acc.UUID__c);

                upsert accAddresses Schema.Account_Address__c.Deduplication_Key__c;
                //
                // Bank accounts
                List<Bank_Account__c> bas = BankAccountService.getBankAccountRecordsForUpsert(persoon, acc.UUID__c);
                upsert bas Schema.Bank_Account__c.Integration_Key__c;


                // Relations
                List<AccountContactRelation> accContactRelations = PersonRelationService.getAccountContactRelationRecordsForUpsert(persoon, acc.UUID__c);
                upsert accContactRelations Schema.AccountContactRelation.Deduplication_Key__c;

                List<Relationship__c> relationships = PersonRelationService.getRelationshipRecordsForUpsert(persoon, acc.UUID__c);
                upsert relationships Schema.Relationship__c.Deduplication_Key__c;

                persoon.id = acc.UUID__c;

                return persoon;
            } else {
                ApexFaultHandler.publishError(JSON.serialize(sr.getErrors()),'PersoonService','patchPersoon');
                throw new PersoonServiceException(JSON.serialize(sr.getErrors()));
            }    
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'PersoonService', 'patchPersoon');
            throw ex;
        }
    }
    //
    // Validates a PATCH body
    public static PersoonRequestValidationResult validatePatchRequest(PersoonModel patchPersoon) {
        PersoonRequestValidationResult result = new PersoonRequestValidationResult();
        result.isValid = true;
        return result;
    }
    //
    // Validates a POST body
    public static PersoonRequestValidationResult validatePostRequest(PersoonModel postPersoon) {
        System.debug('### Validating persoon: '+JSON.serializePretty(postPersoon));
        PersoonRequestValidationResult result = new PersoonRequestValidationResult();
        result.isValid = true;
        if(postPersoon == null) {
            result.isValid = false;
            result.validationErrors.add('Missing Persoon');
        } else {
            if(postPersoon.soort == null) {
                result.isValid = false;
                result.validationErrors.add('Missing Persoon Soort');
            } else {
                if(postPersoon.soort.code == null) {
                    result.isValid = false;
                    result.validationErrors.add('Missing Persoon Soort Code');
                } else {
                    if(postPersoon.soort.code=='NAT') {
                        //
                        // Last Name mandatory
                        if(postPersoon.achternaam == null) {
                            result.isValid = false;
                            result.validationErrors.add('Missing Achternaam for Natuurlijkpersoon');
                        }
                    } else if(postPersoon.soort.code=='REC') {
                        //
                        // Name mandatory
                        if(postPersoon.naam == null) {
                            result.isValid = false;
                            result.validationErrors.add('Missing Naam for Rechtspersoon');

                        }

                    }
                }
            }
        }
        return result;
    }

    public class PersoonRequestValidationResult {
        public Boolean isValid;
        public List<String> validationErrors {
            get {
                if(validationErrors == null) {
                    validationErrors =  new List<String>();
                }
                return validationErrors;
            }
            set;
        }
    }
    public class PersoonServiceException extends Exception {

    }

}