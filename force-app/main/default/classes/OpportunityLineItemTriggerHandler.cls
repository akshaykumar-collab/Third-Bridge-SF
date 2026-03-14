/*
  File Name: OpportunityLineItemTriggerHandler
  Author: Kimberly Small
  Last Revised: October 11, 2019
  Description: This trigger handler takes in a list of Opportunity Line Items (OLIs) and 
  maps them to their respective Quote Line Items (QLIs). From there, the custom field 
  values on the QLI records are updated with the corresponding custom field values from 
  the OLI records.
*/ 

public class OpportunityLineItemTriggerHandler {    
    // Define boolean to prevent the QLI Trigger and OLI trigger from running at the same time
    // Use if the QLI Trigger is Active
    public static Boolean isTriggerFire = TRUE;
    
    public static void syncQLIsToNewOLIs(List<OpportunityLineItem> oliList) {
        
        System.debug('Trigger fired');
        
        // Define a new Set to hold the Oppty IDs
        Set<Id> opptyIds = new Set<Id>();
        
        // Get the Oppty IDs for each OLI
        for (OpportunityLineItem oli : oliList) {
            Id relatedOpptyId = oli.OpportunityId;
            if (relatedOpptyId != null) {
                opptyIds.add(relatedOpptyId);
            }            
        }
        
        // Get Opptys
        List<Opportunity> relatedOpptys = [SELECT Id, RecordTypeId, (SELECT Id FROM Quotes), (SELECT Id FROM OpportunityLineItems)
                                     FROM Opportunity
                                     WHERE Id IN :opptyIds];
        
        // Define a new Set to hold the Quote IDs
        Set<Id> quoteIds = new Set<Id>();
        
        // Get the  IDs for each OLI
        for (Opportunity oppty : relatedOpptys) {
            for(Quote q : oppty.Quotes) {
                if (q.Id != null) {
                	quoteIds.add(Q.Id);
            	}  
            }          
        }
        
        // Get a list of the respective QLIs
        List<QuoteLineItem> respectiveQLIs = [SELECT Id, Trickle__c , Unit_Price_PAYG__c, OpportunityLineItemId, QuoteId 
                                              FROM QuoteLineItem
                                              WHERE QuoteId IN :quoteIds];
        System.debug(respectiveQLIs);
        
        // Define a new Map to hold the Opportunity OLI pairs
        Map<Id, Opportunity> oliOpptyMap = new Map<Id, Opportunity>();
        
        // Map Opptys to OLIs
        for (Opportunity oppty : relatedOpptys) {
            for(OpportunityLineItem oli : oppty.OpportunityLineItems) {
                if (oli.Id != null) {
                	oliOpptyMap.put(oli.Id,oppty);
            	}  
            }          
        }
        System.debug(oliOpptyMap);
        // Define a new list to hold the new OLIs that will need to be updates
        List<OpportunityLineItem> oliToUpdate = new List<OpportunityLineItem>();
        
        // Get Connections & Forum Record Type ID
        Map<String, Schema.RecordTypeInfo> oppRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        List<Id> opptyRecordTypeList = new List<Id>();
        opptyRecordTypeList.add(oppRecordTypes.get('Connections & Forum').getRecordTypeId());
        opptyRecordTypeList.add(oppRecordTypes.get('CX & FM Renewal').getRecordTypeId());
                
        // Add OLIs to our list so we can update the custom field values
        for(QuoteLineItem qli : respectiveQLIs) {
            if(qli.OpportunityLineItemId != NULL) {
                OpportunityLineItem newOli = new OpportunityLineItem(Id = qli.OpportunityLineItemId);
                Opportunity relatedOppty = oliOpptyMap.get(newOli.Id);
                if(opptyRecordTypeList.contains(relatedOppty.RecordTypeId)) {
                    newOli.Trickle__c = qli.Trickle__c;
                    System.debug(newOli.Trickle__c);
                }
                if (qli.Unit_Price_PAYG__c != null){
                   newOli.PAYG_Sales_Price__c = qli.Unit_Price_PAYG__c; 
                }
                oliToUpdate.add(newOli);
            }
        }
    
        // Update the OLIs
        if(!oliToUpdate.isEmpty()) {
            System.debug('olis to update: ' + oliToUpdate);
            isTriggerFire = FALSE;
            update oliToUpdate;
            isTriggerFire = TRUE;
        }
    }
    
    public static void syncOpptyToNewOLIs(List<OpportunityLineItem> oliList) {
        
        System.debug('syncOpptyToNewOLIs: Trigger fired');
        
        // Define a new Set to hold the Oppty IDs
        Set<Id> opptyIds = new Set<Id>();
        
        // Get the Oppty IDs for each OLI
        for (OpportunityLineItem oli : oliList) {
            Id relatedOpptyId = oli.OpportunityId;
            if (relatedOpptyId != null) {
                opptyIds.add(relatedOpptyId);
            }            
        }
        
        // Get Opptys
        List<Opportunity> relatedOpptys = [SELECT Id, RecordTypeId, Planned_Trickle__c, (SELECT Id FROM OpportunityLineItems)
                                     FROM Opportunity
                                     WHERE Id IN :opptyIds];
        
        // Define a new Map to hold the Opportunity OLI pairs
        Map<Id, Opportunity> oliOpptyMap = new Map<Id, Opportunity>();
        
        // Map Opptys to OLIs
        for (Opportunity oppty : relatedOpptys) {
            for(OpportunityLineItem oli : oppty.OpportunityLineItems) {
                if (oli.Id != null) {
                	oliOpptyMap.put(oli.Id,oppty);
            	}  
            }          
        }
        System.debug(oliOpptyMap);
        // Define a new list to hold the new OLIs that will need to be updates
        List<OpportunityLineItem> oliToUpdate = new List<OpportunityLineItem>();
        
        // Get Connections & Forum Record Type ID
        Map<String, Schema.RecordTypeInfo> oppRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        List<Id> opptyRecordTypeList = new List<Id>();
        opptyRecordTypeList.add(oppRecordTypes.get('Connections & Forum').getRecordTypeId());
        opptyRecordTypeList.add(oppRecordTypes.get('CX & FM Renewal').getRecordTypeId());
                
        // Add OLIs to our list so we can update the custom field values
        for(OpportunityLineItem oli : oliList) {
            OpportunityLineItem newOli = new OpportunityLineItem(Id = oli.Id);
            Opportunity relatedOppty = oliOpptyMap.get(newOli.Id);
            if(opptyRecordTypeList.contains(relatedOppty.RecordTypeId)) {
                newOli.Trickle__c = relatedOppty.Planned_Trickle__c;
                System.debug('syncOpptyToNewOLIs: ' + newOli.Trickle__c);
            }
        }
        
        // Update the OLIs
        if(!oliToUpdate.isEmpty()) {
            isTriggerFire = FALSE;
            update oliToUpdate;
            isTriggerFire = TRUE;
        }
    }
}