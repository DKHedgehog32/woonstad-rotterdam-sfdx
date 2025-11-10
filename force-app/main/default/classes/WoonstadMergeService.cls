/*************************************************************************************************
 * Class            : WoonstadMergeService
 * Layer            : Utility
 * Purpose          : Merge template fields with Case/Account/User context.
 *
 * Owner            : Woonstad
 * Author           : Dennis van Musschenbroek
 * Created          : 2025-08-25
 * Last Modified    : 2025-08-25
 * ===============================================================================================
 * Change Log
 * ===============================================================================================
 * 2025-08-25 | DvM | Added safeGet() to prevent SObjectException on unqueried fields.
 *************************************************************************************************/
public with sharing class WoonstadMergeService {

    public class MergeInput {
        public String templateSubject;
        public String templateBodyHtmlOrText;
        public Case caseRecord;
        public Account account;
        public User sender;
    }

    public class MergeOutput {
        public String subjectMerged;
        public String bodyHtmlMerged;
        public String bodyTextMerged;
        public String bodyTextForFile;
    }

    public static MergeOutput render(MergeInput inData) {
        MergeOutput out = new MergeOutput();
        String subj = inData != null ? inData.templateSubject : null;
        String body = inData != null ? inData.templateBodyHtmlOrText : null;

        if (body != null) {
            body = body.replace('{{{Case.Nameplate_Text__c.}}}', '{{{Case.Nameplate_Text__c}}}')
                       .replace('{{Case.Nameplate_Text__c.}}',  '{{Case.Nameplate_Text__c}}');
        }

        Case c = inData != null ? inData.caseRecord : null;
        Account a = inData != null ? inData.account : null;
        User s = inData != null ? inData.sender : null;

        Map<String,String> tokens = new Map<String,String>{
            // Case
            '{{{Case.CaseNumber}}}'         => safe(c != null ? c.CaseNumber : null),
            '{{Case.CaseNumber}}'           => safe(c != null ? c.CaseNumber : null),
            '{{{Case.Subject}}}'            => safe(c != null ? c.Subject : null),
            '{{Case.Subject}}'              => safe(c != null ? c.Subject : null),
            '{{{Case.Description}}}'        => safe(c != null ? c.Description : null),
            '{{Case.Description}}'          => safe(c != null ? c.Description : null),
            '{{{Case.Nameplate_Text__c}}}'  => safe(c != null ? c.Nameplate_Text__c : null),
            '{{Case.Nameplate_Text__c}}'    => safe(c != null ? c.Nameplate_Text__c : null),
            '{{{Case.Account_Address__c}}}' => safe(safeGet(c, 'Account_Address__c')),
            '{{Case.Account_Address__c}}'   => safe(safeGet(c, 'Account_Address__c')),

            // Account
            '{{{Account.Name}}}'               => safe(a != null ? a.Name : null),
            '{{Account.Name}}'                 => safe(a != null ? a.Name : null),
            '{{{Account.PersonEmail}}}'        => safe(a != null ? a.PersonEmail : null),
            '{{Account.PersonEmail}}'          => safe(a != null ? a.PersonEmail : null),
            '{{{Account.Full_Shipping_Street__c}}}'      => safe(a != null ? a.Full_Shipping_Street__c : null),
            '{{Account.Full_Shipping_Street__c}}'        => safe(a != null ? a.Full_Shipping_Street__c : null),
            '{{{Account.Full_Shipping_Postal_Code__c}}}' => safe(a != null ? a.Full_Shipping_Postal_Code__c : null),
            '{{Account.Full_Shipping_Postal_Code__c}}'   => safe(a != null ? a.Full_Shipping_Postal_Code__c : null),
            '{{{Account.Full_Shipping_City__c}}}'        => safe(a != null ? a.Full_Shipping_City__c : null),
            '{{Account.Full_Shipping_City__c}}'          => safe(a != null ? a.Full_Shipping_City__c : null),
            '{{{Account.Full_Shipping_Country__c}}}'     => safe(a != null ? a.Full_Shipping_Country__c : null),
            '{{Account.Full_Shipping_Country__c}}'       => safe(a != null ? a.Full_Shipping_Country__c : null),
            '{{{Account.Label__c}}}'           => safe(a != null ? a.Label__c : null),
            '{{Account.Label__c}}'             => safe(a != null ? a.Label__c : null),

            // Sender
            '{{{Sender.FirstName}}}'          => safe(s != null ? s.FirstName : null),
            '{{Sender.FirstName}}'            => safe(s != null ? s.FirstName : null),
            '{{{Sender.LastName}}}'           => safe(s != null ? s.LastName : null),
            '{{Sender.LastName}}'             => safe(s != null ? s.LastName : null),
            '{{{Sender.Email}}}'              => safe(s != null ? s.Email : null),
            '{{Sender.Email}}'                => safe(s != null ? s.Email : null)
        };

        if (subj != null) for (String k : tokens.keySet()) subj = subj.replace(k, tokens.get(k));
        if (body != null) for (String k : tokens.keySet()) body = body.replace(k, tokens.get(k));

        out.subjectMerged   = subj == null ? '' : subj;
        out.bodyHtmlMerged  = body == null ? '' : body;
        out.bodyTextMerged  = toPlainText(body);
        out.bodyTextForFile = collapseBlankLines(out.bodyTextMerged);
        return out;
    }

    // --- helpers ---
    private static String safe(String v) { return v == null ? '' : v; }

    private static String safeGet(SObject sobj, String fieldApi) {
        if (sobj == null || String.isBlank(fieldApi)) return null;
        try {
            Object val = sobj.get(fieldApi);
            return val == null ? null : String.valueOf(val);
        } catch (SObjectException ex) {
            return null;
        }
    }

    private static String toPlainText(String html) {
        if (String.isBlank(html)) return '';
        String text = html.replaceAll('(?i)<br\\s*/?>', '\n')
                          .replaceAll('(?i)</p\\s*>', '\n')
                          .replaceAll('(?s)<[^>]+>', '');
        return text.trim();
    }

    private static String collapseBlankLines(String txt) {
        return String.isBlank(txt) ? '' : txt.replaceAll('\\n{3,}', '\n\n');
    }
}