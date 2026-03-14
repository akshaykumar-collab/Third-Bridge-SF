global class BatchLeadUnclassifiedToNurturing implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Id NEW_UNCLASSIFIED_LEADS = [SELECT Id FROM Group WHERE Name = 'New Unclassified Leads'].Id;

        String query = 'SELECT Id, OwnerId FROM Lead WHERE pi__score__c < 100 AND Status = \'Open\' AND OwnerId = \'' + NEW_UNCLASSIFIED_LEADS + '\'';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Lead> leadList) {
        Id PROSPECTS_FOR_NURTURING = [SELECT Id FROM Group WHERE Name = 'Prospects for Nurturing'].Id;

        for(Lead l : leadList) {
            l.OwnerId = PROSPECTS_FOR_NURTURING;
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