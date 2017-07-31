public class ThinkingInApexBulkPatterns {


	/* Bad implementation. Not included in the book - just used for limits comparison */

	public static void afterUpdateOpportunityAwful(
		List<Opportunity> newList, Map<ID, Opportunity> oldMap)
	{
		// Pattern 1 - terrible implementation
		
		// Get OpportunityContactRoles
		for(Opportunity op: newList)
		{
			if(op.StageName == oldMap.get(op.id).StageName) continue;	// Only process changes to stagename
			
			List<OpportunityContactRole> ocrs = 
				[Select ID, ContactID, IsPrimary 
					from OpportunityContactRole 
					where OpportunityID = :op.id];
			
			if(ocrs.size()==0)
			{
				// No associated contacts at all - 
				// create a new task for the owner to create said contact
				// Is task already set?
				List<Task> tasks = 
					[SELECT ID, OwnerID, WhatID, Status, Subject, Type 
						from Task 
						where OwnerID = :op.OwnerID 
						And Type='Other' 
						And WhatID = :op.ID 
						And IsClosed = False 
						And Subject = 'Assign Primary Contact'   ];
				if(tasks.size()>0) continue;	// Already set
				
				Task t = new Task(OwnerID = op.OwnerID, 
							Type='Other', WhatID = op.ID, 
							Subject = 'Assign Primary Contact', 
							ActivityDate = Date.Today().AddDays(3) );
				insert t;
				continue;
			}
			
			// If primary exists, we're done
			Boolean primaryFound = false;
			for(OpportunityContactRole ocr: ocrs)
			{
				if(ocr.IsPrimary)
				{
					primaryFound = true;
					break;
				}
				
			}
			if(primaryFound) continue;
			
			// Get a list of the contacts
			List<ID> contactIdsForOps = new List<ID>();
			for(OpportunityContactRole ocr: ocrs)
			{
				contactIdsForOps.add(ocr.ContactID);
			}
			
			// Now query the contacts with their OpportunityContactRoles
			Map<ID, Contact> contactsForOps = 
				new Map<ID, Contact>(
					[Select ID, 
						(Select ID, IsPrimary from OpportunityContactRoles) 
						from Contact where ID in :contactIdsForOps]);

			// Now figure out which of the OpportunityContactRoles should be set to primary
			OpportunityContactRole bestOcr = null;
			Integer bestContactAllOcrCount = 0;
			Integer bestContactPrimaryOcrCount = 0;
			
			for(OpportunityContactRole ocr: ocrs)
			{
				Contact currentContact = contactsForOps.get(ocr.ContactID);
				Integer primaryCount = 0;
				for(OpportunityContactRole testOcr: currentContact.OpportunityContactRoles)
				{
					if(testOcr.IsPrimary) primaryCount ++;
				}
				if(bestOcr == null || 
					primaryCount > bestContactPrimaryOcrCount ||
					(primaryCount == bestContactAllOcrCount && 
						currentContact.OpportunityContactRoles.size()> bestContactAllOcrCount))
				{
					bestOcr = ocr;
					bestContactAllOcrCount = currentContact.OpportunityContactRoles.size();
					bestContactPrimaryOcrCount = primaryCount;
				}
			}
			bestocr.IsPrimary = true;
			update bestOcr;
		}

		
	}


	public static void afterUpdateOpportunityCommon(
		List<Opportunity> newList, Map<ID, Opportunity> newMap, 
		Map<ID, Opportunity> oldMap)
	{
		// Pattern 2 - Straightforward common implementation
		
		Set<ID> opportunityIDsWithStagenameChanges = new Set<ID>();
		
		// Get OpportunityContactRoles
		for(Opportunity op: newList)
		{
			if(op.StageName != oldMap.get(op.id).StageName) 
				opportunityIDsWithStagenameChanges.add(op.id);
		}
		
		// Quick exit if no processing required
		if(opportunityIDsWithStagenameChanges.size()==0) return;	
			
			
		// Query for all related OpportunityContactRole
		List<OpportunityContactRole> ocrs = 
			[Select ID, ContactID, IsPrimary, OpportunityID 
			from OpportunityContactRole 
			where OpportunityID in :opportunityIDsWithStagenameChanges];

		// Look for primary, or for no OCR on opportunities
		Set<ID> primaryFound = new Set<ID>();
		Set<ID> anyFound = new Set<ID>();
		
		for(OpportunityContactRole ocr: ocrs)
		{
			if(ocr.IsPrimary) primaryFound.add(ocr.OpportunityID);
			anyFound.add(ocr.OpportunityID);
		}

		// Build list of opportunities with no contact role, 
		// and list with contact role but no primary contact role
		// Use maps because it's an easy way to get the keyset for later queries
		Map<ID, Opportunity> opsWithNoContactRoles = new Map<ID, Opportunity>();
		Map<ID, Opportunity> opsWithNoPrimary = new Map<ID, Opportunity>();

		for(ID opid: opportunityIDsWithStagenameChanges)
		{
			if(!primaryFound.contains(opid))
			{
				if(anyFound.contains(opid)) 
					opsWithNoPrimary.put(opid, newMap.get(opid));
				else 
					opsWithNoContactRoles.put(opid, newMap.get(opid));
			}
		}
		
		// First deal with any opportunities without contact roles
		if(opsWithNoContactRoles.size()>0)
		{
			// Find out which ones have existing tasks
			List<Task> tasks = 
				[SELECT ID, OwnerID, WhatID, Status, Subject, Type 
				from Task 
				where Type='Other' 
				And WhatID in :OpsWithNoContactRoles.keyset() 
				And IsClosed = False 
				And Subject = 'Assign Primary Contact'   ];

			// Don't loop through opportunities - waste of time. 
			// Loop through tasks to build set of IDs with tasks
			Set<ID> opsWithTasks = new Set<ID>();
			for(Task t: tasks)
			{
				// Get the opportunity
				Opportunity op = opsWithNoContactRoles.get(t.WhatID);	
				// Make sure it's assigned to the right person
				if(t.OwnerID == op.OwnerID) opsWithTasks.add(op.ID);	
			}
			// Now create new tasks
			List<Task> newTasks = new List<Task>();
			for(Opportunity op: opsWithNoContactRoles.values())
			{
				if(!opsWithTasks.contains(op.id))
				{
					newTasks.add(
						new Task(OwnerID = op.OwnerID, Type='Other', 
						WhatID = op.ID, Subject = 'Assign Primary Contact', 
						ActivityDate = Date.Today().AddDays(3) ));
				}				
			}
			if(newTasks.size()>0) insert newTasks;
		}

		if(opsWithNoPrimary.size()>0)
		{			
			// Get a list of the contacts
			List<ID> contactIdsForOps = new List<ID>();
			for(OpportunityContactRole ocr: ocrs)
			{
				if(opsWithNoPrimary.containskey(ocr.OpportunityID)) 
					contactIdsForOps.add(ocr.ContactID);
			}
			
			// Now query the contacts with their OpportunityContactRoles
			Map<ID, Contact> contactsForOps = 
				new Map<ID, Contact>(
					[Select ID, 
					(Select ID, IsPrimary, OpportunityID from OpportunityContactRoles) 
					from Contact where ID in :contactIdsForOps]);

			// Now figure out which of the OpportunityContactRoles should be set to primary
			// Map of opportunity ID to the best OCR for that ID
			Map<ID,OpportunityContactRole> bestOcrs = new Map<ID, OpportunityContactRole>();
			// Map of opportunity to Total # OCRs on the current best opportunity contact
			Map<ID,Integer> bestContactAllOcrCount = new Map<ID,Integer>();
			
			// Map of opportunity to Total # primary OCRs on the current best opportunity contact
			Map<ID,Integer> bestContactPrimaryOcrCount = new Map<ID, Integer>();
			
			for(OpportunityContactRole ocr: ocrs)
			{
				if(!opsWithNoPrimary.containskey(ocr.OpportunityID)) continue;
				Contact currentContact = contactsForOps.get(ocr.ContactID);
				Integer primaryCount = 0;
				for(OpportunityContactRole testOcr: currentContact.OpportunityContactRoles)
				{
					if(testocr.IsPrimary) primaryCount ++;
				}
				if(!bestOcrs.containskey(ocr.OpportunityID) || 
					primaryCount > bestContactPrimaryOcrCount.get(ocr.OpportunityID) ||
					(primaryCount == bestContactAllOcrCount.get(ocr.OpportunityID) && 
					currentContact.OpportunityContactRoles.size()> bestContactAllOcrCount.get(ocr.OpportunityID)))
				{
					bestOcrs.put(ocr.OpportunityID, ocr);
					bestContactAllOcrCount.put(ocr.OpportunityID, currentContact.OpportunityContactRoles.size());
					bestContactPrimaryOcrCount.put(ocr.OpportunityID, primaryCount);
				}
			}
			
			for(OpportunityContactRole best: bestOcrs.values()) best.IsPrimary = true;
			update bestOcrs.values();
		}

		
		
		
	}
	

	public static void afterUpdateOpportunitySets(
		List<Opportunity> newList, Map<ID, Opportunity> newMap, 
		Map<ID, Opportunity> oldMap)
	{
		// Pattern 3 - Straightforward common implementation with sets
		
		Set<ID> opportunityIDsWithStagenameChanges = new Set<ID>();
		
		// Get OpportunityContactRoles
		for(Opportunity op: newList)
		{
			if(op.StageName != oldMap.get(op.id).StageName) 
				opportunityIDsWithStagenameChanges.add(op.id);
		}
		
		// Quick exit if no processing required
		if(opportunityIDsWithStagenameChanges.size()==0) return;	
			
			
		// Query for all related OpportunityContactRole
		List<OpportunityContactRole> ocrs = 
			[Select ID, ContactID, IsPrimary, OpportunityID 
			from OpportunityContactRole 
			where OpportunityID in :opportunityIDsWithStagenameChanges];

		// Look for primary, or for no OCR on opportunities
		Set<ID> opsWithNoPrimary = opportunityIDsWithStagenameChanges.Clone();
		Set<ID> opsWithNoContactRoles = opportunityIDsWithStagenameChanges.Clone();

		
		for(OpportunityContactRole ocr: ocrs)
		{
			if(ocr.IsPrimary) opsWithNoPrimary.remove(ocr.OpportunityID);
			opsWithNoContactRoles.remove(ocr.OpportunityID);
		}

		// First deal with any opportunities without contact roles
		if(opsWithNoContactRoles.size()>0)
		{
			// Find out which ones have existing tasks
			List<Task> tasks = 
				[SELECT ID, OwnerID, WhatID, Status, Subject, Type 
				from Task where Type='Other' 
				And WhatID in :OpsWithNoContactRoles 
				And IsClosed = False 
				And Subject = 'Assign Primary Contact'   ];

			// Don't loop through opportunities - waste of script lines. Loop through tasks to build set of IDs with tasks
			Set<ID> opsWithoutTasks = opsWithNoContactRoles.clone();
			for(Task t: tasks)
			{
				Opportunity op = newMap.get(t.WhatID);	// Get the opportunity
				if(t.OwnerID == op.OwnerID) opsWithoutTasks.remove(op.ID);	// Make sure it's assigned to the right person
			}
			// Now create new tasks
			List<Task> newTasks = new List<Task>();
			for(ID opid: opsWithoutTasks)
			{
				Opportunity op = newMap.get(opid);
				newTasks.add(
					new Task(OwnerID = op.OwnerID, Type='Other', 
					WhatID = op.ID, 
					Subject = 'Assign Primary Contact', 
					ActivityDate = Date.Today().AddDays(3) ));
			}
			if(newTasks.size()>0) insert newTasks;
			
		}
		if(opsWithNoPrimary.size()>0)
		{			
			// Get a list of the contacts
			List<ID> contactIdsForOps = new List<ID>();
			for(OpportunityContactRole ocr: ocrs)
			{
				if(opsWithNoPrimary.contains(ocr.OpportunityID)) 
					contactIdsForOps.add(ocr.ContactID);
			}
			
			// Now query the contacts with their OpportunityContactRoles
			Map<ID, Contact> contactsForOps = 
				new Map<ID, Contact>(
					[Select ID, 
					(Select ID, IsPrimary, OpportunityID from OpportunityContactRoles) 
					from Contact where ID in :contactIdsForOps]);

			// Now figure out which of the OpportunityContactRoles 
			// should be set to primary
			Map<ID,OpportunityContactRole> bestOcrs = 
				new Map<ID, OpportunityContactRole>();
			Map<ID,Integer> bestContactAllOcrCount = 
				new Map<ID,Integer>();
			Map<ID,Integer> bestContactPrimaryOcrCount = 
				new Map<ID, Integer>();
			
			for(OpportunityContactRole ocr: ocrs)
			{
				if(!opsWithNoPrimary.contains(ocr.OpportunityID)) continue;
				Contact currentContact = contactsForOps.get(ocr.ContactID);
				Integer primaryCount = 0;
				for(OpportunityContactRole testocr: 
					currentContact.OpportunityContactRoles)
				{
					if(testOcr.IsPrimary) primaryCount ++;
				}
				if(!bestOcrs.containskey(ocr.OpportunityID) || 
					primaryCount > bestContactPrimaryOcrCount.get(ocr.OpportunityID) ||
					(primaryCount == bestContactAllOcrCount.get(ocr.OpportunityID) 
					&& currentContact.OpportunityContactRoles.size()> 
					bestContactAllOcrCount.get(ocr.OpportunityID)))
				{
					bestOcrs.put(ocr.OpportunityID, ocr);
					bestContactAllOcrCount.put(ocr.OpportunityID, 
						currentContact.OpportunityContactRoles.size());
					bestContactPrimaryOcrCount.put(
						ocr.OpportunityID, primaryCount);
				}
			}
			
			for(OpportunityContactRole best: bestOcrs.values()) 
				best.IsPrimary = true;
			update bestOcrs.values();
		}
	}

	
	public static void afterUpdateOpportunityBetterQueries(
		List<Opportunity> newList, Map<ID, Opportunity> newMap, 
		Map<ID, Opportunity> oldMap)
	{
		// Pattern 4 - Implementation with SOQL aggregates
		
		Set<ID> opportunityIDsWithStagenameChanges = new Set<ID>();
		
		// Get OpportunityContactRoles
		for(Opportunity op: newList)
		{
			if(op.StageName != oldMap.get(op.id).StageName) 
				opportunityIDsWithStagenameChanges.add(op.id);
		}
		
		// Quick exit if no processing required
		if(opportunityIDsWithStagenameChanges.size()==0) return;	
			
			
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

			List<Opportunity> opportunitiesWithoutPrimary = 
				[Select ID ,(Select ID, ContactID, IsPrimary 
				from OpportunityContactRoles) from Opportunity 
				where ID in :opsWithNoPrimaryWithContactRoles];
			List<OpportunityContactRole> ocrsToUpdate = 
				new List<OpportunityContactRole>();

			for(Opportunity op: opportunitiesWithoutPrimary)
			{
				OpportunityContactRole bestOcr = null;
				Integer primaryCount = 0;
				Integer totalCount = 0;
				for(OpportunityContactRole opOcrs: op.OpportunityContactRoles)
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
	}


	public static void afterUpdateOpportunityBetterQueries2(
		List<Opportunity> newList, Map<ID, Opportunity> newMap, 
		Map<ID, Opportunity> oldMap)
	{
		// Pattern 5 - Implementation with SOQL aggregates #2
		
		Set<ID> opportunityIDsWithStagenameChanges = new Set<ID>();
		
		// Get OpportunityContactRoles
		for(Opportunity op: newList)
		{
			if(op.StageName != oldMap.get(op.id).StageName) 
				opportunityIDsWithStagenameChanges.add(op.id);
		}
		
		// Quick exit if no processing required
		if(opportunityIDsWithStagenameChanges.size()==0) return;	
			
			
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
	}

	@future
	public static void futureUpdateOpportunities(Set<ID> opportunitiyIds)
	{
		Map<ID, Opportunity> newMap = 
			new Map<ID, Opportunity>(
				[SELECT ID, OwnerID from Opportunity where ID in :opportunitiyIds]);
		afterUpdateOpportunityFutureSupport(newMap.values(), newMap, null);
	}
	private static Boolean futureCalled = false;

	public static void afterUpdateOpportunityFutureSupport(
		List<Opportunity> newList, Map<ID, Opportunity> newMap, 
		Map<ID, Opportunity> oldMap)
	{
		// Pattern 6 - with future support
		
		Set<ID> opportunityIDsWithStagenameChanges = new Set<ID>();
		
		// Get OpportunityContactRoles
		if(!System.isFuture())
		{
			for(Opportunity op: newList)
			{
				if(op.StageName != oldMap.get(op.id).StageName) 
					opportunityIDsWithStagenameChanges.add(op.id);
			}
			if(newList.size()>100)
			{
				if(!futureCalled) 
					futureUpdateOpportunities(opportunityIDsWithStagenameChanges);
				futureCalled = true;
				return;
			}
		}
		else opportunityIDsWithStagenameChanges.addall(newMap.keyset());
		
		// Quick exit if no processing required
		if(opportunityIDsWithStagenameChanges.size()==0) return;	
			
			
		// Query for all related OpportunityContactRole
		List<OpportunityContactRole> ocrs = [
			Select ID, ContactID, IsPrimary, OpportunityID 
			from OpportunityContactRole where OpportunityID in 
			:opportunityIDsWithStagenameChanges];

		// Look for primary, or for no OCR on opportunities
		Set<ID> opsWithNoPrimaryWithContactRoles = 
			opportunityIDsWithStagenameChanges.Clone();
		Set<ID> opsWithNoContactRoles = 
			opportunityIDsWithStagenameChanges.Clone();

		
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
			List<Task> tasks = [
				SELECT ID, OwnerID, WhatID, Status, Subject, Type 
				from Task where Type='Other' And WhatID in :opsWithNoContactRoles 
				And IsClosed = False And Subject = 'Assign Primary Contact'   ];

			// Don't loop through opportunities - waste of script lines. 
			// Loop through tasks to build set of IDs with tasks
			Set<ID> opsWithoutTasks = opsWithNoContactRoles.clone();
			for(Task t: tasks)
			{
				Opportunity op = newmap.get(t.WhatID);	// Get the opportunity
				// Make sure it's assigned to the right person
				if(t.OwnerID == op.OwnerID) opsWithoutTasks.remove(op.ID);	
			}
			// Now create new tasks
			List<Task> newTasks = new List<Task>();
			for(ID opId: opsWithoutTasks)
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
			List<AggregateResult> ocrsByContact = [
				Select ContactID, Count(ID) total 
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

			List<Opportunity> opportunitiesWithoutPrimary = 
				[Select ID ,(Select ID, ContactID, IsPrimary 
				from OpportunityContactRoles) from Opportunity 
				where ID in :opsWithNoPrimaryWithContactRoles];
			List<OpportunityContactRole> ocrsToUpdate = 
				new List<OpportunityContactRole>();
			
			for(Opportunity op: OpportunitiesWithoutPrimary)
			{
				OpportunityContactRole bestocr = null;
				Integer primaryCount = 0;
				Integer totalCount = 0;
				for(OpportunityContactRole opOcrs: op.OpportunityContactRoles)
				{
					if(bestOcr==null || 
						primaryByContact.get(opOcrs.contactid) > primaryCount ||
					   (primaryByContact.get(opOcrs.contactid) == totalCount && 
					    totalsByContact.get(opOcrs.contactid) > totalCount ))
					   primaryCount = primaryByContact.get(opOcrs.contactid);
					   totalCount = totalsByContact.get(opOcrs.contactid);
					   bestOcr = opOcrs;
				}
				bestOcr.IsPrimary = true;
				ocrsToUpdate.add(bestOcr);
			}
			update ocrsToUpdate;
		}		
	}

	private static Boolean batchCalled = false;

	public static void afterUpdateOpportunityBatchSupport(
		List<Opportunity> newList, Map<ID, Opportunity> newMap, 
		Map<ID, Opportunity> oldMap)
	{
		// Pattern 7 - with batch support
		
		Set<ID> opportunityIDsWithStagenameChanges = new Set<ID>();
		
		// Get OpportunityContactRoles
		if(!System.isBatch())
		{
			for(Opportunity op: newList)
			{
				if(op.StageName != oldmap.get(op.id).StageName) 
					opportunityIDsWithStagenameChanges.add(op.id);
			}
			if(newList.size()>100)
			{
				if(!batchCalled) 
				{
					Database.executeBatch(new BulkPatternBatch(
						opportunityIDsWithStagenameChanges), 100);
				}
				batchCalled = true;
				return;
			}
		}
		else opportunityIDsWithStagenameChanges.addall(newMap.keyset());
		
		// Quick exit if no processing required
		if(opportunityIDsWithStagenameChanges.size()==0) return;	
			
			
		// Query for all related OpportunityContactRole
		List<OpportunityContactRole> ocrs = 
			[Select ID, ContactID, IsPrimary, OpportunityID 
			from OpportunityContactRole 
			where OpportunityID in :opportunityIDsWithStagenameChanges];

		// Look for primary, or for no OCR on opportunities
		Set<ID> opsWithNoPrimaryWithContactRoles = 
			opportunityIDsWithStagenameChanges.Clone();
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
			List<Task> tasks = [
				SELECT ID, OwnerID, WhatID, Status, Subject, Type 
				from Task where Type='Other' 
				And WhatID in :OpsWithNoContactRoles 
				And IsClosed = False 
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
				newTasks.add(
					new Task(OwnerID = op.OwnerID, Type='Other', 
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
			
			// Now get the totals count and primary count for each contact 
			// by using aggregate functions and grouping by contact
			List<AggregateResult> ocrsByContact = 
				[Select ContactID, Count(ID) total 
					from OpportunityContactRole 
					where ContactID in :contactIdsForOps 
					Group By ContactID];
			List<AggregateResult> primaryOcrsByContact = 
				[Select ContactID, Count(ID) total 
					from OpportunityContactRole 
					where IsPrimary=true 
					and ContactID in :contactIdsForOps 
					Group By ContactID];

			// Let's get the totals by contact for faster loop
			Map<ID, Integer> totalsByContact = new Map<ID, Integer>();
			Map<ID, Integer> primaryByContact = new Map<ID, Integer>();
			for(AggregateResult ar: ocrsByContact) 
				totalsByContact.put((ID)ar.get('ContactID'), 
				Integer.ValueOf(ar.get('total')));
			for(AggregateResult ar: primaryOcrsByContact) 
				primaryByContact.put((ID)ar.get('ContactID'), 
							Integer.ValueOf(ar.get('total')));

			List<Opportunity> opportunitiesWithoutPrimary = 
				[Select ID ,
				(Select ID, ContactID, IsPrimary from OpportunityContactRoles) 
				from Opportunity where ID in :OpsWithNoPrimaryWithContactRoles];
			List<OpportunityContactRole> ocrsToUpdate = 
				new List<OpportunityContactRole>();
			
			for(Opportunity op: opportunitiesWithoutPrimary)
			{
				OpportunityContactRole bestOcr = null;
				Integer primaryCount = 0;
				Integer totalCount = 0;
				for(OpportunityContactRole opOcrs: op.OpportunityContactRoles)
				{
					if(bestOcr==null || primaryByContact.get(opOcrs.contactid) > primaryCount ||
					   (primaryByContact.get(opOcrs.contactid) == totalCount && 
					    totalsByContact.get(opOcrs.contactid) > totalCount ))
					   primaryCount = primaryByContact.get(opOcrs.contactid);
					   totalCount = totalsByContact.get(opOcrs.contactid);
					   bestOcr = opOcrs;
				}
				bestOcr.IsPrimary = true;
				ocrsToUpdate.add(bestOcr);
			}
			update ocrsToUpdate;
		}		
	}

	


}