trigger TSANetNoteTrigger on TSANetNote__c (after insert, after update) {
	if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            TSANetNote__c[] notes = (TSANetNote__c[]) Trigger.new;
            
            TSANetNoteTriggerHelper.handleAfterInsert(notes);
        }
        if(Trigger.isUpdate) {
            TSANetNote__c[] notes = (TSANetNote__c[]) Trigger.new;
        	Map<Id, TSANetNote__c> oldNotes = (Map<Id, TSANetNote__c>) Trigger.oldMap;
            
            TSANetNoteTriggerHelper.handleAfterUpdate(notes, oldNotes);
        }
    }
}