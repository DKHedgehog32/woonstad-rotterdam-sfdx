public with sharing class EmailActionSelector implements QuickAction.QuickActionDefaultsHandler {

    public void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
        //
        // Index the relevant entries by case id
        Map<Id, QuickAction.SendEmailQuickActionDefaults> defaultsMap = new Map<Id, QuickAction.SendEmailQuickActionDefaults>();
        for (QuickAction.QuickActionDefaults defaultObj : defaults) {
            // Check if this is an Email Action
            if (defaultObj instanceof QuickAction.SendEmailQuickActionDefaults) {
                QuickAction.SendEmailQuickActionDefaults emailDefaults = (QuickAction.SendEmailQuickActionDefaults) defaultObj;

                Id caseId = emailDefaults.getContextId();
                if (caseId != null && caseId.getSObjectType() == Case.SObjectType) {
                    defaultsMap.put(caseId, emailDefaults);
                }
            }
        }
        //
        // Get Case info
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, Default_Email_Template__c FROM Case WHERE Id IN :defaultsMap.keySet()]);
        //
        // Construct the Email templates query
        Set<String> emailTemplateDevNames = new Set<String>();
        for(Case c : caseMap.values()) {
            emailTemplateDevNames.add(c.Default_Email_Template__c);
        }
        //
        // Get Email template info in map indexed by developername
        Map<String, EmailTemplate> tplMap = new Map<String, EmailTemplate>();
        for(EmailTemplate tpl : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :emailTemplateDevNames]) {
            tplMap.put(tpl.DeveloperName, tpl);
        }

        //
        // Enrich the defaults
        for(Id caseId : defaultsMap.keySet()) {
            if (caseMap.containsKey(caseId)) {
                Case c = caseMap.get(caseId);
                if (tplMap.containsKey(c.Default_Email_Template__c)) {
                    System.debug('## Setting email template to '+c.Default_Email_Template__c);
                    defaultsMap.get(caseId).setTemplateId(tplMap.get(c.Default_Email_Template__c).Id);
                }
            }
        }
    }
}