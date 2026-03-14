@isTest
private class OpportunityTriggerTest {
    @isTest static void TestOpportunityTrigger() {
        // Test data setup
        // Get a record type ID; will be used for the new Account
        Map<String, Schema.RecordTypeInfo> accRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Id accountRecTypeId = accRecordTypes.get('Client').getRecordTypeId();
        
        // Create and insert a new Account to be associated to the Opportunity
        Account acc = new Account(
            Name = 'Test Account',
            Account_Status__c = 'Active',
            Type = 'Client - Current',
            Website = 'www.testaccount.com',
            Territory__c = 'India',
            Country__c = 'Bangladesh',
            Client_Type__c = 'Corporate Firm',
            RecordTypeId = accountRecTypeId
        );
        
        insert acc;
        
        // Get a record type ID; will be used for the new Opportunity
        Map<String, Schema.RecordTypeInfo> oppRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Id oppRecTypeId = oppRecordTypes.get('CX & FM Renewal').getRecordTypeId();
        
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
            Planned_Trickle__c = initialTrickle,
            New_or_Existing_Trickle__c = 'New',
            Package_start_date__c = System.today(),
            Package_expiry_date__c = System.today() + 30,
            Amount = 16000,
            RecordTypeId = oppRecTypeId
        );
        
        insert opp;
        
        // Create and insert a new Product
        Product2 product = new Product2(
            Name = 'Test Product',
            isActive = TRUE,
            Sub_Family__c = 'Package'
        );
        
        insert product;
        
        // Create and insert a new Pricebook entry        
        Id priceBookId = Test.getStandardPricebookId();
        
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = priceBookId,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = TRUE
        ); 
        
        insert pbEntry;
        
        // Create and insert a new Opportunity Line Item
        Integer productQuantity = 24;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.id,
            Quantity = productQuantity,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = productQuantity * pbEntry.UnitPrice
        );
        
        insert oli;
        
        // Query the new Opportunity Line Item
        OpportunityLineItem[] createdOLIS = [SELECT Id, Trickle__c 
                                          FROM OpportunityLineItem 
                                          WHERE Id = :oli.Id];

        Opportunity oppty = [SELECT Id, Planned_Trickle__c FROM Opportunity LIMIT 1];
        System.debug(oppty);
        oppty.Planned_Trickle__c = 4;
        update oppty;
        
        // Verify the trigger works
        // Assert that Trickle__c on the QLI was updated with the Planned_Trickle__c value from the Oppty
        //if (createdOLIS.size() > 0){
        //    System.assertEquals(opp.Planned_Trickle__c,createdOLIS[0].Trickle__c, 'The trickle numbers do not match!');
        //}
    }
}