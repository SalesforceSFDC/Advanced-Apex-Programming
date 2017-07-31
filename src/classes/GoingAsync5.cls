public class GoingAsync5 
	implements ScheduledDispatcher2.IScheduleDispatched {
    
    public void execute(SchedulableContext sc)
    {
      	// When used as a backup to start the asnyc framework
      	system.enqueueJob(new GoingAsync4());
      	// Always abort the job on completion
        system.abortJob(sc.getTriggerID());	
    } 

    public static String getSchedulerExpression(Datetime dt) {
    	// Don't try to schedule Apex before current time + buffer
    	if(dt < DateTime.Now().AddMinutes(1)) 
    		dt = DateTime.Now().AddMinutes(1);
        return ('' + dt.second() + ' ' + dt.minute() + ' ' + 
        	dt.hour() + ' ' + dt.day() + ' ' + 
        	dt.month() + ' ? ' + dt.year());
    }
        
    public static void startScheduler(DateTime scheduledTime, String jobName)
    {
        
        // Is the job already running?
        List<CronTrigger> jobs = 
        	[SELECT Id, CronJobDetail.Name, State, NextFireTime
             FROM CronTrigger 
             WHERE CronJobDetail.Name= :jobName];
    	if(jobs.size()>0 && jobs[0].state!='COMPLETED' && 
           jobs[0].state!='ERROR' && jobs[0].state!='DELETED')
    	{
            // It's already running/scheduled
			
			// Depending on your design you might want to exit,
			// or abort and reschedule if the requested start time 
			// is earlier
			return;            
        }

        // If the job exists, it needs to be deleted
        if(jobs.size()>0) system.abortJob(jobs[0].id);


        try
        {
	        System.schedule(jobName, 
	                        getSchedulerExpression(scheduledTime), 
	                        new ScheduledDispatcher2());
        } catch(Exception ex)
        {
        	system.Debug(ex.getMessage());
        	// Log the error?
        	// Or throw the error to the caller?
        }
    }
}