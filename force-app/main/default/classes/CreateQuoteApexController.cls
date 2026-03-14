/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-04-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class CreateQuoteApexController {        
    @AuraEnabled
    public static OppSobj getQuoteRtId(String oppRtDevName, Double connectionHours, String territory, String tbId, String cgc, String oppType, String trialType, String trialproduct, Boolean accountAddress){   
        Map<String,String> opp2quoteRtMap = new Map<String,String>();
        opp2quoteRtMap.put('Connections','Connections');     
        opp2quoteRtMap.put('Connections_Forum','Connections_Forum');  
        opp2quoteRtMap.put('Forum','Forum');
        opp2quoteRtMap.put('Connections_Renewal','Connections');     
        opp2quoteRtMap.put('CX_FM_Renewal','Connections_Forum');  
        opp2quoteRtMap.put('Forum_Renewal','Forum');
        opp2quoteRtMap.put('Surveys','Surveys');
        opp2quoteRtMap.put('Surveys_Renewal','Surveys');
        opp2quoteRtMap.put('Forum_Auto_Renewal','Forum_Auto_Renewal');
        opp2quoteRtMap.put('Forum_Free_Trial','Forum_Free_Trial'); 
        opp2quoteRtMap.put('Communiunity_Consulations','Communiunity_Consulations');
        opp2quoteRtMap.put('Content_Data_Feed','Content_Data_Feed');  
        //find match for quote rt
        String quoteRtName;

        System.debug(oppType);
        System.debug(trialType);
        System.debug(trialproduct);

        if(oppType == 'Trial' && trialType == 'Free' && oppRtDevName == 'Forum') {
            quoteRtName = opp2quoteRtMap.get('Forum_Free_Trial');
        } else if (oppType == 'Trial' && trialType == 'Free' && oppRtDevName == 'Connections' && trialproduct == 'Community Consultations') {
            quoteRtName = opp2quoteRtMap.get('Communiunity_Consulations');
        }
        else {
           quoteRtName = opp2quoteRtMap.get(oppRtDevName); 
        }
        
        System.debug(quoteRtName);
        
        return new OppSobj(Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(quoteRtName).getRecordTypeId(),
                           getPackageName(oppRtDevName,territory,tbId,cgc,connectionHours,accountAddress));
    }
    
    private static String getPackageName(String oppRtName, String territory, String tbId, String cgc, Double connectionHours, Boolean accountAddress){
        System.debug('Community: ' + cgc);
        String packageName = '';
        
        switch on oppRtName {
            when 'Connections' {
                packageName = 'Connections';
            }
            when 'Connections_Forum' {
                packageName = 'Connections & Forum';
            }
            when 'Forum' {
                packageName = 'Forum';
            }
            when 'Connections_Renewal' {
                packageName = 'Connections';
            }
            when 'CX_FM_Renewal' {
                packageName = 'Connections & Forum';
            }
            when 'Forum_Renewal' {
                packageName = 'Forum';
            }
            when 'Forum_Auto_Renewal' {
                packageName = 'Forum Auto-Renewal';
            }
            when 'Surveys' {
                packageName = 'Surveys';
            }
            when 'Surveys_Renewal' {
                packageName = 'Surveys';
            }
            when 'Content_Data_Feed' {
                packageName = 'Content Data Feed';
            }
        }
        if(cgc == 'Yes' && connectionHours >0) {
            packageName += ' & Community';
            
        } else if (cgc == 'Yes' && (oppRtName =='CX_FM_Renewal' || oppRtName=='Connections_Forum' )){
            packageName = 'Community & Forum';
        }
        else if (cgc == 'Yes'){
            packageName = 'Community';
        }
        
        
        packageName += ' Package '; 
        switch on territory {
            when 'US' {
                packageName += 'U';
            }
            when 'Europe' {
                packageName += 'E';
            }
            when 'Pan-Asia','China','India' {
                packageName += 'A';
            }
            when 'Global' {
                packageName += 'G';
            }
        }
        packageName += '-' + tbId;
        return packageName;
    }
    
    public class OppSobj {
        @AuraEnabled public Id quoteRtId;
        @AuraEnabled public String packageName;
        
        public OppSobj(String quoteRtId, String packageName){
            this.quoteRtId = quoteRtId;
            this.packageName = packageName;
        }
    }
    
}