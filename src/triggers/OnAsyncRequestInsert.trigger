trigger OnAsyncRequestInsert on AsyncRequest__c (after insert) {
	if(Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0)
		try
		{
			GoingAsync4.enqueueGoingAsync4(null);
		} catch(Exception ex)
		{
			// Ignore for now
		}

}