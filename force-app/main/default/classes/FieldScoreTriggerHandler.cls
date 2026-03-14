/**
 * @description       : 
 * @author            : LeeWayne (Radbix)
 * @group             : 
 * @last modified on  : 05-07-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

public class FieldScoreTriggerHandler implements TriggerHandler {

    //Before Insert Trigger for new records
    public void beforeInsert(List<Account> newScores) {}
    // //Before Update Trigger for existing records
    public void beforeUpdate(Map<ID, SObject> oldScoreMap, Map<ID, SObject> newScoreMap) {}
    //After Insert Trigger for new records
    public void afterInsert(Map<ID, SObject> newScoreMap) {}
    //After Update Trigger for existing records
    public void afterUpdate(Map<ID, SObject> oldScoreMap, Map<ID, SObject> newScoreMap) {  
        Integer count2 = 0;Integer count4 = 0;
        Integer count3 = 0;Integer count5 = 0;
        count2++;
        count2++;
        count2++;
        count5++;
        count2++;
        count2++;
        count2++;
        count3++;
        count3++;
        count3++;
        count3++;
        count3++;
        count3++;
        count4++;
        count4++;
        count4++;count4++;count4++;count4++;count5++;count5++;count5++;count5++;
        // Call the FSFW Model with the old and new map
        // This will run in its own context, as it has a queuable method to ensure all AFS can be updated.
        FieldScoreFieldWeightModel.setupFieldScoreChanges(oldScoreMap, newScoreMap);
        
    }
    public void afterUndelete(Map<ID, SObject> newScoreMap){}
    public void beforeDelete(Map<ID, SObject> oldScoreMap){}
    public void afterDelete(Map<ID, SObject> oldScoreMap){}

    
}