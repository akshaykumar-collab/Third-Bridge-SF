/*
// (c) 2018 Appirio (A Wipro company), Inc.
//
// AccountSalesUpdateExtension: Extension class for AccountSalesUpdate
//
// 03 July 2018      Jai Gupta       Original (S-564242) Account Update and Sales Update button on Account and Lead
//
*/
public with sharing class AccountSalesUpdateExtension {
    
    public Id whatId ;
    public Id whoId ;
    public id returnUrlId ; 
    public string type ;
    public string taskSubject = 'Call' ;
    public User assignedTo ;
    public string accountupdateusername = System.Label.AccountUpdateUserName ;
    public string salesupdateusername = System.Label.SalesUpdateUserName ;
    
    public AccountSalesUpdateExtension() {
    
        whatId = ApexPages.currentPage().getParameters().get('accid');
        whoId = ApexPages.currentPage().getParameters().get('leadId');
        type = ApexPages.currentPage().getParameters().get('type');
        
        if(type == 'accountupdate') {
            // redirect to account update
            List<User> accountupdateuser = new List<User>([Select Id,Name from User where Name = :accountupdateusername]);
            if(accountupdateuser.size() > 0) {
                assignedTo =  accountupdateuser[0];
            }
            
        } else if(type == 'salesupdate') {
            List<User> salesuser = new List<User>([Select Id,Name from User where Name = :salesupdateusername]);
            if(salesuser.size() > 0) {
                assignedTo =  salesuser[0];
            }
        }
    }
    
    public string assignedToField = 'tsk1' ;
    public string assignedToFUField = 'tsk1_fu' ;
    public string whatIdField = 'what_id';
    public string whoIdField = 'who_id';
    public string subject = 'tsk5';
   
    
    public pageReference startUpAction() {
        List<String> params = new List<String>();
        string pgurl = '/00T/e?title=Call&followup=1&nooverride=1&' ;
        params.add(assignedToField+'='+assignedTo.Name);
        params.add(assignedToField+'_lkid='+assignedTo.Id);
        params.add(assignedToFUField+'='+assignedTo.Name);
        params.add(assignedToFUField+'_lkid='+assignedTo.Id);
        
        if(whatId != null) {
            params.add(whatIdField+'='+whatId);
            returnUrlId = whatId ;
        }
        
        if(whoId != null) {
            params.add(whoIdField+'='+whoId);
            returnUrlId = whoId ;
        }
        
        if(returnUrlId != null) {
            params.add('retURL=/'+returnUrlId);
        }
        
        params.add(subject+'=Call');
        
        pgurl += String.join(params,'&');
        PageReference parrec = new PageReference(pgurl);
        parrec.setRedirect(true);
        return parrec;
    
    }
}