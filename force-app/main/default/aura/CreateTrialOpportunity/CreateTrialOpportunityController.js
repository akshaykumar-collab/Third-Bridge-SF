({
    recordUpdate : function (component) { 
        var oppType = component.get("v.oppRecord.Type");
        if (oppType == 'Trial'){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Info!",
                "message": "A trial cannot be created for a trial."
            });
            $A.get("e.force:closeQuickAction").fire();
            toastEvent.fire();
        }else {
            var flow = component.find("newTrialFlow");
            var flowVars = [{name:'recordId', type:'String', value:component.get("v.recordId")}];
            flow.startFlow("Paid_Trial",flowVars);
        }
    },
    
    handleStatusChange : function (component, event) {
        if(event.getParam("status") === "FINISHED") {
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        }
    }
})