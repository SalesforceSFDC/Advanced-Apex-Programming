global class GoingAsync2 implements 
	Database.Batchable<SObject>, 
	Database.AllowsCallouts {

	global Database.Querylocator start(Database.BatchableContext bc)
	{
		return Database.getQueryLocator('SELECT ID, SolutionNote, SolutionSpanish__c From Solution Where TranslationPending__c = true');
	}

	global void execute(Database.BatchableContext BC, List<Solution> scope)
	{

		for(Solution sl: scope)
		{
			sl.SolutionSpanish__c = SimulatedTranslator.translate(sl.SolutionNote);
			sl.TranslationPending__c = false;
		}
		update scope;
		
	}

	global void finish(Database.BatchableContext BC)
	{
		List<Solution> stillPending = 
			[SELECT ID From Solution 
			Where TranslationPending__c = true Limit 1];
		if(stillPending.size()>0) StartBatch(true);
	}

	public static Boolean isBatchActive(String classname)
	{
		List<String> activeStatuses = 
			new List<String>{'Completed','Aborted','Failed'};
		AsyncApexJob[] activeJobs = 
			[select id, CompletedDate, Status, ExtendedStatus, ApexClassID 
			from AsyncApexJob where ApexClass.Name = :classname 
			and JobType='BatchApex' 
			And Status Not in :activeStatuses 
			Order By CreatedDate Desc Limit 1];
		return activeJobs.size() >0;
	}

	private static Boolean batchRequested = false;

	public static void startBatch(Boolean forceStart)
	{
		if(!forceStart && 
			(batchRequested || isBatchActive('GoingAsync2'))) return;
		
		GoingAsync2 ga = new GoingAsync2();
		Integer batchSize = Limits.getLimitCallouts();
		if(batchSize>200) batchSize = 200;
		try
		{
			Database.executeBatch(ga, batchSize);
		} catch(Exception ex)
		{
			return;
		}
		
		batchRequested = true;
	}



}