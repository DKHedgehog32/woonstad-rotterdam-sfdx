/*************************************************************************************************
 * Class            : WoonstadEmailTemplateResolver
 * Layer            : Service
 * Purpose          : Look up EmailTemplate Ids with CRUD/FLS guard + sanitizeForRead.
 *
 * Owner            : Woonstad
 * Author           : Dennis van Musschenbroek
 * Created          : 2025-08-25
 * Last Modified    : 2025-10-07
 * ===============================================================================================
 * Description:
 * This service class provides methods to resolve EmailTemplate records in a secure way,
 * enforcing CRUD/FLS permissions. It offers two resolution strategies:
 * 1. resolveByDevNameContains - Finds templates using a LIKE clause (partial match)
 * 2. resolveByExactDevName - Finds templates using exact DeveloperName match (NEW)
 * 
 * All queries use WoonstadCrudFlsGuard to ensure proper security enforcement and
 * field-level security stripping.
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-10-07 | Modified | Added resolveByExactDevName method for exact template matching
 *                        | This supports conditional template selection based on Account Label
 * 2025-08-25 | DvM      | Switched to requireRead + sanitizeForRead.
 *************************************************************************************************/
public with sharing class WoonstadEmailTemplateResolver {
    
    /**
     * @description Resolves an EmailTemplate by partial DeveloperName match using LIKE clause.
     *              Returns the most recently modified template matching the search pattern.
     * @param contains String to search for within the DeveloperName (case-sensitive)
     * @return Id of the matching EmailTemplate, or null if not found
     * @example Id templateId = resolveByDevNameContains('Naamplaatje');
     */
    public static Id resolveByDevNameContains(String contains) {
        if (String.isBlank(contains)) return null;
        String likeToken = '%' + contains + '%';

        // Enforce read permission on EmailTemplate object
        WoonstadCrudFlsGuard.requireRead(EmailTemplate.SObjectType, 'WoonstadEmailTemplateResolver', 'resolveByDevNameContains');

        // Query for templates matching the pattern, return most recent
        List<EmailTemplate> ets = [
            SELECT Id, DeveloperName, LastModifiedDate
            FROM EmailTemplate
            WHERE DeveloperName LIKE :likeToken
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        if (ets.isEmpty()) return null;

        // Strip inaccessible fields based on user's FLS
        List<SObject> filtered = WoonstadCrudFlsGuard.sanitizeForRead(
            (List<SObject>)ets, 'WoonstadEmailTemplateResolver', 'resolveByDevNameContains', null
        );
        return ((EmailTemplate)filtered[0]).Id;
    }

    /**
     * @description Resolves an EmailTemplate by exact DeveloperName match.
     *              This method is used when we need to select a specific template variant
     *              based on business logic (e.g., Account Label__c field).
     * @param developerName Exact DeveloperName of the EmailTemplate to find
     * @return Id of the matching EmailTemplate, or null if not found
     * @example Id templateId = resolveByExactDevName('Naamplaatje_Bevestigingsmail_naar_klant_Woonstad');
     */
    public static Id resolveByExactDevName(String developerName) {
        // Validate input parameter
        if (String.isBlank(developerName)) {
            System.debug(LoggingLevel.WARN, 'resolveByExactDevName called with blank developerName');
            return null;
        }

        // Enforce read permission on EmailTemplate object
        WoonstadCrudFlsGuard.requireRead(
            EmailTemplate.SObjectType, 
            'WoonstadEmailTemplateResolver', 
            'resolveByExactDevName'
        );

        // Query for template with exact DeveloperName match
        List<EmailTemplate> templates = [
            SELECT Id, DeveloperName, Name, LastModifiedDate
            FROM EmailTemplate
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];

        // Handle no results found
        if (templates.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'No EmailTemplate found with DeveloperName: ' + developerName);
            return null;
        }

        // Strip inaccessible fields based on user's FLS permissions
        List<SObject> filtered = WoonstadCrudFlsGuard.sanitizeForRead(
            (List<SObject>)templates, 
            'WoonstadEmailTemplateResolver', 
            'resolveByExactDevName', 
            null
        );

        // Return the Id of the found template
        return ((EmailTemplate)filtered[0]).Id;
    }
}