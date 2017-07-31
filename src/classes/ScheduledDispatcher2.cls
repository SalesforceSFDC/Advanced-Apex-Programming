global class ScheduledDispatcher2 Implements Schedulable {
	
	public Interface IScheduleDispatched 
    { 
        void execute(SchedulableContext sc); 
    } 
    
    global void execute(SchedulableContext sc) 
    {
        Type targetType = Type.forName('GoingAsync5');   
        if(targetType!=null) {
            IScheduleDispatched obj = 
            	(IScheduleDispatched)targettype.newInstance();
            obj.execute(sc);   
        } 
    } 
}