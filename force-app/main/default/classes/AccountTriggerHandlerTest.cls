/**
 * @description       : 
 * @author            : LeeWayne (RadixBay)
 * @group             : 
 * @last modified on  : 05-17-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class AccountTriggerHandlerTest {
    
    /*Test Setup */
    @TestSetup
    static void setupData(){

        Id prospectId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();

        Account testAccount = new Account(
            RecordTypeId = prospectId,
            Name = 'RadixBay1',
            Country__c = 'United States',
            Territory__c = 'North America',
            Primary_Asset_Class__c = 'Credit',
            Pod_Account__c = false,
            Forum_Tier__c = '2'
        );
        insert testAccount;

        Field_Weight__c testweight = new Field_Weight__c (
            Credit_Weight__c = 10,
            Public_Equity_Weight__c = 5,
            Name = 'Style'
        );
        insert testweight;

        Field_Score__c GrowthScore = new Field_Score__c (
            FieldName__c = 'Style',
            Value__c= 'Growth',
            Score__c = 6,
            Field_Weight__c = testweight.id
        );
        Field_Score__c ValueScore = new Field_Score__c (
            FieldName__c = 'Style',
            Value__c = 'Value',
            Score__c = 10,
            Field_Weight__c = testweight.id
        );
        
        insert GrowthScore;
        insert ValueScore;
    
    }
    /*Test to confirm an Account can be inserted */
    @isTest
    private static void accountInsert(){
        // Create an Account, then insert the Account in order to execute the Before Insert & After Insert triggers.
        Account testAccount = new Account(
            RecordTypeId = '0120X000000gKhsQAE', 
            Name = 'RadixBay2', 
            Primary_Asset_Class__c = 'Credit',
            Country__c = 'United States',
            Territory__c = 'North America',
            Pod_Account__c = false,
            Forum_Tier__c = '2'
        );
        insert testAccount;
    }

    /*Test to confirm an Account can be updated */
    @isTest
    private static void accountUpdate(){
        // Pull an Account, update a field then update the Account to trigger the Before Update & After update triggers
        Account testaccount = [select Id, Name, Country__c from Account LIMIT 1];
        testaccount.Country__c = 'Aland Islands';
        update testaccount;
    }

    /*
    Account Ranking Model Account Field Score 
    When a field is set to a value, the AccountRankingModel is called.
    This checks for a Account Field Score record, if none exists for that field, it creates it.
    If the field is updated to a different value, then the linked Field Score is updated to the correct field score record.
    */
    @isTest
    private static void checkAccountScore(){
        
        /*Pull an Account and set the Style field */
        Test.startTest();        
            Account testaccount = [select Id, Style__c from Account LIMIT 1];
            testaccount.Style__c = 'Growth';
            update testaccount;
            System.debug('TESTING TESTING UPDATE');
        Test.stopTest();
        
        /*An Account Field Score record should have been created because the field was set */
        Account_Field_Score__c Styleconnection = [select Id, Account__c, Field_Score__c, Field_Value__c, Score__c, Weight__c, Weighted_Score__c, Weight_Score_Static__c from Account_Field_Score__c LIMIT 1];

        List<Field_Score__c> StyleScore = [select Id, Score__c from Field_Score__c where FieldName__c = 'Style' AND Value__c = 'Growth' ORDER BY Name ASC];
        Field_Score__c growthScore = StyleScore[0];

        Double createdWeight = Styleconnection.Weight_Score_Static__c;
        /*Test to see if the related Account Field Score was create with the create Field Score record */
        System.debug('AFS:' + Styleconnection.Field_Score__c + '   FS:' + growthScore.Id);
        Assert.areEqual(Styleconnection.Field_Score__c, growthScore.Id);
        Assert.areEqual(Styleconnection.Field_Value__c, testaccount.Style__c);
        Assert.areEqual(Styleconnection.Weight_Score_Static__c, Styleconnection.Weighted_Score__c);

    }
}