@isTest
public class TestLightningConnectQuickstart {
    public static testMethod void tester() {
        LightningConnectQuickstart.getCustomerIDsSet();
        /*
        List<Account> accs = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            
            //SSANDHU CASE 224018 START
            accs.add(new Account(name = 'Test '+i, Primary_Asset_Class__c = 'Credit', Client_Type__c = 'Broking', Country__c = 'United States'));
            //SSANDHU CASE 224018 END
        }
        
        insert accs;
        
        LightningConnectQuickstart qs = new LightningConnectQuickstart();
        
        Boolean state = qs.getCustomerIDsSet();
        
        System.assertEquals(false, state, 'IDs should not be set');
        
        qs.setCustomerIDs();

        state = qs.getCustomerIDsSet();
        
        System.assertEquals(true, state, 'IDs should be set');

        // Double check!
        accs = [SELECT Id 
                FROM Account 
                //WHERE Customer_Id__c = null
                ];
        
        System.assertEquals(0, accs.size(), 'IDs should be set');
*/
    }
}