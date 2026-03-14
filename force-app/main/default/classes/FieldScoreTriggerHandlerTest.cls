/*
 * @description       : 
 * @author            : LeeWayne (RadixBay)
 * @group             : 
 * @last modified on  : 05-17-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
*/
@IsTest
public class FieldScoreTriggerHandlerTest {
    /*Test Setup */
    @TestSetup
    static void setupData(){
        Account testAccount = new Account(
            RecordTypeId = '0120X000000gKhsQAE', 
            Name = 'RadixBay1', 
            Country__c = 'United States',
            Territory__c = 'North America',
            Primary_Asset_Class__c = 'Credit',
            Pod_Account__c = false,
            Forum_Tier__c = '4'
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
            Value__c = 'Growth',
            Score__c = 6,
            Field_Weight__c = testweight.id
        );
        insert GrowthScore;

        Account_Field_Score__c Styleconnection = new Account_Field_Score__c(
            Account__c = testAccount.id,
            Field_Score__c = GrowthScore.Id,
            Weight_Score_Static__c = 0.6,
            Field_Value__c = 'Growth'
        );
        insert Styleconnection;

    }

    /* Test to confirm an Field Weight can be inserted */
    @isTest
    private static void fieldScoreInsert(){
        // Grab a Field Weight and create a new FS records to trigger the After Insert trigger
        Field_Weight__c testweight = [SELECT Id FROM Field_Weight__c LIMIT 1];
        Field_Score__c testscore = new Field_Score__c (
            FieldName__c = 'Style',
            Value__c = 'Test',
            Score__c = 6,
            Field_Weight__c = testweight.id
        );
        insert testscore;
    }
    /* Test to confirm an Field Weight can be updated */
    @isTest
    private static void fieldScoreUpdate(){
        // Grab FS records, then update one of the FS records to trigger the After Update trigger
        Field_Score__c testscore = [SELECT Id, Score__c FROM Field_Score__c LIMIT 1];
        testscore.Score__c = 15;
        update testscore;
    }

    /*
    * Test class for Account Ranking Model Field Score 
    * When the Score field is updated on a Field Score record, all related Account Field Score records will be updated with the new Score.
    * Also the Weight Score Static field on related Account Field Score should be updated to be WEIGHT * the NEW Score 
    */
    @isTest
    private static void AccountRankingScoreupdated(){
        // Grab FS records and related records to confirm their related
        Field_Score__c testscore= [SELECT Id, Score__c FROM Field_Score__c LIMIT 1];
        Account_Field_Score__c relatedAFS = [SELECT Id, Weight_Score_Static__c, Weight__c, Score__c FROM Account_Field_Score__c LIMIT 1];

        Double oldWeightScore = relatedAFS.Weight_Score_Static__c;
        Double oldScore = relatedAFS.Score__c;
        System.debug('AFS: ' + oldScore + '   FS: ' + testscore.Score__c);
        Assert.areEqual(testscore.Score__c, oldScore);

        // Update the Score field on the FS record to trigger the After Update trigger
        Test.startTest();{
        testscore.Score__c = 15;
        update testscore;
        }Test.stopTest();

        // Regrab the related AFS records to confirm that the score,weighted score static has been updated
        relatedAFS = [SELECT Id, Weight_Score_Static__c, Weight__c, Score__c FROM Account_Field_Score__c LIMIT 1];
        Double newWeightScore = relatedAFS.Weight_Score_Static__c;
        Double newScore = relatedAFS.Score__c;
        Double weight = relatedAFS.Weight__c / 100;
        Assert.areEqual(testscore.Score__c, newScore);
        Assert.areNotEqual(newWeightScore, oldWeightScore);
        Assert.areEqual(newWeightScore, newScore * weight);
    }

}