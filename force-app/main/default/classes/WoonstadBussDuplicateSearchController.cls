/**
 * ============================================================
 * WoonstadBussDuplicateSearchController
 * ============================================================
 * Date: 2025-08-29
 * Last Changed: 2025-08-29
 * Description:
 *  Business duplicate finder for Business Accounts only.
 *  - Searches separately on each field when provided:
 *      • Company Name: contains match on Name field
 *      • KVK Number: exact match on Chamber_Of_Commerce_Number__c
 *      • Phone: digits-only equality on Phone
 *      • Email: exact match on Business_Email__c
 *  - Returns the UNION of all matches with per-field match flags.
 *  - Only searches Business Accounts (not Person Accounts).
 *  - Skips searches when inputs are null/empty.
 *
 * Notes (awaf.dev-aligned):
 *  - Read-only, cacheable @AuraEnabled.
 *  - with sharing to respect org visibility.
 *  - Defensive null checks and minimized SOQL scope.
 * ============================================================
 */
public with sharing class WoonstadBussDuplicateSearchController {

    // -----------------------------
    // DTOs (Data Transfer Objects)
    // -----------------------------
    public class BusinessDuplicateSearchResponse {
        @AuraEnabled public List<BusinessAccountRow> results;
        @AuraEnabled public Boolean anyMatchFound;
        @AuraEnabled public String message;
    }

    public class BusinessAccountRow {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String KvkNumber;
        @AuraEnabled public String VatNumber;
        @AuraEnabled public String Phone;
        @AuraEnabled public String MobilePhone;
        @AuraEnabled public String Email;
        @AuraEnabled public String AddressName;
        @AuraEnabled public String PostalCode;

        // Per-field flags to indicate WHICH input(s) matched
        @AuraEnabled public Boolean matchedCompanyName;
        @AuraEnabled public Boolean matchedKvkNumber;
        @AuraEnabled public Boolean matchedVatNumber;
        @AuraEnabled public Boolean matchedEmail;
        @AuraEnabled public Boolean matchedPhone;
        @AuraEnabled public Boolean matchedMobile;
    }

    // -----------------------------
    // Entry point for business duplicate search
    // -----------------------------
    @AuraEnabled(cacheable=true)
    public static BusinessDuplicateSearchResponse searchBusinessDuplicates(
        String companyName,
        String kvkNumber,
        String vatNumber,
        String email,
        String phone,
        String mobile
    ) {
        BusinessDuplicateSearchResponse resp = new BusinessDuplicateSearchResponse();
        resp.results = new List<BusinessAccountRow>();
        resp.anyMatchFound = false;
        resp.message = '';

        // Normalize inputs for robust comparison
        final String phoneDigits = normalizeDigits(phone);
        final String mobileDigits = normalizeDigits(mobile);
        final String normalizedCompanyName = String.isBlank(companyName) ? '' : companyName.trim();
        final String normalizedKvk = String.isBlank(kvkNumber) ? '' : kvkNumber.trim();
        final String normalizedVat = String.isBlank(vatNumber) ? '' : vatNumber.trim();
        final String normalizedEmail = String.isBlank(email) ? '' : email.trim().toLowerCase();
        
        final Boolean hasCompanyName = !String.isBlank(normalizedCompanyName);
        final Boolean hasKvkNumber = !String.isBlank(normalizedKvk);
        final Boolean hasVatNumber = !String.isBlank(normalizedVat);
        final Boolean hasEmail = !String.isBlank(normalizedEmail);
        final Boolean hasPhone = !String.isBlank(phoneDigits);
        final Boolean hasMobile = !String.isBlank(mobileDigits);

        // Check if any search criteria provided
        if (!hasCompanyName && !hasKvkNumber && !hasVatNumber && !hasEmail && !hasPhone && !hasMobile) {
            resp.message = 'Geen zoekcriteria voor bedrijf opgegeven.';
            return resp;
        }

        // Collect matches (union) with per-field flags
        Map<Id, BusinessAccountRow> idToRow = new Map<Id, BusinessAccountRow>();

        // Define base fields to query for all searches
        String baseFields = 'Id, Name, Phone, Chamber_Of_Commerce_Number__c, Business_Email__c';
        
        try {
            // 1) Company Name contains match on Account.Name (Business Accounts only)
            if (hasCompanyName) {
                String companyNamePattern = '%' + String.escapeSingleQuotes(normalizedCompanyName) + '%';
                for (Account a : Database.query(
                    'SELECT ' + baseFields + ' FROM Account ' +
                    'WHERE IsPersonAccount = false AND Name LIKE :companyNamePattern ' +
                    'ORDER BY LastModifiedDate DESC LIMIT 200'
                )) {
                    upsertBusinessRowWithFlags(idToRow, a, true, false, false, false, false, false);
                }
            }

            // 2) KVK Number exact match on Chamber_Of_Commerce_Number__c (Business Accounts only)
            if (hasKvkNumber) {
                for (Account a : Database.query(
                    'SELECT ' + baseFields + ' FROM Account ' +
                    'WHERE IsPersonAccount = false AND Chamber_Of_Commerce_Number__c = :normalizedKvk ' +
                    'ORDER BY LastModifiedDate DESC LIMIT 200'
                )) {
                    upsertBusinessRowWithFlags(idToRow, a, false, true, false, false, false, false);
                }
            }

            // 3) Phone digits-only equality on Account.Phone (Business Accounts only)
            if (hasPhone) {
                List<Account> phoneCandidates;
                String last4 = phoneDigits.length() >= 4 ? phoneDigits.substring(phoneDigits.length() - 4) : phoneDigits;

                if (!String.isBlank(last4)) {
                    String likeToken = '%' + last4 + '%';
                    phoneCandidates = Database.query(
                        'SELECT ' + baseFields + ' FROM Account ' +
                        'WHERE IsPersonAccount = false AND Phone LIKE :likeToken ' +
                        'ORDER BY LastModifiedDate DESC LIMIT 500'
                    );
                } else {
                    phoneCandidates = Database.query(
                        'SELECT ' + baseFields + ' FROM Account ' +
                        'WHERE IsPersonAccount = false AND Phone != null ' +
                        'ORDER BY LastModifiedDate DESC LIMIT 500'
                    );
                }

                for (Account a : phoneCandidates) {
                    if (normalizeDigits(a.Phone) == phoneDigits) {
                        upsertBusinessRowWithFlags(idToRow, a, false, false, false, false, true, false);
                    }
                }
            }

            // 4) Business Email exact match on Business_Email__c (Business Accounts only)
            if (hasEmail) {
                for (Account a : Database.query(
                    'SELECT ' + baseFields + ' FROM Account ' +
                    'WHERE IsPersonAccount = false AND Business_Email__c = :normalizedEmail ' +
                    'ORDER BY LastModifiedDate DESC LIMIT 200'
                )) {
                    upsertBusinessRowWithFlags(idToRow, a, false, false, false, true, false, false);
                }
            }

        } catch (Exception e) {
            System.debug('Error in business duplicate search: ' + e.getMessage());
            resp.message = 'Er is een fout opgetreden bij het zoeken naar bedrijfsduplicaten.';
            return resp;
        }

        if (idToRow.isEmpty()) {
            resp.message = 'Geen bedrijfsduplicaten gevonden u gaat automatisch door naar het volgende scherm';
            return resp;
        }

        // -----------------------------
        // Enrichment: Primary active Address for businesses
        // -----------------------------
        Set<Id> accountIds = new Set<Id>(idToRow.keySet());

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

        // Apply address enrichments to business rows
        for (Id accId : idToRow.keySet()) {
            BusinessAccountRow row = idToRow.get(accId);
            
            Id addrId = accToAddressId.get(accId);
            if (addrId != null) {
                Address__c addr = addressMap.get(addrId);
                if (addr != null) {
                    row.AddressName = addr.Name;
                    row.PostalCode = addr.Postal_Code__c;
                }
            }
        }

        // Build response with sorted results
        resp.results = new List<BusinessAccountRow>(idToRow.values());
        resp.results.sort(new BusinessAccountRowComparator());
        resp.anyMatchFound = true;
        resp.message = 'Er zijn mogelijke bedrijfsduplicaten gevonden.';
        return resp;
    }

    // -----------------------------
    // Helper Methods
    // -----------------------------
    
    /**
     * Normalizes phone numbers by removing all non-digit characters
     * @param input Raw phone number string
     * @return String containing only digits
     */
    private static String normalizeDigits(String input) {
        if (String.isBlank(input)) return '';
        return input.replaceAll('[^0-9]', '');
    }

    /**
     * Creates or updates a business account row with match flags
     * @param idToRow Map of account ID to business row
     * @param a Account record
     * @param mCompany Matched on company name
     * @param mKvk Matched on KVK number
     * @param mVat Matched on VAT number  
     * @param mEmail Matched on email
     * @param mPhone Matched on phone
     * @param mMobile Matched on mobile
     */
    private static void upsertBusinessRowWithFlags(
        Map<Id, BusinessAccountRow> idToRow,
        Account a,
        Boolean mCompany,
        Boolean mKvk,
        Boolean mVat,
        Boolean mEmail,
        Boolean mPhone,
        Boolean mMobile
    ) {
        BusinessAccountRow row = idToRow.containsKey(a.Id) ? idToRow.get(a.Id) : new BusinessAccountRow();
        
        if (row.Id == null) {
            // Initialize new row with account data using correct field mappings
            row.Id = a.Id;
            row.Name = a.Name;                                    // Company name -> Account.Name
            row.KvkNumber = a.Chamber_Of_Commerce_Number__c;      // KVK -> Chamber_Of_Commerce_Number__c  
            row.VatNumber = null; // VAT not being searched, set to null
            row.Phone = a.Phone;                                  // Phone -> Account.Phone
            row.MobilePhone = null; // Mobile not being searched, set to null
            row.Email = a.Business_Email__c;                      // Email -> Business_Email__c
            
            row.matchedCompanyName = false;
            row.matchedKvkNumber = false;
            row.matchedVatNumber = false;
            row.matchedEmail = false;
            row.matchedPhone = false;
            row.matchedMobile = false;
        }
        
        // OR the flags for multi-criteria hits
        row.matchedCompanyName = row.matchedCompanyName || mCompany;
        row.matchedKvkNumber = row.matchedKvkNumber || mKvk;
        row.matchedVatNumber = row.matchedVatNumber || mVat;
        row.matchedEmail = row.matchedEmail || mEmail;
        row.matchedPhone = row.matchedPhone || mPhone;
        row.matchedMobile = row.matchedMobile || mMobile;

        idToRow.put(a.Id, row);
    }

    // -----------------------------
    // Sorting: company > kvk > email > phone > name (A–Z)
    // -----------------------------
    private class BusinessAccountRowComparator implements System.Comparator<BusinessAccountRow> {
        public Integer compare(BusinessAccountRow a, BusinessAccountRow b) {
            // Calculate match score based on business criteria priority
            Integer aScore = 
                (a.matchedCompanyName ? 16 : 0) + 
                (a.matchedKvkNumber ? 8 : 0) + 
                (a.matchedEmail ? 4 : 0) + 
                (a.matchedPhone ? 2 : 0);
                
            Integer bScore = 
                (b.matchedCompanyName ? 16 : 0) + 
                (b.matchedKvkNumber ? 8 : 0) + 
                (b.matchedEmail ? 4 : 0) + 
                (b.matchedPhone ? 2 : 0);

            // Higher score first (negative => a before b)
            if (aScore != bScore) {
                return bScore - aScore;
            }

            // Tie-breaker: company name A–Z, case-insensitive
            String aName = a.Name == null ? '' : a.Name.toLowerCase();
            String bName = b.Name == null ? '' : b.Name.toLowerCase();
            return aName.compareTo(bName);
        }
    }
}