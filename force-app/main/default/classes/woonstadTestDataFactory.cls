/*************************************************************************************************
 * Class           : woonstadTestDataFactory
 * Layer           : Test Utility
 * Purpose         : Centralized test data factory for Woonstad test classes
 *                   Provides reusable, consistent test data creation methods
 * Security        : @isTest - excluded from code size limits, test context only
 * Coverage        : N/A - Utility class for test support
 * Owner           : Woonstad KC
 * Last Modified   : 2025-09-04
 * 
 * Description:
 * Centralized test data factory following AWAF.dev principles and Salesforce best practices:
 * - Single source of truth for test data creation
 * - Consistent data patterns across all test classes  
 * - Excludes from org code size limits via @isTest annotation
 * - Supports both single record and bulk record creation
 * - Provides realistic test data that mirrors production scenarios
 * - Enables easy maintenance when data model changes
 * 
 * Key Features:
 * 1. Account creation with various record types and scenarios
 * 2. Address creation with comprehensive field population
 * 3. Account-Address junction record creation
 * 4. Person/Contact creation with address relationships
 * 5. Request object creation for action classes
 * 6. Support for bulk data creation (200+ records)
 * 7. Realistic Dutch address data for Woonstad context
 * 
 * Usage Pattern:
 * - Create records but don't insert (caller controls DML)
 * - Provide overloaded methods for different use cases
 * - Use consistent naming and data patterns
 * - Support negative testing scenarios
 * 
 * Changelog:
 * 2025-09-04: Initial creation with comprehensive factory methods
 * 2025-09-04: Fixed country code to use 'NL' for picklist compatibility
 *************************************************************************************************/
@isTest
public class woonstadTestDataFactory {
    
    // Constants for consistent test data - USING COUNTRY CODES NOT FULL NAMES
    private static final String DEFAULT_COUNTRY_CODE = 'NL'; // Netherlands ISO country code
    private static final String DEFAULT_CITY_AMSTERDAM = 'Amsterdam';
    private static final String DEFAULT_CITY_ROTTERDAM = 'Rotterdam';
    private static final String DEFAULT_CITY_UTRECHT = 'Utrecht';
    private static final String DEFAULT_TYPE_WOO = 'WOO';
    
    // Dutch postal code patterns for realistic test data
    private static final List<String> DUTCH_POSTAL_PATTERNS = new List<String>{
        '1000AA', '2000BB', '3000CC', '4000DD', '5000EE', 
        '6000FF', '7000GG', '8000HH', '9000II', '1100JJ'
    };
    
    // Dutch street names for realistic test data
    private static final List<String> DUTCH_STREET_NAMES = new List<String>{
        'Hoofdstraat', 'Kerkstraat', 'Schoolstraat', 'Dorpsstraat', 'Nieuwstraat',
        'Molenstraat', 'Stationsstraat', 'Marktstraat', 'Beatrixstraat', 'Wilhelminastraat'
    };
    
    // Dutch city names for variety in testing
    private static final List<String> DUTCH_CITIES = new List<String>{
        'Amsterdam', 'Rotterdam', 'Utrecht', 'Eindhoven', 'Tilburg',
        'Almere', 'Groningen', 'Breda', 'Nijmegen', 'Enschede'
    };
    
    /**
     * @description Creates a single test Account with standard fields populated
     * @param accountName Name for the account (optional, generates if null)
     * @return Account record (not inserted)
     */
    public static Account createAccount(String accountName) {
        return createAccount(accountName, 'Customer', null);
    }
    
    /**
     * @description Creates a single test Account with full field control
     * @param accountName Name for the account
     * @param accountType Type field value
     * @param recordTypeId Record Type ID (optional)
     * @return Account record (not inserted)
     */
    public static Account createAccount(String accountName, String accountType, Id recordTypeId) {
        Account acc = new Account();
        acc.Name = accountName != null ? accountName : 'Test Account ' + getRandomNumber();
        acc.Type = accountType != null ? accountType : 'Customer';
        acc.Industry = 'Housing';
        acc.Phone = '+31201234567';
        acc.Website = 'www.test-account.nl';
        
        if (recordTypeId != null) {
            acc.RecordTypeId = recordTypeId;
        }
        
        return acc;
    }
    
    /**
     * @description Creates a list of test Accounts with incremental naming
     * @param count Number of accounts to create
     * @return List of Account records (not inserted)
     */
    public static List<Account> createAccounts(Integer count) {
        return createAccounts(count, 'Customer');
    }
    
    /**
     * @description Creates a list of test Accounts with specified type
     * @param count Number of accounts to create
     * @param accountType Type for all accounts
     * @return List of Account records (not inserted)
     */
    public static List<Account> createAccounts(Integer count, String accountType) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(createAccount('Test Account ' + i, accountType, null));
        }
        return accounts;
    }
    
    /**
     * @description Creates a single Address__c record with realistic Dutch data
     * @param street Street name (optional, generates if null)
     * @return Address__c record (not inserted)
     */
    public static Address__c createAddress(String street) {
        return createAddress(street, null, null, null, null);
    }
    
    /**
     * @description Creates a single Address__c with specified basic fields
     * @param street Street name
     * @param postalCode Postal code
     * @param houseNumber House number
     * @return Address__c record (not inserted)
     */
    public static Address__c createAddress(String street, String postalCode, String houseNumber) {
        return createAddress(street, postalCode, houseNumber, null, null);
    }
    
    /**
     * @description Creates a comprehensive Address__c record with all fields
     * @param street Street name
     * @param postalCode Postal code  
     * @param houseNumber House number
     * @param houseLetter House letter (A, B, C, etc.)
     * @param houseAddition House number addition
     * @return Address__c record (not inserted)
     */
    public static Address__c createAddress(String street, String postalCode, String houseNumber, 
                                         String houseLetter, String houseAddition) {
        
        // Generate realistic defaults if not provided
        String finalStreet = street != null ? street : getRandomStreetName();
        String finalPostalCode = postalCode != null ? postalCode : getRandomPostalCode();
        String finalHouseNumber = houseNumber != null ? houseNumber : String.valueOf(getRandomNumber(1, 999));
        String finalCity = getRandomCity();
        
        // EXPLICITLY USE NL COUNTRY CODE - NOT NETHERLANDS
        return woonstadCreatePersonAddressService.buildAddress(
            finalStreet,
            finalPostalCode, 
            finalHouseNumber,
            houseLetter,
            houseAddition,
            DEFAULT_COUNTRY_CODE, // This should be 'NL'
            finalCity,
            generateBagId()
        );
    }
    
    /**
     * @description Creates a list of Address__c records with varied, realistic data
     * @param count Number of addresses to create
     * @return List of Address__c records (not inserted)
     */
    public static List<Address__c> createAddresses(Integer count) {
        List<Address__c> addresses = new List<Address__c>();
        
        for (Integer i = 0; i < count; i++) {
            // Vary the data for realistic bulk testing
            String street = getRandomStreetName() + ' ' + i;
            String postalCode = getRandomPostalCode();
            String houseNumber = String.valueOf(getRandomNumber(1, 999));
            
            // Add house letters and additions to some records for variety
            String houseLetter = Math.mod(i, 4) == 0 ? String.fromCharArray(new List<Integer>{65 + Math.mod(i, 6)}) : null;
            String houseAddition = Math.mod(i, 7) == 0 ? 'bis' : null;
            
            // DIRECTLY CREATE WITH EXPLICIT NL COUNTRY CODE
            Address__c addr = woonstadCreatePersonAddressService.buildAddress(
                street,
                postalCode, 
                houseNumber,
                houseLetter,
                houseAddition,
                'NL', // HARDCODE NL TO ENSURE IT'S CORRECT
                getRandomCity(),
                generateBagId()
            );
            addresses.add(addr);
        }
        
        return addresses;
    }
    
    /**
     * @description Creates Account_Address__c junction records
     * @param accountIds List of Account IDs
     * @param addressIds List of Address IDs  
     * @param isPrimary Whether the addresses are primary for accounts
     * @return List of Account_Address__c records (not inserted)
     */
    public static List<Account_Address__c> createAccountAddressLinks(List<Id> accountIds, List<Id> addressIds, Boolean isPrimary) {
        List<Account_Address__c> links = new List<Account_Address__c>();
        
        Integer maxSize = Math.min(accountIds.size(), addressIds.size());
        
        for (Integer i = 0; i < maxSize; i++) {
            Account_Address__c link = new Account_Address__c();
            link.Account__c = accountIds[i];
            link.Address__c = addressIds[i];
            link.Is_Primary__c = isPrimary != null ? isPrimary : true;
            link.Type__c = DEFAULT_TYPE_WOO;
            link.Start_Date__c = Date.today().addDays(-getRandomNumber(1, 365));
            
            links.add(link);
        }
        
        return links;
    }
    
    /**
     * @description Creates Contact records with person account relationships
     * @param count Number of contacts to create
     * @param accountIds List of Account IDs to associate (optional)
     * @return List of Contact records (not inserted)
     */
    public static List<Contact> createContacts(Integer count, List<Id> accountIds) {
        List<Contact> contacts = new List<Contact>();
        
        for (Integer i = 0; i < count; i++) {
            Contact con = new Contact();
            con.FirstName = 'Test';
            con.LastName = 'Contact ' + i;
            con.Email = 'test.contact.' + i + '@example.com';
            con.Phone = '+31201234' + String.valueOf(567 + i);
            
            // Associate with account if provided
            if (accountIds != null && !accountIds.isEmpty()) {
                con.AccountId = accountIds[Math.mod(i, accountIds.size())];
            }
            
            contacts.add(con);
        }
        
        return contacts;
    }
    
    /**
     * @description Creates request objects for woonstadCreatePersonWithAdressAction
     * @param count Number of requests to create
     * @return List of request wrapper objects
     */
    public static List<woonstadCreatePersonWithAdressAction.Request> createPersonWithAddressRequests(Integer count) {
        List<woonstadCreatePersonWithAdressAction.Request> requests = new List<woonstadCreatePersonWithAdressAction.Request>();
        
        for (Integer i = 0; i < count; i++) {
            woonstadCreatePersonWithAdressAction.Request req = new woonstadCreatePersonWithAdressAction.Request();
            
            // Person data
            req.firstName = 'Test';
            req.lastName = 'Person ' + i;
            req.email = 'test.person.' + i + '@example.com';
            req.phone = '+31201234' + String.valueOf(567 + i);
            
            // Address data - EXPLICITLY USE NL
            req.street = getRandomStreetName();
            req.postalCode = getRandomPostalCode();
            req.houseNumber = String.valueOf(getRandomNumber(1, 999));
            req.houseLetter = Math.mod(i, 4) == 0 ? String.fromCharArray(new List<Integer>{65 + Math.mod(i, 6)}) : null;
            req.houseNumberAddition = Math.mod(i, 7) == 0 ? 'bis' : null;
            req.country = 'NL'; // HARDCODE NL COUNTRY CODE
            req.city = getRandomCity();
            req.bagId = generateBagId();
            
            // Date handling - provide both formats for testing
            req.startDate = Date.today().addDays(-getRandomNumber(0, 30));
            req.startDateText = req.startDate.format();
            
            requests.add(req);
        }
        
        return requests;
    }
    
    /**
     * @description Creates addresses with known duplicate potential for testing duplicate handling
     * @param baseAddress Template address to create duplicates from
     * @param duplicateCount Number of duplicate addresses to create
     * @return List of Address__c records with duplicate potential (not inserted)
     */
    public static List<Address__c> createDuplicateAddresses(Address__c baseAddress, Integer duplicateCount) {
        List<Address__c> duplicates = new List<Address__c>();
        
        for (Integer i = 0; i < duplicateCount; i++) {
            // ENSURE COUNTRY IS NL NOT NETHERLANDS
            Address__c duplicate = woonstadCreatePersonAddressService.buildAddress(
                baseAddress.Street__c,
                baseAddress.Postal_Code__c,
                baseAddress.House_Number__c,
                baseAddress.House_Letter__c,
                baseAddress.House_Number_Addition__c,
                'NL', // HARDCODE TO NL
                baseAddress.City__c,
                baseAddress.BAG_Id__c
            );
            duplicates.add(duplicate);
        }
        
        return duplicates;
    }
    
    /**
     * @description Creates addresses with invalid data for negative testing
     * @param count Number of invalid addresses to create
     * @return List of Address__c records with validation issues (not inserted)
     */
    public static List<Address__c> createInvalidAddresses(Integer count) {
        List<Address__c> invalidAddresses = new List<Address__c>();
        
        for (Integer i = 0; i < count; i++) {
            Address__c invalid = new Address__c();
            
            // Create different types of invalid data
            switch on Math.mod(i, 4) {
                when 0 {
                    // Too long street name
                    invalid.Street__c = 'A'.repeat(300);
                }
                when 1 {
                    // Invalid postal code format
                    invalid.Postal_Code__c = 'INVALID_FORMAT';
                }
                when 2 {
                    // Missing required fields
                    invalid.Street__c = null;
                    invalid.City__c = null;
                }
                when 3 {
                    // Invalid house number
                    invalid.House_Number__c = 'NOT_A_NUMBER';
                }
            }
            
            invalidAddresses.add(invalid);
        }
        
        return invalidAddresses;
    }
    
    // Private helper methods for realistic data generation
    
    /**
     * @description Generates a random number within range
     * @param min Minimum value (inclusive)
     * @param max Maximum value (inclusive)
     * @return Random integer within range
     */
    private static Integer getRandomNumber(Integer min, Integer max) {
        return min + Math.mod(Math.abs(Crypto.getRandomInteger()), (max - min + 1));
    }
    
    /**
     * @description Generates a random number (simpler version)
     * @return Random integer
     */
    private static Integer getRandomNumber() {
        return Math.mod(Math.abs(Crypto.getRandomInteger()), 10000);
    }
    
    /**
     * @description Gets a random Dutch street name
     * @return Random street name from predefined list
     */
    private static String getRandomStreetName() {
        return DUTCH_STREET_NAMES[Math.mod(Math.abs(Crypto.getRandomInteger()), DUTCH_STREET_NAMES.size())];
    }
    
    /**
     * @description Gets a random Dutch postal code
     * @return Random postal code from predefined patterns
     */
    private static String getRandomPostalCode() {
        String basePattern = DUTCH_POSTAL_PATTERNS[Math.mod(Math.abs(Crypto.getRandomInteger()), DUTCH_POSTAL_PATTERNS.size())];
        // Slightly modify the pattern for uniqueness
        Integer randomNum = getRandomNumber(1000, 9999);
        return String.valueOf(randomNum) + basePattern.substring(4);
    }
    
    /**
     * @description Gets a random Dutch city name
     * @return Random city name from predefined list
     */
    private static String getRandomCity() {
        return DUTCH_CITIES[Math.mod(Math.abs(Crypto.getRandomInteger()), DUTCH_CITIES.size())];
    }
    
    /**
     * @description Generates a realistic BAG ID (Dutch building registry identifier)
     * @return Generated BAG ID string
     */
    private static String generateBagId() {
        return 'BAG' + String.valueOf(getRandomNumber(100000, 999999));
    }
    
    /**
     * @description Creates test data for specific testing scenarios
     * @param scenario Scenario type ('bulk', 'duplicate', 'invalid', 'minimal')
     * @param count Number of records to create
     * @return List of Address__c records for the scenario (not inserted)
     */
    public static List<Address__c> createAddressesForScenario(String scenario, Integer count) {
        switch on scenario?.toLowerCase() {
            when 'bulk' {
                return createAddresses(count);
            }
            when 'duplicate' {
                // ENSURE TEMPLATE USES NL
                Address__c template = woonstadCreatePersonAddressService.buildAddress(
                    'Duplicate Street', '1234AB', '123', null, null, 'NL', 'Amsterdam', null
                );
                return createDuplicateAddresses(template, count);
            }
            when 'invalid' {
                return createInvalidAddresses(count);
            }
            when 'minimal' {
                List<Address__c> minimal = new List<Address__c>();
                for (Integer i = 0; i < count; i++) {
                    // ENSURE MINIMAL ADDRESSES USE NL
                    minimal.add(woonstadCreatePersonAddressService.buildAddress(
                        'Street ' + i, '100' + i + 'AB', String.valueOf(i + 1), 
                        null, null, 'NL', 'Amsterdam', null
                    ));
                }
                return minimal;
            }
            when else {
                return createAddresses(count);
            }
        }
    }
}