/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-04-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class CreateQuoteApexControllerTest {
    
    public static testmethod void testGetQuoteRtId(){
        Account a = new Account(Name='TestAcct',
                                Client_Type__c='Broking', 
                                Primary_Asset_Class__c='Credit', 
                                Territory__c='North America',
                                Country__c='United States');
        insert a;
        
        Contact c = new Contact(FirstName = 'John',
                                LastName = 'Smith',
                                Title = 'test',
                                AccountId = a.Id,
                                Email = 'jsmith@testing.com',
                                Country__c = 'United States');
        insert c;
        
        Product2 prod = new Product2(Name = 'Laptop X200', 
                                     Family = 'Hardware');
        insert prod;

        Product2 mhrrProd = new Product2(Name = 'US Connections - MHRR 1', 
                                        Family = 'CX');
        insert mhrrProd;

        PriceBook2 unitedStatesPriceBook = new Pricebook2(Name = 'US Price Book',
                                                          isActive = true);

        insert unitedStatesPriceBook;
        
        Id standardPricebookId = Test.getStandardPricebookId();
        Id pricebookId = unitedStatesPriceBook.Id;
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPricebookId, 
                                                          Product2Id = prod.Id, 
                                                          UnitPrice = 200, 
                                                          IsActive = true);
        insert standardPrice; 

        PricebookEntry customPrice = new PricebookEntry(Pricebook2Id = pricebookId, 
                                                          Product2Id = prod.Id, 
                                                          UnitPrice = 250, 
                                                          IsActive = true);
        insert customPrice;

        PricebookEntry mhrrStandardPrice = new PricebookEntry(Pricebook2Id = standardPricebookId, 
                                                          Product2Id = mhrrProd.Id, 
                                                          UnitPrice = 1300, 
                                                          IsActive = true);
        insert mhrrStandardPrice; 

        PricebookEntry mhrrCustomPrice = new PricebookEntry(Pricebook2Id = pricebookId, 
                                                          Product2Id = mhrrProd.Id, 
                                                          UnitPrice = 1450, 
                                                          IsActive = true);
        insert mhrrCustomPrice;     
        
        //***opportunity 1
        Opportunity opp = new Opportunity(Name = 'TestOpp',
                                          AccountId = a.Id,
                                          StageName = 'Nurture',
                                          CloseDate = System.today(),
                                          TB_Probability__c = '20%',
                                          Package_start_date__c = System.today(),
                                          Package_expiry_date__c = System.today()+365,
                                          Hours__c = 2,
                                          Primary_Contact__c = c.Id,
                                          Territory__c  = 'US');
        insert opp;
        
        OpportunityLineItem pLine = new OpportunityLineItem(OpportunityId=opp.Id,PricebookEntryId=customPrice.Id,
                                                            Product2Id=prod.Id,Quantity=2,UnitPrice=200);
        insert pLine;         
        
        Quote q = new Quote(Name='Test Quote',opportunityId=opp.Id,Prepopulate__c=true,CanCreateQuoteLineItems=true,
                            PriceBook2Id=pricebookId,Billing_Address__c='123 Test Drive',Fees_payable_within_days__C=120,Use_Account_Address__c = TRUE);
        insert q;    
        
        Id quoteRtId = CreateQuoteApexController.getQuoteRtId('Connections',0,'US', '000123', 'Yes', 'New Business', '', '', true).quoteRtId;
        System.assertEquals(quoteRtId, [Select Id from RecordType where SObjectType = 'Quote' and DeveloperName = 'Connections' limit 1].Id);   
        
        Id quoteRtId2 = CreateQuoteApexController.getQuoteRtId('Connections_Forum',0,'Europe', '000123', 'Yes', 'New Business', '', '', true).quoteRtId;
        System.assertEquals(quoteRtId2, [Select Id from RecordType where SObjectType = 'Quote' and DeveloperName = 'Connections_Forum' limit 1].Id);
        
        Id quoteRtId3 = CreateQuoteApexController.getQuoteRtId('Forum',0,'China', '000123', 'No', 'New Business', '', '', true).quoteRtId;
        System.assertEquals(quoteRtId3, [Select Id from RecordType where SObjectType = 'Quote' and DeveloperName = 'Forum' limit 1].Id);
        
        Id quoteRtId4 = CreateQuoteApexController.getQuoteRtId('Connections_Renewal',0,'US', '000123', 'Yes', 'New Business', '', '', true).quoteRtId;
        System.assertEquals(quoteRtId4, [Select Id from RecordType where SObjectType = 'Quote' and DeveloperName = 'Connections' limit 1].Id);   
        
        Id quoteRtId5 = CreateQuoteApexController.getQuoteRtId('CX_FM_Renewal',0,'Europe', '000123', 'Yes', 'New Business', '', '', true).quoteRtId;
        System.assertEquals(quoteRtId5, [Select Id from RecordType where SObjectType = 'Quote' and DeveloperName = 'Connections_Forum' limit 1].Id);
        
        Id quoteRtId6 = CreateQuoteApexController.getQuoteRtId('Forum_Renewal',0,'China', '000123', 'No', 'New Business', '', '', true).quoteRtId;
        System.assertEquals(quoteRtId6, [Select Id from RecordType where SObjectType = 'Quote' and DeveloperName = 'Forum' limit 1].Id);
        
        String packageName1 = CreateQuoteApexController.getQuoteRtId('Forum',0,'Global', '000123', 'No', 'New Business', '', '', true).packageName;
        System.assertEquals(packageName1, 'Forum Package G-000123');

        String packageName2 = CreateQuoteApexController.getQuoteRtId('Connections',10,'US', '000123', 'Yes', 'New Business', '', '', true).packageName;
        System.assertEquals(packageName2, 'Connections & Community Package U-000123');       
        
        String packageName3 = CreateQuoteApexController.getQuoteRtId('Connections_Forum',0,'US', '000123', 'Yes', 'New Business', '', '', true).packageName;
        System.assertEquals(packageName3, 'Community & Forum Package U-000123');  
        String packageName4 = CreateQuoteApexController.getQuoteRtId('CX_FM_Renewal',0,'US', '000123', 'Yes', 'New Business', '', '', true).packageName;
        System.assertEquals(packageName4, 'Community & Forum Package U-000123');  
        
        System.assertEquals(2, [Select count() from QuoteLineItem where QuoteId = :q.Id]);


        /*
        Test statements to test the CFT (Community Free Trial) portion of the Create Quote Apex Controller
        CFT Opps are defined as a CX opp with a trial type of Free and Trial product of Community COnsulations
        These CFT Opps should create a quote with a Record Type of Community Consulations Free Trials.
        */
        Id quoteRtIdcft = CreateQuoteApexController.getQuoteRtId('Connections',0,'US', '000123', 'Yes', 'Trial', 'Free', 'Community Consultations', true).quoteRtId;
        System.assertEquals(quoteRtIdcft, [Select Id from RecordType where SObjectType = 'Quote' and DeveloperName = 'Communiunity_Consulations' limit 1].Id);
    }

    

}