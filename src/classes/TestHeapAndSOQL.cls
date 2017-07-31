@isTest
private class TestHeapAndSOQL {

	@testsetup static void setup()
	{
		// Build a 10K long string for description
		String longString = '';
		for(Integer x = 0; x<500; x++) longstring += '0123456789';
		
		List<Lead> newLeads = new List<Lead>();
		for(Integer x = 0; x<8000; x++)
			newLeads.add(new Lead(
				Company = 'comp' + string.ValueOf(x), 
				LastName = 'joe'+string.ValueOf(x),
				Description = longString));
		insert newLeads;
	}


    static testMethod void testAllRecords() {
        
        Test.startTest();
        
        List<String> leadNames = new List<String>();
        
        List<Lead> leads = [Select ID, Company, LastName, Description from Lead];
        system.debug(logginglevel.info, 'lead count ' + leads.size());
        for(Lead ld: leads) leadNames.add(ld.LastName);

        ShowLimits();
        Test.stopTest();
        
    }

    static testMethod void testSoqlLoop1() {
        
        Test.startTest();
        
        List<String> leadNames = new List<String>();
        
        for(List<Lead> leads: [Select ID, Company, LastName, Description from Lead])
        	{
		        system.debug(logginglevel.info, 'lead count ' + leads.size());
	        	for(Lead ld: leads) leadNames.add(ld.LastName);
        	}
        ShowLimits();
        Test.stopTest();
        
    }

    static testMethod void testSoqlLoop2() {
        
        Test.startTest();
        
        List<String> leadNames = new List<String>();
        
        for(Lead ld: [Select ID, Company, LastName, Description from Lead])
        	leadNames.add(ld.LastName);
        
        ShowLimits();
        Test.stopTest();
        
    }

	private static void ShowLimits()
	{
		system.debug(LoggingLevel.info, 'SOQL count ' + limits.getQueries());
		system.debug(LoggingLevel.info, 'SOQL rows ' + limits.getQueryRows());
		system.debug(LoggingLevel.info, 'Heap size ' + limits.getHeapSize());
		
	}


}