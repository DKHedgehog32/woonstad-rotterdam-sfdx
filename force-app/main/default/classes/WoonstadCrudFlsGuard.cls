/*************************************************************************************************
 * Class           : WoonstadCrudFlsGuard
 * Layer           : Utility / Security
 * Purpose         : General CRUD + FLS enforcement for all current and future Apex code.
 *
 * Responsibilities:
 *  - CRUD gates: requireCreate/Read/Update/Delete
 *  - FLS enforcement via Security.stripInaccessible for Create/Update/Read
 *  - Fault publishing via ApexFaultHandler on violations
 *  - Stable API with policy-driven behavior (no need to edit this class later)
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-25
 * Last Modified   : 2025-08-25
 * ===============================================================================================
 * Change Log
 * -----------------------------------------------------------------------------------------------
 * 2025-08-25 | DvM | Fixed for orgs without SObjectAccessDecision.getRemovedFields(SObjectType).
 *************************************************************************************************/
public inherited sharing class WoonstadCrudFlsGuard {

    // ======= CRUD REQUIREMENTS ================================================================

    public static void requireCreate(Schema.SObjectType typeToken, String cls, String fn) {
        if (!typeToken.getDescribe().isCreateable()) {
            ApexFaultHandler.publishError('CRUD denied: CREATE on ' + typeToken, cls, fn);
            throw new AuraHandledException(WoonstadSecurityPolicy.crudBlockedMessage('create'));
        }
    }

    public static void requireRead(Schema.SObjectType typeToken, String cls, String fn) {
        if (!typeToken.getDescribe().isAccessible()) {
            ApexFaultHandler.publishError('CRUD denied: READ on ' + typeToken, cls, fn);
            throw new AuraHandledException(WoonstadSecurityPolicy.crudBlockedMessage('view'));
        }
    }

    public static void requireUpdate(Schema.SObjectType typeToken, String cls, String fn) {
        if (!typeToken.getDescribe().isUpdateable()) {
            ApexFaultHandler.publishError('CRUD denied: UPDATE on ' + typeToken, cls, fn);
            throw new AuraHandledException(WoonstadSecurityPolicy.crudBlockedMessage('update'));
        }
    }

    public static void requireDelete(Schema.SObjectType typeToken, String cls, String fn) {
        if (!typeToken.getDescribe().isDeletable()) {
            ApexFaultHandler.publishError('CRUD denied: DELETE on ' + typeToken, cls, fn);
            throw new AuraHandledException(WoonstadSecurityPolicy.crudBlockedMessage('delete'));
        }
    }

    // ======= FLS ENFORCEMENT (CREATE) =========================================================

    public static SObject sanitizeForCreate(SObject record, String cls, String fn, Id contextId) {
        return sanitizeForCreate(record, cls, fn, contextId, WoonstadSecurityPolicy.blockOnRemovedCreate());
    }

    public static List<SObject> sanitizeForCreate(List<SObject> records, String cls, String fn, Id contextId) {
        return sanitizeForCreate(records, cls, fn, contextId, WoonstadSecurityPolicy.blockOnRemovedCreate());
    }

    public static SObject sanitizeForCreate(
        SObject record, String cls, String fn, Id contextId, Boolean blockOnRemoved
    ) {
        List<SObject> sanitized = sanitizeForCreate(new List<SObject>{ record }, cls, fn, contextId, blockOnRemoved);
        return sanitized.isEmpty() ? null : sanitized[0];
    }

    public static List<SObject> sanitizeForCreate(
        List<SObject> records, String cls, String fn, Id contextId, Boolean blockOnRemoved
    ) {
        if (records == null || records.isEmpty()) return new List<SObject>();
        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.CREATABLE, records);
        handleRemovedFields(dec, cls, fn, contextId, blockOnRemoved, 'create');
        return dec.getRecords();
    }

    // ======= FLS ENFORCEMENT (UPDATE) =========================================================

    public static SObject sanitizeForUpdate(SObject record, String cls, String fn, Id contextId) {
        return sanitizeForUpdate(record, cls, fn, contextId, WoonstadSecurityPolicy.blockOnRemovedUpdate());
    }

    public static List<SObject> sanitizeForUpdate(List<SObject> records, String cls, String fn, Id contextId) {
        return sanitizeForUpdate(records, cls, fn, contextId, WoonstadSecurityPolicy.blockOnRemovedUpdate());
    }

    public static SObject sanitizeForUpdate(
        SObject record, String cls, String fn, Id contextId, Boolean blockOnRemoved
    ) {
        List<SObject> sanitized = sanitizeForUpdate(new List<SObject>{ record }, cls, fn, contextId, blockOnRemoved);
        return sanitized.isEmpty() ? null : sanitized[0];
    }

    public static List<SObject> sanitizeForUpdate(
        List<SObject> records, String cls, String fn, Id contextId, Boolean blockOnRemoved
    ) {
        if (records == null || records.isEmpty()) return new List<SObject>();
        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.UPDATABLE, records);
        handleRemovedFields(dec, cls, fn, contextId, blockOnRemoved, 'update');
        return dec.getRecords();
    }

    // ======= FLS ENFORCEMENT (READ) ===========================================================

    public static List<SObject> sanitizeForRead(List<SObject> records, String cls, String fn, Id contextId) {
        if (records == null || records.isEmpty()) return new List<SObject>();
        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, records);

        if (WoonstadSecurityPolicy.logRemovedOnRead()) {
            Set<String> removed = removedFields(dec);
            if (!removed.isEmpty()) {
                ApexFaultHandler.publishError(
                    'FLS removed fields (read): ' + String.join(new List<String>(removed), ','),
                    cls, fn
                );
            }
        }
        return dec.getRecords();
    }

    // ======= INTERNAL ==========================================================================

    private static void handleRemovedFields(
        SObjectAccessDecision dec,
        String cls,
        String fn,
        Id contextId,
        Boolean blockOnRemoved,
        String op // "create" | "update"
    ) {
        Set<String> removed = removedFields(dec);
        if (!removed.isEmpty()) {
            ApexFaultHandler.publishError(
                'FLS removed fields (' + op + '): ' + String.join(new List<String>(removed), ','),
                cls, fn
            );
            if (blockOnRemoved == true) {
                throw new AuraHandledException(WoonstadSecurityPolicy.flsBlockedMessage(op));
            }
        }
    }

    /**
     * Flattens SObjectAccessDecision.getRemovedFields() (Map<String, Set<String>>) into a Set<String>.
     * Works on all API versions that expose only the map-shaped method.
     */
    private static Set<String> removedFields(SObjectAccessDecision dec) {
        Set<String> removed = new Set<String>();
        Map<String, Set<String>> byObject = dec != null ? dec.getRemovedFields() : null;
        if (byObject != null) {
            for (Set<String> s : byObject.values()) {
                if (s != null) removed.addAll(s);
            }
        }
        return removed;
    }
}