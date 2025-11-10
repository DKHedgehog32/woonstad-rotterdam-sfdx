/*************************************************************************************************
 * Class           : woonstadCreatePersonAccountFactory
 * Layer           : Service / Factory
 * Purpose         : Build Person Account (Tenant) records from inputs.
 * Owner           : Woonstad KC
 * Last Modified   : 2025-08-27
 *************************************************************************************************/
public with sharing class woonstadCreatePersonAccountFactory {
    private static final String TENANT = 'Tenant';

    public static Account buildTenant(
        Id recordTypeId,
        String firstName,
        String middleName,
        String lastName,
        Date personBirthdate, // may be null (FLS or missing)
        String phone,
        String email,
        String mobile
    ) {
        Account a = new Account();
        a.RecordTypeId      = recordTypeId;
        a.Account_Type__c   = TENANT;
        a.FirstName         = firstName;
        a.MiddleName        = middleName;
        a.LastName          = lastName;
        if (personBirthdate != null) a.PersonBirthdate = personBirthdate;
        a.Phone             = phone;
        a.PersonEmail       = email;
        a.PersonMobilePhone = mobile;
        return a;
    }
}