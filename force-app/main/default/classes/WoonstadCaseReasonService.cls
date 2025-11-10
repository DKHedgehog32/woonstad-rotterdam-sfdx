/*************************************************************************************************
 * Class            : WoonstadCaseReasonService
 * Layer            : Service / Utility
 * Purpose          : Normalize Flow/LWC input (label or value) to Case_Reason__c picklist value.
 *
 * Owner            : Woonstad
 * Author           : Dennis van Musschenbroek
 * Created          : 2025-08-25
 * Last Modified    : 2025-08-25
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-08-25 | DvM | Extract mapping to its own unit for reuse & tests.
 *************************************************************************************************/
public with sharing class WoonstadCaseReasonService {
    private static final Map<String,String> LABEL_TO_VALUE = new Map<String,String>{
        'Vernield / gestolen'        => 'Vandalism/stolen',
        'Nieuwe woning'              => 'New Tenant',
        'Veranderde Samenstelling'   => 'New composition of residency',
        'Verkeerde Spelling'         => 'Incorrect name spelling'
    };

    public static String normalize(String input) {
        if (String.isBlank(input)) return null;
        return LABEL_TO_VALUE.containsKey(input) ? LABEL_TO_VALUE.get(input) : input;
    }
}