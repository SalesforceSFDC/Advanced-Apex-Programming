public class TriggerArchitectureClass1 implements TriggerArchitectureMain1.ITriggerEntry {

	public static void entry1(List<Opportunity> newlist, 
			Map<ID, Opportunity> newMap, List<Opportunity> oldList, 
			Map<ID,Opportunity> oldMap, Map<ID, Opportunity> objectsToUpdate)
	{
		// Do some processing here
		// Add entries to the objectstoupdate map if they need to be updated
	}


	public static void entry2(List<Opportunity> newList, 
			Map<ID, Opportunity> newMap, List<Opportunity> oldList, 
			Map<ID,Opportunity> oldMap)
	{
		// Do some processing here
		// Add entries to the dispatcher static variable 
		// if they need to be updated
	}


	public static void entry3(List<Opportunity> newList, 
		Map<ID, Opportunity> newMap, List<Opportunity> oldList, 
		Map<ID,Opportunity> oldMap)
	{
		// Do some processing here
		// Add entries to the dispatcher static variable if they need to be updated
	}

	public void mainEntry(String triggerObject, Boolean isBefore, 
		Boolean isDelete, Boolean isAfter, Boolean isInsert, 
		Boolean isUpdate, Boolean isExecuting, 
		List<SObject> newList, Map<ID, SObject> newMap, 
		List<SObject> oldList, Map<ID,SObject> oldMap)
	{
		List<Opportunity> opNewList = (List<Opportunity>)newList;
		List<Opportunity> opOldList = (List<Opportunity>)oldList;
		Map<ID, Opportunity> opNewMap = (Map<ID,Opportunity>)newMap;
		Map<ID, Opportunity> opOldMap = (Map<ID,Opportunity>)oldMap;

		// Do some processing here
		// Add entries to the dispatcher static variable 
		//if they need to be updated or do direct DML

	}

	public void inProgressEntry(String triggerObject, Boolean isBefore, 
		Boolean isDelete, Boolean isAfter, Boolean isInsert, 
		Boolean isUpdate, Boolean isExecuting, 
		List<SObject> newList, Map<ID, SObject> newMap, 
		List<SObject> oldList, Map<ID,SObject> oldMap)
	{
		// Be sure to detect for the objects you actually want to handle.
		// Can dispatch to other classes is necessary
	}


}