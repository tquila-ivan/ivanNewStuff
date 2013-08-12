trigger bondBuyTrigger on Bond_Buy__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

	//Create the Handler instance passing the proper parameters
	bondBuyTriggerHandler handler = new bondBuyTriggerHandler(Trigger.isExecuting, Trigger.size);

	if (Trigger.isAfter) {
		
		if (Trigger.isInsert) {
			handler.bondBuyAfterInsert(Trigger.new);
		}
		
		if (Trigger.isUpdate) {
			handler.bondBuyAfterUpdate(Trigger.new, Trigger.oldMap);
		}
		
		if (Trigger.isDelete) {
			
		}
		
		if (Trigger.isUnDelete) {
			
		}
		
	}
}