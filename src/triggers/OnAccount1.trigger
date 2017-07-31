trigger OnAccount1 on Account 
	(after insert, after update, 
	before insert, before update) {
	
	PersonAccountSupport.processAccountTrigger1(
		trigger.isBefore, trigger.new, trigger.oldMap);

}