@istest
public class FunWithCollections {
	
	static testMethod void quickSet()
	{
		List<Contact>cts = new List<Contact>();    
		for(Integer x=0;x<5;x++)    
		{      
			cts.add(new Contact(LastName = 'cttest_' + String.valueOf(x)));
		}
		
		insert cts;
		
		Set<ID> contactIds = new Set<ID>();
		for(Contact ct: cts) contactIds.add(ct.id);

		List<Task> tasks = 
			[Select ID from Task 
			where Whoid in :contactIds Limit 500];
		
		Map<ID, Contact> contactMap = new Map<ID, Contact>(cts);
		
		List<Task> tasks2 = 
			[Select ID from Task 
			where Whoid in :contactMap.keyset() Limit 500];
		
	}



	static testMethod void collectionGroup()
	{
		List<Contact>cts = new List<Contact>();    
		for(Integer x=0;x<50;x++)    
		{      
			cts.add(new Contact(LastName = 'cttest_' + String.valueOf(x)));
		}
		
		insert cts;
		
		List<Task> newTasks = new List<Task>();
		for(Integer x=0; x<50; x++)
		{
			newTasks.add(
				new Task(WhoID = cts[x].id, 
						ActivityDate = Date.Today().addDays(x), 
						Description='some task', Type='Call'));			
		}
		insert newTasks;
		
		// cts is the list of input contacts
		Map<ID, Contact> contactMap = new Map<ID, Contact>(cts);
		
		List<Task> tasks = 
			[Select ID, ActivityDate, Description 
			from Task where Whoid in :contactMap.keyset() Order 
			By ActivityDate Desc Limit 500];
		
		Map<Date, List<Task>> tasksByWeek = new Map<Date, List<Task>>();
		
		for(Task t: tasks)
		{
			// Perform global task operation here
			
			
			// Group by week
			Date weekStart = t.ActivityDate.toStartOfWeek();
			if(tasksByWeek.get(weekStart)==null) 
				tasksByWeek.put(weekStart, new List<Task>());
			tasksByWeek.get(weekStart).add(t);
			
			// Perform week related operation here
		}
		
		system.debug(tasksByWeek);
		
		
	}



	static testMethod void caseSensitivity()
	{
		Map<String,Integer> intMap = new Map<String,Integer>{'A'=>0, 'b'=>1, 'C'=>2};
		system.assert(!intMap.containskey('a'));
		system.assert(!intMap.containskey('B'));

	}

    static testMethod void caseOnDescribe() {
        // Get global describe
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        
        System.Assert(gd.ContainsKey('CampaignMember'));
        System.Assert(gd.ContainsKey('campaignmember'));
        System.Assert(gd.ContainsKey('CAMPAIGNMEMBER'));
        system.debug(gd);

        System.Assert(gd.keyset().Contains('campaignmember'));
        System.Assert(!gd.keyset().Contains('CampaignMember'));
        System.Assert(!gd.keyset().Contains('CAMPAIGNMEMBER'));
        
    }
    
    static testMethod void objectKeys()
    {
		List<Contact>cts = new List<Contact>();    
		for(Integer x=0;x<5;x++)    
		{      
			cts.add(new Contact(LastName = 'cttest_' + String.valueOf(x)));
		}
		
		insert cts;

		// Create a map keyed on contacts
		Map<Contact, Integer> contactMap = new Map<Contact, Integer>();
		
		for(Integer x = 0; x< 5; x++)
		{
			contactMap.put(cts[x], x);
		}

		system.assertEquals(contactMap.size(),5);
		
		// Create another list to reference these
		List<Contact> sameContacts = new List<Contact>(cts);

		for(Integer x = 0; x< 5; x++)
		{
			samecontacts[x].AssistantName = 'person' + string.ValueOf(x);
			system.assertEquals(cts[x].AssistantName ,sameContacts[x].AssistantName);
			system.assertNotEquals(contactMap.get(cts[x]), x);
			contactMap.put(sameContacts[x], x);
		}
		system.assertNotEquals(contactMap.size(),5);
		
    	
    }

    static testMethod void objectSets()
    {
		List<Contact>cts = new List<Contact>();    
		for(Integer x=0;x<5;x++)    
		{      
			cts.add(new Contact(LastName = 'cttest_' + String.valueOf(x)));
		}
		
		insert cts;

		// Create a map keyed on contacts
		Set<Contact> contactSet = new Set<Contact>();
		
		for(Integer x = 0; x< 5; x++)
		{
			contactSet.add(cts[x]);
		}

		system.assertEquals(contactSet.size(),5);
		
		// Create another list to reference these
		List<Contact> sameContacts = new List<Contact>(cts);

		for(Integer x = 0; x< 5; x++)
		{
			sameContacts[x].AssistantName = 'person' + string.ValueOf(x);
			system.assertEquals(cts[x].AssistantName ,sameContacts[x].AssistantName);
			system.assert(!contactSet.contains(cts[x]));
			contactSet.add(sameContacts[x]);
		}
		system.assertNotEquals(contactSet.size(),5);
		
    	
    }
    
    static testMethod void objectKeysCorrect()
    {
		List<Contact>cts = new List<Contact>();    
		for(Integer x=0;x<5;x++)    
		{      
			cts.add(new Contact(LastName = 'cttest_' + String.valueOf(x)));
		}
		
		insert cts;

		// Create a map keyed on contacts
		Map<ID, Integer> contactMap = new Map<ID, Integer>();
		
		for(Integer x = 0; x< 5; x++)
		{
			contactMap.put(cts[x].id, x);
		}

		system.assertEquals(contactMap.size(),5);
		
		// Create another list to reference these
		List<Contact> sameContacts = new List<Contact>(cts);

		for(Integer x = 0; x< 5; x++)
		{
			sameContacts[x].AssistantName = 'person' + string.ValueOf(x);
			system.assertEquals(cts[x].AssistantName ,sameContacts[x].AssistantName);
			system.assertEquals(contactMap.get(cts[x].id), x);
			contactMap.put(sameContacts[x].id, x);
		}
		system.assertEquals(contactMap.size(),5);
		
    	
    }    

	static testMethod void LimitUpdates()
	{
		List<Contact>cts = new List<Contact>();    
		for(Integer x=0;x<50;x++)    
		{      
			cts.add(new Contact(LastName = 'cttest_' + String.valueOf(x)));
		}
		
		insert cts;
		
		Map<ID,Contact> contactsToUpdate = new Map<ID, Contact>();
		
		// First set of operations
		for(Contact ct: cts)
		{
			// Do various operations
			// If an update is needed:
			contactsToUpdate.put(ct.id, ct);
			
		}
		
		// Second set of operations
		for(Contact ct: cts)
		{
			// Do various operations
			// If an update is needed:
			contactsToUpdate.put(ct.id, ct);
			
		}

		if(contactsToUpdate.size()>0) update contactsToUpdate.values();
		
		
	}
    
}