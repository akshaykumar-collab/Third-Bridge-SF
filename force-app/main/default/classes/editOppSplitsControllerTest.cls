@isTest
public class editOppSplitsControllerTest {
    private static String setupData(String recordType, String oppType) {
        // Get a record type ID; will be used for the new Account
        Map<String, Schema.RecordTypeInfo> accRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Id accountRecTypeId = accRecordTypes.get('Client').getRecordTypeId();

        // Create and insert a new Account to be associated to the Opportunity
        Account acc = new Account(
            Name = 'Test Account',
            Account_Status__c = 'Active',
            Type = 'Client – Current',
            Website = 'www.testaccount.com',
            Territory__c = 'North America',
            Country__c = 'United States',
            RecordTypeId = accountRecTypeId
        );
        insert acc;

        // Create and insert a new Product
        Product2 product = new Product2(
        	Name = 'USA Forum - Small Subscription',
            isActive = TRUE,
            Family = 'FM',
            Sub_Family__c = 'Subscription'
        );
        insert product;

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry strdPbEntry = new PricebookEntry(
        	Pricebook2Id = pricebookId, 
            Product2Id = product.Id,
        	UnitPrice = 5161.00,
            IsActive = TRUE
        );
        insert strdPbEntry;

        // Create and insert a custom Pricebook        
        Pricebook2 pb = new Pricebook2(
            Name ='US Price Book',
            isActive = TRUE
        );
        insert pb;
        
        // Create and insert a custom Pricebook entry   
       	PricebookEntry pbEntry = new PricebookEntry(
        	Pricebook2Id = pb.Id,
            Product2Id = product.Id,
            UnitPrice = 5161.00,
            IsActive = TRUE
        );
        insert pbEntry;

        // Get a record type ID; will be used for the new Opportunity
        Map<String, Schema.RecordTypeInfo> oppRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Id oppRecTypeId = oppRecordTypes.get(recordType).getRecordTypeId();

        Opportunity opp = new Opportunity(
            Name='Test Opportunity',
            Type = oppType,
            Territory__c = 'US',
            StageName = 'Qualify',
            AccountId = acc.Id,
            CloseDate = System.today() + 30,
            TB_Probability__c = '0%',
            ForecastCategoryName = 'Not Likely',
            Connections_Package_Includes_Trickle__c = 'No',
            Package_start_date__c = System.today(),
            Package_expiry_date__c = System.today() + 180,
            //Amount = 16000,
            RecordTypeId = oppRecTypeId,
            Pricebook2Id = pb.Id
        );
        if(recordType.contains('Connections') || recordType.contains('CX')) {
            opp.Hours__c = 10;
        }
        if(recordType.contains('Forum') || recordType.contains('FM')) {
            opp.Forum_Users__c = 4;
        }
        insert opp;

        return opp.Id;
    }

    @isTest static void Test1_getSplits() {
        String id = setupData('Forum', 'New Business');

        List<OpportunitySplit> splits = editOppSplitsController.getSplits(id);
    }

    @isTest static void Test2_getOppTeam() {
        String id = setupData('Forum', 'New Business');

        List<OpportunityTeamMember> team = editOppSplitsController.getOppTeam(id);
    }

    @isTest static void Test3_getOpp() {
        String id = setupData('Forum', 'New Business');

        Opportunity opp = editOppSplitsController.getOpp(id);
    }

    @isTest static void Test4_saveSplits() {
        String id = setupData('Forum', 'New Business');

        List<OpportunitySplit> splits = editOppSplitsController.getSplits(id);
        String serializedSplits = JSON.serialize(splits);

        editOppSplitsController.saveSplits('[]', serializedSplits, id);
    }
}