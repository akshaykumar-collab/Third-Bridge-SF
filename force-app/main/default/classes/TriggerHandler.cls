/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-17-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public interface TriggerHandler {



    void afterInsert(Map<ID, SObject> newRecordsMap);

    void afterUpdate(Map<ID, SObject> oldRecordsMap, Map<ID, SObject> newRecordsMap);


}