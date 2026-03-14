/*
  File Name: OpportunityTriggerHandler
  Author: Kimberly Small
  Last Revised: September 13, 2019
*/

public class OpportunityTriggerHandler {
    /*
      This class syncs the Expected Monthly Trickle from the Opportunity Object
      with the Monthly Forum Allocation field from the related Opportunity Line Item 
    */ 
    
    // Boolean used to prevent the trigger from running recursively
    public static Boolean isFirstRun = TRUE;
    
    public static void syncTrickleWithOli(Map<Id, Opportunity> oppMap) {
        Set<Id> oppIds = oppMap.keySet();
        
        List<OpportunityLineItem> oliList = [SELECT Id, Trickle__c, OpportunityId, Product2.Sub_Family__c
                                             FROM OpportunityLineItem
                                             WHERE OpportunityId IN :oppIds];
        
        System.debug('Test');
        // Get Connections & Forum Record Type ID
        Map<String, Schema.RecordTypeInfo> oppRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        List<Id> opptyRecordTypeList = new List<Id>();
        opptyRecordTypeList.add(oppRecordTypes.get('Connections & Forum').getRecordTypeId());
        opptyRecordTypeList.add(oppRecordTypes.get('CX & FM Renewal').getRecordTypeId());
        
        List<OpportunityLineItem> oliToUpdate = new List<OpportunityLineItem>();
        System.debug('Test 2');
        System.debug(oliList);
        if(!oliList.isEmpty()) {
            for (OpportunityLineItem oli : oliList) {
                Opportunity opp = oppMap.get(oli.OpportunityId);
                if (opptyRecordTypeList.contains(opp.RecordTypeId) && oli.Product2.Sub_Family__c == 'Package') {
                    System.debug(opp.Planned_Trickle__c);
                    oli.Trickle__c = opp.Planned_Trickle__c;
                	oliToUpdate.add(oli);
                    System.debug(oliToUpdate);
                }
        	}
        }
        
        if(!oliToUpdate.isEmpty() && isFirstRun) {
            isFirstRun = FALSE;
            update oliToUpdate;
            isFirstRun = TRUE;
        }
    }
}