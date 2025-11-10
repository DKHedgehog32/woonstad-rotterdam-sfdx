/*************************************************************************************************
 * Class           : woonstadCreateBussLog
 * Layer           : Utility / Logging
 * Purpose         : Lightweight logging wrappers with consistent prefix for business account creation.
 *
 * Key Changes     : Updated context prefix for business account operations
 *                   - Changed context from person to business account creation
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Created         : 2025-08-29
 * Last Modified   : 2025-08-29
 *************************************************************************************************/
public with sharing class woonstadCreateBussLog {
    private static final String CTX = 'woonstadCreateBussWithAddressAction';
    
    /**
     * Logs an informational message with correlation ID
     * @param cid Correlation ID for tracking
     * @param msg Message to log
     */
    public static void info(String cid, String msg) { 
        System.debug(LoggingLevel.INFO, CTX + ' [' + cid + '] ' + msg); 
    }
    
    /**
     * Logs a warning message with correlation ID
     * @param cid Correlation ID for tracking
     * @param msg Message to log
     */
    public static void warn(String cid, String msg) { 
        System.debug(LoggingLevel.WARN, CTX + ' [' + cid + '] ' + msg); 
    }
    
    /**
     * Logs an error message with correlation ID
     * @param cid Correlation ID for tracking
     * @param msg Message to log
     */
    public static void error(String cid, String msg) { 
        System.debug(LoggingLevel.ERROR, CTX + ' [' + cid + '] ' + msg); 
    }
}