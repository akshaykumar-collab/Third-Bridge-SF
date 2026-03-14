global class BatchLeadMLToNotRelevant implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Id MARKETING_LEADS = [SELECT Id FROM Group WHERE Name = 'Marketing Leads'].Id;

        String query = 'SELECT Id, OwnerId FROM Lead WHERE Status = \'Unqualified\' AND OwnerId = \'' + MARKETING_LEADS + '\'';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Lead> leadList) {
        Id PROSPECTS_NOT_RELEVANT = [SELECT Id FROM Group WHERE Name = 'Prospects not Relevant'].Id;

        for(Lead l : leadList) {
            l.OwnerId = PROSPECTS_NOT_RELEVANT;
        }

        try {
            update leadList;
        } catch(Exception e) {
            System.debug(e);
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('batch complete');
    }
}