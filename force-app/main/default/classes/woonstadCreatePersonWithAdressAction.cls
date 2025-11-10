/*************************************************************************************************
 * Apex Class Name  : woonstadCreatePersonWithAdressAction
 * Layer            : Application (Invocable for Flow)
 * Purpose          : Create Person Account (Tenant) + Address__c + Account_Address__c via Flow.
 *
 * Responsibilities :
 *  - Person Account creation (Tenant) incl. PersonEmail & PersonMobilePhone
 *  - Address__c creation or reuse on duplicate (Unique_Key__c handling via service)
 *  - Account_Address__c link with Start_Date__c (Date preferred; Text fallback parsed)
 *  - Birthdate: Date preferred; Text fallback parsed
 *
 * Security         : with sharing; CRUD/FLS via WoonstadCrudFlsGuard; faults via ApexFaultHandler.
 * Owner            : Woonstad KC
 * Author           : Dennis van Musschenbroek
 * Last Modified    : 2025-08-27
 *************************************************************************************************/
public with sharing class woonstadCreatePersonWithAdressAction {

    // ----- DTOs -----
    public class Request {
        @InvocableVariable(label='Person Account RecordType DeveloperName') public String personAccountRecordTypeDevName;

        // Person Account
        @InvocableVariable(label='First Name' required=true)   public String firstName;
        @InvocableVariable(label='Middle Name')                public String middleName;
        @InvocableVariable(label='Last Name' required=true)    public String lastName;

        // Birthdate (Date preferred; Text fallback)
        @InvocableVariable(label='Birthdate (Date)')           public Date   personBirthdate;
        @InvocableVariable(label='Birthdate (Text)')           public String personBirthdateText;

        @InvocableVariable(label='Phone')                      public String phone;
        @InvocableVariable(label='Email Address')              public String email;
        @InvocableVariable(label='Mobile Number')              public String mobilePhone;

        // Address__c
        @InvocableVariable(label='Street' required=true)       public String street;
        @InvocableVariable(label='Postal Code' required=true)  public String postalCode;
        @InvocableVariable(label='House Number' required=true) public String houseNumber;
        @InvocableVariable(label='House Letter')               public String houseLetter;
        @InvocableVariable(label='House Number Addition')      public String houseNumberAddition;
        @InvocableVariable(label='Country' required=true)      public String country;
        @InvocableVariable(label='City' required=true)         public String city;
        @InvocableVariable(label='BAG Id')                     public String bagId;

        // Link (Account_Address__c)
        @InvocableVariable(label='Start Date')                 public Date   startDate;
        @InvocableVariable(label='Start Date (Text)')          public String startDateText;
    }

    public class Response {
        @InvocableVariable(label='Account Id')         public Id accountId;
        @InvocableVariable(label='Address Id')         public Id addressId;
        @InvocableVariable(label='Account_Address Id') public Id accountAddressId;
        @InvocableVariable(label='Success')            public Boolean success;
        @InvocableVariable(label='Message')            public String message;
        @InvocableVariable(label='Correlation Id')     public String correlationId;
    }

    // ----- Entry Point -----
    @InvocableMethod(label='Create Person + Address + Link' description='Creates Tenant Person Account + Address__c + Account_Address__c')
    public static List<Response> createPersons(List<Request> requests) {
        List<Response> out = new List<Response>();
        if (requests == null || requests.isEmpty()) return out;

        final String cid = 'cid-' + String.valueOf(Crypto.getRandomInteger());
        woonstadCreatePersonLog.info(cid, 'Start batch: ' + requests.size());

        // CRUD guards
        try {
            WoonstadCrudFlsGuard.requireCreate(Account.SObjectType,                          'woonstadCreatePersonWithAdressAction','createPersons');
            WoonstadCrudFlsGuard.requireCreate((new Address__c()).getSObjectType(),         'woonstadCreatePersonWithAdressAction','createPersons');
            WoonstadCrudFlsGuard.requireCreate((new Account_Address__c()).getSObjectType(), 'woonstadCreatePersonWithAdressAction','createPersons');
        } catch (Exception guardEx) {
            ApexFaultHandler.publishError(guardEx, 'woonstadCreatePersonWithAdressAction', 'guardCRUD');
            return denyAll(requests.size(), cid, guardEx.getMessage());
        }

        // Resolve RecordTypes
        Set<String> devNames = new Set<String>();
        for (Request r : requests) if (!String.isBlank(r.personAccountRecordTypeDevName)) devNames.add(r.personAccountRecordTypeDevName.trim());
        Map<String, Id> rtByDev = woonstadCreatePersonRecordTypeUtil.resolveAccountByDevName(devNames);
        Id fallbackRt = woonstadCreatePersonRecordTypeUtil.resolveFallbackPersonRtId();

        // Stage
        List<Account>    stagedAcc   = new List<Account>();
        List<Address__c> stagedAddr  = new List<Address__c>();
        List<Integer>    accMapIdx   = new List<Integer>();
        List<Integer>    addrMapIdx  = new List<Integer>();

        Boolean canWriteBirthdate = Account.PersonBirthdate.getDescribe().isCreateable();

        for (Integer i = 0; i < requests.size(); i++) {
            Request r = requests[i];
            Response res = new Response(); res.correlationId = cid; out.add(res);

            Id rtId = !String.isBlank(r.personAccountRecordTypeDevName) ? rtByDev.get(r.personAccountRecordTypeDevName) : fallbackRt;
            if (rtId == null) {
                res.success = false; res.message = 'No suitable Person Account Record Type found.';
                accMapIdx.add(-1); addrMapIdx.add(-1);
                continue;
            }

            Date bd = (r.personBirthdate != null) ? r.personBirthdate : woonstadCreatePersonDateParser.parse(r.personBirthdateText, cid);

            Account acc = woonstadCreatePersonAccountFactory.buildTenant(
                rtId, r.firstName, r.middleName, r.lastName,
                canWriteBirthdate ? bd : null,
                r.phone, r.email, r.mobilePhone
            );
            Address__c addr = woonstadCreatePersonAddressService.buildAddress(
                r.street, r.postalCode, r.houseNumber, r.houseLetter,
                r.houseNumberAddition, r.country, r.city, r.bagId
            );

            stagedAcc.add(acc);
            stagedAddr.add(addr);
            accMapIdx.add(stagedAcc.size()-1);
            addrMapIdx.add(stagedAddr.size()-1);
        }

        if (!canWriteBirthdate) {
            for (Response r : out) r.message = addMsg(r.message, 'Note: PersonBirthdate not writeable (FLS).');
        }

        // Insert Accounts (FLS sanitize)
        try {
            List<SObject> accToSanitize = new List<SObject>();
            for (Account a : stagedAcc) accToSanitize.add(a);

            List<SObject> sanitizedAcc = WoonstadCrudFlsGuard.sanitizeForCreate(
                accToSanitize, 'woonstadCreatePersonWithAdressAction', 'insertAccounts', null
            );

            List<Account> safeAccounts = new List<Account>();
            for (SObject s : sanitizedAcc) safeAccounts.add((Account)s);

            if (!safeAccounts.isEmpty()) insert safeAccounts;

            for (Integer i = 0; i < safeAccounts.size(); i++) stagedAcc[i].Id = safeAccounts[i].Id;
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadCreatePersonWithAdressAction', 'insertAccounts');
            markPerItemError(out, accMapIdx, 'Failed to create Account: ' + ex.getMessage());
        }

        // Insert Addresses (service handles FLS + duplicates)
        try {
            woonstadCreatePersonAddressService.insertAddressesWithDuplicateReuse(stagedAddr, cid);
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadCreatePersonWithAdressAction', 'insertAddresses');
            markPerItemError(out, addrMapIdx, 'Failed to create Address__c: ' + ex.getMessage());
        }

        // Build & Insert Links
        try {
            List<Account_Address__c> links = woonstadCreatePersonAddressService.buildLinks(
                stagedAcc, stagedAddr, accMapIdx, addrMapIdx, requests, cid
            );

            if (!links.isEmpty()) {
                List<SObject> linkToSanitize = new List<SObject>();
                for (Account_Address__c l : links) linkToSanitize.add(l);

                List<SObject> sanitizedLinks = WoonstadCrudFlsGuard.sanitizeForCreate(
                    linkToSanitize, 'woonstadCreatePersonWithAdressAction','insertLinks', null
                );

                List<Account_Address__c> safeLinks = new List<Account_Address__c>();
                for (SObject s : sanitizedLinks) safeLinks.add((Account_Address__c)s);

                if (!safeLinks.isEmpty()) insert safeLinks;

                Integer li = 0;
                for (Integer i = 0; i < requests.size(); i++) {
                    Integer ai = accMapIdx[i], ad = addrMapIdx[i];
                    Response r = out[i];
                    if (ai < 0 || ad < 0 || stagedAcc[ai].Id == null || stagedAddr[ad].Id == null) continue;
                    r.accountId        = stagedAcc[ai].Id;
                    r.addressId        = stagedAddr[ad].Id;
                    r.accountAddressId = safeLinks.isEmpty() ? null : safeLinks[Math.min(li, safeLinks.size()-1)].Id;
                    r.success = (r.accountId != null);
                    r.message = (r.success ? 'Created.' : 'Failed.');
                    li++;
                }
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadCreatePersonWithAdressAction', 'insertLinks');
            for (Response r : out) {
                if (r.accountId != null && r.addressId != null && r.accountAddressId == null) {
                    r.success = false;
                    r.message = addMsg(r.message, 'Failed to create Account_Address__c: ' + ex.getMessage());
                }
            }
        }

        Integer ok = 0;
        for (Response r : out) { if (r.success == true) ok++; if (String.isBlank(r.message)) r.message = r.success ? 'Created.' : 'Failed.'; }
        woonstadCreatePersonLog.info(cid, 'End batch. Success: ' + ok + '/' + out.size());
        return out;
    }

    // ----- helpers -----
    private static List<Response> denyAll(Integer size, String cid, String msg) {
        ApexFaultHandler.publishError(msg, 'woonstadCreatePersonWithAdressAction', 'denyAll');
        List<Response> out = new List<Response>();
        for (Integer i = 0; i < size; i++) {
            Response r = new Response(); r.success = false; r.message = msg; r.correlationId = cid; out.add(r);
        }
        return out;
    }
    private static void markPerItemError(List<Response> results, List<Integer> mapIdx, String message) {
        for (Integer i = 0; i < mapIdx.size(); i++) if (mapIdx[i] >= 0) { results[i].success = false; results[i].message = addMsg(results[i].message, message); }
    }
    private static String addMsg(String a, String b) { return String.isBlank(a) ? b : a + ' | ' + b; }
}