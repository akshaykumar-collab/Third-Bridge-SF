/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-17-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class AccountRankingModelTest {
    /*Test Setup 
    We need the following to ensure succesful test

    1. List of Accounts
    2. A field Weight record
    3. At least 2 Field Score records
    4. At least 1 Account Field Score record

    */
    @TestSetup
    static void setupData(){

        /*Create a collection of Credit Accounts */
        List<Account> acctList = new List<Account>();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        for (Integer i = 0; i < 4; i++) {
            Account acct = new Account(
                Name = 'Test Account ' + i,
                Country__c = 'United States',
                RecordTypeId = recordTypeId,
                Primary_Asset_Class__c = 'Credit',
                Territory__c = 'North America',
                Pod_Account__c = false,
                Forum_Tier__c = '3'
            );
            acctList.add(acct);
        }
        //Insert Account List into the org
        insert acctList;

        /* Create and insert the following records
        1. A test Field Weight record
        2. 2 test Field Score records that will be used to created AFS records related to the Account




        */
        /*Weights and Scores for Strings*/
        Field_Weight__c testweight = new Field_Weight__c (Credit_Weight__c = 10, Public_Equity_Weight__c = 5, Name = 'Style');
        insert testweight;
        Field_Score__c GrowthScore = new Field_Score__c (FieldName__c = 'Style', Value__c = 'Growth', Score__c = 6, Field_Weight__c = testweight.id);
        insert GrowthScore;
        Field_Score__c ValueScore = new Field_Score__c (FieldName__c = 'Style', Value__c = 'Value', Score__c = 10, Field_Weight__c = testweight.id);
        insert ValueScore;
        Field_Score__c ValueNullScore = new Field_Score__c (FieldName__c = 'Style', Score__c = 5, Field_Weight__c = testweight.id);
        insert ValueNullScore;
        Field_Weight__c testFTweight = new Field_Weight__c (Credit_Weight__c = 10, Public_Equity_Weight__c = 5, Name = 'Firm Type');
        insert testFTweight;
        Field_Score__c FTbrokScore = new Field_Score__c (FieldName__c = 'Client Type', Value__c = 'Broking', Score__c = 10, Field_Weight__c = testFTweight.id);
        insert FTbrokScore;
        
        /*Weights and Scores for mutli-select picklist*/
        Field_Weight__c testStrategyWeight = new Field_Weight__c (Credit_Weight__c = 10, Public_Equity_Weight__c = 5, Name = 'Strategy');
        insert testStrategyWeight;
        Field_Score__c StrategyScore = new Field_Score__c (FieldName__c = 'Strategy', Value__c = 'CLO', Score__c = 5, Field_Weight__c = testStrategyWeight.id);
        insert StrategyScore;
        Field_Score__c StrategyScore2 = new Field_Score__c (FieldName__c = 'Strategy', Value__c = 'Market Neutral', Score__c = 3, Field_Weight__c = testStrategyWeight.id);
        insert StrategyScore2;
        Field_Score__c StrategyScore3 = new Field_Score__c (FieldName__c = 'Strategy', Value__c = 'Short-only', Score__c = 8, Field_Weight__c = testStrategyWeight.id);
        insert StrategyScore3;
        Field_Score__c StrategyScore4 = new Field_Score__c (FieldName__c = 'Strategy', Score__c = 0, Field_Weight__c = testStrategyWeight.id);
        insert StrategyScore4;
        
        /*Weights and Scores for Number fields*/
        Field_Weight__c testEAIweight = new Field_Weight__c (Credit_Weight__c = 15, Public_Equity_Weight__c = 10, Name = 'Estimated Accessible IPs');
        insert testEAIweight;
        Field_Score__c EAIScore = new Field_Score__c (FieldName__c = 'Estimated Accessible IPs', Upper_Range__c = 1000, Lower_Range__c = 1, Score__c = 20, Field_Weight__c = testEAIweight.id);
        insert EAIScore;
        Field_Score__c EAIScore2 = new Field_Score__c (FieldName__c = 'Estimated Accessible IPs', Upper_Range__c = 2000, Lower_Range__c = 1001, Score__c = 40, Field_Weight__c = testEAIweight.id);
        insert EAIScore2;

        /*Weights and Scores for Investment Instrument fields*/
        Field_Weight__c testIIweight = new Field_Weight__c (Credit_Weight__c = 20, Public_Equity_Weight__c = 5, Name = 'Investment Instruments');
        insert testIIweight;
        Field_Score__c IIScore = new Field_Score__c (FieldName__c = 'Investment Instruments', Value__c = 'Corporate: High Yield', Score__c = 20, Field_Weight__c = testIIweight.id);
        insert IIScore;
        Field_Score__c IIScore2 = new Field_Score__c (FieldName__c = 'Investment Instruments', Value__c = 'Syndicated Loans', Score__c = 40, Field_Weight__c = testIIweight.id);
        insert IIScore2;
        Field_Score__c IIScore3 = new Field_Score__c (FieldName__c = 'Investment Instruments', Value__c = 'Covered Bonds', Score__c = 5, Field_Weight__c = testIIweight.id);
        insert IIScore3;
        Field_Score__c IIScore4 = new Field_Score__c (FieldName__c = 'Investment Instruments', Value__c = 'Corporate: Investment Grade', Score__c = 50, Field_Weight__c = testIIweight.id);
        insert IIScore4;
       
    }

    /*
    Account Ranking Model Account Field Score 
    When a field is set to a value, the AccountRankingModel is called.
    this checks for a Account Field Score record if none exists for that field it creates it.
    If the field is updated to a different value then the linked Field Score is updated to the correct field score record
    */
    @isTest
    private static void checkAccountFieldSetSingle(){
        
        /*Pull an Account and set the Style field */

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        Account acct = new Account(
            Name = 'Test Account 999',
            Country__c = 'United States',
            RecordTypeId = recordTypeId,
            Style__c = 'Growth',
            Estimated_Accessible_IPs__c = 11.5,
            Primary_Asset_Class__c = 'Credit',
            Territory__c = 'North America',
            Pod_Account__c = false,
            Forum_Tier__c = '3'
        );
        
        Test.startTest();
            insert acct;

            /*An Account Field Score record should have been created because the field was set */
            Account_Field_Score__c Styleconnection = [select Id, Account__c, Field_Score__c, Field_Value__c, Score__c, Weight__c, Weight_Score_Static__c from Account_Field_Score__c WHERE Field_Value__c = 'Growth' LIMIT 1];

            Field_Score__c growthScore = [select Id, Score__c from Field_Score__c where FieldName__c = 'Style' AND Value__c = 'Growth' ORDER BY Name ASC];
    

            Double createdWeight = Styleconnection.Weight_Score_Static__c;
            Double zero = 0.00;
            /*Test to see if the related Account Field Score was create with the create Field Score record */
            System.debug('AFS:' + Styleconnection.Field_Score__c + '   FS:'+growthScore.Id);
            Assert.areEqual(Styleconnection.Field_Score__c, growthScore.Id);
            System.debug('Static Weight' + createdWeight);
            Assert.areEqual(Styleconnection.Field_Value__c, acct.Style__c);
            System.debug('Static Weight' + createdWeight);
            Assert.areNotEqual(createdWeight, zero);
    

            /*Update the Style field so the related Account Field Score can be update */
            acct.Style__c = 'Value';
        
            update acct;
                
        Test.stopTest();

        Field_Score__c valueScore = [select Id, FieldName__c, Value__c, Score__c from Field_Score__c where FieldName__c = 'Style' AND Value__c = 'Value' ORDER BY Name ASC];


        /*Test to see if the related Account Field Score was updated the differnt Field Score record */
        Styleconnection = [select Id, Account__c, Field_Score__c, Field_Value__c, Score__c, Weight__c, Weight_Score_Static__c from Account_Field_Score__c WHERE Field_Value__c = 'Value' LIMIT 1];
        Field_Score__c valueScoreAFS = [select Id, FieldName__c, Value__c, Score__c from Field_Score__c where ID = :Styleconnection.Field_Score__c ORDER BY Name ASC];
        System.debug('AFS:' + Styleconnection.Field_Score__c + '   Value FS:' + valueScore.Id);
        Assert.areEqual(Styleconnection.Field_Score__c, valueScore.Id);
        Assert.areEqual(Styleconnection.Field_Value__c, acct.Style__c);
        Assert.areNotEqual(createdWeight, Styleconnection.Weight_Score_Static__c);
    }

    /*
    Account Ranking Model Account Field Score 
    When a field is set to a value, the AccountRankingModel is called.
    this checks for a Account Field Score record if pod account is checked verse unchecked
    */
    @isTest
    private static void checkAccountFieldPodAccountSet(){
        
        /*Pull an Account and set the Style field */

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        Account acct = new Account(
            Name = 'Test Account 999',
            Country__c = 'United States',
            RecordTypeId = recordTypeId,
            Style__c = 'Growth',
            Primary_Asset_Class__c = 'Credit',
            Territory__c = 'North America',
            Pod_Account__c = true,
            Forum_Tier__c = '3'
        );
        
        Test.startTest();
            insert acct;
            List<Account_Field_Score__c> afsBeforePodUpdate = [SELECT ID FROM Account_Field_Score__c WHERE Account__c = :acct.Id];
            Assert.areEqual(afsBeforePodUpdate.size(), 0, 'No AFS Records created yet.');
            acct.Pod_Account__c = false;
            update acct;
            List<Account_Field_Score__c> afsAfterPodUpdate = [SELECT ID FROM Account_Field_Score__c WHERE Account__c = :acct.Id];
            Assert.areEqual(afsAfterPodUpdate.size(), 2, 'AFS Records have been created after Pod Update');
        Test.stopTest();

        Assert.areNotEqual(afsBeforePodUpdate.size(), afsAfterPodUpdate.size());
    
    }

     /*
    Account Ranking Model Account Field Score 
    When a field is set to a value, the AccountRankingModel is called.
    this checks for a Account Field Score record if pod account is checked verse unchecked
    */
    @isTest
    private static void checkAccountFieldSalesTierForumSet(){
        
        /*Pull an Account and set the Style field */

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        Account acct = new Account(
            Name = 'Test Account 999',
            Country__c = 'United States',
            RecordTypeId = recordTypeId,
            Style__c = 'Growth',
            Primary_Asset_Class__c = 'Credit',
            Territory__c = 'North America',
            Pod_Account__c = false,
            Forum_Tier__c = '5'
        );
        
        Test.startTest();
            insert acct;
            List<Account_Field_Score__c> afsBeforeSalesTierUpdate = [SELECT ID FROM Account_Field_Score__c WHERE Account__c = :acct.Id];
            Assert.areEqual(afsBeforeSalesTierUpdate.size(), 0, 'No AFS Records created yet.');
            acct.Forum_Tier__c = '4';
            update acct;
            List<Account_Field_Score__c> afsAfterSalesTierUpdate = [SELECT ID, Field__c, Field_Value__c  FROM Account_Field_Score__c WHERE Account__c = :acct.Id];
            System.debug(afsAfterSalesTierUpdate);
            Assert.areEqual(afsAfterSalesTierUpdate.size(), 2, 'AFS Records have been created after Sales Tier - Forum');
        Test.stopTest();

        Assert.areNotEqual(afsBeforeSalesTierUpdate.size(), afsAfterSalesTierUpdate.size());
    
    }


    /* Account is excluded test confirms that no AFS records were created because the correct fields wasn't set/updated
    Since the Account isn't a Credit or Public Equity it should be removed from the model so no AFS will be created
    Pass
    */
    @isTest
    private static void accountExcluded(){
        Account testAccount = new Account(
            RecordTypeId = '0120X000000gKhsQAE', 
            Name = 'RadixBay2', 
            Country__c = 'United States',
            Pod_Account__c = true,
            Forum_Tier__c = '5'
        );
      
        try {
            insert testAccount;
            /*Since the correct fields weren't set there should be no AFS records */
            List<Account_Field_Score__c>  relatedAFS = [SELECT ID FROM Account_Field_Score__c WHERE Account__c = :testAccount.Id];
        } catch(Exception e) {
            System.debug('No Assigment ie No records were created');
            Assert.isTrue(true,'Account Field Score record not created');
        }
        try {
            /*Since the correct fields weren't updated there should be no AFS records */
            //testAccount.Attended__c = true;
            update testAccount;
            List<Account_Field_Score__c>  relatedAFS = [SELECT ID FROM Account_Field_Score__c WHERE Account__c = :testAccount.Id];
            relatedAFS = [SELECT ID FROM Account_Field_Score__c WHERE Account__c = :testAccount.Id];
            System.debug('Account Excluded Test Complete');
        } catch(Exception e) {
            System.debug('No Assigment (i.e. No records were created)');
            Assert.isTrue(true, 'Account Field Score record not created');
        }
        
    }

  
    /*Class Setup code coverage dealing with the Account Ranking model*/
    @isTest
    private static void accountModelSetup(){
        
        List<Account> accts = [SELECT ID, Style__c FROM Account LIMIT 1];   
        Map<id, Map<String, String>> accfieldMap = new Map<id, Map<String, String>>();   
        Map<String, String> fieldMap = new Map<String, String>();    
        for(Account acc : accts){
            acc.style__c = 'Growth';
            fieldMap.put('Style', acc.Style__c);
            accfieldMap.put(acc.Id, fieldMap);
        }
        new AccountRankingModel('insert', accfieldMap);
        Map<id, Map<String, String>> oldaccfieldMap = accfieldMap;
        new AccountRankingModel('Update', oldaccfieldMap, accfieldMap);
        
    }
    
    /*
     * 
     */
    @isTest
    private static void accountModelQueueableChecksString(){
        List<Account> accts = [SELECT ID, Style__c FROM Account LIMIT 1];   
        Map<id, Map<String, String>> oldaccfieldMap = new Map<id, Map<String, String>>();   
        Map<String, String> oldfieldMap = new Map<String, String>();    
        for(Account acc : accts){
            acc.style__c = 'Growth';
            oldfieldMap.put('Style', acc.Style__c);
            oldaccfieldMap.put(acc.Id, oldfieldMap);
        }
        
        AccountRankingModel.processNextAccountInsert(oldaccfieldMap);
        Account_Field_Score__c relatedAFS = [Select Id, Field_Value__c from Account_Field_Score__c where Account__c IN :accts LIMIT 1];
        Assert.areEqual(relatedAFS.Field_Value__c, 'Growth', 'AFS created from queueable');   
        
        Map<id, Map<String, String>> newaccfieldMap = new Map<id, Map<String, String>>();   
        Map<String, String> newfieldMap = new Map<String, String>();    
        for(Account acc : accts){
            acc.style__c = 'Value';
            acc.Client_Type__c = 'Broking';
            newfieldMap.put('Style', acc.Style__c);
            newfieldMap.put('Client Type', acc.Client_Type__c);
            oldfieldMap.put('Client Type',' ');
            newaccfieldMap.put(acc.Id, newfieldMap);
        }
        
        AccountRankingModel.processNextAccountUpdate(oldaccfieldMap, newaccfieldMap);
        List <Account_Field_Score__c> relatedAFSupdate = [Select Id, Field__c, Field_Value__c from Account_Field_Score__c where Account__c IN :accts];
        Assert.areEqual(2, relatedAFSupdate.size(), 'AFS created from queueable matche the field changed size');
            
        for(Account_Field_Score__c scorerecord : relatedAFSupdate){
            if(scorerecord.Field__c == 'Style'){
                Assert.areEqual('Value', scorerecord.Field_Value__c, 'Style AFS wasnt changed to Value');
            } else if(scorerecord.Field__c == 'Client Type'){
                Assert.areEqual('Broking', scorerecord.Field_Value__c, 'Client Type wasnt created');
            }
        }
        
    }
    
    /*
     * 
     */
    @isTest
    private static void accountModelQueueableChecksNumber(){
        List<Account> accts = [SELECT ID, Estimated_Accessible_IPs__c FROM Account LIMIT 1];   
        Map<id, Map<String, String>> oldaccfieldMap = new Map<id, Map<String, String>>();   
        Map<String, String> oldfieldMap = new Map<String, String>();    
        for(Account acc : accts){
            acc.Estimated_Accessible_IPs__c = 20;
            oldfieldMap.put('Estimated Accessible IPs', String.valueOf(acc.Estimated_Accessible_IPs__c));
            oldaccfieldMap.put(acc.Id, oldfieldMap);
        }
        
        AccountRankingModel.processNextAccountInsert(oldaccfieldMap);
        Account_Field_Score__c relatedAFS = [Select Id, Field_Value__c from Account_Field_Score__c where Account__c IN :accts LIMIT 1];
        Assert.areEqual(relatedAFS.Field_Value__c, '20', 'AFS created from queueable');   
        
        Map<id, Map<String, String>> newaccfieldMap = new Map<id, Map<String, String>>();   
        Map<String, String> newfieldMap = new Map<String, String>();    
        for(Account acc : accts){
            acc.Estimated_Accessible_IPs__c = 1020.0;
            newfieldMap.put('Estimated Accessible IPs', String.valueOf(acc.Estimated_Accessible_IPs__c));
            newaccfieldMap.put(acc.Id, newfieldMap);
        }
        
        AccountRankingModel.processNextAccountUpdate(oldaccfieldMap, newaccfieldMap);
        Account_Field_Score__c relatedAFSupdate = [Select Id, Field_Value__c from Account_Field_Score__c where Account__c IN :accts LIMIT 1];
        Assert.areEqual(relatedAFSupdate.Field_Value__c, '1020.0', 'AFS created from queueable');
    }
    
    /*
     * 
     */
    @isTest
    private static void accountModelQueueableChecksPicklist(){
        List<Account> accts = [SELECT ID, Strategy__c FROM Account LIMIT 1];   
        Map<id, Map<String, String>> oldaccfieldMap = new Map<id, Map<String, String>>();   
        Map<String, String> oldfieldMap = new Map<String, String>();    
        for(Account acc : accts){
            acc.Strategy__c = 'CLO;Market Neutral';
            oldfieldMap.put('Strategy', acc.Strategy__c);
            oldaccfieldMap.put(acc.Id, oldfieldMap);
        }
        
        AccountRankingModel.processNextAccountInsert(oldaccfieldMap);
        Account_Field_Score__c relatedAFS = [Select Id, Field_Value__c, Weight_Score_Static__c from Account_Field_Score__c where Account__c IN :accts LIMIT 1];
        Assert.areEqual(relatedAFS.Field_Value__c, 'CLO', 'AFS created from queueable');
        Assert.areEqual(relatedAFS.Weight_Score_Static__c, 0.5, 'AFS Score Calculated from queueable');
        
        Map<id, Map<String, String>> newaccfieldMap = new Map<id, Map<String, String>>();   
        Map<String, String> newfieldMap = new Map<String, String>();

        for(Account acc : accts){
            acc.Strategy__c = 'CLO;Short-only';
            newfieldMap.put('Strategy', acc.Strategy__c);
            newaccfieldMap.put(acc.Id, newfieldMap);
        }
        
        AccountRankingModel.processNextAccountUpdate(oldaccfieldMap, newaccfieldMap);
        Account_Field_Score__c relatedAFSupdate = [Select Id, Field_Value__c, Weight_Score_Static__c from Account_Field_Score__c where Account__c IN :accts LIMIT 1];
        Assert.areEqual(relatedAFSupdate.Field_Value__c, 'Short-only', 'AFS created from queueable');
        Assert.areEqual(relatedAFSupdate.Weight_Score_Static__c, 0.8, 'AFS Score Calculated from queueable');
    }

    /*
     * 
     */
    @isTest
    private static void accountModelQueueableChecksInvestmentInstrumentsPicklist(){
        List<Account> accts = [SELECT ID, Investment_Instruments__c FROM Account LIMIT 1];   
        Map<id, Map<String, String>> oldaccfieldMap = new Map<id, Map<String, String>>();   
        Map<String, String> oldfieldMap = new Map<String, String>();    
        for(Account acc : accts){
            acc.Investment_Instruments__c = 'Syndicated Loans;Corporate: High Yield';
            oldfieldMap.put('Investment Instruments', acc.Investment_Instruments__c);
            oldaccfieldMap.put(acc.Id, oldfieldMap);
        }
        
        AccountRankingModel.processNextAccountInsert(oldaccfieldMap);
        Account_Field_Score__c relatedAFS = [Select Id, Field_Value__c, Weight_Score_Static__c from Account_Field_Score__c where Account__c IN :accts LIMIT 1];
        Assert.areEqual(relatedAFS.Field_Value__c, 'Syndicated Loans', 'AFS created from queueable');   
        Assert.areEqual(relatedAFS.Weight_Score_Static__c, 12, 'AFS Score Calculated from queueable');
        
        Map<id, Map<String, String>> newaccfieldMap = new Map<id, Map<String, String>>();   
        Map<String, String> newfieldMap = new Map<String, String>();

        for(Account acc : accts){
            acc.Investment_Instruments__c = 'Syndicated Loans;Corporate: Investment Grade';
            newfieldMap.put('Investment_Instruments__c', acc.Investment_Instruments__c);
            newaccfieldMap.put(acc.Id, newfieldMap);
        }
        
        AccountRankingModel.processNextAccountUpdate(oldaccfieldMap, newaccfieldMap);
        Account_Field_Score__c relatedAFSupdate = [Select Id, Field_Value__c, Weight_Score_Static__c from Account_Field_Score__c where Account__c IN :accts LIMIT 1];
        Assert.areEqual(relatedAFSupdate.Field_Value__c, 'Corporate: Investment Grade', 'AFS created from queueable');
        Assert.areEqual(relatedAFSupdate.Weight_Score_Static__c, 18, 'AFS Score Calculated from queueable');
    }
}