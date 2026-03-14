/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-10-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
private class FieldWeightTriggerHandlerTest {
    // Setup Test Data (only used during test, not commited to database)
    @TestSetup
    static void setupData(){
        Account testAccount = new Account(
            RecordTypeId = '0120X000000gKhsQAE', 
            Name = 'RadixBay1', 
            Country__c = 'United States',
            Territory__c = 'North America',
            Primary_Asset_Class__c = 'Equity',
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
            Value__c = 'Growth', 
            Score__c = 6,
            Field_Weight__c = testweight.id
        );
        insert GrowthScore;

        Account_Field_Score__c Styleconnection = new Account_Field_Score__c(
            Account__c = testAccount.id,
            Field_Score__c = GrowthScore.Id,
            Weight_Score_Static__c = 0.3,
            Field_Value__c = 'Growth'
        );
        insert Styleconnection;

    }

    /* Test to confirm a Field Weight can be inserted */
    @isTest
    private static void FieldWeightInsert(){
        Field_Weight__c testfieldweight = new Field_Weight__c(
            Name = 'Test 2', 
            Public_Equity_Weight__c = 25, 
            Credit_Weight__c = 25
        );
        insert testfieldweight;

        List<Field_Weight__c> weightcreated = [SELECT Id, Public_Equity_Weight__c FROM Field_Weight__c WHERE Name = 'Test 2' ];

        System.debug('# of Weight created: ' + weightcreated.size());
        System.assertEquals(weightcreated.size(), 1, 'Actual number of Weights created: ' + weightcreated.size());
    }
    /* Test to confirm a Field Weight can be updated */
    @isTest
    private static void FieldWeightUpdate(){
        Field_Weight__c testfieldweight = [SELECT Id, Public_Equity_Weight__c FROM Field_Weight__c LIMIT 1];
        testfieldweight.Public_Equity_Weight__c = 30;
        update testfieldweight;

        System.debug('Updated Weight: ' + testfieldweight.Public_Equity_Weight__c);
        System.assertEquals(testfieldweight.Public_Equity_Weight__c, 30, 'Actual weight set: ' + testfieldweight.Public_Equity_Weight__c);
    }

    /*
    * Test class for Account Ranking Model Field Weight 
    * When the Public Equity Weight field is updated on a Field Weight record, all related AFS records will be updated with the new Public Equity Weight.
    * Also the Weight Score Static field on related AFS should match the Weight Score field 
    */
    @isTest
    private static void AccountRankingWeightupdated(){
        Field_Weight__c testfieldweight = [SELECT Id, Public_Equity_Weight__c FROM Field_Weight__c LIMIT 1];
        Account_Field_Score__c relatedtestAFS = [SELECT Id, Weight_Score_Static__c,Weight__c,Weighted_Score__c FROM Account_Field_Score__c LIMIT 1];

        Double oldWeight = relatedtestAFS.Weight__c;
        Double oldweightscore = relatedtestAFS.Weighted_Score__c;
        System.debug('AFS:' + oldWeight + '   FS:'+testfieldweight.Public_Equity_Weight__c);
        System.assertEquals(testfieldweight.Public_Equity_Weight__c, oldWeight, 'AFS Weight doesnt match weight FROM field weight record');

        //Update weight field
        Test.startTest();{
            
        
        testfieldweight.Public_Equity_Weight__c = 35;
        update testfieldweight; 
            
        }
        Test.stopTest();

        relatedtestAFS = [SELECT Id, Weight_Score_Static__c, Weight__c, Weighted_Score__c FROM Account_Field_Score__c LIMIT 1];
        Double newWeight = relatedtestAFS.Weight__c;
        Double newweightScore = relatedtestAFS.Weighted_Score__c;
        Double weightscorestatic = relatedtestAFS.Weight_Score_Static__c;

        System.debug('AFS:' + newWeight + '   FS:' + testfieldweight.Public_Equity_Weight__c);
        System.assertEquals(testfieldweight.Public_Equity_Weight__c, newWeight, 'Weight wasnt updated with new weight');
        System.assertNotEquals(newWeight, oldWeight, 'New & Old Weight Matches on AFS');
        System.debug('New Weight Score: ' + newWeightScore + '   New Weight Static: ' + weightscorestatic);
        System.assertEquals(newWeightScore, weightscorestatic, 'Static Weight wasnt updated with new weight');
    }

}