@istest
public class TestTriggersExample {

	private static final Integer numberOfOpportunities = 5;

    static testMethod void testTaskCount() {
    	
    	List<Opportunity> ops = new List<Opportunity>();
    	
        for(Integer x=0; x<numberOfOpportunities; x++)
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
        Test.StartTest();
        update ops;
        Test.StopTest();
        
        Map<ID, Opportunity> opMap = new Map<ID, Opportunity>(ops);
        
        List<task> tasks = 
        	[Select ID, WhatID from Task 
        	where WhatID in :opmap.keyset() 
        	And Subject ='Opportunity stage update'];
        	
        System.AssertEquals(numberOfOpportunities, tasks.size());
    }

}