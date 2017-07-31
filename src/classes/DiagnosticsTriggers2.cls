public class DiagnosticsTriggers2 Implements DiagnosticsMain.ITriggerEntry {

	private static Map<ID, Double> probabilityOverrides = null;
	
	public void mainEntry(String triggerObject, Boolean isBefore, 
			Boolean isDelete, Boolean isAfter, Boolean isInsert, 
			Boolean isUpdate, Boolean isExecuting, 
			List<SObject> newList, Map<ID, SObject> newMap, 
			List<SObject> oldList, Map<ID,SObject> oldMap)
	{
		DiagnosticsInstrumentation.push('DiagnosticsTriggers2.MainEntry');
		afterUpdateOpportunityCreateTasks2((List<Opportunity>)newList, (Map<ID,Opportunity>) newMap, (Map<ID,Opportunity>) oldMap);
		DiagnosticsInstrumentation.pop();

	}
	public void inProgressEntry(String triggerObject, Boolean isBefore, Boolean isDelete, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean IsExecuting, List<SObject> newlist, Map<ID, SObject> newmap, List<SObject> oldlist, Map<ID,SObject> oldmap)
	{
		// Ignore triggers within triggers
	}
	
	
	private static void afterUpdateOpportunityCreateTasks2(
		List<Opportunity> newList, Map<ID, Opportunity> newMap, 
		Map<ID, Opportunity> oldMap)
	{
		DiagnosticsInstrumentation.push(
			'DiagnosticsTriggers2.AfterUpdateOpportunityCreateTasks2');

		List<Task> newTasks;
		// Comment out the following line to fake a runtime error
		// newtasks = new List<Task>();
		if(probabilityOverrides==null) 
			probabilityOverrides = new Map<ID, Double>();
		
		for(Opportunity op: newList)
		{
			Double oldProbability = (probabilityOverrides.containsKey(op.id))? 
				probabilityOverrides.get(op.id) : oldMap.get(op.id).Probability;
			system.debug('old probability ' + oldMap.get(op.id).Probability + 
			' new probability ' + op.Probability);
			if(oldProbability == 10 && op.Probability > 10)
			{
				newTasks.add(new Task(OwnerId = op.OwnerID, WhatID = op.id, 
					ActivityDate = Date.Today().addDays(2), 
					Subject='Opportunity stage update', Type='Other'));
			}
			if(oldProbability != op.Probability) 
				probabilityOverrides.put(op.id, op.Probability);
			
		}
		insert newTasks;
		DiagnosticsInstrumentation.pop();
		
	}	

}