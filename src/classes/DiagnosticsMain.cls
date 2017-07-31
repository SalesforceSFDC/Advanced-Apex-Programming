public class DiagnosticsMain {

	public interface ITriggerEntry
	{
		void mainEntry(String triggerObject, Boolean isBefore, 
			Boolean isDelete, Boolean isAfter, Boolean isInsert, 
			Boolean isUpdate, Boolean isExecuting, 
			List<SObject> newList, Map<ID, SObject> newMap, 
			List<SObject> oldList, Map<ID,SObject> oldMap);

		void inProgressEntry(String triggerObject, Boolean isBefore, 
			Boolean isDelete, Boolean isAfter, Boolean isInsert, 
			Boolean isUpdate, Boolean isExecuting, 
			List<SObject> newList, Map<ID, SObject> newMap, 
			List<SObject> oldList, Map<ID,SObject> oldMap);
	}

	public static ITriggerEntry activeFunction = null;
	
	public static Boolean fakeException = false;

	public static void mainEntry(String triggerObject, Boolean isBefore, 
			Boolean isDelete, Boolean isAfter, Boolean isInsert, 
			Boolean isUpdate, Boolean isExecuting, 
			List<SObject> newList, Map<ID, SObject> newMap, 
			List<SObject> oldList, Map<ID,SObject> oldMap)
	{	
		DiagnosticsInstrumentation.push('MainEntry TriggerObject: ' + 
			triggerObject + ' IsBefore: ' + isBefore + ' IsInsert: ' + 
			isInsert + ' IsUpdate: ' + isUpdate);
		try
		{
			if(fakeException && activeFunction==null ) 
				activefunction.inProgressEntry(triggerObject, isBefore, isDelete, 
				isAfter, isInsert, isUpdate, isExecuting, 
				newList, newMap, oldList, oldMap);
			 			
			if(activeFunction != null) 
			{
				activefunction.inProgressEntry(
					triggerObject, isBefore, isDelete, 
					isAfter, isInsert, isUpdate, isExecuting, 
					newList, newMap, oldList, oldMap);
				return;
			}
			
			if(triggerObject == 'Opportunity' && isAfter && isUpdate)
			{
				activeFunction = new DiagnosticsTriggers1();
				activeFunction.mainEntry(triggerObject, isBefore, isDelete, 
					isAfter, isInsert, isUpdate, isExecuting, 
					newList, newMap, oldList, oldMap);
			}
			
			if(TriggerObject == 'Opportunity' && isAfter && isUpdate)
			{
				activeFunction = new DiagnosticsTriggers2();
				activefunction.mainEntry(triggerObject, isBefore, isDelete, 
					isAfter, isInsert, isUpdate, isExecuting, 
					newList, newMap, oldList, oldMap);
			}
			diagnosticsInstrumentation.Pop();

		}
		catch(Exception ex)
		{
			diagnosticsInstrumentation.debugException(ex);
			diagnosticsInstrumentation.popAll();	
		}
	}
}