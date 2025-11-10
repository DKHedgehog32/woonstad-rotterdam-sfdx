/**
 * ============================================================
 * WoonstadDuplicateSearchController
 * ============================================================
 * Date: 2025-08-12
 * Last Changed: 2025-08-12
 * Description:
 *  Duplicate finder for Accounts (Person Accounts supported).
 *  - Treats input fields SEPARATELY (no combinations/AND):
 *      • Email: exact match on PersonEmail
 *      • Phone: digits-only equality on Phone
 *      • Mobile: digits-only equality on PersonMobilePhone
 *  - Returns the UNION of all matches with per-field match flags.
 *  - Enriches results with masked IBAN (last 4) and primary active Address.
 *
 * Notes (awaf.dev-aligned):
 *  - Read-only, cacheable @AuraEnabled.
 *  - with sharing to respect org visibility.
 *  - Defensive null checks and minimized SOQL scope.
 * ============================================================
 */
public with sharing class WoonstadDuplicateSearchController {

    // -----------------------------
    // DTOs
    // -----------------------------
    public class DuplicateSearchResponse {
        @AuraEnabled public List<AccountRow> results;
        @AuraEnabled public Boolean anyMatchFound;
        @AuraEnabled public String message;
    }

    public class AccountRow {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public Date PersonBirthdate;
        @AuraEnabled public String Phone;
        @AuraEnabled public String PersonMobilePhone;
        @AuraEnabled public String MaskedIban;
        @AuraEnabled public String AddressName;
        @AuraEnabled public String PostalCode;

        // Per-field flags to indicate WHICH input(s) matched
        @AuraEnabled public Boolean matchedEmail;
        @AuraEnabled public Boolean matchedPhone;
        @AuraEnabled public Boolean matchedMobile;
    }

    // -----------------------------
    // Entry point (kept name for LWC compatibility)
    // -----------------------------
    @AuraEnabled(cacheable=true)
    public static DuplicateSearchResponse searchByEmailPhone(
        String email,
        String phone,
        String mobile
    ) {
        DuplicateSearchResponse resp = new DuplicateSearchResponse();
        resp.results = new List<AccountRow>();
        resp.anyMatchFound = false;
        resp.message = '';

        // Normalize inputs for robust comparison
        final String phoneDigits  = normalizeDigits(phone);
        final String mobileDigits = normalizeDigits(mobile);
        final Boolean hasEmail    = !String.isBlank(email);
        final Boolean hasPhone    = !String.isBlank(phoneDigits);
        final Boolean hasMobile   = !String.isBlank(mobileDigits);

        if (!hasEmail && !hasPhone && !hasMobile) {
            resp.message = 'Geen zoekcriteria opgegeven.';
            return resp;
        }

        // Collect matches (union) with per-field flags
        Map<Id, AccountRow> idToRow = new Map<Id, AccountRow>();

        // 1) Email exact match
        if (hasEmail) {
            for (Account a : [
                SELECT Id, Name, PersonBirthdate, Phone, PersonMobilePhone
                FROM Account
                WHERE PersonEmail = :email
                ORDER BY LastModifiedDate DESC
                LIMIT 200
            ]) {
                upsertRowWithFlags(idToRow, a, true, false, false);
            }
        }

        // 2) Phone digits-only equality (candidate narrowing by last4 LIKE)
        if (hasPhone) {
            List<Account> phoneCandidates;
            String last4 = phoneDigits.length() >= 4 ? phoneDigits.substring(phoneDigits.length() - 4) : phoneDigits;

            if (!String.isBlank(last4)) {
                String likeToken = '%' + last4 + '%';
                phoneCandidates = [
                    SELECT Id, Name, PersonBirthdate, Phone, PersonMobilePhone
                    FROM Account
                    WHERE Phone LIKE :likeToken
                    ORDER BY LastModifiedDate DESC
                    LIMIT 500
                ];
            } else {
                phoneCandidates = [
                    SELECT Id, Name, PersonBirthdate, Phone, PersonMobilePhone
                    FROM Account
                    WHERE Phone != null
                    ORDER BY LastModifiedDate DESC
                    LIMIT 500
                ];
            }

            for (Account a : phoneCandidates) {
                if (normalizeDigits(a.Phone) == phoneDigits) {
                    upsertRowWithFlags(idToRow, a, false, true, false);
                }
            }
        }

        // 3) Mobile digits-only equality (candidate narrowing by last4 LIKE)
        if (hasMobile) {
            List<Account> mobileCandidates;
            String last4m = mobileDigits.length() >= 4 ? mobileDigits.substring(mobileDigits.length() - 4) : mobileDigits;

            if (!String.isBlank(last4m)) {
                String likeTokenM = '%' + last4m + '%';
                mobileCandidates = [
                    SELECT Id, Name, PersonBirthdate, Phone, PersonMobilePhone
                    FROM Account
                    WHERE PersonMobilePhone LIKE :likeTokenM
                    ORDER BY LastModifiedDate DESC
                    LIMIT 500
                ];
            } else {
                mobileCandidates = [
                    SELECT Id, Name, PersonBirthdate, Phone, PersonMobilePhone
                    FROM Account
                    WHERE PersonMobilePhone != null
                    ORDER BY LastModifiedDate DESC
                    LIMIT 500
                ];
            }

            for (Account a : mobileCandidates) {
                if (normalizeDigits(a.PersonMobilePhone) == mobileDigits) {
                    upsertRowWithFlags(idToRow, a, false, false, true);
                }
            }
        }

        if (idToRow.isEmpty()) {
            resp.message = 'Geen duplicaten gevonden u gaat automatisch door naar het volgende scherm';
            return resp;
        }

        // -----------------------------
        // Enrichment: IBAN mask & primary active Address
        // -----------------------------
        Set<Id> accountIds = new Set<Id>(idToRow.keySet());

        Map<Id, String> accToMaskedIban = new Map<Id, String>();
        for (Bank_Account__c ba : [
            SELECT Account__c, IBAN__c
            FROM Bank_Account__c
            WHERE Account__c IN :accountIds
        ]) {
            if (String.isNotBlank(ba.IBAN__c) && ba.IBAN__c.length() >= 4) {
                accToMaskedIban.put(ba.Account__c, '*' + ba.IBAN__c.right(4));
            }
        }

        Map<Id, Id> accToAddressId = new Map<Id, Id>();
        for (Account_Address__c aa : [
            SELECT Account__c, Address__c
            FROM Account_Address__c
            WHERE Account__c IN :accountIds
            AND Is_Primary__c = true
            AND Active__c = true
        ]) {
            accToAddressId.put(aa.Account__c, aa.Address__c);
        }

        Map<Id, Address__c> addressMap = accToAddressId.isEmpty()
            ? new Map<Id, Address__c>()
            : new Map<Id, Address__c>([
                SELECT Id, Name, Postal_Code__c
                FROM Address__c
                WHERE Id IN :accToAddressId.values()
            ]);

        // Apply enrichments
        for (Id accId : idToRow.keySet()) {
            AccountRow row = idToRow.get(accId);
            row.MaskedIban = accToMaskedIban.get(accId);

            Id addrId = accToAddressId.get(accId);
            if (addrId != null) {
                Address__c addr = addressMap.get(addrId);
                if (addr != null) {
                    row.AddressName = addr.Name;
                    row.PostalCode = addr.Postal_Code__c;
                }
            }
        }

        // Build response
        resp.results = new List<AccountRow>(idToRow.values());
        resp.results.sort(new AccountRowComparator()); // custom sort (email > phone > mobile > name)
        resp.anyMatchFound = true;
        resp.message = 'Er zijn mogelijke duplicaten gevonden.';
        return resp;
    }

    // -----------------------------
    // Helpers
    // -----------------------------
    private static String normalizeDigits(String input) {
        if (String.isBlank(input)) return '';
        return input.replaceAll('[^0-9]', '');
    }

    private static void upsertRowWithFlags(
        Map<Id, AccountRow> idToRow,
        Account a,
        Boolean mEmail,
        Boolean mPhone,
        Boolean mMobile
    ) {
        AccountRow row = idToRow.containsKey(a.Id) ? idToRow.get(a.Id) : new AccountRow();
        if (row.Id == null) {
            row.Id = a.Id;
            row.Name = a.Name;
            row.PersonBirthdate = a.PersonBirthdate;
            row.Phone = a.Phone;
            row.PersonMobilePhone = a.PersonMobilePhone;
            row.matchedEmail = false;
            row.matchedPhone = false;
            row.matchedMobile = false;
        }
        // OR the flags for multi-criteria hits
        row.matchedEmail  = row.matchedEmail  || mEmail;
        row.matchedPhone  = row.matchedPhone  || mPhone;
        row.matchedMobile = row.matchedMobile || mMobile;

        idToRow.put(a.Id, row);
    }

    // -----------------------------
    // Sorting: email > phone > mobile > name (A–Z)
    // -----------------------------
    private class AccountRowComparator implements System.Comparator<AccountRow> {
        public Integer compare(AccountRow a, AccountRow b) {
            Integer aScore = (a.matchedEmail ? 4 : 0) + (a.matchedPhone ? 2 : 0) + (a.matchedMobile ? 1 : 0);
            Integer bScore = (b.matchedEmail ? 4 : 0) + (b.matchedPhone ? 2 : 0) + (b.matchedMobile ? 1 : 0);

            // Higher score first (negative => a before b)
            if (aScore != bScore) {
                return bScore - aScore;
            }

            // Tie-breaker: name A–Z, case-insensitive
            String aName = a.Name == null ? '' : a.Name.toLowerCase();
            String bName = b.Name == null ? '' : b.Name.toLowerCase();
            return aName.compareTo(bName);
        }
    }
}