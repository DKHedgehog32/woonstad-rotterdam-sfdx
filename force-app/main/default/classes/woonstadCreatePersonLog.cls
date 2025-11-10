/*************************************************************************************************
 * Class           : woonstadCreatePersonLog
 * Layer           : Utility / Logging
 * Purpose         : Lightweight logging wrappers with a consistent prefix.
 * Owner           : Woonstad KC
 * Last Modified   : 2025-08-27
 *************************************************************************************************/
public with sharing class woonstadCreatePersonLog {
    private static final String CTX = 'woonstadCreatePersonWithAdressAction';
    public static void info(String cid, String msg) { System.debug(LoggingLevel.INFO,  CTX + ' [' + cid + '] ' + msg); }
    public static void warn(String cid, String msg) { System.debug(LoggingLevel.WARN,  CTX + ' [' + cid + '] ' + msg); }
    public static void error(String cid, String msg){ System.debug(LoggingLevel.ERROR, CTX + ' [' + cid + '] ' + msg); }
}