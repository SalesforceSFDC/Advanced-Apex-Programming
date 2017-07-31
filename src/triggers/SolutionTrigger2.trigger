trigger SolutionTrigger2 on Solution (before insert, before update) {
	
	/*
	GoingAsync1.handleTrigger2(trigger.new,
		trigger.oldMap, trigger.isInsert);
	*/
	/*
	GoingAsync1.handleTrigger3(trigger.new,
		trigger.oldMap, trigger.isInsert);
	*/

	
	GoingAsync1.handleTrigger4(trigger.new,
		trigger.oldMap, trigger.isInsert);
	


}