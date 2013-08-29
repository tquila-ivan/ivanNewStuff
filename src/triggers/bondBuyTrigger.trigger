/**
 * Trigger for the Bond_Buy__c object
 */
trigger bondBuyTrigger on Bond_Buy__c (before insert, after insert, before update, after update, after delete, after undelete) {

	//Create the Handler instance passing the proper parameters
	bondBuyTriggerHandler handler = new bondBuyTriggerHandler(Trigger.isExecuting, Trigger.size);
		
	if (Trigger.isAfter) {	
		//After Insert
		if (Trigger.isInsert) {
			handler.bondBuyAfterInsertUndelete(Trigger.new, Trigger.newMap);
		}
		
		//After update
		if (Trigger.isUpdate) {
			handler.bondBuyAfterUpdate(Trigger.new, Trigger.oldMap, Trigger.newMap);
		}
		
		//After delete
		if (Trigger.isDelete) {
			handler.bondBuyAfterDelete(Trigger.old, Trigger.oldMap);
		}
		
		//After undelete
		if (Trigger.isUnDelete) {
			handler.bondBuyAfterInsertUndelete(Trigger.new, Trigger.newMap);
		}
	}
	else {
		//Before insert
		if (Trigger.isInsert) {
			handler.bondBuyBeforeInsert(Trigger.new);
		}
		
		//Before update
		if (Trigger.isUpdate) {
			handler.bondBuyBeforeUpdate(Trigger.new);
		}
	}
		
}