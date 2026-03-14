trigger FieldWeightTrigger on Field_Weight__c (after update) {
    TriggerHandler handler = new FieldWeightTriggerHandler();

    switch on Trigger.operationType {
        when AFTER_UPDATE {
            handler.afterUpdate( Trigger.oldMap, Trigger.newMap);
        }
    }
}