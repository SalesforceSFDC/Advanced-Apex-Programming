trigger OnContact1 on Contact (before insert, before update) {
	PersonAccountSupport.processContactTrigger1(
		trigger.isBefore, trigger.new, trigger.oldMap);
}