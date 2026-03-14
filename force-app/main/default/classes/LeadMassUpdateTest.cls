@IsTest
public class LeadMassUpdateTest {

    @TestSetup static void makeData() {
        Id NEW_UNCLASSIFIED_LEADS = [SELECT Id FROM Group WHERE Name = 'New Unclassified Leads'].Id;
        Id MARKETING_LEADS = [SELECT Id FROM Group WHERE Name = 'Marketing Leads'].Id;

        List<Lead> leads = new List<Lead>{
            new Lead(FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Open',
            pi__score__c = 50,
            OwnerId = NEW_UNCLASSIFIED_LEADS),

            new Lead(FirstName = 'Test',
            LastName = 'Lead 2',
            Company = 'Test Company 2',
            Close_Reason__c = 'Budget',
            Status = 'Unqualified',
            OwnerId = MARKETING_LEADS)
        };

        insert leads;
    } 

    @isTest public static void BatchTest() {
        Test.startTest();
            UnclassifiedToNurturingInvocable.unclassifiedToNurturing();
            DQMLToNotRelevant.dqMLtoNotRelevant();
        Test.stopTest();
    }
}