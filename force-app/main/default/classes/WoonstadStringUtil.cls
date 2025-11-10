/*************************************************************************************************
 * Class            : WoonstadStringUtil
 * Layer            : Utility
 * Purpose          : Small string helpers used across services.
 *************************************************************************************************/
public with sharing class WoonstadStringUtil {
    public static String concatName(String first, String last) {
        String a = String.isBlank(first) ? '' : first.trim();
        String b = String.isBlank(last)  ? '' : last.trim();
        return (a + ' ' + b).trim();
    }
}