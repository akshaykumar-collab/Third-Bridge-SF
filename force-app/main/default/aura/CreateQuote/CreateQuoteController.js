({
    handleRecordUpdate : function(component, event, helper) {
        var type = component.get("v.quoteRecord.Type");
        var recordIdentification = component.get("v.recordId");
        console.log("DEBUG Opp Record Load Error: " + component.get("v.recordLoadError"));
        var isApproved = component.get("v.quoteRecord.Approved__c");
        if (type == 'Trial' && !isApproved){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "A quote cannot be created until it is approved."
            });
            $A.get("e.force:closeQuickAction").fire();
            toastEvent.fire();
        } else {
            var ctrler = component.get("c.getQuoteRtId");
            var opprtName = component.get("v.quoteRecord.RecordType.DeveloperName");
            ctrler.setParams({ oppRtDevName : component.get("v.quoteRecord.RecordType.DeveloperName") ,
                              connectionHours: component.get("v.quoteRecord.Hours__c") ,
                              territory: component.get("v.quoteRecord.Territory__c") ,
                              tbId: component.get("v.quoteRecord.TB_ID__c"),
                              cgc: component.get("v.quoteRecord.Deal_Include_CGC__c"),
                              oppType: component.get("v.quoteRecord.Type"),
                              trialType: component.get("v.quoteRecord.Trial_Type__c"),
                              trialproduct: component.get("v.quoteRecord.Trial_Product__c"),
                              accountAddress: component.get("v.quoteRecord.Is_Account_Address_Populated__c")
                            });
            ctrler.setCallback(this, function(response) {      
                var createnewQuote = $A.get("e.force:createRecord"); 
                createnewQuote.setParams({ 
                    "entityApiName": "Quote", 
                        "recordTypeId": response.getReturnValue().quoteRtId,
                    "defaultFieldValues": { 
                        AccountId: component.get("v.quoteRecord.AccountId"),
                        OpportunityId: component.get("v.recordId"),
                        Prepopulate__c: true,
                        CanCreateQuoteLineItems: true,
                        Pricebook2Id: component.get("v.quoteRecord.Pricebook2Id"),
                        Use_Account_Address__c: component.get("v.quoteRecord.Is_Account_Address_Populated__c"),
                        Package_Name__c: response.getReturnValue().packageName
                        
                    } 
                }); 
                createnewQuote.fire(); 
            });
            $A.enqueueAction(ctrler);        
        }}
    
})

/*({
    handleRecordUpdate : function(component, event, helper) {
        var type = component.get("v.quoteRecord.Type");
        var isApproved = component.get("v.quoteRecord.Approved__c");

        if (type === 'Trial' && !isApproved) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "A quote cannot be created until it is approved.",
                "type": "error"
            });
            $A.get("e.force:closeQuickAction").fire();
            toastEvent.fire();
        } else {
            var action = component.get("c.getQuoteRtId");

            action.setParams({
                oppRtDevName: component.get("v.quoteRecord.RecordType.DeveloperName"),
                connectionHours: component.get("v.quoteRecord.Hours__c"),
                territory: component.get("v.quoteRecord.Territory__c"),
                tbId: component.get("v.quoteRecord.TB_ID__c"),
                cgc: component.get("v.quoteRecord.Deal_Include_CGC__c"),
                oppType: component.get("v.quoteRecord.Type"),
                trialType: component.get("v.quoteRecord.Trial_Type__c"),
                trialproduct: component.get("v.quoteRecord.Trial_Product__c")
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                 console.log('state'+state);
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    if (result && result.quoteRtId) {
                        var createQuote = $A.get("e.force:createRecord");
                        createQuote.setParams({
                            entityApiName: "Quote",
                            recordTypeId: result.quoteRtId,
                            defaultFieldValues: {
                                AccountId: component.get("v.quoteRecord.AccountId"),
                                OpportunityId: component.get("v.recordId"),
                                Prepopulate__c: true,
                                CanCreateQuoteLineItems: true,
                                Pricebook2Id: component.get("v.quoteRecord.Pricebook2Id"),
                                Package_Name__c: result.packageName
                            }
                        });
                        createQuote.fire();
                    } else {
                        console.error("No record type ID returned.");
                    }
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": response.getError()[0].message,
                        "type": "error"
                    });
                    $A.get("e.force:closeQuickAction").fire();
                    toastEvent.fire();
                }
            });

            $A.enqueueAction(action);
        }
    }
})*/