public class editOppSplitsController {

    @AuraEnabled(cacheable=true)
    public static List<OpportunitySplit> getSplits(String oppId) {
        return [SELECT Id, SplitAmount, SplitPercentage, SplitOwnerId, SplitOwner.Name, MRR_Split__c, TAS_Split__c, OpportunityId FROM OpportunitySplit WHERE OpportunityId =: oppId ORDER BY CreatedDate ASC];
    }

    @AuraEnabled(cacheable=true)
    public static List<OpportunityTeamMember> getOppTeam(String oppId) {
        return [SELECT Id, UserId, User.Name FROM OpportunityTeamMember WHERE OpportunityId =: oppId];
    }

    @AuraEnabled(cacheable=true)
    public static Opportunity getOpp(String oppId) {
        return [SELECT Id, Amount, Forum_MRR_2__c, RecordType.Name, CurrencyIsoCode, Type, Global_ENTERPRISE_TAS_ORIGINAL__c, Global_ACCESSIBLE_TAS_ORIGINAL__c FROM Opportunity WHERE ID =: oppId];
    }

    @AuraEnabled
    public static void saveSplits(String splitsToDelete, String splits, String oppId) {

        List<OpportunitySplit> deleteSplits = (List<OpportunitySplit>) JSON.deserialize(splitsToDelete, List<OpportunitySplit>.class);
        List<OpportunitySplit> upsertSplits = (List<OpportunitySplit>) JSON.deserialize(splits, List<OpportunitySplit>.class);

        for(OpportunitySplit os : deleteSplits) {
            os.SplitPercentage = 0;
            os.MRR_Split__c = 0;
            os.TAS_Split__c = 0;
            os.Delete_Split__c = true;
        }
        
        upsertSplits.addall(deleteSplits);

        Database.upsertResult[] upsertResults = Database.upsert(upsertSplits, true);
        for(Database.upsertResult ur : upsertResults) {                   
            if (!ur.isSuccess()) {
                for(Database.Error err : ur.getErrors()) {
                    System.debug(LoggingLevel.Error, 'The following error has occurred.'
                        + '\n' + err.getStatusCode() + ': ' + err.getMessage()
                        + '\n fields that affected this error: ' + err.getFields());
                }
            }
        }

        delete [SELECT Id from OpportunitySplit WHERE OpportunityId =: oppId AND Delete_Split__c = true];
    }

}