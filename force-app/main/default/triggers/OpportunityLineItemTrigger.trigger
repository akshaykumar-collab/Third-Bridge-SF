trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert) {
    if (OpportunityLineItemTriggerHandler.isTriggerFire) {
        OpportunityLineItemTriggerHandler.syncQLIsToNewOLIs(Trigger.new);
    }
}