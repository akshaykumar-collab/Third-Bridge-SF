/**
 * @description       : 
 * @author            : Kyle (RadixBay)
 * @group             : 
 * @last modified on  : 10-2-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class AccountRankingModel implements Queueable{

    public String executionType = '';
    Map <Id, Map<String, String>> oldAccountValues;
    Map <Id, Map<String, String>> newAccountValues;
    
    // Constructor for Inserts
    public AccountRankingModel(String executionType, Map<Id, Map<String, String>> newAccountValues){
        this.executionType = executionType;
        this.newAccountValues = newAccountValues;
    }
    //Constructor for Updates/Upserts
    public AccountRankingModel(String executionType, Map<Id, Map<String, String>> oldAccountValues, Map<Id, Map<String, String>> newAccountValues){
        this.executionType = executionType;
        this.oldAccountValues = oldAccountValues;
        this.newAccountValues = newAccountValues;
    }

    //Queueable class that executes the account updates through batches 
    public void execute(System.QueueableContext ctx){
        if (executionType.equals('insert')){
            processNextAccountInsert(newAccountValues);
        } else if (executionType.equals('update')) {
            processNextAccountUpdate(oldAccountValues, newAccountValues);
        }
    }

    public static void accountSetup(Map<Id, SObject> oldAccountFields, Map<Id, SObject> newAccountFields){

        // The account maps that come in are read-only. We must copy them to new maps that we can manipulate.
        Map<Id, Account> accountsBeforeUpdate = new Map<Id, Account>();
        Map<Id, Account> accountsAfterUpdate = new Map<Id, Account>();
        Map<Id, Account> newMap = (Map<Id, Account>)newAccountFields;
        Map<Id, Account> oldMap = (Map<Id, Account>)oldAccountFields;
        

        Id prospectId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        
        // Only add an account to process if the Primary Asset Class type is "Public Equity" or "Credit"
        for(Account a : newMap.values()){
            if ((a.Primary_Asset_Class__c == 'Equity' || a.Primary_Asset_Class__c == 'Credit') && 
                a.Territory__c == 'North America' && 
                a.RecordTypeId == prospectId && 
                a.Pod_Account__c == false && 
                a.Forum_Tier__c != '5')
            {
                if (oldAccountFields != null){
                    accountsBeforeUpdate.put(a.Id, oldMap.get(a.Id));
                }
                    accountsAfterUpdate.put(a.Id, a);
            }
        }

        //System.debug('Accounts coming in before: ' + accountsBeforeUpdate);
        //System.debug('Accounts coming in after: ' + accountsAfterUpdate);
        //System.debug('Accounts left to process: ' + accountsAfterUpdate.size());

        IF(accountsAfterUpdate.size()>0){
            // Aggregate result is needed as the type when dealing with a GROUP BY Clause in a SOQL query
            List<AggregateResult> fieldScores = [SELECT FieldName__c FROM Field_Score__c GROUP BY FieldName__c];
    
            System.debug('List of values: ' + fieldScores);
            
            // A list of the field score values on the account we use for the Ranking Model.
            List<String> fieldScoreNames = new List<String>();
    
            //Variables used to translate Field Score Names to their API equivalent.
            String fieldScoreString;
            String fieldScoreStringUnderscored;
            String fieldScoreAPIString;
    
            // DEV NOTE: If a FieldName__c value is missing on a FS record, a Null reference will be thrown.
            // Convert The Field Score Names pulled above and translate them into their API names for querying on accounts further down in the code.
            for (AggregateResult fieldScore:fieldScores) {
                System.debug(fieldScore);
                System.debug(String.valueOf(fieldScore.get('FieldName__c')));
                fieldScoreString = String.valueOf(fieldScore.get('FieldName__c'));
                if (fieldScoreString.contains(' ')){
                    fieldScoreStringUnderscored = fieldScoreString.replace(' ', '_');
                    fieldScoreAPIString = fieldScoreStringUnderscored + '__c';
                    fieldScoreNames.add(fieldScoreAPIString);
                } else {
                    fieldScoreAPIString = fieldScoreString + '__c';
                    fieldScoreNames.add(fieldScoreAPIString);
                }
            }
            //If there are no field scores, don't run.
        if (!fieldScores.isEmpty()){
            // If there are no "Before Update" records, we are processing a new account, and we are only inserting new Account Field Score records.
            if (accountsBeforeUpdate.isempty()){
                // Setup the Map of Accounts and their associated fields that need to be inserted.
                Map<Id, Map<String, String>> qualifiedAccounts = new Map<Id, Map<String, String>>();
                
                // Loop through the accounts and create the inner Map of fields to set later in the logic.
                for (Account a : accountsAfterUpdate.values()){
                    // This is a map of the fields names on the account relevant to Account Ranking and their respective values.
                    Map<String, String> qualifiedAccountFields = new Map<String, String>();
                    for(Integer i = 0; i < fieldScoreNames.size(); i++){
                        String fieldScoreValue = String.valueOf(a.get(fieldScoreNames.get(i)));
                        qualifiedAccountFields.put(fieldScoreNames.get(i), fieldScoreValue);
                    }
                    qualifiedAccounts.put(a.Id, qualifiedAccountFields);
                }
                if(!qualifiedAccounts.isempty()){
                    //Call the Overloaded Queue Method
                    processNextAccountInsert(qualifiedAccounts);
                }
            // If "Before Update" accounts exist, this means the are existing accounts, and an update/upsert is needed.
            } else {
                // Setup the Map of Accounts and their associated fields that need to be inserted.
                Map<Id, Map<String, String>> oldAccountFSValues = new Map<Id, Map<String, String>>();
                Map<Id, Map<String, String>> newAccountFSValues = new Map<Id, Map<String, String>>();

                // This list and map is used to query the original maps pulled through the method parameters.
                // This is used in order to pull each account from the main list with the use of integers.
                List<Id> accountIDsToUpdate = new List<Id> (accountsAfterUpdate.keySet());
                Map<Integer, Id> accountMapForLoop = new Map<Integer, Id>();

                for(Integer acc = 0; acc < accountsAfterUpdate.size(); acc++){
                    accountMapForLoop.put(acc, accountIDsToUpdate.get(acc));
                }

                // Check if the bypass was set to true in order to process older Accounts.
                Apex_Bypass_Setting__mdt armSetting = Apex_Bypass_Setting__mdt.getInstance('Account_Ranking_Model_Settings');
                Boolean bypass = armSetting.Bypass__c;
                String nullFieldScore = armSetting.ARM_Blank_Field_Scores_API__c;

                System.debug('Null Field MDT Setting: ' + nullFieldScore);

                // This loop parses through both incoming Account Maps and determines the fields that were updated.
                // We only check the relative Account Ranking Field Score values set on the account. 
                for(Integer i = 0; i < accountsAfterUpdate.size(); i++){                    
                    Map<String, String> oldAccountFieldsTemp = new Map<String, String>();
                    Map<String, String> newAccountFieldsTemp = new Map<String, String>();
                    
                    ID accountMapId = accountMapForLoop.get(i);
                    Account oldAccountValues = accountsBeforeUpdate.get(accountMapId);
                    Account newAccountValues = accountsAfterUpdate.get(accountMapId);
                    System.debug('oldAccountValues:'+accountsBeforeUpdate.get(accountMapId));
                    System.debug('newAccountValues:'+accountsAfterUpdate.get(accountMapId));
                    System.debug('newAccountValues:'+fieldScoreNames);

                    Boolean hedgeFundChange = false;
                    Boolean podForumChange = false;

                    //System.debug('New Account Values' + newAccountValues);

                    if(!String.isblank(newAccountValues.Client_Type__c)){
                        
                        // These two if-blocks account for if the Account was changed to a hedge fund from a previous firm type.
                        if (oldAccountValues.Client_Type__c != 'Hedge Fund' && newAccountValues.Client_Type__c == 'Hedge Fund'){
                            hedgeFundChange = true;
                        }
    
                        if (oldAccountValues.Client_Type__c == 'Hedge Fund' && newAccountValues.Client_Type__c != 'Hedge Fund'){
                            hedgeFundChange = true;
                        }
                    }
                    
                    // Checks if Pod Access is flipped from true to false on the account or Sales Tier - Forum is set from 5 to not 5
                    // and creates afs records if none already exist for the account.
                    if((oldAccountValues.Pod_Account__c == true && newAccountValues.Pod_Account__c == false) ||
                       (oldAccountValues.Forum_Tier__c == '5' && newAccountValues.Forum_Tier__c != '5')){

                        List<Account_Field_Score__c> afsCheck = [SELECT ID from Account_Field_Score__c WHERE Account__c = :accountMapId];

                        // If afs records don't exist for this account, treat it as a hedgefund change and run the bypass to create the missing afs records.
                        if (afsCheck.isEmpty()){
                            podForumChange = true;
                        }
                    }

                    for(Integer j = 0; j < fieldScoreNames.size(); j++){

                        String oldFieldValue = String.valueOf(oldAccountValues.get(fieldScoreNames.get(j)));
                        String newFieldValue = String.valueOf(newAccountValues.get(fieldScoreNames.get(j)));
                        System.debug('fieldScoreNames:' + fieldScoreNames.get(j));
                        System.debug('Old Value:' + oldFieldValue);
                        System.debug('New Value:' + newFieldValue);

                        System.debug('Null Check Old:' + String.isBlank(oldFieldValue));
                        System.debug('Null Check NewField' + newFieldValue != null);

                        System.debug('Field Score Name Value: ' + fieldScoreNames.get(j));
                        System.debug('Contains Null Value Check: ' + nullFieldScore.contains(fieldScoreNames.get(j)));
                        
                        if (!podForumChange){
                            // If the bypass mdt value is false, run the normal logic
                            if (!bypass){
                                // If the account was not changed to or from firm type "Hedge Fund", run the normal logic
                                if (!hedgeFundChange){
                                    if (newFieldValue != null && String.isBlank(oldFieldValue)){
                                        System.debug('HedgeFund If 1');
                                        oldAccountFieldsTemp.put(fieldScoreNames.get(j), oldFieldValue);
                                        newAccountFieldsTemp.put(fieldScoreNames.get(j), newFieldValue);
                                    // If the new field value is populated and the old value is not the same as the new value
                                    } else if(newFieldValue != null && !oldFieldValue.equals(newFieldValue)){
                                        System.debug('HedgeFund If 2');
                                        System.debug('DoesnT Equal Check:'+!oldFieldValue.equals(newFieldValue));
                                        oldAccountFieldsTemp.put(fieldScoreNames.get(j), oldFieldValue);
                                        newAccountFieldsTemp.put(fieldScoreNames.get(j), newFieldValue);
                                    // If a value is set to blank or nothing, which was once populated.
                                    } else if(newFieldValue == null && oldFieldValue != null){
                                        System.debug('HedgeFund If 3');
                                        oldAccountFieldsTemp.put(fieldScoreNames.get(j), oldFieldValue);
                                        newAccountFieldsTemp.put(fieldScoreNames.get(j), newFieldValue);
                                    }
                                // If the account was changed to or from firm type "Hedge Fund", ignore field score values 
                                // that or the same from before and after updates.
                                } else {
                                    if (newFieldValue != null && oldFieldValue != null){
                                        System.debug('HedgeFund Else 1');
                                        oldAccountFieldsTemp.put(fieldScoreNames.get(j), oldFieldValue);
                                        newAccountFieldsTemp.put(fieldScoreNames.get(j), newFieldValue);
                                    } else if (newFieldValue == null && oldFieldValue != null){
                                        System.debug('HedgeFund Else 2');
                                        oldAccountFieldsTemp.put(fieldScoreNames.get(j), oldFieldValue);
                                        newAccountFieldsTemp.put(fieldScoreNames.get(j), newFieldValue);
                                    }
                                }
                            // If the bypass mdt value is true, ignore the standard logic, and insert all new Account Field Score values for the accounts.
                            } else {
                                if (newFieldValue != null && oldFieldValue != null){
                                    System.debug('Bypass 1');
                                    oldAccountFieldsTemp.put(fieldScoreNames.get(j), oldFieldValue);
                                    newAccountFieldsTemp.put(fieldScoreNames.get(j), newFieldValue);
                                } else if(newFieldValue == null && nullFieldScore.contains(fieldScoreNames.get(j))){
                                    System.debug('Bypass 2');
                                    oldAccountFieldsTemp.put(fieldScoreNames.get(j), oldFieldValue);
                                    newAccountFieldsTemp.put(fieldScoreNames.get(j), newFieldValue);
                                }
                            }
                        } else {
                            if (newFieldValue != null && oldFieldValue != null){
                                System.debug('Bypass 1');
                                oldAccountFieldsTemp.put(fieldScoreNames.get(j), oldFieldValue);
                                newAccountFieldsTemp.put(fieldScoreNames.get(j), newFieldValue);
                            } else if(newFieldValue == null && nullFieldScore.contains(fieldScoreNames.get(j))){
                                System.debug('Bypass 2');
                                oldAccountFieldsTemp.put(fieldScoreNames.get(j), oldFieldValue);
                                newAccountFieldsTemp.put(fieldScoreNames.get(j), newFieldValue);
                            }
                        }
                    }

                    // New Account ID was inserted on both, as the Maps contain the identical relative order of accounts.
                    System.debug('oldAccountFieldsTemp:'+oldAccountFieldsTemp);
                    System.debug('newAccountFieldsTemp:'+newAccountFieldsTemp);
                    if (!oldAccountFieldsTemp.isEmpty()){
                        oldAccountFSValues.put(newAccountValues.Id, oldAccountFieldsTemp);
                        newAccountFSValues.put(newAccountValues.Id, newAccountFieldsTemp);
                    }
                    hedgeFundChange = false;
                    podForumChange = false;
                }

                if(!newAccountFSValues.isEmpty()){
                    processNextAccountUpdate(oldAccountFSValues, newAccountFSValues); 
                }
            }
        }
            
            
        
        }
 
    }

    // This below method will execute on insert, after AccountInsertSetup runs
    public static void processNextAccountInsert(Map<Id, Map<String, String>> AccountsToProcess){

        // Convert the Set into a List so we can pull the initial ID value.
        ID topAccountId = new List<Id> (AccountsToProcess.keySet()).get(0);
        // Locate the map of values associated with the first account in AccountsToProcess and assign it to a new Map for processing.
        Map<String, String> currentAccountToProcess = AccountsToProcess.get(topAccountId);
        // remove the first index from the incoming Account Map.
        AccountsToProcess.remove(topAccountID);
        // Instantiate the list of Account Field Scores that we will later be inserting.
        List<Account_Field_Score__c> accountFieldScores = new List<Account_Field_Score__c>();

        Double investmentInstrumentValue = 0;
        
        List<String> fieldScoreNames = new List<String>();
        List<String> fieldScoreValues = new List<String>();
        List<Field_Score__c> fieldScoreRecords = new List<Field_Score__c>();

        // Pull the account and check if it's a "Hedge Fund" Firm Type.
        Account currentAccount = [SELECT Client_Type__c FROM Account WHERE Id =:topAccountId];
        Boolean accountHF =false;
        if(currentAccount.Client_Type__c == 'Hedge Fund'){
            accountHF = true;
        }

        System.debug('Key'+currentAccountToProcess.keySet());

        // Accounts for field score values that have a score for blank field values.
        Apex_Bypass_Setting__mdt blankNullFieldScores = Apex_Bypass_Setting__mdt.getInstance('Account_Ranking_Model_Settings');
        String fieldScoreNull = blankNullFieldScores.ARM_Blank_Field_Scores__c;

        System.debug('Null Field MDT Setting: ' + fieldScoreNull);

        // Loop through each Account Field set on the account
        for(String field : currentAccountToProcess.keySet()){
            
            String fieldValue = currentAccountToProcess.get(field);

            String stringFieldValue = String.valueOf(currentAccountToProcess.get(field));

            String fieldTrim = field.remove('__c');
            String actualFieldName = fieldTrim.replace('_', ' ');

            if(!String.isBlank(stringFieldValue) || fieldScoreNull.contains(actualFieldName)){
                // Remove the initial API formatting so we can query the associated Field Score record.

                fieldScoreNames.add(actualFieldName);
                fieldScoreValues.add(fieldValue);
                System.debug('Field Score Names: ' + fieldScoreNames);
                System.debug('Field Score Values: ' + fieldScoreValues);
                System.debug('Current Field Score Name: ' + actualFieldName);
                System.debug('Current Field Score Value: ' + fieldValue);

                Boolean decimalCheck = false;
                String firstHalf = 'not numeric';
                if (fieldValue != null && fieldValue.contains('.') && fieldValue.indexOf('.') == fieldValue.lastIndexOf('.')){
                    System.debug('length: ' + fieldValue.length());
                    System.debug('fieldValue ' + fieldValue);
                    System.debug('Field Value Split: ' + String.valueOf(fieldValue).split('\\.'));
                    System.debug('Field Value Split number: ' + String.valueOf(fieldValue).split('0'));
                    List<String> numberFieldValue = String.valueOf(fieldValue).split('\\.');
                    System.debug('The Split String: ' + numberFieldValue);
                    firstHalf = numberFieldValue.get(0);
                    String secondHalf = numberFieldValue.get(1);
                    System.debug('First Half Number: ' + firstHalf + ' Second Half Number: ' + secondHalf);

                    if (firstHalf.isNumeric() && secondHalf.isNumeric()){
                        decimalCheck = true;
                    }
                }
                
                // If the field score value is a number, we check if it falls within a range.
                if(fieldvalue != null && (fieldvalue.isNumeric() || decimalCheck)){
                    List<Field_Score__c> numberFieldScoreRecords = [SELECT Id, FieldName__c, Lower_Range__c, Upper_Range__c FROM Field_Score__c WHERE FieldName__c = :actualFieldName AND Hedge_Fund__c =:accountHF];
                    for (Field_Score__c fieldScoreRecord : numberFieldScoreRecords){
                        if (Decimal.valueOf(fieldValue) >= fieldScoreRecord.Lower_Range__c && Decimal.valueOf(fieldValue) <= fieldScoreRecord.Upper_Range__c){
                            fieldScoreRecords.add(fieldScoreRecord);
                        }
                    }
                // If the field score value is a multi-select picklist, we find the picklist value with the highest field score and use that one.
                } else if (fieldvalue != null && fieldvalue.contains(';') ) {
                    List<String> multiSelectValues = fieldvalue.split(';');
                    List<Field_Score__c> highestFieldScore = [SELECT Id, FieldName__c, Value__c, Score__c FROM Field_Score__c WHERE FieldName__c = :actualFieldName AND Value__c IN :multiSelectValues AND Hedge_Fund__c =:accountHF ORDER BY Score__c DESC];
                    System.debug('multi select list return ' + highestFieldScore);
                    if (actualFieldName == 'Investment Instruments'){
                        for( Field_Score__c score : highestFieldScore){
                            investmentInstrumentValue += score.Score__c;
                        }
                    }
                    fieldScoreRecords.add(highestFieldScore[0]);
                // If the field score value is a string.
                } else {
                    Field_Score__c fieldScoreRecord = [SELECT Id, FieldName__c, Value__c, Score__c FROM Field_Score__c WHERE FieldName__c = :actualFieldName AND Value__c = :fieldValue AND Hedge_Fund__c =:accountHF LIMIT 1];
                    if (actualFieldName == 'Investment Instruments'){
                        investmentInstrumentValue = fieldScoreRecord.Score__c;
                    }
                    fieldScoreRecords.add(fieldScoreRecord);
                }
            }
        }

        // Locate the associated field score records, and insert a new Account Field Score record for each field score record.
        System.debug('Field Score Records SQOL Response: ' + fieldScoreRecords);
        System.debug('Field Score Value Count: ' + fieldScoreValues.size());
        System.debug('Field Score Record Count: ' + fieldScoreRecords.size());
        Integer fieldValueIndex = 0;
        for(Field_Score__c fieldScore : fieldScoreRecords){
            System.debug('Field Value Index: ' + fieldValueIndex);
            if (fieldScore.isSet(Field_Score__c.Lower_Range__c) || fieldScore.isSet(Field_Score__c.Upper_Range__c)){
                Account_Field_Score__c currentFieldScore = new Account_Field_Score__c(Account__c = topAccountId, Field_Score__c = fieldScore.Id, Field_Value__c = fieldScoreValues.get(fieldValueIndex));
                accountFieldScores.add(currentFieldScore);
            } else if (fieldScore.Value__c == null) {
                Account_Field_Score__c currentFieldScore = new Account_Field_Score__c(Account__c = topAccountId, Field_Score__c = fieldScore.Id, Field_Value__c = '(blank)');
                accountFieldScores.add(currentFieldScore);
            } else {
                Account_Field_Score__c currentFieldScore = new Account_Field_Score__c(Account__c = topAccountId, Field_Score__c = fieldScore.Id, Field_Value__c = fieldScore.Value__c);
                accountFieldScores.add(currentFieldScore);
            }
            fieldValueIndex++;
        }

        insert accountFieldScores;

        // Now that the AFS records have been inserted for the account, we must set the Weighted Score Static field.
        List<Account_Field_Score__c> newlyCreatedScores = [SELECT Id, Field__c, Weight__c, Weighted_Score__c, Weight_Score_Static__c FROM Account_Field_Score__c WHERE Account__c = :topAccountID];

        // This static field is derived from the Weighted_Score__c formula field. This is used in the Account Priority rank calculation on the account.
        // The Weighted score on the account record is a rollup field from the Weight_Score_Static__c field.
        for(Account_Field_Score__c fieldScore : newlyCreatedScores){
            if (fieldScore.Field__c == 'Investment Instruments'){
                if (investmentInstrumentValue != 0){
                    Double weightValue = fieldScore.Weight__c * 0.01;
                    System.debug(fieldScore.Weight__c);
                    System.debug(investmentInstrumentValue);
                    System.debug(investmentInstrumentValue * weightValue);
                    fieldScore.Weight_Score_Static__c = investmentInstrumentValue * weightValue;
                }
            } else {
                fieldScore.Weight_Score_Static__c = fieldScore.Weighted_Score__c;
            }
        }

        update newlyCreatedScores;

        // If there are still more accounts in the original map, there are more to process.
        // Call the queueable class with the remaining accounts to process.
        if(!AccountsToProcess.isEmpty() && !Test.IsRunningTest()){
            String type = 'insert';
            List<ID> queueID = new List<ID>();
            queueID.add(System.enqueueJob(new AccountRankingModel(type, AccountsToProcess)));
        }

    }

    public static void processNextAccountUpdate(Map<Id, Map<String, String>> oldAccountFieldValues, Map<Id, Map<String, String>> newAccountFieldValues){
        
        System.debug('OAF: ' + oldAccountFieldValues + ' ' + 'NAF: ' + newAccountFieldValues);
        // Convert the Set into a List so we can pull the initial ID value.
        ID topAccountId = new List<Id> (newAccountFieldValues.keySet()).get(0);
        Double investmentInstrumentValue = 0;

        // Locate the map of values associated with the first account in newAccountFieldValues and assign it to a new Map for processing.
        Map<String, String> newAccountFieldsToProcess = newAccountFieldValues.get(topAccountId);
        Map<String, String> oldAccountFields = oldAccountFieldValues.get(topAccountId);

        // remove the first index from the incoming Account Map.
        newAccountFieldValues.remove(topAccountID);
        oldAccountFieldValues.remove(topAccountID);
        // Instantiate the list of Account Field Scores that we will later be inserting.
        List<Account_Field_Score__c> AccountFieldScores = new List<Account_Field_Score__c>();

        // Field Score Names and Values
        Map<String, String> fieldScores = new Map<String, String>();
        List<Field_Score__c> fieldScoreRecords = new List<Field_Score__c>();
        // For any AFS records that need to be removed for the account. i.e. value is set to null on the Account.
        List<String> fieldScoresToDelete = new List<String>();

        // Pull the account and check if it's a "Hedge Fund" Firm Type.
        Account currentAccount = [SELECT Client_Type__c FROM Account WHERE Id =:topAccountId];
        Boolean accountHF = false;
        if (currentAccount.Client_Type__c == 'Hedge Fund'){
            accountHF = true;
        }

        // Accounts for field score values that have a score for blank field values.
        Apex_Bypass_Setting__mdt blankNullFieldScores = Apex_Bypass_Setting__mdt.getInstance('Account_Ranking_Model_Settings');
        String fieldScoreNull = blankNullFieldScores.ARM_Blank_Field_Scores__c;

        System.debug('Null Field MDT Setting: ' + fieldScoreNull);

        // Loop through each Account Field set on the account
        for(String field : newAccountFieldsToProcess.keySet()){
            
            String fieldValue = newAccountFieldsToProcess.get(field);

            // Remove the initial API formatting so we can query the associated Field Score record.
            String fieldTrim = field.remove('__c');
            String actualFieldName = fieldTrim.replace('_', ' ');

            System.debug('field: ' + field + ' Field Value: ' + fieldValue + ' Actual Field Name: ' + actualFieldName + ' contains the null value: ' + fieldScoreNull.contains(actualFieldName));
            
            // System.debug('Field: '+actualFieldName+' Value: '+fieldValue +' MSP: '+fieldvalue.contains(';')+'Number: '+fieldvalue.isNumeric());
            // check if the field was set to null, and verifys the field name category is not flagged for having a scored blank value.
            if (fieldValue == null && !fieldScoreNull.contains(actualFieldName)){
                fieldScoresToDelete.add(actualFieldName);
            } else {
                // Track the actual value entered in case it's needed. Used for numeric fields.
                fieldScores.put(actualFieldName, fieldValue);

                Boolean decimalCheck = false;
                String firstHalf = 'not numeric';
                if (fieldValue != null && fieldValue.contains('.') && fieldValue.indexOf('.') == fieldValue.lastIndexOf('.')){
                    System.debug('length: ' + fieldValue.length());
                    System.debug('fieldValue ' + fieldValue);
                    System.debug('Field Value Split: ' + String.valueOf(fieldValue).split('\\.'));
                    System.debug('Field Value Split number: ' + String.valueOf(fieldValue).split('0'));
                    List<String> numberFieldValue = String.valueOf(fieldValue).split('\\.');
                    System.debug('The Split String: ' + numberFieldValue);
                    firstHalf = numberFieldValue.get(0);
                    String secondHalf = numberFieldValue.get(1);
                    System.debug('First Half Number: ' + firstHalf + ' Second Half Number: ' + secondHalf);

                    if (firstHalf.isNumeric() && secondHalf.isNumeric()){
                        decimalCheck = true;
                    }
                }

                // If the field score value is a number, we check if it falls within a range.
                if(fieldvalue != null && (fieldvalue.isNumeric() || decimalCheck)){
                    List<Field_Score__c> numberFieldScoreRecords = [SELECT Id, FieldName__c, Value__c, Lower_Range__c, Upper_Range__c FROM Field_Score__c WHERE FieldName__c = :actualFieldName AND Hedge_Fund__c =:accountHF];
                    for (Field_Score__c fieldScoreRecord : numberFieldScoreRecords){
                        if (Decimal.valueOf(fieldValue) >= fieldScoreRecord.Lower_Range__c && Decimal.valueOf(fieldValue) <= fieldScoreRecord.Upper_Range__c){
                            fieldScoreRecords.add(fieldScoreRecord);
                        }
                    }
                // If the field score value is a multi-select picklist, we find the picklist value with the highest field score and use that one.
                } else if (fieldvalue != null && fieldvalue.contains(';')) {
                    List<String> multiSelectValues = fieldvalue.split(';');
                    List<Field_Score__c> highestFieldScore = [SELECT Id, FieldName__c, Value__c, Score__c FROM Field_Score__c WHERE FieldName__c = :actualFieldName AND Value__c IN :multiSelectValues AND Hedge_Fund__c =:accountHF ORDER BY Score__c DESC];
                    System.debug('multi select list return ' + highestFieldScore);
                    if (actualFieldName == 'Investment Instruments'){
                        for( Field_Score__c score : highestFieldScore){
                            investmentInstrumentValue += score.Score__c;
                        }
                    }
                    fieldScoreRecords.add(highestFieldScore[0]);
                // If the field score value is a string.
                } else {
                    Field_Score__c fieldScoreRecord = [SELECT Id, FieldName__c, Value__c, Score__c FROM Field_Score__c WHERE FieldName__c = :actualFieldName AND Value__c = :fieldValue AND Hedge_Fund__c =:accountHF LIMIT 1];
                    if (actualFieldName == 'Investment Instruments'){
                        investmentInstrumentValue = fieldScoreRecord.Score__c;
                    }
                    fieldScoreRecords.add(fieldScoreRecord);
                } 
            }
        }
        
        //Total Field Score Records that exist
        System.debug('Field Score Records: ' + fieldScoreRecords);
        //The AFS records that currently exist for the given Account
        List<Account_Field_Score__c> currentFieldScores = [SELECT Field__c, Field_Score__c, Field_Value__c FROM Account_Field_Score__c WHERE Account__c = :topAccountID];
        //The List we will use to upsert AFS records on the Account
        List<Account_Field_Score__c> accountFieldScoreRecordsToUpsert = new List<Account_Field_Score__c>();

        //This flag will determine if an AFS record exists with the respective Field Score record.
        Boolean insideAFS = false;
        // Loop through all Field Score Records
        for (Field_Score__c fs : fieldScoreRecords){
            System.debug('Field Score ' + fs);
            // For each Field Score Record, check to see if there's an associated AFS record already created.
            for(Account_Field_Score__c afs : currentFieldScores){
                // If a AFS record with the current Field Score record is found
                if(fs.FieldName__c == afs.Field__c){
                    System.debug('FS Name: ' + fs.FieldName__c + ' AFS linked name: ' + afs.Field__c);
                    insideAFS = true;
                    afs.Field_Score__c = fs.Id;
                    // If the field processing is a number, use the entered number on the update, since the FS record itself won't have a number value.
                    if (fs.isSet(Field_Score__c.Lower_Range__c) || fs.isSet(Field_Score__c.Upper_Range__c)){
                        afs.Field_Value__c = fieldScores.get(fs.FieldName__c);
                    } else if (String.isBlank(fs.Value__c)) {
                         afs.Field_Value__c = '(blank)';
                    // If the field is not a number, just use the value on the Field Score record.
                    } else {
                        afs.Field_Value__c = fs.Value__c;
                    }
                    // Queue the Account Field Score record for update.
                    accountFieldScoreRecordsToUpsert.add(afs);
                }
            }
            //If the FS record was not able to find an associated AFS record, create a new AFS record.
            if(insideAFS == false){
                System.debug('Is this getting pulled: ' + fs.Value__c);
                // If either of these values are set on the Field Score record, it is a number field and should be processed with the value originally entered.
                if (fs.isSet(Field_Score__c.Lower_Range__c) || fs.isSet(Field_Score__c.Upper_Range__c)){
                    Account_Field_Score__c newAccountNumberFieldScore = new Account_Field_Score__c(Account__c = topAccountID, Field_Score__c = fs.Id, Field_Value__c = fieldScores.get(fs.FieldName__c));
                    System.debug('Account to Create: ' + newAccountNumberFieldScore);
                    accountFieldScoreRecordsToUpsert.add(newAccountNumberFieldScore);
                // the Field Score value is blank, set the field value on the afs record to (blank).
                } else if (String.isBlank(fs.Value__c)) {
                    Account_Field_Score__c newAccountNumberFieldScore = new Account_Field_Score__c(Account__c = topAccountID, Field_Score__c = fs.Id, Field_Value__c = '(blank)');
                    System.debug('Account to Create: ' + newAccountNumberFieldScore);
                    accountFieldScoreRecordsToUpsert.add(newAccountNumberFieldScore);
                // It is not a number value, and can be set with the Field Scores records value field.
                } else {
                    Account_Field_Score__c newAccountFieldScore = new Account_Field_Score__c(Account__c = topAccountID, Field_Score__c = fs.Id, Field_Value__c = fs.Value__c);
                    System.debug('Account to Create: ' + newAccountFieldScore);
                    accountFieldScoreRecordsToUpsert.add(newAccountFieldScore);
                }
            }
            insideAFS = false;
        }
        System.debug('Account to Upsert: ' + accountFieldScoreRecordsToUpsert);
        upsert accountFieldScoreRecordsToUpsert;

        // Delete associated afs records where the assocatied account value was set to nothing/null.
        if (!fieldScoresToDelete.isEmpty()){
            List<Account_Field_Score__c> afsRecordsToDelete = [SELECT Id FROM Account_Field_Score__c WHERE Account__c = :topAccountID AND Field__c IN :fieldScoresToDelete];
            delete afsRecordsToDelete;
        }
        
        System.debug('Account being queried: ' + topAccountId);

        // Now that the AFS records have been inserted for the account, we must set the Weighted Score Static field.
        List<Account_Field_Score__c> newlyCreatedScores = [SELECT Id, Field__c, Weight__c, Weighted_Score__c, Weight_Score_Static__c FROM Account_Field_Score__c WHERE Account__c = :topAccountID];

        // This static field is derived from the Weighted_Score__c formula field. This is used in the Account Priority rank calculation on the account.
        // The Weighted score on the account record is a rollup field from the Weight_Score_Static__c field.
        for(Account_Field_Score__c fieldScore : newlyCreatedScores){
            if (fieldScore.Field__c == 'Investment Instruments'){
                 if (investmentInstrumentValue != 0){
                    Double weightValue = fieldScore.Weight__c * 0.01;
                    System.debug(fieldScore.Weight__c);
                    System.debug(investmentInstrumentValue);
                    System.debug(investmentInstrumentValue * weightValue);
                    fieldScore.Weight_Score_Static__c = investmentInstrumentValue * weightValue;
                }
            } else {
                fieldScore.Weight_Score_Static__c = fieldScore.Weighted_Score__c;
            }
        }

        update newlyCreatedScores;

        System.debug('Accounts left to queue: ' + newAccountFieldValues.size());
        System.debug('Is the flag true: ' + newAccountFieldValues.isEmpty());

        // If there are still more accounts in the original map, there are more to process.
        // Call the queueable class with the remaining accounts to process.
        if(!newAccountFieldValues.isEmpty() && !Test.IsRunningTest()){
            String type = 'update';
            List<ID> queueID = new List<ID>();
            queueID.add(System.enqueueJob(new AccountRankingModel(type, oldAccountFieldValues, newAccountFieldValues)));
        }
    }
}