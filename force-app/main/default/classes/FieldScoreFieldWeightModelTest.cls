/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@IsTest
public class FieldScoreFieldWeightModelTest {

   @TestSetup
    static void setupData(){
        Account testAccount = new Account(
            RecordTypeId = '0120X000000gKhsQAE', 
            Name = 'RadixBay1', 
            Country__c = 'United States', 
            Primary_Asset_Class__c = 'Credit',
            Pod_Account__c = false,
            Forum_Tier__c = '1',
            Investment_Instruments__c = 'Syndicated Loans;Corporate: High Yield'
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
        Field_Weight__c IIWeight = new Field_Weight__c (
            Credit_Weight__c = 20, 
            Public_Equity_Weight__c = 10, 
            Name = 'Investment Instruments'
        );
        insert IIWeight;
        Field_Score__c IIScore1 = new Field_Score__c (
            FieldName__c = 'Investment Instruments', 
            Value__c = 'Corporate: High Yield', 
            Score__c = 5, 
            Field_Weight__c = IIWeight.id
        );
        insert IIScore1;
        Field_Score__c IIScore2 = new Field_Score__c (
            FieldName__c = 'Investment Instruments', 
            Value__c = 'Syndicated Loans', 
            Score__c = 15, 
            Field_Weight__c = IIWeight.id
        );
        insert IIScore2;
        Account_Field_Score__c InvestmentInstrumentsConnection = new Account_Field_Score__c(
            Account__c = testAccount.id, 
            Field_Score__c = IIScore2.Id, 
            Weight_Score_Static__c = 4, 
            Field_Value__c = 'Syndicated Loans'
        );
        insert InvestmentInstrumentsConnection;
        

    }

    /*
    Test class for FSFW Model test to see to ensure when a Field Score score field is updated related AFS records are updated to include the new score 
    /**
    */
    @isTest
    private static void FieldScoreupdated(){
        //Grab FS records and related records to confirm their related
        Field_Score__c testscore= [select Id, Score__c from Field_Score__c LIMIT 1];
        Account_Field_Score__c relatedAFS = [select Id, Weight_Score_Static__c, Weight__c, Score__c from Account_Field_Score__c LIMIT 1];

        Double oldWeightScore = relatedAFS.Weight_Score_Static__c;
        Double oldScore = relatedAFS.Score__c;
        System.debug('AFS:' + oldScore + '   FS:' + testscore.Score__c);
        Assert.areEqual(testscore.Score__c, oldScore);


        Test.startTest();
        //Update the Score field on the FS record to trigger the After Update trigger
        testscore.Score__c = 15;
        update testscore;

        Test.stopTest();

        /*Regrab the related AFS records to confirm that the score,weighted score static has been updated
        */
        relatedAFS = [select Id, Weight_Score_Static__c, Weight__c, Score__c from Account_Field_Score__c LIMIT 1];
        Double newWeightScore = relatedAFS.Weight_Score_Static__c;
        Double newScore = relatedAFS.Score__c;
        Double weight = relatedAFS.Weight__c / 100;
        Assert.areEqual(testscore.Score__c, newScore);
        Assert.areNotEqual(newWeightScore, oldWeightScore);
        Assert.areEqual(newWeightScore, newScore * weight);
    }

    /*
    Test class for FSFW Model test to see to ensure when a Field Score score field is updated related AFS records are updated to include the new score 
    /**
    */
    @isTest
    private static void FieldScoreInvestmentInstrumentsUpdated(){
        //Grab FS records and related records to confirm their related
        Field_Score__c testscore = [select Id, Score__c from Field_Score__c WHERE Value__c = 'Syndicated Loans' LIMIT 1];
        Account_Field_Score__c relatedAFS = [select Id, Weight_Score_Static__c, Weight__c, Score__c from Account_Field_Score__c WHERE Field_Value__c = 'Syndicated Loans' LIMIT 1];
        Double investmentInstrumentValue = 0;

        Double oldWeightScore = relatedAFS.Weight_Score_Static__c;
        Double oldScore = relatedAFS.Score__c;
        System.debug('AFS:' + oldScore + '   FS:' + testscore.Score__c);
        Assert.areEqual(testscore.Score__c, oldScore);


        Test.startTest();
        //Update the Score field on the FS record to trigger the After Update trigger
        testscore.Score__c = 30;
        update testscore;

        Test.stopTest();

        /*Regrab the related AFS records to confirm that the score,weighted score static has been updated
        */
        Account testAccountVerify = [SELECT Id, Investment_Instruments__c FROM Account LIMIT 1];
        List<String> multiSelectValues = testAccountVerify.Investment_Instruments__c.split(';');
        List<Field_Score__c> fieldScores = [SELECT Id, FieldName__c, Value__c, Score__c FROM Field_Score__c WHERE FieldName__c = 'Investment Instruments' AND Value__c IN :multiSelectValues ORDER BY Score__c DESC];
        for( Field_Score__c score : fieldScores){
            investmentInstrumentValue += score.Score__c;
        }
        System.debug(investmentInstrumentValue);
        relatedAFS = [select Id, Weight_Score_Static__c, Weight__c, Score__c from Account_Field_Score__c WHERE Field_Value__c = 'Syndicated Loans' LIMIT 1];
        Double newWeightScore = relatedAFS.Weight_Score_Static__c;
        Double newScore = relatedAFS.Score__c;
        Double weight = relatedAFS.Weight__c / 100;
        Assert.areEqual(testscore.Score__c, newScore);
        Assert.areNotEqual(newWeightScore, oldWeightScore);
        Assert.areEqual(newWeightScore, investmentInstrumentValue * weight);
    }

    /*
    Test class for FSFW Model test to see to ensure when a Field Weight score field is updated related AFS records are updated to include the new weight value 
    /**
    */
    @isTest
    private static void FieldWeightInvestmentInstrumentsUpdated(){
        //Grab FW records and related records to confirm their related
        Field_Weight__c testweight = [select Id, Credit_Weight__c, Public_Equity_Weight__c from Field_Weight__c WHERE Name = 'Investment Instruments' LIMIT 1];
        Field_Score__c testscore= [select Id, Score__c from Field_Score__c WHERE Value__c = 'Syndicated Loans' LIMIT 1];
        Account_Field_Score__c relatedAFS = [select Id, Weight_Score_Static__c, Weight__c, Score__c from Account_Field_Score__c WHERE Field_Value__c = 'Syndicated Loans' LIMIT 1];
        Double investmentInstrumentValue = 0;

        Double originalWeightScore = relatedAFS.Weight_Score_Static__c;
        Double originalAFSWeight = relatedAFS.Weight__c;
        System.debug('AFS:' + originalAFSWeight + '   FW:' + testweight.Credit_Weight__c);
        Assert.areEqual(testweight.Credit_Weight__c, originalAFSWeight);


        Test.startTest();
        //Update the credit weight field on the FW record to trigger the After Update trigger
        testweight.Credit_Weight__c = 40;
        update testweight;

        Test.stopTest();

        Account testAccountVerify = [SELECT Id, Investment_Instruments__c FROM Account LIMIT 1];
        List<String> multiSelectValues = testAccountVerify.Investment_Instruments__c.split(';');
        List<Field_Score__c> fieldScores = [SELECT Id, FieldName__c, Value__c, Score__c FROM Field_Score__c WHERE FieldName__c = 'Investment Instruments' AND Value__c IN :multiSelectValues ORDER BY Score__c DESC];
        for( Field_Score__c score : fieldScores){
            investmentInstrumentValue += score.Score__c;
        }

        /*Regrab the related AFS records to confirm that the weight, weighted score static has been updated
        */
        relatedAFS = [select Id, Weight_Score_Static__c, Weight__c, Score__c from Account_Field_Score__c WHERE Field_Value__c = 'Syndicated Loans' LIMIT 1];
        Double updatedWeightScore = relatedAFS.Weight_Score_Static__c;
        Double score = investmentInstrumentValue;
        Double newWeight = relatedAFS.Weight__c / 100;
        //Converted to a decimal in order to round the value for testing.
        Decimal calculatedWeight = Decimal.valueOf(score * newWeight).setScale(1);
        System.debug('Original WSS: ' + originalWeightScore);
        System.debug('Updated WSS: ' + updatedWeightScore);
        System.debug('Updated Score: ' + score);
        System.debug('Updated Weight: ' + relatedAFS.Weight__c );
        System.debug('Updated WSS: ' + newWeight);
        Assert.areEqual(testweight.Credit_Weight__c, relatedAFS.Weight__c);
        Assert.areNotEqual(updatedWeightScore, originalWeightScore);
        //DEV NOTE: in intial testing, without rounding the right value, It was failing when comparing 1.2 and 1.2000000000000002
        Assert.areEqual(updatedWeightScore, calculatedWeight);
    }

    /*
    Test class for FSFW Model test to see to ensure when a Field Weight score field is updated related AFS records are updated to include the new weight value 
    /**
    */
    @isTest
    private static void FieldWeightupdated(){
        //Grab FW records and related records to confirm their related
        Field_Weight__c testweight = [select Id, Credit_Weight__c, Public_Equity_Weight__c from Field_Weight__c LIMIT 1];
        Field_Score__c testscore = [select Id, Score__c from Field_Score__c LIMIT 1];
        Account_Field_Score__c relatedAFS = [select Id, Weight_Score_Static__c, Weight__c, Score__c from Account_Field_Score__c LIMIT 1];

        Double originalWeightScore = relatedAFS.Weight_Score_Static__c;
        Double originalAFSWeight = relatedAFS.Weight__c;
        System.debug('AFS:' + originalAFSWeight + '   FW:' + testweight.Credit_Weight__c);
        Assert.areEqual(testweight.Credit_Weight__c, originalAFSWeight);


        Test.startTest();
        //Update the credit weight field on the FW record to trigger the After Update trigger
        testweight.Credit_Weight__c = 20;
        update testweight;

        Test.stopTest();

        /*Regrab the related AFS records to confirm that the weight, weighted score static has been updated
        */
        relatedAFS = [select Id, Weight_Score_Static__c, Weight__c, Score__c from Account_Field_Score__c LIMIT 1];
        Double updatedWeightScore = relatedAFS.Weight_Score_Static__c;
        Double score = relatedAFS.Score__c;
        Double newWeight = relatedAFS.Weight__c / 100;
        //Converted to a decimal in order to round the value for testing.
        Decimal calculatedWeight = Decimal.valueOf(score * newWeight).setScale(1);
        System.debug('Original WSS: ' + originalWeightScore);
        System.debug('Updated WSS: ' + updatedWeightScore);
        System.debug('Updated Score: ' + score);
        System.debug('Updated Weight: ' + relatedAFS.Weight__c );
        System.debug('Updated WSS: ' + newWeight);
        Assert.areEqual(testweight.Credit_Weight__c, relatedAFS.Weight__c);
        Assert.areNotEqual(updatedWeightScore, originalWeightScore);
        //DEV NOTE: in intial testing, without rounding the right value, It was failing when comparing 1.2 and 1.2000000000000002
        Assert.areEqual(updatedWeightScore, calculatedWeight);
    }
}