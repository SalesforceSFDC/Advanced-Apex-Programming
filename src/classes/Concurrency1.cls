public class Concurrency1 {
    
    public static void delay(Integer seconds)
    {
        List<Integer> largeArray = new List<Integer>();
        for(Integer x =0; x<10000; x++) largeArray.add(x);
        for(Integer counter = 0; counter<seconds * 4; counter++)
        {
            String s = json.serialize(largeArray);
        }
    }

    // Create this opportunity by hand
	private static String opportunityName = 'Concurrency1';
    
    @future
    public static void incrementOptimistic(
    	double amount, Integer delayBefore, 
    	Integer delayFromQuery, Integer delayAfter)
    {
        if(delayBefore>0) delay(delayBefore);
        List<Opportunity> ops = 
        	[Select ID, Amount From Opportunity 
        	where Name = :opportunityName];
        for(Opportunity op: ops)
        	op.Amount = (op.Amount==null)? 
        		amount: op.Amount + Amount;
        if(delayFromQuery>0) delay(delayFromQuery);
        update ops;
        if(delayAfter>0) delay(delayAfter);
    }

    @future
    public static void incrementPessimistic(
    	double amount, Integer delayBefore, 
    	Integer delayFromQuery, Integer delayAfter)
    {
        if(DelayBefore>0) delay(delayBefore);
        List<Opportunity> ops = 
        	[Select ID, Amount From Opportunity 
        	where Name = :opportunityName For Update];
        for(Opportunity op: ops)
        	op.Amount = (op.Amount==null)? 
        		amount: op.Amount + Amount;
        if(delayFromQuery>0) delay(delayFromQuery);
        update ops;
        if(delayAfter>0) delay(delayAfter);
    }


    
    @future
    public static void incrementOptimisticWithCapture(
    	double amount, Integer delayBefore, 
    	Integer delayFromQuery, Integer delayAfter)
    {
        if(delayBefore>0) delay(delayBefore);
        List<Opportunity> ops = 
        	[Select ID, Amount From Opportunity 
        	where Name = :opportunityName];
        for(Opportunity op: ops)
        	op.Amount = (op.Amount==null)? 
        		amount: op.Amount + Amount;
        if(delayFromQuery>0) delay(delayFromQuery);
        List<Database.SaveResult> 
        	dmlResults = Database.Update(ops, false);
		List<Opportunity> failedUpdates = new List<Opportunity>(); 
		for(Integer x = 0; x< ops.size(); x++)
		{
			Database.SaveResult sr = dmlResults[x];
			if(!sr.isSuccess())
			{
				for(Database.Error err: sr.getErrors())
				{
					if(err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW)
					{
						failedUpdates.add(ops[x]);
						break;
					}
				}
			}
			
		}
		
		if(failedUpdates.size()>0)
		{
			// Do a logging or recovery operation here
			recordRecoveryInformation(failedUpdates, amount);
		}
        
        if(delayAfter>0) delay(delayAfter);
    }
    
    @testvisible 
    private static void recordRecoveryInformation(
    	List<Opportunity> failedOps, double amount)
    {
    	List<AsyncRequest__c> requests = new List<AsyncRequest__c>();
    	for(Opportunity op: failedOps)
    	{
    		requests.add(new AsyncRequest__c(AsyncType__c = 'Amount Update', 
    			NewAmount__c = op.Amount, 
    			OriginalAmount__c = op.Amount - amount, 
    			TargetOpportunity__c = op.id ));
    	}
    	insert requests;
    }
   
}