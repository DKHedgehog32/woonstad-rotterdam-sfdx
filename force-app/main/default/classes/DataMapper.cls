/**
 * Holds mapping for the interface datamodel to the salesforce model and vice versa
 * Does not map external id's, foreign keys and most other identifiers, they should be mapped inside the service class
 * Also does not contain some junction objects
 */
public class DataMapper {

    public static Account persoonToAccount(PersoonModel persoon) {
        System.assertNotEquals(null, persoon, 'Need an persoonmodel as input!');

        //
        // There are other way of doing this
        Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Account.getRecordTypeInfosById();
        Map<String, ID> rtIdByDeveloperName = new Map<String, ID>();
        for(ID rtId : rtMapById.keySet()) {
            Schema.RecordTypeInfo rti = rtMapById.get(rtId);
            if(rti.active) {
                rtIdByDeveloperName.put(rti.getDeveloperName(), rtId);
            }
        }

        //
        // Obtain the 2 required id's
        Id paId = rtIdByDeveloperName.get('PersonAccount');
        Id baId = rtIdByDeveloperName.get('Business_Account');

        //
        // Generic fields
        Account output = new Account();
        output.Administration_Id__c = persoon.idAdministratie;
        output.External_Id__c = persoon.idExtern;
        output.UUID__c = persoon.id;
        //output.Is_Creditor__c = persoon.isCrediteur;

        switch on persoon.soort.code {
            //
            // NatuurlijkPersoon, Persoongroep of Rechtspersoon. Referentiedatasoort RELATIESOORT.
            // https://www.coraveraonline.nl/index.php/Referentiedata:RELATIESOORT
            // NAT, REC, GRO
            when 'NAT' {
                output.LastName = persoon.achternaam;
                output.FirstName = persoon.voornaam?.abbreviate(40);
                output.PersonBirthdate = persoon.geboortedatum;
                output.Salutation = persoon.aanhef;
                output.PersonGenderIdentity = persoon.geslacht?.code;
                output.Death_Date__pc = persoon.overlijdensdatum;
                output.MiddleName = persoon.tussenvoegsels;
                output.Initials__pc = persoon.initialen;
                output.PersonEmail = persoon.contactGegevens?.email;
                output.PersonMobilePhone = persoon.contactGegevens?.telefoonMobiel;
                output.Phone = persoon.contactGegevens?.telefoonVast;
                output.Preferred_Phone__pc = persoon.contactGegevens?.telefoonVoorkeur;
                output.Preferred_Communication_Channel__pc = persoon.communicatievoorkeur?.code;
                output.RecordTypeId = paId;
            }
            when else {
                output.Name = persoon.naam;
                output.VAT_Number__c = persoon.btwNummer;
                //output.Global_Location_Number__c = persoon.globaalLocatienummer;
                output.Chamber_Of_Commerce_Number__c = persoon.kvkNummer;
                output.Organisation_Type__c = persoon.organisatievorm?.code;
                output.Type = persoon.detailSoort?.code;
                output.Phone = persoon.contactGegevens?.telefoonVast;
                output.Business_Email__c =  persoon.contactGegevens?.email;
                output.Mobile_Business_Phone__c = persoon.contactGegevens?.telefoonMobiel;
                output.RecordTypeId = baId;
            }
        }
        //  System.debug('## persoonToAccount output: '+JSON.serializePretty(output));
        return output;
    }

    public static PersoonModel accountToPersoon(Account account) {
        System.assertNotEquals(null, account, 'Need an account as input!');

        PersoonModel output = new PersoonModel();
        output.idAdministratie = account.Administration_Id__c;
        output.id = account.UUID__c;
        output.idExtern = account.External_Id__c;
        //output.isCrediteur = account.Is_Creditor__c;
        if(account.IsPersonAccount) {
            output.achternaam = account.LastName;
            output.voornaam = account.FirstName;
            output.geboortedatum = account.PersonBirthdate;
            output.aanhef = account.Salutation;
            output.geslacht = new ReferentieCodeModel();
            output.geslacht.code = account.PersonGenderIdentity;
            output.overlijdensdatum = account.Death_Date__pc;
            output.tussenvoegsels = account.MiddleName;
            output.initialen = account.Initials__pc;
            output.overlijdensdatum = account.Death_Date__pc;
            output.contactGegevens = new ContactGegevensModel();
            output.contactGegevens.email = account.PersonEmail;
            output.contactGegevens.telefoonMobiel = account.PersonMobilePhone;
            output.contactGegevens.telefoonVast = account.Phone;
            output.contactGegevens.telefoonVoorkeur = account.Preferred_Phone__pc;
            output.soort = new ReferentieCodeModel();
            output.soort.code = 'NAT';
            output.soort.naam = 'Natuurlijke persoon';
            output.communicatievoorkeur = new ReferentieCodeModel();
            output.communicatievoorkeur.code = account.Preferred_Communication_Channel__pc;

        } else {
            output.naam = account.Name;
            output.btwNummer = account.VAT_Number__c;
            //output.globaalLocatienummer = account.Global_Location_Number__c;
            output.kvkNummer = account.Chamber_Of_Commerce_Number__c;
            output.organisatievorm = new ReferentieCodeModel();
            output.organisatievorm.code = account.Organisation_Type__c;
            output.contactGegevens = new ContactGegevensModel();
            output.contactGegevens.telefoonVast = account.Phone;
            output.detailSoort = new ReferentieCodeModel();
            output.detailSoort.code = account.Type;
            output.soort = new ReferentieCodeModel();
            output.soort.code = 'REC';
            output.soort.naam = 'Rechtspersoon';
        }

        return output;
    }

    public static Address__c mapPersoonAdresToAddress(PersoonAdresModel addressInput) {
        System.assertNotEquals(null, addressInput, 'Need an address as input!');
        Address__c ad = mapAdresModelToAddress(addressInput.adres);

        return ad;
    }
    public static Address__c mapAdresModelToAddress(AdresModel addressInput) {
        System.assertNotEquals(null, addressInput, 'Need an address as input!');
        Address__c ad = new Address__c();
        ad.Country__c = (addressInput.land?.code == null) ? 'NL' : addressInput.land?.code; // Default NL
        if(ad.Country__c <> 'NL') {
            //
            // Foreign address
            ad.Address_Line_1__c = addressInput.straatnaam;
            ad.Address_Line_1__c += (addressInput.huisnummer<>null) ? ' '+addressInput.huisnummer : '';
            ad.Address_Line_1__c += (addressInput.huisnummerToevoeging<>null) ? addressInput.huisnummerToevoeging : '';
            ad.Address_Line_1__c += (addressInput.huisletter<>null) ? addressInput.huisletter : '';
            ad.Address_Line_2__c = addressInput.postcode;
        } else {
            //
            // Dutch address
            ad.Postal_Code__c = addressInput.postcode;
            ad.Province__c = addressInput.provincie?.code;
        }
        //
        // Any address
        ad.Street__c = addressInput.straatnaam;
        ad.House_Number__c = addressInput.huisnummer;
        ad.House_Number_Addition__c = addressInput.huisnummerToevoeging;
        ad.House_Letter__c = addressInput.huisletter;
        ad.City__c = addressInput.woonplaats;
        ad.Freepost_number__c = addressInput.antwoordnummer;
        ad.PO_Box_Number__c = addressInput.postbusnummer;
        ad.Denotation__c = addressInput.aanduiding;
        //
        // Keys
        AddressService.normalizePostalCodesByReference(ad);
        ad.Unique_Key__c = AddressService.getAddressKey(ad);
        ad.Name = AddressService.getNameValue(ad);
        return ad;
    }
    public static AdresModel mapAddressToAdresModel(Address__c addressInput) {
        System.assertNotEquals(null, addressInput, 'Need an address as input!');
        AdresModel ad = new AdresModel();
        ad.postcode = addressInput.Postal_Code__c;
        ad.woonplaats = addressInput.City__c;
        ad.huisnummer = addressInput.House_Number__c;
        ad.huisnummerToevoeging = addressInput.House_Number_Addition__c;
        ad.huisletter = addressInput.House_Letter__c;
        ad.land = new ReferentieCodeModel();
        ad.land.code = addressInput.Country__c;
        ad.straatnaam = addressInput.Street__c;
        ad.provincie = new ReferentieCodeModel();
        ad.provincie.code = addressInput.Province__c;
        ad.antwoordnummer = addressInput.Freepost_number__c;
        ad.postbusnummer = addressInput.PO_Box_Number__c;
        ad.aanduiding = addressInput.Denotation__c;
        return ad;
    }
    public static PersoonAdresModel mapAddressToPersoonAdresModel(Account_Address__c accountAddressInput) {
        System.assertNotEquals(null, accountAddressInput, 'Need an accountAddressInput as input!');
        PersoonAdresModel ad = new PersoonAdresModel();
        ad.id = accountAddressInput.Id;
        ad.idPersoon = accountAddressInput.Account__r.UUID__c;
        ad.adres = new AdresModel();
        ad.adres = mapAddressToAdresModel(accountAddressInput.Address__r);
        ad.begindatum = accountAddressInput.Start_Date__c;
        ad.einddatum = accountAddressInput.End_Date__c;
        ad.soort = new ReferentieCodeModel();
        ad.soort.code = accountAddressInput.Type__c;
        return ad;
    }
    //
    // idExtern, idAdminstratie and id on bank account are mapped counter to their name
    public static BetaalgegevenModel mapBankAccountToBetaalGegevenModel(Bank_Account__c bankAccountInput) {
        System.assertNotEquals(null, bankAccountInput, 'Need an Bank_Account__c as input!');
        BetaalgegevenModel bm = new BetaalgegevenModel();
        bm.id = bankAccountInput.External_Id__c;
        bm.idAdministratie = 'SALESFORCE';
        bm.idExtern = bankAccountInput.Id;
        bm.primair = bankAccountInput.Default__c;
        bm.bic = bankAccountInput.Bic__c;
        bm.iban = bankAccountInput.IBAN__c;
        bm.begindatum = bankAccountInput.Valid_From__c;
        bm.einddatum = bankAccountInput.Valid_To__c;
        bm.idPersoon = bankAccountInput.Account__r.UUID__c;
        bm.actief = bankAccountInput.Active__c;
        return bm;
    }
    //
    // idExtern, idAdminstratie and id on bank account are mapped counter to their name
    public static Bank_Account__c mapBetaalGegevenModelToBankAccount(BetaalgegevenModel betaalgegevenModelInput) {
        System.assertNotEquals(null, betaalgegevenModelInput, 'Need an BetaalgegevenModel as input!');
        Bank_Account__c baRecord = new Bank_Account__c();
        baRecord.Administration_Id__c = 'WOCAS';
        baRecord.External_Id__c = betaalgegevenModelInput.id;
        baRecord.Valid_From__c = betaalgegevenModelInput.begindatum;
        baRecord.Valid_To__c = betaalgegevenModelInput.einddatum;
        baRecord.Bic__c = betaalgegevenModelInput.bic;
        baRecord.IBAN__c = betaalgegevenModelInput.iban;
        baRecord.Default__c = betaalgegevenModelInput.primair;
        baRecord.Active__c = betaalgegevenModelInput.actief;
        return baRecord;
    }
    //
    // Convert Relationship__c to PersoonRelatieModel
    public static PersoonRelatieModel mapRelationShipToPersoonRelatieModel(Relationship__c relationInput) {
        System.assertNotEquals(null, relationInput, 'Need an Relationship__c as input!');
        PersoonRelatieModel prm = new PersoonRelatieModel();
        //prm.persoonId = relationInput.Primary_Relation__r.UUID__c;
        //prm.relatieId = relationInput.Subsidiary_Relation__r.UUID__c;
        prm.relatieId = relationInput.Primary_Relation__r.UUID__c;
        prm.persoonId = relationInput.Subsidiary_Relation__r.UUID__c;
        prm.begindatum = relationInput.Start_Date__c;
        prm.einddatum = relationInput.End_Date__c;
        prm.persoonRol = new ReferentieCodeModel();
        prm.persoonRol.code = relationInput.Type__c;
        prm.id = relationInput.Id;
        return prm;
    }
    //
    // Convert Relationship__c to PersoonRelatieModel
    public static Relationship__c mapPersoonRelatieModelToRelationship(PersoonRelatieModel relationInput) {
        System.assertNotEquals(null, relationInput, 'Need an PersoonRelatieModel as input!');
        Relationship__c rel = new Relationship__c();
        //rel.Primary_Relation__r = new Account(UUID__c=relationInput.persoonId);
        //rel.Subsidiary_Relation__r = new Account(UUID__c=relationInput.relatieId);
        rel.Primary_Relation__r = new Account(UUID__c=relationInput.relatieId);
        rel.Subsidiary_Relation__r = new Account(UUID__c=relationInput.persoonId);
        rel.Start_Date__c = relationInput.begindatum;
        rel.End_Date__c = relationInput.einddatum;
        rel.Type__c = relationInput.relatieRol?.code;
        rel.Administration_Id__c = relationInput.idAdministratie;
        rel.External_Id__c = relationInput.idExtern;
        return rel;
    }
    //
    // Overload for AccountContactRelation to PersoonRelatieModel
    public static PersoonRelatieModel mapRelationShipToPersoonRelatieModel(AccountContactRelation relationInput) {
        System.assertNotEquals(null, relationInput, 'Need an AccountContactRelation as input!');
        PersoonRelatieModel prm = new PersoonRelatieModel();
        prm.persoonId = relationInput.Account.UUID__c;
        prm.relatieId = relationInput.Contact.Contact_UUID__c;
        prm.begindatum = relationInput.StartDate;
        prm.einddatum = relationInput.EndDate;
        prm.persoonRol = new ReferentieCodeModel();
        prm.persoonRol.code = relationInput.Roles;
        prm.id = relationInput.Id;
        return prm;
    }
    //
    // Overload for PersoonRelatieModel to AccountContactRelation
    public static AccountContactRelation mapPersoonRelatieModelToAccountContactRelation(PersoonRelatieModel relationInput) {
        System.assertNotEquals(null, relationInput, 'Need a PersoonRelatieModel as input!');
        AccountContactRelation rel = new AccountContactRelation();
        //rel.Account = new Account(UUID__c=relationInput.persoonId);
        rel.StartDate = relationInput.begindatum;
        rel.EndDate = relationInput.einddatum;
        rel.Role_2__c = relationInput.relatieRol?.code;
        rel.Administration_Id__c = relationInput.idAdministratie;
        rel.External_Id__c = relationInput.idExtern;
        return rel;
    }
    //
    // Contract related
    public static Real_Estate_Contract__c mapContractModelToRealEstateContract(ContractModel contractModelInput) {
        System.assertNotEquals(null, contractModelInput, 'Need an ContractModel as input!');
        Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Real_Estate_Contract__c.getRecordTypeInfosById();
        //
        // Oddly the only standard get by name function gets the rt's by label :( :(
        Map<String, ID> rtIdByDeveloperName = new Map<String, ID>();
        for(ID rtId : rtMapById.keySet()) {
            Schema.RecordTypeInfo rti = rtMapById.get(rtId);
            if(rti.active) {
                rtIdByDeveloperName.put(rti.getDeveloperName(), rtId);
            }
        }
        System.debug('### Contract Record Type Map: '+JSON.serializePretty(rtIdByDeveloperName));
        //
        // Obtain the 3 required id's
        Id rentalCtrRecordTypeId = rtIdByDeveloperName.get('Rental');
        Id salesCtdRecordTypeId = rtIdByDeveloperName.get('Sales');
        Id serviceCtdRecordTypeId = rtIdByDeveloperName.get('Service');


        Real_Estate_Contract__c contr = new Real_Estate_Contract__c();
        contr.Start_Date__c = contractModelInput.begindatum;
        contr.End_Date__c = contractModelInput.einddatum;
        contr.Gross_Rent__c	= contractModelInput.brutoContractprijs;
        contr.Parent_Contract_Number__c = contractModelInput.bovenliggendeOvereenkomst;
        contr.Contract_Number__c = contractModelInput.id;
        contr.Next_Rent_Price_Change_Date__c = contractModelInput.huurprijsWijzigingVanafDatum;
        contr.Actual_Usage__c = contractModelInput.feitelijkGebruik;
        contr.Product_Description__c = contractModelInput.detailSoort?.naam;
        if(contractModelInput?.eenheden?.size() > 0 && !String.isEmpty(contractModelInput?.eenheden[0].code)) {
            contr.Contract_Unit__r = new Contract_Unit__c(External_Id__c=contractModelInput.eenheden[0].code); // Code bevat consistente waarheid
        }        
        
        if(!String.isEmpty(contractModelInput.idContractPartij)) {
            contr.Contract_Party__r = new Account(UUID__c=contractModelInput.idContractPartij);
        }
        if(!String.isEmpty(contractModelInput.idBetaalgegeven)) {
            contr.Bank_Account__r = new Bank_Account__c(Integration_Key__c = contractModelInput.idBetaalgegeven);
        }
        if(contractModelInput.soort?.code?.toLowerCase()=='koo') {
            contr.RecordTypeId = salesCtdRecordTypeId;
            contr.Contract_Type__c = 'KOO';
        } else if(contractModelInput.soort?.code?.toLowerCase()=='ser') {
            contr.RecordTypeId = serviceCtdRecordTypeId;
            contr.Contract_Type__c = 'SER';
        } else {
            //
            // Defaults to huur
            contr.RecordTypeId = rentalCtrRecordTypeId;
            contr.Contract_Type__c = 'HUU';
        }
        return contr;
    }
    public static Contract_Line__c mapContractModelToContractLine(ContractModel contractModelInput) {
        System.assertNotEquals(null, contractModelInput, 'Need a ContractEenheidModel as input!');
        Contract_Line__c line = new Contract_Line__c();
        line.Contract_Number__c = contractModelInput.id;
        line.Real_Estate_Contract__r = new Real_Estate_Contract__c(Parent_Contract_Number__c=contractModelInput.bovenliggendeOvereenkomst);
        line.Active_from_Date__c = contractModelInput.geldigVanafDatumTijd?.date();
        line.Active_to_Date__c = contractModelInput.einddatum;
        line.Price__c = contractModelInput.brutoContractprijs;
        line.Quantity__c = 1; // Always 1
        if(contractModelInput?.eenheden?.size() > 0 && !String.isEmpty(contractModelInput?.eenheden[0].code)) {
            line.Contract_Unit__r = new Contract_Unit__c(External_Id__c=contractModelInput.eenheden[0].code); // Code bevat consistente waarheid
        }
        line.Account__r = new Account(UUID__c=contractModelInput.idPersoon);
        line.External_Id__c = contractModelInput.code; // Contains the OID from Wocas!
        line.Administration_Id__c = contractModelInput.idAdministratie;
        line.Status__c = contractModelInput.status?.code;
        line.Product_Description__c = contractModelInput.detailSoort?.naam;
        line.Source_System__c = contractModelInput.bronSysteem;
        line.Next_Rent_Price_Change_Date__c = contractModelInput.huurprijsWijzigingVanafDatum;
        line.Actual_Usage__c = contractModelInput.feitelijkGebruik;
        return line;
    }

    public static Contract_Contact_Role__c mapContractRoleToContractContactRole(ContractRolModel contractRolInput) {
        System.assertNotEquals(null, contractRolInput, 'Need a ContractRolModel as input!');
        Contract_Contact_Role__c ccRole = new Contract_Contact_Role__c();
        ccRole.Start_Date__c = contractRolInput.begindatum;
        ccRole.End_Date__c = contractRolInput.einddatum;
        ccRole.Role__c = contractRolInput.rol?.code;
        return ccRole;
    }
}