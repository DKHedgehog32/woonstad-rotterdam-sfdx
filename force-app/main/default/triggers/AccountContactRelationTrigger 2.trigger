trigger AccountContactRelationTrigger on AccountContactRelation (before insert) {
    if(Trigger.isInsert) {
        PersonRelationService.fillCompositeKeys(Trigger.new);
    }
}