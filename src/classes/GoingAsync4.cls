public without sharing class GoingAsync4
	implements queueable, Database.AllowsCallouts {

	// Version of execute at the end of chapter 7
	/*
 	public void execute(QueueableContext context)
    {
    	if(!AppConfigSupport.appEnabled) return; // On/off switch
    	List<AsyncRequest__c> requests;
    	try
    	{
	    	requests = [Select ID, AsyncType__c, Params__c 
	    		from AsyncRequest__c 
	    		where Error__c = false And
	    		CreatedById = :UserInfo.getUserId() 
	    		Limit 1 for update];
    	}
    	catch(Exception ex) { return; }
    	if(requests.size()==0 ) return;
    	
    	AsyncRequest__c currentRequest = requests[0];
    	
    	try
    	{
    		if(currentRequest.AsyncType__c=='Translate Solution') 
    			translate(currentRequest);
    		
    		// Add more here
    		
    		delete currentRequest;
    		// Optional
    		database.emptyRecycleBin(new List<ID>{currentRequest.id}); 
    		
    	}
    	catch(Exception ex)
    	{
    		currentRequest.Error__c = true;
    		currentRequest.Error_Message__c = ex.getMessage();
    		update currentRequest;
    	}

    	List<AsyncRequest__c> moreRequests = [Select ID, AsyncType__c, Params__c 
    		from AsyncRequest__c 
    		where Error__c = false 
    		and ID <> :currentRequest.id 
    		and	CreatedById = :UserInfo.getUserId() 
    		Limit 1 ];
    	
    	if(moreRequests.size()==0) return;
    	
		try
		{
			enqueGoingAsync4(context.getJobId());
		}
		catch(Exception ex)
		{
			tryToQueue();
		}
		
    }
    */

	// Version of execute at the end of chapter 8
 	public void execute(QueueableContext context)
    {
    	if(!AppConfigSupport.appEnabled) return; // On/off switch
    	List<AsyncRequest__c> requests;
    	try
    	{
	    	requests = [Select ID, AsyncType__c, Params__c,
	    		NewAmount__c, OriginalAmount__c, TargetOpportunity__c 
	    		from AsyncRequest__c 
	    		where Error__c = false And
	    		CreatedById = :UserInfo.getUserId() 
	    		Limit 1 for update];
    	}
    	catch(Exception ex) { return; }
    	if(requests.size()==0 ) return;
    	
    	AsyncRequest__c currentRequest = requests[0];
    	
    	try
    	{
    		if(currentRequest.AsyncType__c=='Translate Solution') 
    			translate(currentRequest);
    		
    		if(currentRequest.AsyncType__c=='Amount Update') 
    			updateAmounts(currentRequest);

    		// Add more here
    		
    		delete currentRequest;
    		// Optional
    		database.emptyRecycleBin(new List<ID>{currentRequest.id}); 
    		
    	}
    	catch(Exception ex)
    	{
    		currentRequest.Error__c = true;
    		currentRequest.Error_Message__c = ex.getMessage();
    		update currentRequest;
    	}

    	List<AsyncRequest__c> moreRequests = [Select ID, AsyncType__c, Params__c 
    		from AsyncRequest__c 
    		where Error__c = false 
    		and ID <> :currentRequest.id 
    		and	CreatedById = :UserInfo.getUserId() 
    		Limit 1 ];
    	
    	if(moreRequests.size()==0) return;
    	
		try
		{
			enqueueGoingAsync4(context.getJobId());
		}
		catch(Exception ex)
		{
			tryToQueue();
		}
		
    }

	public static void enqueueGoingAsync4(ID currentJobId)
	{
		List<AsyncApexJob> jobs = [Select ID, Status, ExtendedStatus from AsyncApexJob 
					where JobType = 'Queueable' And (status='Queued'  Or Status='Holding') 
					and CreatedById = :userinfo.getUserID() and 
					ApexClass.Name='GoingAsync4' and ID!= :currentJobId Limit 1 ];
		if(jobs.size()==1) return;	// Already have one queued that isn't this one.
		
		system.enqueueJob(new GoingAsync4());
	}

    
    @future
    private static void tryToQueue()
    {
    	if(!AppConfigSupport.appEnabled) return; // On/off switch
    	try
    	{
			if(Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0)
				enqueueGoingAsync4(null);
    	}
    	catch(Exception ex)
    	{
    		// Wait for someone else to make a request...
    		// Or maybe use scheduled Apex?
    	}
    }
    
    public void translate(AsyncRequest__c request)
    {
    	Integer allowedCallouts = 
    	Limits.getLimitCallouts() - Limits.getCallouts();
		if(allowedCallouts<=0) return;
		
		List<ID> idsAfterSplit = request.Params__c.split(',');
		
		List<Solution> solutionsToUpdate = 
			[SELECT ID, SolutionNote, SolutionSpanish__c 
			from Solution 
			where ID in :idsAfterSplit 
			LIMIT :allowedCallouts];
		for(Solution sl: solutionsToUpdate)
		{
			sl.SolutionSpanish__c = 
				SimulatedTranslator.translate(sl.SolutionNote);
			sl.TranslationPending__c = false;
		}
		update solutionsToUpdate;
    }

	public void updateAmounts(AsyncRequest__c request)
	{
		List<Opportunity> ops = 
			[Select ID, Amount from Opportunity 
			 where ID = :request.TargetOpportunity__c for update];
		if(ops.size()==0) return; // The op may have been deleted 
		Opportunity op = ops[0];
		
		// Implement update scneario here

		// Option #1
		//op.Amount = request.NewAmount__c;

		// Option #2
		op.Amount += (request.NewAmount__c - 
						request.OriginalAmount__c);

		// Option #3
		if(op.Amount!= request.OriginalAmount__c)
		{
			// Concurrency error - throw an exception here
			throw new AsyncUpdateException(
				'Amount on opportunity update has changed');
		}

		try
		{
			update op;
		}
		catch(DmlException dex)
		{
			if(dex.getDmlType(0) == StatusCode.UNABLE_TO_LOCK_ROW)
			{
				insert request.clone();
				return;
			}
			throw dex;
		}
		// Any other exception will not be caught

	}

	public class AsyncUpdateException extends Exception {}

}