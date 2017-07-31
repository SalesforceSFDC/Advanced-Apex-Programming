@isTest
private class TestDiagnostics1 {

    static testMethod void updateOpportunityTest() {
        List<Opportunity> ops = new List<Opportunity>();
        initTestObjects(ops, 100, 100, 40, 80);
        
        DiagnosticsInstrumentation.Debug(
        	'Starting testing: UpdateOpportunityTest');
        Test.StartTest();
        for(Opportunity op: ops) 
        	op.StageName = 'Qualification';
        update ops;
        Test.stopTest();
        
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

        DiagnosticsInstrumentation.Debug('Starting testing: CreateTaskTest');
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
    
	private static final Integer numberOfStageUpdateOpportunities = 5;

    static testMethod void testTaskCount() {
    	
    	List<Opportunity> ops = new List<Opportunity>();
    	
        for(Integer x=0; x<numberOfStageUpdateOpportunities; x++)
		{
			ops.add(
				new Opportunity(CloseDate = Date.Today().addDays(5), 
				Name = 'optest_' + String.valueOf(x), 
				StageName = 'Prospecting' ));	
		}
		
		insert ops;
        
        for(Opportunity op: ops)
        {
        	op.StageName = 'Negotiation/Review';
        }

        DiagnosticsInstrumentation.Debug('Starting testing: testTaskCount');
        Test.StartTest();
        update ops;
        Test.StopTest();
        
        Map<ID, Opportunity> opMap = new Map<ID, Opportunity>(ops);
        
        List<task> tasks = 
        	[Select ID, WhatID from Task 
        	where WhatID in :opmap.keyset() 
        	And Subject ='Opportunity stage update'];
        	
        System.AssertEquals(numberOfStageUpdateOpportunities, tasks.size());
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
    	
		List<Opportunity> opresults = 
			[SELECT ID, (SELECT ID from OpportunityContactRoles 
			where IsPrimary = true) 
			from opportunity where ID in :opmap.keyset() ];

    	for(Opportunity op: opResults) 
    		System.Assert(op.OpportunityContactRoles.size()==1);	
    }
    
}