trigger TSANetNoteTrigger on TSANetNote__c (before insert, after insert, after update) {
    
    if (Trigger.isBefore) {
        if(Trigger.isInsert) {
            TSANetNoteTriggerHelper.handleBeforeInsert((TSANetNote__c[]) Trigger.new);
        }
    }
	if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            TSANetNoteTriggerHelper.handleAfterInsert((TSANetNote__c[]) Trigger.new);
        }
        if(Trigger.isUpdate) {
            TSANetNoteTriggerHelper.handleAfterUpdate((TSANetNote__c[]) Trigger.new, (Map<Id, TSANetNote__c>) Trigger.oldMap);
        }
    }
}