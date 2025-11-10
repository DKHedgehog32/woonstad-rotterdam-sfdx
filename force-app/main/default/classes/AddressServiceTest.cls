/**
 * Test class for the Address service
 */
@IsTest
private class AddressServiceTest {
    @IsTest
    static void testTrigger() {
        List<Address__c> addresses = TestDataFactory.getAddresses(2);
        Test.startTest();
        insert addresses;
        addresses = [SELECT Id, Name, Unique_Key__c FROM Address__c];
        System.assertEquals(2,addresses.size(),'Expected 2 address records');
        System.assertNotEquals(null,addresses[0].Id,'Expected an Id');
        System.assertNotEquals(null,addresses[1].Id,'Expected an Id');
        System.assertNotEquals(null,addresses[0].Name,'Expected a name');
        System.assertNotEquals(null,addresses[1].Name,'Expected a name');
        System.assertNotEquals(null,addresses[0].Unique_Key__c,'Expected a key');
        System.assertNotEquals(null,addresses[1].Unique_Key__c,'Expected a key');
        Test.stopTest();
    }
    @IsTest
    static void testPostalCode() {
        Address__c add1 = new Address__c();
        add1.Postal_Code__c = '1234 AA';
        Address__c add2 = new Address__c();
        add2.Postal_Code__c = '4234AA';
        Test.startTest();
        AddressService.normalizePostalCodesByReference(new List<Address__c> {add1, add2});
        System.assertEquals('1234AA',add1.Postal_Code__c,'Expected spaces removed');
        System.assertEquals('4234AA',add2.Postal_Code__c,'Expected unchanged');
        Test.stopTest();
    }
    @IsTest
    static void testKey() {
        Address__c add1 = new Address__c();
        add1.Postal_Code__c = '1234AA';
        add1.House_Number_Addition__c = 'x';
        add1.House_Number__c = '1';
        add1.House_Letter__c = 'a';
        add1.Country__c = 'NL';
        Address__c add2 = new Address__c();
        add2.Postal_Code__c = '4234AA';
        add2.House_Number_Addition__c = 'x';
        add2.House_Number__c = '1';
        add2.House_Letter__c = '';
        add2.Country__c = 'NL';
        //
        // Non NL, should return null key
        Address__c add3 = new Address__c();
        add3.Postal_Code__c = '4234AA';
        add3.House_Number_Addition__c = 'x';
        add3.House_Number__c = '1';
        add3.House_Letter__c = '';
        add3.Country__c = 'BE';
        //
        // Non NL, should return null key
        Address__c add4 = new Address__c();
        add4.PO_Box_Number__c = '1234';
        add4.Postal_Code__c = '4234AA';
        add4.House_Number_Addition__c = 'x';
        add4.House_Number__c = '1';
        add4.House_Letter__c = '';
        add4.Country__c = 'NL';
        //
        // Non NL, should return null key
        Address__c add5 = new Address__c();
        add5.Freepost_number__c = 'fp123';
        add5.Postal_Code__c = '4234AA';
        add5.House_Number_Addition__c = 'x';
        add5.House_Number__c = '1';
        add5.House_Letter__c = '';
        add5.Country__c = 'NL';
        Test.startTest();
        List<String> keys = AddressService.getAddressKeys(new List<Address__c> { add1, add2, add3, add4, add5 });
        System.assertEquals('1234AA1Xax', keys[0],'Expected 1234AA1Xax');
        System.assertEquals('4234AA1Xx', keys[1], 'Expected 4234AA1Xx');
        System.assert(keys[2].startsWith('BE'),'Expected BE in key for foreign address');
        System.assertEquals('4234AA1234', keys[3], 'Expected 4234AA1234 for po box');
        System.assertEquals('4234AAfp123', keys[4],'Expected 4234AAfp123 for antwoordnummer');
        Test.stopTest();
    }
    @IsTest
    static void testName() {
        Address__c add1 = new Address__c();
        add1.Street__c = 'De straat';
        add1.House_Number_Addition__c = 'x';
        add1.House_Number__c = '1';
        add1.House_Letter__c = 'a';
        add1.City__c = 'Dorp';
        add1.Country__c = 'NL';
        Address__c add2 = new Address__c();
        add2.Street__c = 'Hoofdweg';
        add2.House_Number__c = '1';
        add2.House_Letter__c = '';
        add2.City__c = 'Stad';
        add2.Country__c = 'NL';
        //
        // Ensure name value gets abbreviated to 80 chars
        Address__c addLong = new Address__c();
        addLong.Street__c = 'TencharactTencharactTencharactTencharactTencharactTencharactTencharactTencharact';
        addLong.House_Number_Addition__c = 'x';
        addLong.House_Number__c = '1';
        addLong.House_Letter__c = '';
        addLong.City__c = 'Stad';
        addLong.Country__c = 'NL';
        Address__c addNonNl = new Address__c();
        addNonNl.Street__c = 'Hoofdweg';
        addNonNl.House_Number__c = '1';
        addNonNl.House_Letter__c = '';
        addNonNl.City__c = 'Stad';
        addNonNl.Address_Line_1__c = 'addr1line';
        addNonNl.Address_Line_2__c = 'addr2line';
        addNonNl.Country__c = 'BE';
        Test.startTest();
        List<String> names = AddressService.getNameValues(new List<Address__c> { add1, add2, addLong, addNonNl });
        System.assertEquals('De straat 1 a x, Dorp, NL', names[0],'Expected De straat 1 a x, Dorp, NL');
        System.assertEquals('Hoofdweg 1, Stad, NL', names[1], 'Expected Hoofdweg 1, Stad, NL');
        System.assertEquals('TencharactTencharactTencharactTencharactTencharactTencharactTencharactTenchar...', names[2], 'Expected only streetname of 80 positions');
        System.assert(names[3].contains('addr1line'), 'Expected "addr1line" in name');
        Test.stopTest();
    }

    @IsTest
    static void testCreationAndJunctionDiffAddress() {
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());

        Account[] oneAcc = TestDataFactory.getPersonAccounts(1);
        oneAcc[0].UUID__c = IdentifierService.getUUID();
        upsert oneAcc Account.UUID__c;

        PersoonModel pm = new PersoonModel();
        pm.id = oneAcc[0].UUID__c;
        pm.postadres = new PersoonAdresModel();
        pm.postadres.begindatum = System.today();
        pm.postadres.adres = new AdresModel();
        pm.postadres.adres.woonplaats = 'Leeuwarden';
        pm.postadres.adres.postcode = '1234AB';
        pm.postadres.adres.huisnummer = '1';
        pm.postadres.adres.land = new ReferentieCodeModel();
        pm.postadres.adres.land.code = 'NL';
        pm.woonadres = new PersoonAdresModel();
        pm.woonadres.begindatum = System.today();
        pm.woonadres.adres = new AdresModel();
        pm.woonadres.adres.postcode = '1234AA';
        pm.woonadres.adres.woonplaats = 'Leeuwarden';
        pm.woonadres.adres.huisnummer = '1';
        pm.woonadres.adres.land = new ReferentieCodeModel();
        pm.woonadres.adres.land.code = 'NL';
        Test.startTest();
        Account_Address__c[] accAddress = AddressService.convertPersoonAddresses(pm, oneAcc[0].UUID__c);
        //System.debug('### UPSERTING '+JSON.serializePretty(accAddress));
        upsert accAddress;
        Test.stopTest();
        System.assertEquals(2, [SELECT Count() FROM Address__c],'Expected 2 address records');
        System.assertEquals(2, [SELECT Count() FROM Account_Address__c],'Expected 2 account address records');
        Account_Address__c[] acas = [SELECT Start_Date__c, Type__c, Address__r.Postal_Code__c, Is_Primary__c FROM Account_Address__c];
        for(Account_Address__c aca : acas) {
            System.assertEquals(true, aca.Is_Primary__c,'Expected account address primary to be true');
            if(aca.Type__c == 'POS') {
                System.assertEquals('1234AB', aca.Address__r.Postal_Code__c,'Expected 1234AB as postal code for the postal address');
            } else {
                System.assertEquals('1234AA', aca.Address__r.Postal_Code__c,'Expected 1234AA as postal code for the shipping address');
                System.assertEquals('WOO', aca.Type__c,'Expected type "WOO" for the shipping address');
            }
        }
    }

    @IsTest
    static void testCreationAndJunctionDiffDateSameAddress() {
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());

        Account[] oneAcc = TestDataFactory.getPersonAccounts(1);
        oneAcc[0].UUID__c = IdentifierService.getUUID();
        upsert oneAcc Account.UUID__c;

        PersoonModel pm = new PersoonModel();
        pm.id = oneAcc[0].UUID__c;
        pm.postadres = new PersoonAdresModel();
        pm.postadres.begindatum = System.today();
        pm.postadres.adres = new AdresModel();
        pm.postadres.adres.woonplaats = 'Leeuwarden';
        pm.postadres.adres.postcode = '1234AA';
        pm.postadres.adres.huisnummer = '1';
        pm.postadres.adres.land = new ReferentieCodeModel();
        pm.postadres.adres.land.code = 'NL';

        pm.woonadres = new PersoonAdresModel();
        pm.woonadres.begindatum = System.today().addDays(10);
        pm.woonadres.adres = new AdresModel();
        pm.woonadres.adres.woonplaats = 'Leeuwarden';
        pm.woonadres.adres.postcode = '1234AA';
        pm.woonadres.adres.huisnummer = '1';
        pm.woonadres.adres.land = new ReferentieCodeModel();
        pm.woonadres.adres.land.code = 'NL';

        Test.startTest();
        Account_Address__c[] accAddress = AddressService.convertPersoonAddresses(pm, oneAcc[0].UUID__c);
        upsert accAddress;
        Test.stopTest();
        System.assertEquals(1, [SELECT Count() FROM Address__c],'Expected 1 address record');
        System.assertEquals(2, [SELECT Count() FROM Account_Address__c],'Expected 2 account address records');
        Account_Address__c[] acas = [SELECT Start_Date__c, Type__c, Address__r.Postal_Code__c, Is_Primary__c FROM Account_Address__c LIMIT 1];
        for(Account_Address__c aca : acas) {
            System.assertEquals(true, aca.Is_Primary__c,'Expected account address to be primary');

            if(aca.Type__c == 'POS') {
                System.assertEquals('1234AA', aca.Address__r.Postal_Code__c,'Expected 1234AA as postal code for the postal address');
                System.assertEquals(System.today(), aca.Start_Date__c,'Expected today as start date for the postal address');
            } else {
                System.assertEquals('1234AA', aca.Address__r.Postal_Code__c,'Expected 1234AA as postal code for the shipping address');
                System.assertEquals(System.today().addDays(10), aca.Start_Date__c,'Expected today+10 as start date for the shipping address');
            }
        }
    }

    @IsTest
    static void testGetPersoonAddresses() {
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());

        Account[] accs = TestDataFactory.getPersonAccounts(1);
        accs[0].UUID__c = IdentifierService.getUUID();
        accs.addAll(TestDataFactory.getBusinessAccounts(1));
        accs[1].UUID__c = IdentifierService.getUUID();
        upsert accs;

        List<Address__c> addresses = TestDataFactory.getAddresses(4);
        upsert addresses;

        List<Account_Address__c> accountAddresses = new List<Account_Address__c>();
        Integer counter = 0;
        for(Account acc : accs) {
            Account_Address__c acc1 = new Account_Address__c();
            acc1.Start_Date__c = System.today();
            acc1.Type__c = 'WOO';
            acc1.Account__c = acc.Id;
            acc1.Address__c = addresses[counter].Id;
            accountAddresses.add(acc1);
            counter++;
        }
        //
        // Add another address so each has 2
        for(Account acc : accs) {
            Account_Address__c acc1 = new Account_Address__c();
            acc1.Start_Date__c = System.today();
            acc1.Type__c = 'POS';
            acc1.Account__c = acc.Id;
            acc1.Address__c = addresses[counter].Id;
            accountAddresses.add(acc1);
            counter++;
        }
        upsert accountAddresses;
        Test.startTest();
        List<PersoonAdresModel> pasPersoon = AddressService.getPersoonAddressen(accs[0].UUID__c);
        List<PersoonAdresModel> pasBusiness = AddressService.getPersoonAddressen(accs[1].UUID__c);
        System.assertEquals(2, pasPersoon.size(),'Expected 2 addresses for person');
        System.assertEquals(2, pasBusiness.size(),'Expected 2 addresses for business');
        Test.stopTest();
    }
    @IsTest
    static void testSetStandardFields() {
        Test.setMock(HttpCalloutMock.class, new OkapiMocks.GetRelationSuccess());

        Account[] accs = TestDataFactory.getPersonAccounts(1);
        accs[0].UUID__c = IdentifierService.getUUID();
        upsert accs;
        List<Address__c> addresses = TestDataFactory.getAddresses(2);
        upsert addresses;
        Test.startTest();
        accs[0].Primary_Billing_Address__r = addresses[0];
        accs[0].Primary_Shipping_Address__r = addresses[1];
        update accs;
        System.assertEquals(addresses[0].Full_Street_Name__c, accs[0].BillingStreet, 'Expected same billing street as the primary address');
        System.assertEquals(addresses[1].Full_Street_Name__c, accs[0].ShippingStreet, 'Expected same shipping street as the primary address');
        Test.stopTest();
    }
}