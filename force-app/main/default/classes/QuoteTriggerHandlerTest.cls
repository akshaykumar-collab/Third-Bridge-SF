// 
// (c) 2018 Appirio, Inc.
//
// **Universal Test Class for QuoteTriggerHandler on Quote
//
// 4.25.18    Nick Sharp     Original   S-554925
// 
@isTest
private class QuoteTriggerHandlerTest {
    //MDUNCAN START - 06.25.2018 - C-00231744 Removed logic in handler and disabled trigger per client request
    /*
    @testSetup static void setup(){
        Id nonAdminProfile = [Select Id FROM Profile WHERE Name = 'Custom Standard User' LIMIT 1].Id;
        User u = [SELECT Id FROM User WHERE ProfileId =: nonAdminProfile AND isActive = true limit 1];
        
        System.runAs(u) {
            Account a = new Account();
            a.Name = 'Test Account';
            a.Primary_Asset_Class__c = 'Corporate';
            a.Client_Type__c = 'Corporate Firm';
            insert a;
            
            Opportunity o = new Opportunity();
            o.Name = 'Test Opp';
            o.AccountId = a.Id;
            o.StageName = 'Order Signed';
            o.CloseDate = Date.Today().addDays(10);
            insert o;
            
            Quote q = new Quote();
            q.Passed_Approval_Process__c = true;
            q.OpportunityId = o.Id;
            q.Contract_Signed_Date__c = Date.Today();
            q.Contract_Entity__c = 'Test Contract Entity';
            q.Out_of_band_pricing__c = true;
            q.Name = 'Test Quote';
            q.Client_Name__c = 'Test';
            q.Needs_PC_Approval__c = 'Yes';
            q.Fees_payable_within_days__c = 15.0;
            insert q;
        }
    }
    
    static testMethod void testValidateRecordLockAdmin(){
        Id adminProfile = [Select Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u = [SELECT Id FROM User WHERE ProfileId =: adminProfile AND isActive = true limit 1];
        Quote q = [Select Id, Contract_Entity__c FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        q.Contract_Entity__c = 'New Value';
        Test.startTest();
        system.runAs(u){
            update q;
        }
        Test.stopTest();
    }
    
    static testMethod void testValidateRecordLockNonAdminAllow(){
        Quote q = [Select Id, Contract_Entity__c, OwnerId FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        User u = [SELECT Id FROM User WHERE Id = :q.OwnerId limit 1];
        
        q.Contract_Entity__c = 'New Value';
        Test.startTest();
        system.runAs(u){
            update q;
        }
        Test.stopTest();
    }
    
    static testMethod void testValidateRecordLockNonAdminError(){
        Quote q = [Select Id, Needs_PC_Approval__c, OwnerId FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        User u = [SELECT Id FROM User WHERE Id = :q.OwnerId limit 1];
        
        q.Needs_PC_Approval__c = 'No';
        try{
        	system.runAs(u){
            	update q;
        	}
        }
        catch(Exception e){
            System.debug(e.getMessage());
            system.assertEquals(e.getMessage().contains(Label.Quote_Record_Lock_Error),true);
        }
    }
    */
    //MDUNCAN END - 06.25.2018 - C-00231744 Removed logic in handler and disabled trigger per client request
}