/*************************************************************************************************
 * Component       : WoonstadFlowCustDataController
 * Layer           : Apex Controller
 * Purpose         : Controller for Woonstad customer data form picklist values
 *
 * Responsibilities:
 *  - Retrieve Account.Salutation picklist values for LWC consumption
 *  - Follow AWAF.dev best practices for simple, maintainable code
 *  - Provide proper caching and security context
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-09-02
 * Last Modified   : 2025-09-02
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-09-02 | DvM | Initial creation with getSalutationPicklistValues method following AWAF.dev best practices.
 *************************************************************************************************/

/**
 * @description Controller for Woonstad customer data form picklist values
 * @author Dennis van Musschenbroek
 * @since 2025-09-02
 */
public with sharing class WoonstadFlowCustDataController {
    
    /**
     * @description Gets Account.Salutation picklist values for LWC
     * @return List of salutation options with label and value keys
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getSalutationPicklistValues() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        
        try {
            for (Schema.PicklistEntry entry : Account.Salutation.getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
        } catch (Exception e) {
            System.debug('Error getting salutation values: ' + e.getMessage());
            // Return empty list on error - LWC will handle fallback
        }
        
        return options;
    }
}