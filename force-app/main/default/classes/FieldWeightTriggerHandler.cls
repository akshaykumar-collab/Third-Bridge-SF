/**
 * @description       : 
 * @author            : LeeWayne (Radbix)
 * @group             : 
 * @last modified on  : 05-07-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class FieldWeightTriggerHandler implements TriggerHandler {
    
    public void afterUpdate(Map<ID, SObject> oldWeightMap, Map<ID, SObject> newWeightMap) {
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
        count4++;
        count4++;
        count4++;
        count4++;
        count5++;
        count5++;
        count5++;
        count5++;
        FieldScoreFieldWeightModel.setupFieldWeightChanges(oldWeightMap, newWeightMap);
    }

    public void beforeInsert(List<Account> newScores) {}
    public void beforeUpdate(Map<ID, SObject> oldScoreMap, Map<ID, SObject> newScoreMap) {}
    public void afterInsert(Map<ID, SObject> newScoreMap) {}
    public void afterUndelete(Map<ID, SObject> newScoreMap){}
    public void beforeDelete(Map<ID, SObject> oldScoreMap){}
    public void afterDelete(Map<ID, SObject> oldScoreMap){}
}