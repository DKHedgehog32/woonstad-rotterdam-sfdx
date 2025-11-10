/*************************************************************************************************
 * Apex Class Name  : woonstadCreateBussWithAddressAction
 * Layer            : Application (Invocable for Flow)
 * Purpose          : Create Business Account + Address__c + Account_Address__c via Flow.
 *
 * Responsibilities :
 *  - Business Account creation (Business_Account Record Type) with business fields
 *  - Address__c creation or reuse on duplicate (Unique_Key__c handling via service)
 *  - Account_Address__c link with Start_Date__c (Date preferred; Text fallback parsed)
 *  - Business-specific field mapping (Company name, KVK, VAT, business email/phone, Account Type)
 *
 * Security         : with sharing; CRUD/FLS via WoonstadCrudFlsGuard; faults via ApexFaultHandler.
 * Owner            : Woonstad KC
 * Author           : Dennis van Musschenbroek
 * Created          : 2025-08-29
 * Last Modified    : 2025-09-01
 * 
 * Changelog:
 * 2025-08-29 | DvM | Initial creation for business account with address
 * 2025-09-01 | DvM | Added Account Type field support from LWC form integration
 *************************************************************************************************/
public with sharing class woonstadCreateBussWithAddressAction {

    // ----- DTOs -----
    public class Request {
        @InvocableVariable(label='Business Account RecordType DeveloperName') 
        public String businessAccountRecordTypeDevName;

        // Business Account Information
        @InvocableVariable(label='Account Type' description='Account type API value from picklist selection (stores the Value, not Label)') 
        public String accountType;
        
        @InvocableVariable(label='Company Name' required=true)     
        public String companyName;
        
        @InvocableVariable(label='KVK Number')                     
        public String kvkNumber;
        
        @InvocableVariable(label='VAT Number')                     
        public String vatNumber;
        
        @InvocableVariable(label='Phone')                          
        public String phone;
        
        @InvocableVariable(label='Email Address')                  
        public String email;
        
        @InvocableVariable(label='Mobile Number')                  
        public String mobilePhone;

        // Address__c (same as person version)
        @InvocableVariable(label='Street' required=true)           
        public String street;
        
        @InvocableVariable(label='Postal Code' required=true)      
        public String postalCode;
        
        @InvocableVariable(label='House Number' required=true)     
        public String houseNumber;
        
        @InvocableVariable(label='House Letter')                   
        public String houseLetter;
        
        @InvocableVariable(label='House Number Addition')          
        public String houseNumberAddition;
        
        @InvocableVariable(label='Country' required=true)          
        public String country;
        
        @InvocableVariable(label='City' required=true)             
        public String city;
        
        @InvocableVariable(label='BAG Id')                         
        public String bagId;

        // Link (Account_Address__c)
        @InvocableVariable(label='Start Date')                     
        public Date   startDate;
        
        @InvocableVariable(label='Start Date (Text)')              
        public String startDateText;
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
    @InvocableMethod(label='Create Business + Address + Link' description='Creates Business Account + Address__c + Account_Address__c with Account Type')
    public static List<Response> createBusinesses(List<Request> requests) {
        List<Response> out = new List<Response>();
        if (requests == null || requests.isEmpty()) return out;

        final String cid = 'cid-' + String.valueOf(Crypto.getRandomInteger());
        woonstadCreateBussLog.info(cid, 'Start batch: ' + requests.size());

        // CRUD guards - verify permissions for all required objects
        try {
            WoonstadCrudFlsGuard.requireCreate(Account.SObjectType,                          'woonstadCreateBussWithAddressAction','createBusinesses');
            WoonstadCrudFlsGuard.requireCreate((new Address__c()).getSObjectType(),         'woonstadCreateBussWithAddressAction','createBusinesses');
            WoonstadCrudFlsGuard.requireCreate((new Account_Address__c()).getSObjectType(), 'woonstadCreateBussWithAddressAction','createBusinesses');
        } catch (Exception guardEx) {
            ApexFaultHandler.publishError(guardEx, 'woonstadCreateBussWithAddressAction', 'guardCRUD');
            return denyAll(requests.size(), cid, guardEx.getMessage());
        }

        // Resolve RecordTypes for Business Accounts
        Set<String> devNames = new Set<String>();
        for (Request r : requests) {
            if (!String.isBlank(r.businessAccountRecordTypeDevName)) {
                devNames.add(r.businessAccountRecordTypeDevName.trim());
            }
        }
        Map<String, Id> rtByDev = woonstadCreateBussRecordTypeUtil.resolveAccountByDevName(devNames);
        Id fallbackRt = woonstadCreateBussRecordTypeUtil.resolveFallbackBusinessRtId();

        // Stage Business Accounts and Addresses
        List<Account>    stagedAcc   = new List<Account>();
        List<Address__c> stagedAddr  = new List<Address__c>();
        List<Integer>    accMapIdx   = new List<Integer>();
        List<Integer>    addrMapIdx  = new List<Integer>();

        // Process each request to build Account and Address records
        for (Integer i = 0; i < requests.size(); i++) {
            Request r = requests[i];
            Response res = new Response(); 
            res.correlationId = cid; 
            out.add(res);

            // Resolve Record Type ID
            Id rtId = !String.isBlank(r.businessAccountRecordTypeDevName) ? 
                rtByDev.get(r.businessAccountRecordTypeDevName) : fallbackRt;
            
            if (rtId == null) {
                res.success = false; 
                res.message = 'No suitable Business Account Record Type found.';
                accMapIdx.add(-1); 
                addrMapIdx.add(-1);
                continue;
            }

            // Build Business Account - now includes Account Type parameter
            Account acc = woonstadCreateBussAccountFactory.buildBusiness(
                rtId, 
                r.companyName, 
                r.kvkNumber, 
                r.vatNumber,
                r.phone, 
                r.email, 
                r.mobilePhone,
                r.accountType  // NEW: Pass Account Type from LWC form
            );
            
            // Build Address (reuse existing service - no changes needed)
            Address__c addr = woonstadCreatePersonAddressService.buildAddress(
                r.street, r.postalCode, r.houseNumber, r.houseLetter,
                r.houseNumberAddition, r.country, r.city, r.bagId
            );

            stagedAcc.add(acc);
            stagedAddr.add(addr);
            accMapIdx.add(stagedAcc.size()-1);
            addrMapIdx.add(stagedAddr.size()-1);
        }

        // Insert Business Accounts (FLS sanitize for security)
        try {
            List<SObject> accToSanitize = new List<SObject>();
            for (Account a : stagedAcc) accToSanitize.add(a);

            List<SObject> sanitizedAcc = WoonstadCrudFlsGuard.sanitizeForCreate(
                accToSanitize, 'woonstadCreateBussWithAddressAction', 'insertAccounts', null
            );

            List<Account> safeAccounts = new List<Account>();
            for (SObject s : sanitizedAcc) safeAccounts.add((Account)s);

            if (!safeAccounts.isEmpty()) insert safeAccounts;

            // Copy IDs back to staged accounts for linking
            for (Integer i = 0; i < safeAccounts.size(); i++) {
                stagedAcc[i].Id = safeAccounts[i].Id;
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadCreateBussWithAddressAction', 'insertAccounts');
            markPerItemError(out, accMapIdx, 'Failed to create Business Account: ' + ex.getMessage());
        }

        // Insert Addresses (service handles FLS + duplicates)
        try {
            woonstadCreatePersonAddressService.insertAddressesWithDuplicateReuse(stagedAddr, cid);
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadCreateBussWithAddressAction', 'insertAddresses');
            markPerItemError(out, addrMapIdx, 'Failed to create Address__c: ' + ex.getMessage());
        }

        // Build & Insert Links (cast requests to compatible type)
        try {
            // Convert business requests to format expected by service
            List<woonstadCreatePersonWithAdressAction.Request> compatibleRequests = new List<woonstadCreatePersonWithAdressAction.Request>();
            for (Request busReq : requests) {
                woonstadCreatePersonWithAdressAction.Request compatReq = new woonstadCreatePersonWithAdressAction.Request();
                compatReq.startDate = busReq.startDate;
                compatReq.startDateText = busReq.startDateText;
                compatibleRequests.add(compatReq);
            }
            
            List<Account_Address__c> links = woonstadCreatePersonAddressService.buildLinks(
                stagedAcc, stagedAddr, accMapIdx, addrMapIdx, compatibleRequests, cid
            );

            if (!links.isEmpty()) {
                List<SObject> linkToSanitize = new List<SObject>();
                for (Account_Address__c l : links) linkToSanitize.add(l);

                List<SObject> sanitizedLinks = WoonstadCrudFlsGuard.sanitizeForCreate(
                    linkToSanitize, 'woonstadCreateBussWithAddressAction','insertLinks', null
                );

                List<Account_Address__c> safeLinks = new List<Account_Address__c>();
                for (SObject s : sanitizedLinks) safeLinks.add((Account_Address__c)s);

                if (!safeLinks.isEmpty()) insert safeLinks;

                // Map results back to responses
                Integer li = 0;
                for (Integer i = 0; i < requests.size(); i++) {
                    Integer ai = accMapIdx[i], ad = addrMapIdx[i];
                    Response r = out[i];
                    if (ai < 0 || ad < 0 || stagedAcc[ai].Id == null || stagedAddr[ad].Id == null) continue;
                    
                    r.accountId        = stagedAcc[ai].Id;
                    r.addressId        = stagedAddr[ad].Id;
                    r.accountAddressId = safeLinks.isEmpty() ? null : safeLinks[Math.min(li, safeLinks.size()-1)].Id;
                    r.success = (r.accountId != null);
                    r.message = (r.success ? 'Business Account Created.' : 'Failed.');
                    li++;
                }
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'woonstadCreateBussWithAddressAction', 'insertLinks');
            for (Response r : out) {
                if (r.accountId != null && r.addressId != null && r.accountAddressId == null) {
                    r.success = false;
                    r.message = addMsg(r.message, 'Failed to create Account_Address__c: ' + ex.getMessage());
                }
            }
        }

        // Final logging and cleanup
        Integer ok = 0;
        for (Response r : out) { 
            if (r.success == true) ok++; 
            if (String.isBlank(r.message)) r.message = r.success ? 'Business Account Created.' : 'Failed.'; 
        }
        woonstadCreateBussLog.info(cid, 'End batch. Success: ' + ok + '/' + out.size());
        return out;
    }

    // ----- Helper Methods -----
    
    /**
     * Creates error responses for all requests when CRUD permissions fail
     * @param size Number of requests to create responses for
     * @param cid Correlation ID for logging
     * @param msg Error message to include in all responses
     * @return List of error responses
     */
    private static List<Response> denyAll(Integer size, String cid, String msg) {
        ApexFaultHandler.publishError(msg, 'woonstadCreateBussWithAddressAction', 'denyAll');
        List<Response> out = new List<Response>();
        for (Integer i = 0; i < size; i++) {
            Response r = new Response(); 
            r.success = false; 
            r.message = msg; 
            r.correlationId = cid; 
            out.add(r);
        }
        return out;
    }
    
    /**
     * Marks responses as failed for items that had processing errors
     * @param results List of responses to update
     * @param mapIdx Index mapping for which responses to mark as failed
     * @param message Error message to add to the responses
     */
    private static void markPerItemError(List<Response> results, List<Integer> mapIdx, String message) {
        for (Integer i = 0; i < mapIdx.size(); i++) {
            if (mapIdx[i] >= 0) { 
                results[i].success = false; 
                results[i].message = addMsg(results[i].message, message); 
            }
        }
    }
    
    /**
     * Concatenates two messages with a separator
     * @param a First message (can be null/blank)
     * @param b Second message to append
     * @return Combined message string
     */
    private static String addMsg(String a, String b) { 
        return String.isBlank(a) ? b : a + ' | ' + b; 
    }
}