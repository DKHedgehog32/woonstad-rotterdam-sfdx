/*************************************************************************************************
 * Class           : woonstadCreatePersonAddressService
 * Layer           : Service
 * Purpose         : Address__c creation, duplicate reuse, and Account_Address__c link creation.
 * Security        : with sharing; CRUD/FLS via WoonstadCrudFlsGuard; faults via ApexFaultHandler.
 * Owner           : Woonstad KC
 * Last Modified   : 2025-08-27
 *************************************************************************************************/
public with sharing class woonstadCreatePersonAddressService {
    private static final String LINK_TYPE_WOO = 'WOO';

    public static Boolean canCreateAddress() {
        return (new Address__c()).getSObjectType().getDescribe().isCreateable();
    }
    public static Boolean canCreateAccountAddress() {
        return (new Account_Address__c()).getSObjectType().getDescribe().isCreateable();
    }

    public static Address__c buildAddress(
        String street, String postalCode, String houseNumber, String houseLetter,
        String houseNumberAddition, String country, String city, String bagId
    ) {
        Address__c a = new Address__c();
        a.Street__c                = street;
        a.Postal_Code__c           = postalCode;
        a.House_Number__c          = houseNumber;
        a.House_Letter__c          = houseLetter;
        a.House_Number_Addition__c = houseNumberAddition;
        a.Country__c               = country;
        a.City__c                  = city;
        a.BAG_Id__c                = bagId;
        a.Address_Line_1__c        = composeLine1(street, houseNumber, houseLetter, houseNumberAddition);
        return a;
    }

    /** Inserts addresses with FLS via Guard; reuses existing on DUPLICATE_VALUE; throws if unrecoverable. */
    public static void insertAddressesWithDuplicateReuse(List<Address__c> staged, String cid) {
        if (staged == null || staged.isEmpty()) return;
        try {
            List<SObject> toSanitize = new List<SObject>();
            for (Address__c a : staged) toSanitize.add(a);

            List<SObject> sanitized = WoonstadCrudFlsGuard.sanitizeForCreate(
                toSanitize, 'woonstadCreatePersonAddressService','insertAddressesWithDuplicateReuse', null
            );

            List<Address__c> safe = new List<Address__c>();
            for (SObject s : sanitized) safe.add((Address__c)s);

            if (!safe.isEmpty()) {
                insert safe;
                for (Integer i = 0; i < safe.size(); i++) staged[i].Id = safe[i].Id;
            }
        } catch (DmlException ex) {
            ApexFaultHandler.publishError(ex, 'woonstadCreatePersonAddressService', 'insertAddressesWithDuplicateReuse');

            for (Integer i = 0; i < ex.getNumDml(); i++) {
                System.StatusCode code = System.StatusCode.valueOf(String.valueOf(ex.getDmlStatusCode(i)));
                if (code == System.StatusCode.DUPLICATE_VALUE) {
                    String dupId = extractIdFromDuplicateMessage(ex.getDmlMessage(i));
                    if (dupId != null) {
                        try {
                            Address__c existing = [SELECT Id FROM Address__c WHERE Id = :dupId LIMIT 1];
                            Integer failingIndex = ex.getDmlIndex(i);
                            if (failingIndex != null && failingIndex >= 0 && failingIndex < staged.size()) {
                                staged[failingIndex].Id = existing.Id;
                            }
                        } catch (Exception fetchEx) {
                            ApexFaultHandler.publishError(fetchEx, 'woonstadCreatePersonAddressService', 'fetchDuplicateAddress');
                        }
                    }
                }
            }
            for (Address__c a : staged) if (a.Id == null) throw ex;
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadCreatePersonAddressService', 'insertAddressesWithDuplicateReuse:outer');
            throw ex;
        }
    }

    public static List<Account_Address__c> buildLinks(
        List<Account> accounts,
        List<Address__c> addresses,
        List<Integer> accIdx,
        List<Integer> addrIdx,
        List<woonstadCreatePersonWithAdressAction.Request> reqs,
        String cid
    ) {
        List<Account_Address__c> out = new List<Account_Address__c>();
        for (Integer i = 0; i < reqs.size(); i++) {
            Integer ai = accIdx[i], ad = addrIdx[i];
            if (ai < 0 || ad < 0 || accounts[ai].Id == null || addresses[ad].Id == null) {
                ApexFaultHandler.publishError('Missing Account/Address Id for link at index ' + i, 'woonstadCreatePersonAddressService', 'buildLinks');
                continue;
            }
            Account_Address__c link = new Account_Address__c();
            link.Account__c    = accounts[ai].Id;
            link.Address__c    = addresses[ad].Id;
            link.Is_Primary__c = true;

            // Start Date: prefer Date; fallback to parsed Text
            Date parsedStart = reqs[i].startDate;
            if (parsedStart == null && !String.isBlank(reqs[i].startDateText)) {
                parsedStart = woonstadCreatePersonDateParser.parse(reqs[i].startDateText, cid);
            }
            link.Start_Date__c = parsedStart;
            link.Type__c       = LINK_TYPE_WOO;

            out.add(link);
        }
        return out;
    }

    // ---- private helpers ----
    private static String composeLine1(String street, String houseNo, String letter, String addition) {
        List<String> parts = new List<String>();
        if (!String.isBlank(street))  parts.add(street.trim());
        if (!String.isBlank(houseNo)) parts.add(houseNo.trim());
        String tail = '';
        if (!String.isBlank(letter))   tail += letter.trim();
        if (!String.isBlank(addition)) tail += addition.trim();
        if (!String.isBlank(tail))     parts.add(tail);
        return String.join(parts, ' ');
    }
    private static String extractIdFromDuplicateMessage(String msg) {
        if (String.isBlank(msg)) return null;
        String lower = msg.toLowerCase();
        String needle = 'record with id:';
        Integer p = lower.indexOf(needle);
        if (p < 0) return null;
        String tail = msg.substring(p + needle.length()).trim();
        for (String token : tail.split('[ ,.;]')) {
            if (!String.isBlank(token) && token.length() >= 15) return token;
        }
        return null;
    }
}