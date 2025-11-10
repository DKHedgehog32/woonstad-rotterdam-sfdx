/**
 * Class to create keys for various purposes
 *
 * AccountContactRelation
Relationship__c
Account_Address__c
Contract_Line__c
Cluster_Role__c
Contract_Contact_Role__c
 */
public class IdentifierService {
    public static String getUUID() {
        UUID randomUUID = UUID.randomUUID();
        System.Debug('#### Generated UUID '+randomUUID.toString());
        return randomUUID.toString();
    }

    //
    // Converts data to a string usable in key
    public static String getDateStamp(Date dateInput) {
        String output;
        if(dateInput == null) {
            output = '';
        } else {
            //
            // Only datetime has a useful format() function
            DateTime temp = DateTime.newInstance(dateInput, Time.newInstance(0,0,0,0));
            output = String.valueOf(temp.format('yyyyMMdd'));
        }
        return output;
    }
}