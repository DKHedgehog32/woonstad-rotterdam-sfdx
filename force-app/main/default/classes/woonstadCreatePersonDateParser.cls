/*************************************************************************************************
 * Class           : woonstadCreatePersonDateParser
 * Layer           : Utility
 * Purpose         : Parse common date strings (yyyy-MM-dd, dd-MM-yyyy, ISO-like, digit-only) to Date.
 *
 * Notes           :
 *  - Safe: returns null on parse failure (never throws).
 *  - Tolerates separators -, /, . and basic ISO timestamps like 1990-08-26T00:00:00Z.
 *  - Trims and upper/lower tolerant for 'T'/'Z'.
 *
 * Owner           : Woonstad KC
 * Author          : Dennis van Musschenbroek
 * Last Modified   : 2025-08-27
 *************************************************************************************************/
public with sharing class woonstadCreatePersonDateParser {

    /**
     * Parse a date string into a Date, or return null if it cannot be parsed.
     * Examples accepted:
     *  - 1990-08-26
     *  - 26-08-1990
     *  - 1990/08/26
     *  - 26/08/1990
     *  - 19900826  (yyyyMMdd)
     *  - 26081990  (ddMMyyyy)
     *  - 1990-08-26T00:00:00Z (ISO-like; time part ignored)
     */
    public static Date parse(String input, String correlationId) {
        if (String.isBlank(input)) return null;
        String s = input.trim();

        // ISO-like with time (e.g., 1990-08-26T00:00:00Z)
        if (s.contains('T') || s.endsWithIgnoreCase('Z') || s.contains(':')) {
            String t = s;
            Integer dot = t.indexOf('.');
            if (dot > 0) t = t.substring(0, dot);
            t = t.replace('T', ' ').replace('t', ' ');
            if (t.endsWithIgnoreCase('Z')) t = t.substring(0, t.length()-1);
            try {
                if (t.contains(' ')) return parseDelims(t.substring(0, t.indexOf(' ')), '-', '/', '.');
                return parseDelims(t, '-', '/', '.');
            } catch (Exception e) {
                logWarn(correlationId, 'ISO-like date parse failed: ' + s);
            }
        }

        // Common delimited formats (yyyy-MM-dd) or (dd-MM-yyyy) with -, /, .
        Date out = parseDelims(s, '-', '/', '.');
        if (out != null) return out;

        // Digit-only formats: yyyyMMdd or ddMMyyyy
        String digits = s.replaceAll('[^0-9]', '');
        if (digits.length() >= 8) {
            try {
                // Try yyyyMMdd first
                String a = digits.substring(0, 4);
                Integer y = Integer.valueOf(a);
                if (y >= 1900 && y <= 2100) {
                    Integer m = Integer.valueOf(digits.substring(4, 6));
                    Integer d = Integer.valueOf(digits.substring(6, 8));
                    return Date.newInstance(y, m, d);
                } else {
                    // Fallback ddMMyyyy
                    Integer d2 = Integer.valueOf(digits.substring(0, 2));
                    Integer m2 = Integer.valueOf(digits.substring(2, 4));
                    Integer y2 = Integer.valueOf(digits.substring(4, 8));
                    return Date.newInstance(y2, m2, d2);
                }
            } catch (Exception e) {
                logWarn(correlationId, 'Digit-only date parse failed: ' + s);
            }
        }

        // Last-chance: swap day/month if it looks like d-m-y with separators
        if (out == null && (s.contains('-') || s.contains('/') || s.contains('.'))) {
            try {
                List<String> parts = s.split('[^0-9]');
                if (parts.size() >= 3) {
                    Integer p0 = Integer.valueOf(parts[0]);
                    Integer p1 = Integer.valueOf(parts[1]);
                    Integer p2 = Integer.valueOf(parts[2]);
                    try { return Date.newInstance(p2, p1, p0); } catch (Exception ignore) {}
                    try { return Date.newInstance(p0, p1, p2); } catch (Exception ignore) {}
                }
            } catch (Exception e) {
                // ignore
            }
        }

        return null;
    }

    // ---- helpers ----
    private static Date parseDelims(String s, String d1, String d2, String d3) {
        if (String.isBlank(s)) return null;
        List<String> parts = s.split('[\\' + d1 + '\\' + d2 + '\\' + d3 + ']');
        if (parts.size() < 3) return null;
        try {
            // yyyy-MM-dd
            if (parts[0].length() == 4) {
                Integer y = Integer.valueOf(parts[0]);
                Integer m = Integer.valueOf(parts[1]);
                Integer d = Integer.valueOf(parts[2]);
                return Date.newInstance(y, m, d);
            }
            // dd-MM-yyyy
            if (parts[2].length() == 4) {
                Integer d = Integer.valueOf(parts[0]);
                Integer m = Integer.valueOf(parts[1]);
                Integer y = Integer.valueOf(parts[2]);
                return Date.newInstance(y, m, d);
            }
        } catch (Exception ignore) {}
        return null;
    }

    private static void logWarn(String cid, String msg) {
        System.debug(LoggingLevel.WARN, 'woonstadCreatePersonDateParser [' + cid + '] ' + msg);
    }
}