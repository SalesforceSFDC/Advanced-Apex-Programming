trigger OnOpportunity3 on Opportunity (after delete, after insert, 
	after undelete, after update, before delete, 
	before insert, before update) {
		
	DiagnosticsMain.mainEntry('Opportunity', trigger.isBefore, 
		trigger.isDelete, trigger.isAfter, trigger.isInsert, 
		trigger.isUpdate, trigger.isExecuting, 
		trigger.new, trigger.newMap, trigger.old, trigger.oldMap);


}