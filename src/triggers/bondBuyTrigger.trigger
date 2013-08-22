trigger bondBuyTrigger on Bond_Buy__c (before insert, after insert, before update, after update, after delete, after undelete) {

	//Create the Handler instance passing the proper parameters
	bondBuyTriggerHandler handler = new bondBuyTriggerHandler(Trigger.isExecuting, Trigger.size);
		
	if (Trigger.isAfter) {	
		if (Trigger.isInsert) {
			handler.bondBuyAfterInsertUndelete(Trigger.new, Trigger.newMap);
		}
		
		if (Trigger.isUpdate) {
			handler.bondBuyAfterUpdate(Trigger.new, Trigger.oldMap, Trigger.newMap);
		}
		
		if (Trigger.isDelete) {
			handler.bondBuyAfterDelete(Trigger.old, Trigger.oldMap);
		}
		
		if (Trigger.isUnDelete) {
			handler.bondBuyAfterInsertUndelete(Trigger.new, Trigger.newMap);
		}
	}
	else {
		if (Trigger.isInsert) {
			handler.bondBuyBeforeInsert(Trigger.new);
		}
		
		if (Trigger.isUpdate) {
			handler.bondBuyBeforeUpdate(Trigger.new);
		}
	}
		
}