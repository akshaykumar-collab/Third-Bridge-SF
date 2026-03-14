@isTest(SeeAllData=true)
public class RHX_TEST_Opportunity {
    static testMethod void RHX_Testmethod() {
        //SSANDHU CASE 224018 START
        List<sObject> sourceList = [SELECT Id 
            FROM Opportunity WHERE StageName != 'Closed Won' LIMIT 1];
            //SSANDHU CASE 224018 END
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Opportunity()
            );
        }
        rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}