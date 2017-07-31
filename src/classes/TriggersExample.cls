public class TriggersExample {

	public static void afterUpdateOpportunityCreateTasks1(
		List<Opportunity> newList, Map<ID, Opportunity> newMap, 
		Map<ID, Opportunity> oldMap)
	{
		List<Task> newTasks = new List<Task>();
		
		for(Opportunity op: newList)
		{
			system.debug('old probability ' + 
				oldMap.get(op.id).Probability + 
				' new probability ' + op.Probability);
			if(oldMap.get(op.id).Probability == 10 && op.Probability > 10)
			{
				newTasks.add(
					new Task(ownerId = op.OwnerID, 
						WhatID = op.id, 
						ActivityDate = Date.Today().addDays(2), 
						Subject='Opportunity stage update', 
						Type='Other'));
			}
		}
		insert newTasks;
	}

	private static Map<ID, Double> probabilityOverrides = null;

	public static void afterUpdateOpportunityCreateTasks2(
		List<Opportunity> newList, Map<ID, Opportunity> newMap, 
		Map<ID, Opportunity> oldMap)
	{
		List<Task> newTasks = new List<Task>();
		if(probabilityOverrides==null) probabilityOverrides = new Map<ID, Double>();
		
		for(Opportunity op: newList)
		{
			Double oldProbability = (probabilityOverrides.containskey(op.id))? 
				probabilityOverrides.get(op.id) : 
				oldMap.get(op.id).Probability;
			system.debug('old probability ' + oldMap.get(op.id).Probability + 
			' new probability ' + op.Probability);
			if(oldProbability == 10 && op.Probability > 10)
			{
				newTasks.add(
					new Task(ownerId = op.OwnerID, WhatID = op.id, 
							ActivityDate = Date.Today().addDays(2), 
							Subject='Opportunity stage update', 
							Type='Other'));
			}
			if(oldProbability != op.Probability) 
				probabilityOverrides.put(op.id, op.Probability);
			
		}
		insert newTasks;
	}	

}