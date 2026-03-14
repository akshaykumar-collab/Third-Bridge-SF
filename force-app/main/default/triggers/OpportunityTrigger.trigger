/*
  File Name: OpportunityTriggerHandler
  Author: Kimberly Small
  Last Revised: September 13, 2019
*/

trigger OpportunityTrigger on Opportunity (after update) {
    if(OpportunityTriggerHandler.isFirstRun) {
        OpportunityTriggerHandler.syncTrickleWithOli(Trigger.newMap);
    }
}