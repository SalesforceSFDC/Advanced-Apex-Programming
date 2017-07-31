@isTest
private class TestGoingAsync {

	private static Integer bulkTestSize = 101;

    static testMethod void testSolutionsInsert() {
 		
 		List<Solution> sols = new List<Solution>();
 		
 		for(Integer x = 0; x<bulkTestSize; x++)
    	{
    		sols.add(
    			new Solution(
    				SolutionName='solution_' + String.valueOf(x), 
    				Status = 'Draft', 
    				SolutionNote = 'This is solution # ' + String.ValueOf(x) ));
    	}
    	Test.StartTest();

 		Test.setMock(HttpCalloutMock.class, 
 			new SimulatedTranslator.MockTranslator());

		insert sols;
		Test.StopTest();
 
 		Map<ID, Solution> solsmap = new Map<ID, Solution>(sols);
 		
 		List<Solution> results = 
 			[Select ID, SolutionNote, SolutionSpanish__c 
 			from Solution where ID in :solsmap.keyset()];
 		for(Solution sol: results) 
 			System.AssertEquals(sol.SolutionNote + ' in Spanish', 
 				sol.SolutionSpanish__c);
 
    }
    
}