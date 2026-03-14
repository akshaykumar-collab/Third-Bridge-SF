public class BatchConvertLeads implements Database.Batchable<sObject> {
    public String campaignId;
    public String memberStatus;
    public List<Account> accountsInactive = new List<Account>();

    public BatchConvertLeads(String campaign, String status) {
        campaignId = campaign;
        memberStatus = status;
    }

    public List<sObject> start(Database.BatchableContext context) {
        List<String> leadIds = new List<String>();
        List<CampaignMember> campaignMembers = [SELECT LeadId FROM CampaignMember WHERE CampaignId =: campaignId AND Status =: memberStatus AND LeadId != null];
        for(CampaignMember cm : campaignMembers) {
            leadIds.add(cm.LeadId);
        }

        System.debug(leadIds);
        System.debug(leadIds.size());

        return [SELECT Id, Name, Status, Company, Email, Close_Reason__c, IsConverted FROM LEAD WHERE Id IN: leadIds AND IsConverted = FALSE AND Country__c != NULL];
    }

    public void execute(Database.BatchableContext context, List<Lead> leads) {
        List<String> companyNames = new List<String>();
        Map<String, Account> accountMap = new Map<String, Account>();
        LeadStatus convertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        List<Id> unconvertedLeads = new List<Id>();
        List<Id> inactiveOwner = new List<Id>();

        //Set to Qualified with Reason of 'Data Enrichment'; get Company names
        for(Lead l : leads) {
            
            companyNames.add(l.Company);
            l.Status = 'Qualified';
            l.Close_Reason__c = 'Data Enrichment';
        }
        Database.update(leads, false);

        //Get Accounts from list of Company names and add to Map
        List<Account> accountsActive = [SELECT Id, Name, OwnerId, Owner.IsActive, Owner.Name FROM Account WHERE Name IN: companyNames];
        for(Account a : accountsActive) {
            if(!accountMap.containsKey(a.Name)) {
                accountMap.put(a.Name, a);
            }
        }

        List<Account> inactiveAcc = [SELECT Id, Name, OwnerId, Owner.Name, Owner.IsActive FROM Account WHERE Name IN: companyNames AND Owner.IsActive = FALSE];
        for(Account a : inactiveAcc) {
            if(!accountsInactive.contains(a)) {
                accountsInactive.add(a);
            }
        }
        

        
        for(Lead l : leads) {
            System.debug(l.Name);
            //If Company name is in Account Map, convert Lead
            if(accountMap.containskey(l.Company)) {
                if(accountMap.get(l.Company).Owner.IsActive) {
                    try{
                        Database.LeadConvert lc = new Database.LeadConvert();
                        lc.setLeadId(l.id);
                        lc.setDoNotCreateOpportunity(true);
                        lc.setConvertedStatus(convertedStatus.MasterLabel);

                        //Find Account in Map and set Account ID and Owner for conversion
                        Account account = accountMap.get(l.Company);
                        lc.setAccountId(account.Id);
                        lc.setOwnerId(account.OwnerId);

                        //If a Contact already exists with this Lead's Name and Email, merge the Lead into that Contact on conversion
                        List<Contact> contact = [SELECT Id FROM Contact WHERE Name =: l.Name AND Email =: l.Email LIMIT 1];
                        if(contact.size() > 0) {
                            lc.setContactId(contact[0].Id);
                        }

                        Database.LeadConvertResult lcr = Database.convertLead(lc);
                        System.debug(lcr);
                    }catch(Exception e) {
                        System.debug(l.Name);
                        System.debug(e);
                    }
                } else {
                    inactiveOwner.add(l.Id);
                }
                
            } 
            //Else add to list of Unconverted Leads so the Campaign Member can have its status changed
            else {
                unconvertedLeads.add(l.Id);
            }
        }

        //Change Campaign Member status of unconverted Leads to Assigned - No Matching Account
        List<CampaignMember> noAccountCM = [SELECT Id FROM CampaignMember WHERE CampaignId =: campaignId AND LeadId IN: unconvertedLeads];
        for(CampaignMember cm : noAccountCM) {
            cm.Status = 'Assigned - No Matching Account';
        }
        Database.update(noAccountCM, false);

        List<CampaignMember> inactiveAccountCM = [SELECT Id FROM CampaignMember WHERE CampaignId =: campaignId AND LeadId IN: inactiveOwner];
        for(CampaignMember cm : inactiveAccountCM) {
            cm.Status = 'Assigned - Inactive AM';
        }
        Database.update(inactiveAccountCM, false);
    }

    public void finish(Database.BatchableContext context) {
        if(accountsInactive.size() > 0) {
            accountListCSV(accountsInactive);
        }
        System.debug('Batch Insert Complete');
    }

    //Converts List of Accounts with Inactive Owners to a CSV file
    public static void accountListCSV(List<Account> accounts) {
        String csvBody = 'Id,Name,Owner ID,Owner Name\n';

        for(Account a : accounts) {
            String row = a.Id + ',' + a.Name + ',' + a.OwnerId + ',' + a.Owner.Name + '\n';
            csvBody += row;
        }

        ContentVersion newCSVFile = new ContentVersion();
        newCSVFile.title = 'Mass Convert Inactive Accounts - ' + System.now();
        newCSVFile.VersionData = Blob.valueOf(csvBody);
        newCSVFile.PathOnClient = newCSVFile.title + '.csv';

        try {
            insert newCSVFile;
            System.debug('CSV Creation Successful!');
        }catch(Exception e) {
            System.debug(e);
        }
        
    }
}