// 
// (c) 2018 Appirio, Inc.
//
// **Universal Trigger for Quote Object
//
// 4.25.18    Nick Sharp     Original   S-554925
// 

trigger QuoteTrigger on Quote (before insert, before update, before delete, after insert, after update, after delete, after undelete){ 
    
    //populate collections used in event handler 
    //MDUNCAN Modified Below 1 line - 06.25.2018 - C-00231744 Removed logic in Trigger per client request
    //QuoteTriggerHandler  handler = new QuoteTriggerHandler(trigger.new, trigger.old, trigger.newMap, trigger.oldMap); 
    
    //call event handler methods 
    if(Trigger.IsInsert){ 
        if(Trigger.isBefore){ 
            
            //NO BEFORE INSERT METHODS DEFINED AT THIS TIME 
            
        } 
        else{ 
            //The ff block is for creating quote line items since executing -
            //"new quote" create action from anywhere but the standard button bypasses -
            //the creation of QLIs  
            List<QuoteLineItem> qlis = new List<QuoteLineItem>();
            Set<Id> oppIds = new Set<Id>();            
            
            for (Quote q : Trigger.New){
                if (q.CanCreateQuoteLineItems){ //setting this flag to true from the ltng component. It eventually gets set to false by SF
                    oppIds.add(q.opportunityId);
                }                
            }
            
            for(OpportunityLineItem oppline:[Select id,quantity,Description,UnitPrice,OpportunityId,PriceBookEntry.Product2Id,PriceBookEntryId
                                             from OpportunityLineItem where OpportunityId in :oppIds]){
                                                 for (Quote q : Trigger.New){ 
                                                     if (q.OpportunityId == oppLine.OpportunityId){
                                                         QuoteLineItem qli = new QuoteLineItem();
                                                         qli.QuoteId = q.Id;
                                                         qli.PricebookEntryId = oppLine.PriceBookEntryId;
                                                         qli.UnitPrice = oppline.UnitPrice;
                                                         qli.Product2Id = oppline.PriceBookEntry.Product2Id;
                                                         qli.Quantity = oppline.Quantity;
                                                         qli.Description = oppline.Description;
                                                         qlis.add(qli);
                                                     }                                                     
                                                 }
                                             }
            if (!qlis.isEmpty()){
                insert qlis;
            }
        } 
    } 
    else if (Trigger.IsUpdate){ 
        if(Trigger.isBefore) { 
            //MDUNCAN Modified Below 1 line - 06.25.2018 - C-00231744 Removed logic in Trigger per client request
            //handler.onBeforeUpdate();
        } 
        else{ 
            //NO AFTER UPDATE METHODS DEFINED AT THIS TIME 
        } 
    } 
    /*
else if(Trigger.isDelete){ 
if(Trigger.isBefore) { 
//NO BEFORE DELETE METHODS DEFINED AT THIS TIME 
} 
else{ 
//NO AFTER DELETE METHODS DEFINED AT THIS TIME 
} 
} 
else if(Trigger.isUnDelete){ 
//NO UNDELETE METHODS DEFINED AT THIS TIME 
} 
*/
    
}