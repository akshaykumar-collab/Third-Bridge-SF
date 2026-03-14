/**
 * @description       : 
 * @author            : Kyle (RadixBay)
 * @group             : 
 * @last modified on  : 05-15-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class FieldScoreFieldWeightModel implements Queueable{

    public String executionType = '';
    List<ID> fieldsToUpdate;

    
    public FieldScoreFieldWeightModel(String executionType, List<ID> fieldsToUpdate){
        this.executionType = executionType;
        this.fieldsToUpdate = fieldsToUpdate;
    }

    //Queueable class that executes the account updates through batches 
    public void execute(System.QueueableContext ctx){
        if (executionType.equals('score')){
            fieldScoreUpdatesQueue(fieldsToUpdate);
        }
    }
    
    //Field Score Change Setup
    public static void setupFieldScoreChanges(Map<Id, SObject> oldFieldScoreValues, Map<Id, SObject> newFieldScoreValues){
        
        Map<Id, Field_Score__c> fieldScoreBeforeUpdate = new Map<Id, Field_Score__c>();
        Map<Id, Field_Score__c> fieldScoreAfterUpdate = new Map<Id, Field_Score__c>();
        Map<Id, Field_Score__c> newMap = (Map<Id, Field_Score__c>)newFieldScoreValues;
        Map<Id, Field_Score__c> oldMap = (Map<Id, Field_Score__c>)oldFieldScoreValues;

        // Iterate over the incoming Maps and copy them to Maps we will use in the Model.
        for(Field_Score__c fs : newMap.values()){
            if (oldFieldScoreValues != null){
                fieldScoreBeforeUpdate.put(fs.Id, oldMap.get(fs.Id));
            }
                fieldScoreAfterUpdate.put(fs.Id, fs); 
        }

        List<Id> fieldScoreIDsToUpdate = new List<Id> (fieldScoreAfterUpdate.keySet());
        Map<Integer, Id> fieldScoreMapForLoop = new Map<Integer, Id>();

        for(Integer fsi = 0; fsi < fieldScoreAfterUpdate.size(); fsi++){
            fieldScoreMapForLoop.put(fsi, fieldScoreIDsToUpdate.get(fsi));
        }

        List<ID> fieldScoresChanged = new List<ID>();
        
        // This loop parses through both incoming Account Maps and determines the fields that were updated.
        // We only check the relative Field Score values set on the account. 
        for(Integer i = 0; i < fieldScoreAfterUpdate.size(); i++){                    
            // Possible rewrite for this needed to support the Map Datatypes coming in.
            ID accountMapId = fieldScoreMapForLoop.get(i);
            Field_Score__c oldFieldScoreValue = fieldScoreBeforeUpdate.get(accountMapId);
            Field_Score__c newFieldScoreValue = fieldScoreAfterUpdate.get(accountMapId);

            if (oldFieldScoreValue.Score__c != newFieldScoreValue.Score__c){
                fieldScoresChanged.add(newFieldScoreValue.Id);
            }
        }

        if (!fieldScoresChanged.isEmpty()){
            initialFieldScoreUpdates(fieldScoresChanged);
        }

    }
    //Field Weight Change Setup
    public static void setupFieldWeightChanges(Map<Id, SObject> oldFieldWeightValues, Map<Id, SObject> newFieldWeightValues){
        
        Map<Id, Field_Weight__c> fieldWeightBeforeUpdate = new  Map<Id, Field_Weight__c>();
        Map<Id, Field_Weight__c> fieldWeightAfterUpdate = new  Map<Id, Field_Weight__c>();
        Map<Id, Field_Weight__c> newMap = (Map<Id, Field_Weight__c>)newFieldWeightValues;
        Map<Id, Field_Weight__c> oldMap = (Map<Id, Field_Weight__c>)oldFieldWeightValues;

        // Iterate over the incoming Maps and copy them to Maps we will use in the Model.
        for(Field_Weight__c fw : newMap.values()){
            if (oldFieldWeightValues != null){
                fieldWeightBeforeUpdate.put(fw.Id, oldMap.get(fw.Id));
            }
                fieldWeightAfterUpdate.put(fw.Id, fw); 
        }

        List<Id> fieldWeightIDsToUpdate = new List<Id> (fieldWeightAfterUpdate.keySet());

        List<ID> fieldWeightsChanged = new List<ID>();
        
        // This loop parses through both incoming Account Maps and determines the fields that were updated.
        // We only check the relative Field Score values set on the account. 
        for(Integer i = 0; i < fieldWeightAfterUpdate.size(); i++){                    
            // Possible rewrite for this needed to support the Map Datatypes coming in.
            ID accountMapId = fieldWeightIDsToUpdate.get(i);
            Field_Weight__c oldFieldWeightValue = fieldWeightBeforeUpdate.get(accountMapId);
            Field_Weight__c newFieldWeightValue = fieldWeightAfterUpdate.get(accountMapId);

            
            if ((oldFieldWeightValue.Credit_Weight__c != newFieldWeightValue.Credit_Weight__c) || oldFieldWeightValue.Public_Equity_Weight__c != newFieldWeightValue.Public_Equity_Weight__c){
                fieldWeightsChanged.add(newFieldWeightValue.Id);
            }
        }

        if (!fieldWeightsChanged.isEmpty()){
            List<Field_Score__c> fieldScoresToUpdate = [SELECT Id from Field_Score__c WHERE Field_Weight__c IN :fieldWeightsChanged];
            List<ID> fieldScoreRecordIDs = new List<ID>();
            for (Field_Score__c fieldScore : fieldScoresToUpdate){
                fieldScoreRecordIDs.add(fieldScore.Id);
            }
            initialFieldScoreUpdates(fieldScoreRecordIDs);
        }

    }

    /* 
     * This method only runs once at the start of every change. If this is not done, the first request is ran synchronously.
     * This would cause potential issues with Apex CPU Timeout limits. This runs the first call asynchronously so that we have 60 seconds
     * to perform a round of AFS record updates. Every round in the Queueable context after this will be asynchronous as well.
     */  
    @future
    private static void initialFieldScoreUpdates(List<Id> fieldScoreIDsToUpdate){

        List<Id> fieldScoreIDsRemaining = fieldScoreUpdates(fieldScoreIDsToUpdate);

        if(!fieldScoreIDsRemaining.isEmpty()){
            fieldScoreUpdatesQueue(fieldScoreIDsRemaining);
        }

    }

    private static void fieldScoreUpdatesQueue(List<Id> fieldScoreIDsToUpdate){

        List<Id> fieldScoreIDsRemaining = fieldScoreUpdates(fieldScoreIDsToUpdate);

        if(!fieldScoreIDsRemaining.isEmpty()){
            String type = 'score';
            List<ID> queueID = new List<ID>();
            queueID.add(System.enqueueJob(new FieldScoreFieldWeightModel(type, fieldScoreIDsRemaining)));
        }

    }

    // The main logic used to update Field Scores.
    private static List<Id> fieldScoreUpdates(List<Id> fieldScoreIDsToUpdate){

        List<ID> fieldScoreIDBatch = new List<ID>();

        // If we hit 50 field score records, stop adding records and queue the rest for another run.
        Integer i = 0;
        for (ID fieldScoreID : fieldScoreIDsToUpdate){
            if(i != 2){
                fieldScoreIDBatch.add(fieldScoreID);
                i++;
            }
        }
        System.debug('Initial list size: ' + fieldScoreIDsToUpdate.size());
        System.debug('ID list size: ' + fieldScoreIDBatch.size());

        List<Account_Field_Score__c> accountFieldScoresToUpdate = [SELECT Id, Field__c, Account__c, Weighted_Score__c, Weight__c, Weight_Score_Static__c FROM Account_Field_Score__c WHERE Field_Score__c IN :fieldScoreIDBatch];

        // This static field is derived from the Weighted_Score__c formula field. This is used in the Account Priority rank calculation on the account.
        // The Weighted score on the account record is a rollup field from the Weight_Score_Static__c field.
        for(Account_Field_Score__c accountFieldScore : accountFieldScoresToUpdate){
            // If the Field in question is Investment Instruments, then we must make the sum calculation for the field score numbers, instead of direct update.
            if (accountFieldScore.Field__c == 'Investment Instruments'){
                Double investmentInstrumentSum = 0;
                Boolean accountHF = false;
                Account accountToUpdate = [SELECT Id, Investment_Instruments__c, Client_Type__c FROM Account WHERE Id =:accountFieldScore.Account__c LIMIT 1];

                if (accountToUpdate.Client_Type__c == 'Hedge Fund'){
                    accountHF = true;
                }

                List<String> investmentInstrumentFieldScores = accountToUpdate.Investment_Instruments__c.split(';');

                List<Field_Score__c> highestFieldScore = [SELECT Id, FieldName__c, Value__c, Score__c FROM Field_Score__c WHERE FieldName__c = :accountFieldScore.Field__c AND Value__c IN :investmentInstrumentFieldScores AND Hedge_Fund__c =:accountHF ORDER BY Score__c DESC];

                for( Field_Score__c score : highestFieldScore){
                    investmentInstrumentSum += score.Score__c;
                }

                Double weightValue = accountFieldScore.Weight__c * 0.01;
                accountFieldScore.Weight_Score_Static__c = investmentInstrumentSum * weightValue;

            } else {
                accountFieldScore.Weight_Score_Static__c = accountFieldScore.Weighted_Score__c;
            }
        }

        update accountFieldScoresToUpdate;

        /*
        * This loop will remove the field score records that were just updated to setup the next batch for queue.
        * We are not able to remove the Field Score records in the first for each loop, as it throws a System.FinalException
        * Hence the need for this below for each loop.
        */
        Integer fieldScoreIDsToUpdatePosition = 0;
        System.debug('Initial list size: ' + fieldScoreIDsToUpdate.size());
        System.debug('ID list size: ' + fieldScoreIDBatch.size());
        for (ID fsid : fieldScoreIDBatch){
            if(fieldScoreIDsToUpdatePosition != 2 && fieldScoreIDsToUpdatePosition < fieldScoreIDsToUpdate.size()){
                fieldScoreIDsToUpdate.remove(fieldScoreIDsToUpdatePosition);
                fieldScoreIDsToUpdatePosition++; 
                System.debug('Remove Size' + fieldScoreIDsToUpdate.size());
            }
        }

        return fieldScoreIDsToUpdate;
    }
}