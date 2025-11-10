/*************************************************************************************************
 * Class           : woonstadCreateBussAccountFactory
 * Layer           : Service / Factory
 * Purpose         : Build Business Account records from inputs with Account Type field support.
 *
 * Key Changes     : Modified for Business Accounts instead of Person Accounts
 *                   - Uses Business_Account Record Type
 *                   - Maps to business-specific fields (Business_Email__c, etc.)
 *                   - Sets Account_Type__c based on user selection from LWC form
 *                   - Handles Account.Type field from picklist selection
 *                   - FIXED: Enabled VAT_Number__c field mapping
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-29
 * Last Modified   : 2025-09-03
 * 
 * Changelog:
 * 2025-08-29 | DvM | Initial creation for business account factory
 * 2025-09-01 | DvM | Added Account Type parameter support from LWC integration
 * 2025-09-03 | DvM | FIXED: Uncommented and activated VAT_Number__c field mapping
 *************************************************************************************************/
public with sharing class woonstadCreateBussAccountFactory {
    
    /**
     * Default Account Type for business accounts when none specified
     * This maintains backward compatibility and provides a sensible default
     */
    private static final String DEFAULT_BUSINESS_TYPE = 'Business';

    /**
     * Builds a Business Account record with the provided business information including Account Type
     * 
     * @param recordTypeId Record Type ID for Business_Account
     * @param companyName Company/business name (required)
     * @param kvkNumber KVK (Chamber of Commerce) number
     * @param vatNumber VAT (BTW) number - now properly mapped to VAT_Number__c
     * @param phone Primary business phone number
     * @param email Business email address
     * @param mobile Business mobile/secondary phone number
     * @param accountType Account type API value from picklist selection (e.g., 'Customer_Direct', 'Partner', etc.)
     *                    This should be the Value (API name) from the picklist, not the Label
     * 
     * @return Account Business Account record ready for insert with all fields populated
     * 
     * @description This method creates a complete Business Account record with:
     *              - Standard Account fields (Name, RecordTypeId, Type)
     *              - Business-specific custom fields (KVK, VAT, business contact info)
     *              - Account Type from user selection in LWC form
     *              - Proper field mapping following Woonstad data model
     *              - VAT Number correctly mapped to VAT_Number__c custom field
     * 
     * @example
     * Account businessAccount = woonstadCreateBussAccountFactory.buildBusiness(
     *     recordTypeId, 
     *     'Acme Corp', 
     *     '12345678', 
     *     'NL123456789B01',
     *     '+31201234567', 
     *     'contact@acme.com', 
     *     '+31612345678',
     *     'Customer - Direct'
     * );
     */
    public static Account buildBusiness(
        Id recordTypeId,
        String companyName,
        String kvkNumber,
        String vatNumber,
        String phone,
        String email,
        String mobile,
        String accountType
    ) {
        Account a = new Account();
        
        // ===== CORE ACCOUNT FIELDS =====
        a.RecordTypeId = recordTypeId;
        a.Name = companyName;  // Business accounts use Name field for company name
        
        // Account Type: Store the API value in the standard Account.Type field
        a.Type = !String.isBlank(accountType) ? accountType.trim() : null;
        
        // ===== BUSINESS REGISTRATION FIELDS =====
        // These fields store official business registration information
        
        // KVK (Chamber of Commerce) Number mapping
        a.Chamber_Of_Commerce_Number__c = !String.isBlank(kvkNumber) ? kvkNumber.trim() : null;
        
        // FIXED: VAT Number field - now properly enabled and mapped
        // This was previously commented out, causing VAT numbers to not be stored
        a.VAT_Number__c = !String.isBlank(vatNumber) ? vatNumber.trim() : null;
        
        // ===== CONTACT INFORMATION =====
        // Primary business phone (standard Account field)
        a.Phone = !String.isBlank(phone) ? phone.trim() : null;
        
        // Business email mapping
        // Maps to custom field Business_Email__c for business-specific email storage
        if (!String.isBlank(email)) {
            a.Business_Email__c = email.trim();
        }
        
        // Business mobile phone mapping
        // Maps to custom field for secondary/mobile business contact number
        if (!String.isBlank(mobile)) {
            a.Mobile_Business_Phone__c = mobile.trim();
        }
        
        return a;
    }
    
    /**
     * Overloaded method for backward compatibility
     * This version maintains compatibility with existing code that doesn't pass Account Type
     * 
     * @param recordTypeId Record Type ID for Business_Account
     * @param companyName Company/business name (required)
     * @param kvkNumber KVK number
     * @param vatNumber VAT number - will now be properly mapped to VAT_Number__c
     * @param phone Primary phone
     * @param email Business email
     * @param mobile Mobile phone
     * 
     * @return Account Business Account record with default Account Type
     * 
     * @description Creates business account without specifying Account Type.
     *              All field mappings including VAT Number work the same as main method.
     */
    public static Account buildBusiness(
        Id recordTypeId,
        String companyName,
        String kvkNumber,
        String vatNumber,
        String phone,
        String email,
        String mobile
    ) {
        // Call the main method with null Account Type (will use default)
        return buildBusiness(
            recordTypeId,
            companyName,
            kvkNumber,
            vatNumber,
            phone,
            email,
            mobile,
            null  // No account type specified - will use default
        );
    }
    
    /**
     * Validation method to verify all required custom fields exist
     * This helps catch field mapping issues during deployment or testing
     * 
     * @return Map<String, Boolean> Field existence status for each custom field
     * 
     * @description Use this method to validate that all expected custom fields
     *              exist in the target org before deploying the factory class.
     *              Helps prevent runtime errors due to missing custom fields.
     */
    public static Map<String, Boolean> validateCustomFields() {
        Map<String, Boolean> fieldStatus = new Map<String, Boolean>();
        
        try {
            // Get Account object describe information
            Schema.DescribeSObjectResult accountDescribe = Account.SObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = accountDescribe.fields.getMap();
            
            // Check for required custom fields used in this factory
            fieldStatus.put('Chamber_Of_Commerce_Number__c', fieldMap.containsKey('Chamber_Of_Commerce_Number__c'));
            fieldStatus.put('VAT_Number__c', fieldMap.containsKey('VAT_Number__c'));
            fieldStatus.put('Business_Email__c', fieldMap.containsKey('Business_Email__c'));
            fieldStatus.put('Mobile_Business_Phone__c', fieldMap.containsKey('Mobile_Business_Phone__c'));
            
        } catch (Exception e) {
            // If describe fails, mark all as false
            fieldStatus.put('Chamber_Of_Commerce_Number__c', false);
            fieldStatus.put('VAT_Number__c', false);
            fieldStatus.put('Business_Email__c', false);
            fieldStatus.put('Mobile_Business_Phone__c', false);
        }
        
        return fieldStatus;
    }
}