@istest
public class TestBulkPatterns {

    static testMethod void bulkOpportunityTest() {
        List<Opportunity> ops = new List<Opportunity>();
        initTestObjects(ops, 100, 20, 20, 40);
        
        Test.StartTest();
        for(Opportunity op: ops) op.StageName = 'Qualification';
        update ops;
        Test.StopTest();
        
        validateOCRs(ops);
        
    }
    
    static testMethod void createTaskTest()
    {
    	Integer numberOfOpportunities = 100;
        List<Opportunity> ops = new List<Opportunity>();
		for(Integer x=0; x<numberOfOpportunities; x++)
		{
			ops.add(new Opportunity(
				CloseDate = Date.Today().addDays(5), 
				Name = 'optest_' + String.valueOf(x), 
				StageName = 'Prospecting' ));	
		}
		
		insert ops;

        Test.StartTest();
        for(Opportunity op: ops) op.StageName = 'Qualification';
        update ops;
        Test.StopTest();

		List<Task> tasks = 
			[SELECT ID, OwnerID, WhatID, Status, Subject, Type 
				from Task 
				where OwnerID = :UserInfo.getUserID() 
				And Type='Other' And IsClosed = False 
				And Subject = 'Assign Primary Contact' ];
		system.assertEquals(NumberOfOpportunities, tasks.size());
    	
    }
 

 
    // Prepare the specified number of opportunities, with contact roles on each.
    // The contact roles are distributed evenly among the number of contacts specified.
    public static void initTestObjects(List<Opportunity> newOpportunities, 
    	Integer numberOfOpportunities, Integer numberOfOtherOpportunities, 
    	Integer contactRolesPerOp, Integer numberOfContacts)
    {
    	if(numberOfContacts < contactRolesPerOp) 
    		numberOfContacts = contactRolesPerOp;

		List<Contact>cts = new List<Contact>();    
		for(Integer x=0;x<numberOfContacts;x++)    
		{      
			cts.add(new Contact(LastName = 'cttest_' + String.valueOf(x)));
		}
		
		insert cts;

		newOpportunities.clear();
		for(Integer x=0; x<numberOfOpportunities; x++)
		{
			newOpportunities.add(
				new Opportunity(CloseDate = Date.Today().addDays(5), 
						Name = 'optest_' + String.valueOf(x), 
						StageName = 'Prospecting' ));	
		}

		// Insert the test opportunities
		insert newOpportunities;
		
		List<Opportunity> otherOpportunities = new List<Opportunity>();
		for(Integer x=0; x<numberOfOtherOpportunities; x++)
		{
			otherOpportunities.add(
				new Opportunity(CloseDate = Date.Today().addDays(5), 
				Name = 'optest_' + String.valueOf(x + NumberOfOpportunities), 
				StageName = 'Prospecting' ));	
		}
		
		insert otherOpportunities;
		// Combine the two for creating OpportunityContactRoles
		otherOpportunities.addall(newOpportunities);	
		
		// Now insert contact roles
		List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
		Integer contactNumber = 0;
		for(Opportunity op: otherOpportunities)
		{
			for(Integer ocrNumber = 0; ocrNumber < contactRolesPerOp; ocrNumber++)
			{
				ocrList.add(
					new OpportunityContactRole(OpportunityID = op.id, 
									ContactID = cts[contactNumber].id));
				contactNumber++;
				if(contactNumber >= numberOfContacts) contactNumber = 0;
			}
			
		}
		insert ocrList;
    }
    
    public static void validateOCRs(List<Opportunity> ops)
    {
    	// Get map for IDs
    	Map<ID, Opportunity> opMap = new Map<ID, Opportunity>(ops);
    	
    	// Query for primary Contacts
    	List<OpportunityContactRole> ocrs = 
    		[SELECT ID, OpportunityID from OpportunityContactRole 
    			where OpportunityID in :opMap.keyset() 
    			And IsPrimary= true];
    	
    	// Create set of opportunity IDs with primary contacts
    	Set<ID> opportunitiesWithPrimaryContact = new Set<ID>();
    	for(OpportunityContactRole ocr: ocrs) 
    		opportunitiesWithPrimaryContact.add(ocr.OpportunityID);
    	
    	// Now make sure every opportunity has a primary contact role
    	for(Opportunity op: ops) 
    		System.Assert(opportunitiesWithPrimaryContact.contains(op.id));

		List<Opportunity> opResults = 
			[SELECT ID, 
				(SELECT ID from OpportunityContactRoles 
					where IsPrimary = true) 
				from opportunity where ID in :opmap.keyset() ];
    	
    	for(Opportunity op: opResults) 
    		System.Assert(op.OpportunityContactRoles.size()==1);	
    }
    
/*
	These are a couple of tests used while writing the book to identify the
	time cost of iterating over a subquery collection
     static testMethod void benchMarkTest1() {
        List<Opportunity> ops = new List<Opportunity>();
        initTestObjects(ops, 100, 20, 20, 40);

		List<OpportunityContactRole > allOCRS = [Select ID, OpportunityID, ContactID from OpportunityContactRole];
        
        Test.StartTest();
			List<Opportunity> opportunities = 
				[Select ID ,(Select ID, ContactID, IsPrimary 
				from OpportunityContactRoles) from Opportunity]; 
			for(Opportunity op: opportunities)
			{
				for(OpportunityContactRole ocr: op.OpportunityContactRoles)
				{
					ID ctid = ocr.ContactID;
				}
			}		

        Test.StopTest();
        
    }
 
      static testMethod void benchMarkTest2() {
        List<Opportunity> ops = new List<Opportunity>();
        initTestObjects(ops, 100, 20, 20, 40);
		List<OpportunityContactRole > allOCRS = [Select ID, OpportunityID, ContactID from OpportunityContactRole];
        
        Test.StartTest();

			Map<ID, List<OpportunityContactRole>> opportunitiesMap = 
				new Map<ID, List<OpportunityContactRole>>();

			for(OpportunityContactRole ocr: allOCRS)
			{
				ID opid = ocr.OpportunityID;	// Use temp variable for speed
				if(!opportunitiesMap.containsKey(opid))
					opportunitiesMap.put(opid, new List<OpportunityContactRole>());
				opportunitiesMap.get(opid).add(ocr);
			}

			 
			for(ID opid: opportunitiesMap.keyset())
			{
				for(OpportunityContactRole ocr: opportunitiesMap.get(opid))
				{
					ID ctid = ocr.ContactID;
				}
			}		

        Test.StopTest();
        
    }
*/    

}