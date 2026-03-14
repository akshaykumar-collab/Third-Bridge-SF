/**
 * @description       : 
 * @author            : LeeWayne (RadixBay)
 * @group             : 
 * @last modified on  : 05-09-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger AccountTrigger on Account (before insert,before update,before delete,after insert,after update,after delete,after undelete) {
    TriggerHandler handler = new AccountTriggerHandler();

    /*
    Depening on the OperationType send it to the correct Operation method in the Trigger Handler Class
    The Handler Class is seperated from the Trigger to enable more dynamic functionality in the future.
    */
        switch on Trigger.operationType {
            when AFTER_INSERT {
                handler.afterInsert(Trigger.newMap);
            }
            when AFTER_UPDATE {
                handler.afterUpdate( Trigger.oldMap, Trigger.newMap);
            }
        }
}