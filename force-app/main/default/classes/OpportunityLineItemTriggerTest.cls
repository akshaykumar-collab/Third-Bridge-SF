@isTest
private class OpportunityLineItemTriggerTest {
    private static QuoteLineItem setupData(String recordType){
                // Test data setup
        // Get a record type ID; will be used for the new Account
        Map<String, Schema.RecordTypeInfo> accRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Id accountRecTypeId = accRecordTypes.get('Client').getRecordTypeId();
        
        // Create and insert a new Account to be associated to the Opportunity
        Account acc = new Account(
            Name = 'Test Account',
            Account_Status__c = 'Active',
            Type = 'Client – Current',
            Website = 'www.testaccount.com',
            Territory__c = 'India',
            Country__c = 'Bangladesh',
            Primary_Asset_Class__c = 'Corporate',
            Client_Type__c = 'Corporate Firm',
            RecordTypeId = accountRecTypeId
        );
        
        insert acc;
        
        // Create and insert a new Product
        Product2 product = new Product2(
        	Name = 'Test Product',
            isActive = TRUE,
            Sub_Family__c = 'Package'
        );
        
        insert product;
        
        // Create and insert a standard Pricebook entry
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry strdPbEntry = new PricebookEntry(
        	Pricebook2Id = pricebookId, 
            Product2Id = product.Id,
        	UnitPrice = 100,
            IsActive = TRUE
        );

		insert strdPbEntry;

        // Create and insert a custom Pricebook        
        Pricebook2 pb = new Pricebook2(
            Name ='Test Pricebook',
            isActive = TRUE
        );

        insert pb;
        
        // Create and insert a custom Pricebook entry   
       	PricebookEntry pbEntry = new PricebookEntry(
        	Pricebook2Id = pb.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = TRUE
        ); 
        
        insert pbEntry;
        
        // Get a record type ID; will be used for the new Opportunity
        Map<String, Schema.RecordTypeInfo> oppRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Id oppRecTypeId = oppRecordTypes.get(recordType).getRecordTypeId();
        
        // Create and insert a new opportunity
        Double initialTrickle = 130;
        
        Opportunity opp = new Opportunity(
            Name='Test Opportunity',
            Type = 'New Business',
            Territory__c = 'India',
            StageName = 'Qualify',
            AccountId = acc.Id,
            CloseDate = System.today() + 30,
            TB_Probability__c = '0%',
            ForecastCategoryName = 'Not Likely',
            Connections_Package_Includes_Trickle__c = 'Yes',
            Forum_Users__c = 5,
            Planned_Trickle__c = initialTrickle,
            New_or_Existing_Trickle__c = 'New',
            Package_start_date__c = System.today(),
            Package_expiry_date__c = System.today() + 30,
            Amount = 16000,
            RecordTypeId = oppRecTypeId,
            Pricebook2Id = pb.Id
        );
        
        insert opp;
        
        // Create and insert a new Quote        
       	Quote qt = new Quote(
			Name = 'Test Quote',
            OpportunityId = opp.id,
            Billing_Address__c = '123 Test Drive',
            Package_Name__c = 'Connections & Forum Package T-00000001',
            Fees_payable_within_days__C = 120,
            Payment_remitted_to__c = 'Third Bridge Group Limited',
            Spotlight_Discussions1__c = 'Monthly Trickle',
            Pricebook2Id = pb.Id
        ); 
        
        insert qt;

        // Create and insert a new Quote Line Item
        Integer productQuantity = 24;
        
        QuoteLineItem qli = new QuoteLineItem(
        	QuoteId = qt.id,
            Quantity = productQuantity,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = 120
        );
        
        insert qli;
        
        // Sync Quote
		opp.SyncedQuoteId = qt.Id;
        
        update opp;
        
        return qli;
    }
    
    @isTest static void TestOpportunityLineItemTrigger() {
        QuoteLineItem qli = setupData('CX & FM Renewal');
        
        // Query the new Opportunity Line Item
        OpportunityLineItem[] createdOLIS = [SELECT Id, Trickle__c 
                                             FROM OpportunityLineItem 
                                             WHERE Id = :qli.OpportunityLineItemId];
        if (createdOLIS.size() > 0){
            // Verify the trigger works
            // Assert that Trickle__c on the QLI was updated with the Planned_Trickle__c value from the Oppty
            System.assertEquals(qli.Trickle__c,createdOLIS[0].Trickle__c, 'The trickle numbers do not match!');
        }
    }

    @isTest static void TestOpportunityLineItemTriggerOppSync() {
        QuoteLineItem qli = setupData('CX & FM Renewal');
        
        // Query the new Opportunity Line Item
        OpportunityLineItem[] createdOLIS = [SELECT Id, Trickle__c 
                                             FROM OpportunityLineItem 
                                             WHERE Id = :qli.OpportunityLineItemId];
        OpportunityLineItemTriggerHandler.syncOpptyToNewOLIs(createdOLIS);
    }
}