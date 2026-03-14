/**
 * @description       : 
 * @author            : LeeWayne (RadixBay)
 * @group             : 
 * @last modified on  : 05-14-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class AccountTriggerHandler implements TriggerHandler {

    //After Insert Trigger for new records
    public void afterInsert(Map<ID, SObject> newAccountMap) {


        
        //Call the Account Ranking Model so AFS records can be created/updated, send a nullmap for the first parameter as these are brand new accounts.
        Map<ID, SObject> nullmap = null;
        System.debug('Old Map: ' + nullmap + '  New Map: ' + newAccountMap);

        TriggerSettings__mdt triggerSetting = TriggerSettings__mdt.getInstance('Account_Trigger_ACT');
        Boolean runTrigger = triggerSetting.Active__c;

        if (runTrigger){
            AccountRankingModel.accountSetup(nullmap, newAccountMap);
        }

    }
    //After Update Trigger for existing records
    public void afterUpdate(Map<ID, SObject> oldAccountMap, Map<ID, SObject> newAccountMap) {

        
        //System.debug('TESTING TESTING UPDATE Old Map: ' + oldAccountMap + ' New Map: '+newAccountMap);
        //Call the Account Ranking Model so AFS records can be created/updated.
        TriggerSettings__mdt triggerSetting = TriggerSettings__mdt.getInstance('Account_Trigger_ACT');
        Boolean runTrigger = triggerSetting.Active__c;

        if (runTrigger){
            AccountRankingModel.accountSetup(oldAccountMap, newAccountMap);
        }
    }


    
}