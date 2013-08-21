trigger bondBuyTrigger on Bond_Buy__c (after delete, after insert, after undelete, after update) {

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
}