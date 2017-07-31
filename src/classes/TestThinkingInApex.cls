@isTest
private class TestThinkingInApex {

	// This test will fail when OnOpportunity1 trigger is enabled
    static testMethod void testOCRs1()
    {
    	Opportunity op = new Opportunity( 
    		name='optest', StageName ='Prospecting', 
    		CloseDate = Date.Today() );
    	
    	insert op;
    }

    static testMethod void testOCRs2()
    {
    	Opportunity op = new Opportunity( 
    		name='optest', StageName ='Prospecting', 
    		CloseDate = Date.Today() );
    	
    	Contact ct = new Contact(LastName = 'newct');
    	insert ct;
    	ThinkingInApex.associateContacts = new List<Contact>{ct};

    	insert op;
    }
    
}