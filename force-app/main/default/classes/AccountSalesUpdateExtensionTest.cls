/*
// (c) 2018 Appirio (A Wipro company), Inc.
//
// AccountSalesUpdateExtensionTest: Test class for AccountSalesUpdateExtension
//
// 03 July 2018      Jai Gupta       Original (S-564242) Account Update and Sales Update button on Account and Lead
//												AccountSalesUpdateExtension : 100%
//
*/
@isTest
private class AccountSalesUpdateExtensionTest {
	
	@isTest static void test_method_one() {
		Lead l = new Lead();
		l.LastName = 'Test Lead';
		l.Company = 'Test Company' ;
		insert l ;
		
		ApexPages.currentPage().getParameters().put('leadId',l.Id);
		ApexPages.currentPage().getParameters().put('type','accountupdate');
		AccountSalesUpdateExtension obj = new AccountSalesUpdateExtension();
		Test.startTest();
			obj.startUpAction();
		Test.stopTest();
	}
	
	@isTest static void test_method_two() {
		// Implement test code
		Account a = new Account();
        a.name    = 'TEST';
		a.Primary_Asset_Class__c = 'Credit';
        a.Client_Type__c = 'Broking';
		insert a ;
		ApexPages.currentPage().getParameters().put('accid',a.Id);
		ApexPages.currentPage().getParameters().put('type','salesupdate');
		AccountSalesUpdateExtension obj = new AccountSalesUpdateExtension();
		Test.startTest();
			obj.startUpAction();
		Test.stopTest();
	}
	
}