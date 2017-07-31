@istest
public class TestDiagnostics2 {

    static testMethod void updateOpportunityTest() {
        List<Opportunity> ops = new List<Opportunity>();
        initTestObjects(ops, 100, 20, 20, 40);

        DiagnosticsInstrumentation.Debug('Starting testing: bulkOpportunityTest');
        Test.StartTest();
        for(Opportunity op: ops) op.StageName = 'Qualification';
        update ops;
        Test.StopTest();
        
        validateOCRs(ops);
        
    }

    @istest(oninstall=true seealldata=false)
    static void createTaskTestSingle()
    {
    	createTaskTest(1);
    }

    @istest(oninstall=false seealldata=false)
    static void createTaskTestBulk()
    {
    	createTaskTest(100);
    }
    
    static void createTaskTest(Integer numberOfOpportunities)
    {
        List<Opportunity> ops = 
        	createOpportunities('optest_', numberOfOpportunities);
		for(Opportunity op: ops)
		{
			op.CloseDate = Date.Today().addDays(5);
			op.StageName = 'Prospecting';	
		}
		insert ops;

        diagnosticsInstrumentation.Debug(
        	'Starting testing: CreateTastTest');
        Test.StartTest();
        for(Opportunity op: ops) op.StageName = 'Qualification';
        update ops;
        Test.StopTest();

		List<Task> tasks = 
			[SELECT ID, OwnerID, WhatID, Status, Subject, Type 
			from Task where OwnerID = :UserInfo.getUserID() 
			And Type='Other' And IsClosed = False 
			And Subject = 'Assign Primary Contact'   ];

		system.assertEquals(numberOfOpportunities, tasks.size());
    	
    }
    
	private static final Integer numberOfStageUpdateOpportunities = 5;

    static testMethod void testTaskCount() {
    	
    	if(isTestDisabled(1)) return;
    	
    	List<Opportunity> ops = createOpportunities(
    		'optest_', numberOfStageUpdateOpportunities);
    	
        for(Opportunity op: ops)
		{
			op.CloseDate = Date.Today().addDays(5);
			op.StageName = 'Prospecting' ;	
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
        	
        //System.AssertEquals(numberOfStageUpdateOpportunities, tasks.size());
        System.AssertEquals(numberOfStageUpdateOpportunities, tasks.size(),
        	'Error in TestTaskCount. Stacktrace: ' + 
        	DiagnosticsInstrumentation.exceptionTrace);

    }
  
  	static testmethod void testFakeException()
  	{
  		DiagnosticsMain.fakeException = true;
  		DiagnosticsInstrumentation.diagnosticsEnabled = true;
    	List<Opportunity> ops = 
    		createOpportunities('optest_', numberOfStageUpdateOpportunities);
    	
        for(Opportunity op: ops)
		{
			op.CloseDate = Date.Today().addDays(5);
			op.StageName = 'Prospecting' ;	
		}
		Test.StartTest();
		insert ops;
		Test.StopTest();
		
		List<DebugInfo__c> dbg = [Select ID from DebugInfo__c];
		system.assert(dbg.size()>0);
		
  	}  
  
    // Prepare the specified number of opportunities, with contact roles on each.
    // The contact roles are distributed evenly among the number of contacts specified.
    public static void initTestObjects(List<Opportunity> newOpportunities, 
    	Integer numberOfOpportunities, Integer numberOfOtherOpportunities, 
    	Integer contactRolesPerOp, Integer numberOfContacts)
    {
    	if(numberOfContacts < contactRolesPerOp) 
    		numberOfContacts = contactRolesPerOp;

		List<Contact>cts = createContacts('cttest_', numberOfContacts);    
		
		insert cts;

		newopportunities = createOpportunities(
			'optest_', numberOfOpportunities);
		for(Opportunity op: newOpportunities)
		{
			op.CloseDate = Date.Today().addDays(5);
			op.StageName = 'Prospecting';	
		}
		
		// Insert the test opportunities
		insert newOpportunities;
		
		List<Opportunity> otherOpportunities = 
			createOpportunities('optest2_', numberOfOtherOpportunities);
		for(Opportunity op:otherOpportunities)
		{
			op.CloseDate = Date.Today().addDays(5);
			op.StageName = 'Prospecting';	
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
			where IsPrimary = true) from opportunity 
			where ID in :opmap.keyset() ];
    	for(Opportunity op: opresults) 
    		System.Assert(op.OpportunityContactRoles.size()==1);	
    }
    
    public static List<Opportunity> createOpportunities
    	(String baseName, Integer count)
    {
    	List<Opportunity> results = new List<Opportunity>();
    	for(Integer x = 0; x< count; x++)
    	{
			//results.add(new Opportunity(Name = baseName + String.valueOf(x) ));
			Opportunity op = (Opportunity)Opportunity.sObjectType.newSObject(null, true);
			op.Name = baseName + String.valueOf(x);
			results.add(op);
    	}
		setDefaultFields('Opportunity', results);
		return results;	
    	
    }
    
    public static List<Contact> createContacts(String baseName, Integer count)
    {
    	List<Contact> results = new List<Contact>();
    	
    	for(Integer x = 0; x< count; x++)
    	{
			//results.add(new Contact(LastName = baseName + String.valueOf(x) ));
			Contact ct = (Contact)Contact.sObjectType.newSObject(null, true);
			ct.LastName = baseName + String.valueOf(x);
			results.add(ct);
    	}
		
		return results;	
    	
    }
    
    public static List<Account> createAccounts(String baseName, Integer count)
    {
    	List<Account> results = new List<Account>();
    	
    	for(Integer x = 0; x< count; x++)
    	{
			//results.add(new Account(Name = baseName + String.valueOf(x) ));
			Account act = (Account)Account.sObjectType.newSObject(null, true);
			act.Name = baseName + String.valueOf(x);
			results.add(act);
    	}
		
		return results;	
    	
    }


    public static Boolean isTestDisabled(Integer testNumber)
    {
    	List<StaticResource> resources = 
    		[Select Body from StaticResource 
    		where Name = 'Apx1Predeployment' ];
    	if(resources.size()==0) return false;
    	String contents = resources[0].Body.ToString();
    	if(contents==null) return false;
    	List<String> lines = contents.split('\\n');
    	for(String line:lines)
    	{
    		List<String> entries = line.split(':');
    		system.debug('entries ' + entries);
    		try
    		{
    			if(entries[0]=='disable' && 
    				Integer.valueOf(entries[1].trim())== testnumber) 
    				return true;
    		}
    		catch(Exception ex){}
    	}
    	return false;
    }
    
	public static Boolean setDefaultFields(String objectType, List<SObject> theObjects)
    {
    	List<StaticResource> resources = 
    		[Select Body from StaticResource 
    		where Name = 'Apx1Predeployment' ];
    	if(resources.size()==0) return false;
    	String contents = resources[0].Body.ToString();
    	if(contents==null) return false;
    	List<String> lines = contents.split('\\n');
    	for(String line:lines)
    	{
    		List<String> entries = line.split(':');
    		try
    		{
    			if(entries[0]==objectType)
    			{
    				List<String> fieldinfo = entries[1].split('=');
    				for(SObject obj: theObjects)
    				{
						// Implemented only for strings
    					obj.put(fieldinfo[0], fieldinfo[1]);	
    				}
    			}
    		}
    		catch(Exception ex){}
    	}
    	return false;
    }    

}