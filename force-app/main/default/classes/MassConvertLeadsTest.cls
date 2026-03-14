@IsTest
public class MassConvertLeadsTest {

    @TestSetup static void makeData() {
        Account acc = new Account(
            Name = 'Company 1',
            Country__c = 'United States'
        );
        insert acc;

        Campaign testCampaign = new Campaign(
            Name = 'Test Campaign'
        );
        insert testCampaign;

        List<Lead> leads = new List<Lead>();
        Integer numOfRecords = 20;
        for(Integer i = 0; i < numOfRecords; i++) {
            Lead leadRecord = new Lead(
                FirstName = 'Test Lead',
                LastName = String.valueOf(i),
                Company = 'Company ' + i,
                Country__c = 'United States'
            );
            leads.add(leadRecord);
        }
        insert leads;

        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        for(Lead l : leads) {
            CampaignMember cm = new CampaignMember(
                CampaignId = testCampaign.Id,
                LeadId = l.Id,
                Status = 'Sent'
            );
            campaignMembers.add(cm);
        }
        insert campaignMembers;
    }

    private static List<String> getFlowInput() {
        List<String> input = new List<String>();
        String campaignId = [SELECT Id FROM Campaign LIMIT 1].Id;
        String status = 'Sent';
        String inputString = campaignId + ',' + status;
        input.add(inputString);

        return input;
    }

    public static testmethod void Test1_DateCreated() {
        List<String> input = getFlowInput();
        List<Account> acc = [SELECT Id, Name, OwnerId, Owner.Name FROM Account];
        Test.startTest();
            MassConvertLeads.massConvertLeads(input);
            BatchConvertLeads.accountListCSV(acc);
        Test.stopTest();
    }

}