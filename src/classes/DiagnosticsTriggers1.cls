public class DiagnosticsTriggers1 Implements DiagnosticsMain.ITriggerEntry {

	public void mainEntry(String triggerObject, Boolean isBefore, 
			Boolean isDelete, Boolean isAfter, Boolean isInsert, 
			Boolean isUpdate, Boolean isExecuting, 
			List<SObject> newList, Map<ID, SObject> newMap, 
			List<SObject> oldList, Map<ID,SObject> oldMap)
	{
		DiagnosticsInstrumentation.push('DiagnosticsTriggers1.MainEntry');
		afterUpdateOpportunityBetterQueries2((List<Opportunity>)newList, 
				(Map<ID,Opportunity>) newMap, (Map<ID,Opportunity>) oldMap, 
				IsInsert, IsUpdate);
		DiagnosticsInstrumentation.pop();
	}
	public void inProgressEntry(String triggerObject, Boolean isBefore, 
			Boolean isDelete, Boolean isAfter, Boolean isInsert, 
			Boolean isUpdate, Boolean isExecuting, 
			List<SObject> newList, Map<ID, SObject> newMap, 
			List<SObject> oldList, Map<ID,SObject> oldMap)
	{
		// Ignore triggers within triggers
	}


	public static void afterUpdateOpportunityBetterQueries2(
		List<Opportunity> newList, Map<ID, Opportunity> newMap, 
		Map<ID, Opportunity> oldMap, Boolean isInsert, Boolean isUpdate)
	{
		// Pattern 5 - Implementation with SOQL aggregates #2

		DiagnosticsInstrumentation.Push(
			'DiagnosticsTriggers1.AfterUpdateOpportunityBetterQueries2');

		
		Set<ID> opportunityIDsWithStagenameChanges = new Set<ID>();
		
		// Get OpportunityContactRoles
		for(Opportunity op: newList)
		{
			if(op.StageName != oldMap.get(op.id).StageName) 
				opportunityIDsWithStagenameChanges.add(op.id);
		}
		
		// Quick exit if no processing required
		if(opportunityIDsWithStagenameChanges.size()==0) 
		{
			DiagnosticsInstrumentation.Pop();
			return;
		}	
			
			
		// Query for all related OpportunityContactRole
		List<OpportunityContactRole> ocrs = 
			[Select ID, ContactID, IsPrimary, OpportunityID 
			from OpportunityContactRole 
			where OpportunityID in :opportunityIDsWithStagenameChanges];

		// Look for primary, or for no OCR on opportunities
		Set<ID> opsWithNoPrimaryWithContactRoles = opportunityIDsWithStagenameChanges.Clone();
		Set<ID> opsWithNoContactRoles = opportunityIDsWithStagenameChanges.Clone();

		
		for(OpportunityContactRole ocr: ocrs)
		{
			if(ocr.IsPrimary) opsWithNoPrimaryWithContactRoles.remove(ocr.OpportunityID);
			opsWithNoContactRoles.remove(ocr.OpportunityID);
		}
		opsWithNoPrimaryWithContactRoles.RemoveAll(opsWithNoContactRoles);

		// First deal with any opportunities without contact roles
		if(opsWithNoContactRoles.size()>0)
		{
			// Find out which ones have existing tasks
			List<Task> tasks = 
				[SELECT ID, OwnerID, WhatID, Status, Subject, Type 
				from Task where Type='Other' 
				And WhatID in :opsWithNoContactRoles And IsClosed = False 
				And Subject = 'Assign Primary Contact'   ];

			// Don't loop through opportunities - waste of script lines. Loop through tasks to build set of IDs with tasks
			Set<ID> opsWithoutTasks = opsWithNoContactRoles.clone();
			for(Task t: tasks)
			{
				Opportunity op = newMap.get(t.WhatID);	// Get the opportunity
				// Make sure it's assigned to the right person
				if(t.OwnerID == op.OwnerID) opsWithoutTasks.remove(op.ID);	
			}
			// Now create new tasks
			List<Task> newTasks = new List<Task>();
			for(ID opid: opsWithoutTasks)
			{
				Opportunity op = newMap.get(opid);
				newTasks.add(new Task(OwnerID = op.OwnerID, Type='Other', 
						WhatID = op.ID, Subject = 'Assign Primary Contact', 
						ActivityDate = Date.Today().AddDays(3) ));
			}
			if(newTasks.size()>0) insert newTasks;
			
		}
		if(opsWithNoPrimaryWithContactRoles.size()>0)
		{			
			// Get a list of the contacts
			List<ID> contactIdsForOps = new List<ID>();
			for(OpportunityContactRole ocr: ocrs)
			{
				if(opsWithNoPrimaryWithContactRoles.contains(ocr.OpportunityID)) 
					contactIdsForOps.add(ocr.ContactID);
			}
			
			// Now get the totals count and primary count for each contact by 
			// using aggregate functions and grouping by contact
			List<AggregateResult> ocrsByContact = 
				[Select ContactID, Count(ID) total 
				from OpportunityContactRole 
				where ContactID in :contactIdsForOps 
				Group By ContactID];
			List<AggregateResult> primaryOcrsByContact = 
				[Select ContactID, Count(ID) total 
				from OpportunityContactRole where IsPrimary=true 
				and ContactID in :contactIdsForOps Group By ContactID];

			// Let's get the totals by contact for faster loop
			Map<ID, Integer> totalsByContact = new Map<ID, Integer>();
			Map<ID, Integer> primaryByContact = new Map<ID, Integer>();
			for(AggregateResult ar: ocrsByContact) 
				totalsByContact.put((ID)ar.get('ContactID'), 
				Integer.ValueOf(ar.get('total')));
			for(AggregateResult ar: primaryOcrsByContact) 
				primaryByContact.put((ID)ar.get('ContactID'), 
				Integer.ValueOf(ar.get('total')));

			// Instead of requerying opportunties with a subquery of contact roles
			// Build a map from opportunity ID to related contact roles
			// for opportunties without primary contact roles
			Map<ID, List<OpportunityContactRole>> opportunitiesWithoutPrimary = 
				new Map<ID, List<OpportunityContactRole>>();
			for(OpportunityContactRole ocr: ocrs)
			{
				ID opid = ocr.OpportunityID;	// Use temp variable for speed
				if(opsWithNoPrimaryWithContactRoles.contains(opid))
				{
					if(!opportunitiesWithoutPrimary.containsKey(opid))
						opportunitiesWithoutPrimary.put(opid, new List<OpportunityContactRole>());
					opportunitiesWithoutPrimary.get(opid).add(ocr);
				}
			}
			
			
			List<OpportunityContactRole> ocrsToUpdate = 
				new List<OpportunityContactRole>();
			
			for(ID opid: opportunitiesWithoutPrimary.keyset())
			{
				OpportunityContactRole bestOcr = null;
				Integer primaryCount = 0;
				Integer totalCount = 0;
				for(OpportunityContactRole opOcrs: opportunitiesWithoutPrimary.get(opid))
				{
					if(bestOcr==null || 
						primaryByContact.get(opOcrs.contactid) > primaryCount ||
					   (primaryByContact.get(opOcrs.contactid) == totalCount && 
					    totalsByContact.get(opocrs.contactId) > totalCount ))
					   primaryCount = primaryByContact.get(opocrs.Contactid);
					   totalCount = totalsByContact.get(opocrs.Contactid);
					   bestOcr = opOcrs;
				}
				bestOcr.IsPrimary = true;
				ocrsToUpdate.add(bestOcr);
			}
			update ocrsToUpdate;
		}	
		DiagnosticsInstrumentation.pop();
	}

}