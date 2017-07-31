@istest
public class TestThinkingInApexLimits {

    // Demonstration of using a single query for an object and related object to reduce SOQL calls
    // First examples shows a straightforward approach:
    
    static testMethod void testContactsWithAccountRevenue1() {
        // Set up a dummy account and contact
        Account newact = new Account(Name = 'testaccount');
        insert newact;
        Contact newct = new Contact(LastName = 'testcontactln');
        newct.AccountId = newact.id;
        insert newct;
        
        Test.startTest();
        
        // Query for contact info
        List<Contact> cts = [SELECT ID, AccountID from Contact 
        	where Name = 'testcontactln'];
        
        // Some code that operates on the contacts here....
        
        // Get list of account IDs.
        Set<ID> accountIds = new Set<ID>();
        for(Contact ct: cts) 
        	if(ct.AccountID!=null) accountIds.add(ct.AccountID);
        
        if(accountIds.size()>0)
        {
        	List<Account> accounts = [Select ID, AnnualRevenue from Account 
        								where ID in :accountids];
        	for(Account accountfound: accounts) 
        		if(accountfound.AnnualRevenue == null) 
        			accountfound.AnnualRevenue = 500;
        	update accounts;
        }
        
        Test.stopTest();
        
        // Make sure it worked
       	if(accountIds.size()>0)
		{
       		List<Account> accounts2 = [Select ID, AnnualRevenue from Account where ID in :accountids];
       		for(Account accountFound: accounts2) system.assertEquals(500, accountFound.AnnualRevenue);
		}
        
        
    }
    
	// Second example shows how you can use a related query
    static testMethod void testContactsWithAccountRevenue2() {
        // Set up a dummy account and contact
        Account newact = new Account(Name = 'testaccount');
        insert newact;
        Contact newct = new Contact(LastName = 'testcontactln');
        newct.AccountId = newact.id;
        insert newct;
        
        Test.startTest();
        
        // Query for contact info and annual revenue on 
        // account in a single query
        List<Contact> cts = [SELECT ID, AccountID, Account.ID, 
        	Account.AnnualRevenue from Contact 
        	where Name = 'testcontactln'];

        // Some code that operates on the contacts here....
        
        Map<ID, Account> accountsToUpdate = new Map<ID,Account>();
        
        for(Contact ct: cts)
        {
        	if (ct.Account.AnnualRevenue == null) 
        	{
        		ct.Account.AnnualRevenue = 500;
        		accountsToUpdate.put(ct.AccountID, ct.Account);
        	}
        }
        
		if(accountsToUpdate.size()>0) 
			update accountsToUpdate.values();
        
        Test.stopTest();
        
        // Make sure it worked
       	if(accountsToUpdate.size()>0)
		{
       		List<Account> accounts2 = [Select ID, AnnualRevenue from Account where ID in :accountstoupdate.keyset()];
       		for(Account accountFound: accounts2) system.assertEquals(500, accountFound.AnnualRevenue);
		}
        
        
    }   

}