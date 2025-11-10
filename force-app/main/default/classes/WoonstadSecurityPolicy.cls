/*************************************************************************************************
 * Class           : WoonstadSecurityPolicy
 * Layer           : Utility / Policy
 * Purpose         : Central policy toggles used by WoonstadCrudFlsGuard. Change behavior here
 *                   without modifying the guard or any consumers.
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-25
 * Last Modified   : 2025-08-25
 * ===============================================================================================
 * Change Log
 * -----------------------------------------------------------------------------------------------
 * 2025-08-25 | DvM | Initial creation with simple, future-proof toggles.
 *************************************************************************************************/
public inherited sharing class WoonstadSecurityPolicy {

    // If true, throw when stripInaccessible removes any fields on CREATE.
    public static Boolean blockOnRemovedCreate() { return true; }

    // If true, throw when stripInaccessible removes any fields on UPDATE.
    public static Boolean blockOnRemovedUpdate() { return true; }

    // If true, log (publish fault) when READ strips fields.
    public static Boolean logRemovedOnRead() { return true; }

    // Message for generic FLS block (can be localized later).
    public static String flsBlockedMessage(String op) {
        return 'You do not have field-level access to ' + op + ' this record.';
    }

    // Message for generic CRUD block (can be localized later).
    public static String crudBlockedMessage(String op) {
        return 'You do not have permission to ' + op + ' this record.';
    }
}