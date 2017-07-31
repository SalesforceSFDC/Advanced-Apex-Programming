trigger OnOpportunity2 on Opportunity (after update) {

	// Samples for use with ThinkingInApexBulkPatterns.cls
	//ThinkingInApexBulkPatterns.afterUpdateOpportunityAwful(trigger.new, trigger.oldmap);
	//ThinkingInApexBulkPatterns.afterUpdateOpportunityCommon(trigger.new, trigger.newmap, trigger.oldmap);
	//ThinkingInApexBulkPatterns.afterUpdateOpportunitySets(trigger.new, trigger.newmap, trigger.oldmap);
	//ThinkingInApexBulkPatterns.afterUpdateOpportunityBetterQueries(trigger.new, trigger.newmap, trigger.oldmap);
	//ThinkingInApexBulkPatterns.afterUpdateOpportunityBetterQueries2(trigger.new, trigger.newmap, trigger.oldmap);
	//ThinkingInApexBulkPatterns.afterUpdateOpportunityFutureSupport(trigger.new, trigger.newmap, trigger.oldmap);
	//ThinkingInApexBulkPatterns.afterUpdateOpportunityBatchSupport(trigger.new, trigger.newmap, trigger.oldmap);


	// Trigger arhitecture examples
	// Example using parameters to track update objects
	/*Map<ID, Opportunity> objectsToUpdate = new Map<ID, Opportunity>();
	TriggerArchitectureClass1.Entry1(trigger.new, trigger.newMap, trigger.old, trigger.oldMap, objectsToUpdate);
	TriggerArchitectureClass2.Entry1(trigger.new, trigger.newMap, trigger.old, trigger.oldMap, objectsToUpdate);
	if(objectstoupdate.size()>0) update objectsToUpdate.values();
	*/
	
	// Examples using a dispatcher class
	
	//TriggerArchitectureMain1.Entry2(trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
	//TriggerArchitectureMain1.Entry3(trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
	
	// Compelte centralized dispatching
/*	TriggerArchitectureMain1.entry4('Opportunity', trigger.isBefore, trigger.isDelete, trigger.isAfter,
									trigger.isInsert, trigger.isUpdate, trigger.isExecuting, 
									trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
*/


	// Samples for use with TriggerExample.cls
	//TriggersExample.afterUpdateOpportunityCreateTasks1(trigger.new, trigger.newmap, trigger.oldmap);
	TriggersExample.afterUpdateOpportunityCreateTasks2(trigger.new, trigger.newmap, trigger.oldmap);

}