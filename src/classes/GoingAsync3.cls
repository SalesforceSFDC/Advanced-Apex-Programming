public without sharing class GoingAsync3 
	implements queueable, Database.AllowsCallouts {

 	public void execute(QueueableContext context)
    {
    	if(!AppConfigSupport.appEnabled) return; // On/off switch
    	
    	Integer allowedCallouts = 
    		Limits.getLimitCallouts() - Limits.getCallouts();
   		
		if(allowedCallouts<=0) return;
		List<Solution> solutionsToUpdate = 
			[SELECT ID, SolutionNote, SolutionSpanish__c 
			from Solution 
			where LastModifiedDate > :DateTime.Now().addHours(-24) 
			And TranslationPending__c = true LIMIT :allowedCallouts];
		for(Solution sl: solutionsToUpdate)
		{
			sl.SolutionSpanish__c = 
				SimulatedTranslator.translate(sl.SolutionNote);
			sl.TranslationPending__c = false;
		}
		update solutionsToUpdate;
		
		
		if(solutionsToUpdate.size()== allowedCallouts &&
			Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0)
			try
			{
				system.enqueueJob(new GoingAsync3());
			} catch(Exception ex)
			{
				// Alternate chaining mechanism
			}
		
    }
    
    
}