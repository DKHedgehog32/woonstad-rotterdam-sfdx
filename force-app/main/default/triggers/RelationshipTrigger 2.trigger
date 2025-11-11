trigger RelationshipTrigger on Relationship__c (before insert) {
    if(Trigger.isInsert) {
        PersonRelationService.fillCompositeKeys(Trigger.new);
    }
}