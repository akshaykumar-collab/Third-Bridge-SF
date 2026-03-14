// 
// (c) 2018 Appirio, Inc.
//
// **Universal Trigger Handler for QuoteTrigger on Quote 
//
// 4.25.18    Nick Sharp     Original   S-554925
// 
public class QuoteTriggerHandler { 
	//MDUNCAN START - 06.25.2018 - C-00231744 Removed logic in handler and disabled trigger per client request
    /*
    public Quote[] newLst = new Quote[]{}; 
	public Quote[] oldLst = new Quote[]{}; 
	public Map <ID, Quote> newMap = new Map<ID, Quote>{}; 
	public Map <ID, Quote> oldMap = new Map<ID, Quote>{}; 

	public QuoteTriggerHandler(Quote[] triggered, Quote[] triggeredFrom, 
		Map<ID,Quote> triggerNewMap, 
		Map<ID,Quote> triggerOldMap){ 
			newLst = triggered; 
			oldLst = triggeredFrom; 
			newMap = triggerNewMap; 
			oldMap = triggerOldMap; 
		} 

	public void onBeforeUpdate() { 
		validateRecordLock();
	} 
    
    public void validateRecordLock(){
        Schema.FieldSet	editableRecords = Schema.SObjectType.Quote.fieldSets.Editable_Fields_on_Quote;
        Map<Id,Profile> adminProfiles = new Map<Id,Profile>([SELECT Id FROM Profile WHERE Name IN ('System Administrator','SystemAdminNoSMS','Regional Leader','SVP')]);
        Map<String,String> allFieldsMap = new Map<String,String>();
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Quote.fields.getMap();
        for(String f: fields.keySet()){
            if(fields.get(f).getDescribe().isUpdateable()){
                allFieldsMap.put(f,fields.get(f).getDescribe().getLabel());
            }
        }
        Set<String> apiNames = new Set<String>();
		for(Schema.FieldSetMember f: editableRecords.getFields()){
            apiNames.add(f.getFieldPath().toLowerCase());
		}
        for(Quote q: newLst){
            List<String> errorFields = new List<String>();
            if(oldMap.get(q.Id).Passed_Approval_Process__c && q.Passed_Approval_Process__c && !adminProfiles.containsKey(UserInfo.getProfileId())){
                for(String s: allFieldsMap.KeySet()){
                    if(!apiNames.contains(s) && q.get(s) != oldMap.get(q.Id).get(s)){ 
                        String test = (q.get(s) != oldMap.get(q.Id).get(s)) ? 'true' : 'false';
                        errorFields.add(allFieldsMap.get(s));
                    }
                }
                if(!errorFields.isEmpty()){
                    String errorMessage = '<br/>';
                    for(String s: errorFields){
                        errorMessage += '&#8226 '+s + '<br/>';
                    }
                	q.addError(Label.Quote_Record_Lock_Error + errorMessage,false);
                }
            }
        }
    }
    */
    //MDUNCAN END - 06.25.2018 - C-00231744 Removed logic in handler and disabled trigger per client request
}