public class GoingAsync1 {

	// Simple protection from workflows and triggers
	private static Boolean alreadyProcessed = false;	

	public static void handleTrigger1(List<Solution> solutionList, 
		Map<ID, Solution> newMap, Map<ID, Solution> oldMap, 
		Boolean isInsert)
	{
		if(alreadyProcessed) return;
		alreadyProcessed = true;
		if(isInsert) firstAttempt(newMap.keyset());
		else
		{
			Set<ID> textChangedIds = new Set<ID>();
			for(Solution sl: solutionList)
			{
				if(sl.SolutionNote!= oldMap.get(sl.id).SolutionNote) 
					textChangedIds.add(sl.id); 
			}
			if(textChangedIds.size()>0) firstAttempt(textChangedIds);
		}

	}
	
	
	@future(callout=true)
	public static void firstAttempt(Set<ID> solutionIds)
	{
		List<Solution> solutionsToUpdate = 
			[SELECT ID, SolutionNote, SolutionSpanish__c 
			from Solution where ID in :solutionids];
		for(Solution sl: solutionsToUpdate) 
			sl.SolutionSpanish__c = SimulatedTranslator.translate(sl.SolutionNote);
		update solutionsToUpdate;
	}


	public static void handleTrigger2(List<Solution> solutionlist, 
		Map<ID, Solution> oldmap, Boolean isInsert)
	{
		if(alreadyProcessed) return;
		alreadyProcessed = true;
		for(Solution sl:solutionlist)
		{
			if(isInsert || sl.SolutionNote!= oldMap.get(sl.id).SolutionNote) 
				sl.TranslationPending__c = true; 
		}
		secondAttemptRequestAsync();
	}
	
	public static void secondAttemptRequestAsync()
	{
		if(system.isFuture() || system.isBatch()) secondAttemptSync();
		else
		{
			if(Limits.getFutureCalls()< Limits.getLimitFutureCalls()-3)
				secondAttemptAsync();
		}
	}

	@future(callout=true)
	private static void secondAttemptAsync()
	{
		secondAttemptSync();
	}
	
	public static void secondAttemptSync()
	{
		Integer allowedCallouts = Limits.getLimitCallouts() - Limits.getCallouts();
		if(allowedCallouts<=0) return;
		List<Solution> solutionsToUpdate = 
			[SELECT ID, SolutionNote, SolutionSpanish__c 
			from Solution 
			where LastModifiedDate > :DateTime.Now().addHours(-24) 
			And TranslationPending__c = true LIMIT :allowedCallouts];
		if(solutionsToUpdate.size()==0) return;
		for(Solution sl: solutionsToUpdate)
		{
			sl.SolutionSpanish__c = SimulatedTranslator.translate(sl.SolutionNote);
			sl.TranslationPending__c = false;
		}
		update solutionsToUpdate;
		
	}

	public static void handleTrigger3(List<Solution> solutionlist, 
		Map<ID, Solution> oldmap, Boolean isInsert)
	{
		if(alreadyProcessed) return;
		alreadyProcessed = true;
		Boolean foundOne = false;
		for(Solution sl:solutionlist)
		{
			if(isInsert || sl.SolutionNote!= oldMap.get(sl.id).SolutionNote) 
			{
				sl.TranslationPending__c = true;
				foundOne = true;
			} 
		}
		if(foundOne) GoingAsync2.StartBatch(false);
	}
	
	public static void handleTrigger4(List<Solution> solutionlist, 
		Map<ID, Solution> oldmap, Boolean isInsert)
	{
		if(alreadyProcessed) return;
		alreadyProcessed = true;
		Boolean foundOne = false;
		for(Solution sl:solutionlist)
		{
			if(isInsert || sl.SolutionNote!= oldMap.get(sl.id).SolutionNote) 
			{
				sl.TranslationPending__c = true;
				foundOne = true;
			} 
		}
		if(foundOne && (Limits.GetLimitQueueableJobs() - Limits.GetQueueableJobs() > 0))
			system.EnqueueJob(new GoingAsync3());
	}

	public static void handleTrigger5(List<Solution> solutionList, 
		Map<ID, Solution> newMap, Map<ID, Solution> oldMap, 
		Boolean isInsert)
	{
		if(alreadyProcessed) return;
		alreadyProcessed = true;
		List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();

		List<String> textChangedIds = new List<ID>();
		for(Solution sl: solutionList)
		{
			if(isInsert || sl.SolutionNote!= oldMap.get(sl.id).SolutionNote) 
				textChangedIds.add(sl.id); 
			if(textChangedIds.size()>=100)
			{
				newAsyncRequests.add(
					new AsyncRequest__c(AsyncType__c = 'Translate Solution',
							Params__c = string.Join(textChangedIds,',')));
				textChangedIds.clear();
			}
		}

		if(textChangedIds.size()>0)
			newAsyncRequests.add(
				new AsyncRequest__c(AsyncType__c = 'Translate Solution',
							Params__c = string.Join(textChangedIds,',')));

		insert newAsyncRequests;
	}
	
}