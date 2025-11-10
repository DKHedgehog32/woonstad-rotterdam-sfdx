/*************************************************************************************************
 * Class            : WoonstadFlowTimeUtil
 * Layer            : Utility
 * Purpose          : Parse flowStartTime → elapsed minutes (rounded down). Safe on bad input.
 *************************************************************************************************/
public with sharing class WoonstadFlowTimeUtil {
    public static Integer tryParseMinutesSince(String flowStartTime) {
        if (String.isBlank(flowStartTime)) return 0;
        try {
            Datetime startTime = Datetime.valueOf(flowStartTime);
            Long diffMillis = Datetime.now().getTime() - startTime.getTime();
            return Integer.valueOf(Math.floor((Decimal)diffMillis / (1000 * 60)));
        } catch (Exception ignore) {
            System.debug(LoggingLevel.WARN, 'Could not parse flowStartTime: ' + flowStartTime);
            return 0;
        }
    }
}