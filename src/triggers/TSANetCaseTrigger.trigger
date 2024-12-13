trigger TSANetCaseTrigger on tsanet_connect__TSANetCase__c (after update) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            tsanet_connect__TSANetCase__c[] cases = (tsanet_connect__TSANetCase__c[]) Trigger.new;
            //TSANetCaseTriggerHelper.handleAfterInsert(cases);
        }
    }
    
	/*if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            tsanet_connect__TSANetCase__c[] cases = (tsanet_connect__TSANetCase__c[]) Trigger.new;
        	Map<Id, tsanet_connect__TSANetCase__c> oldCases = (Map<Id, tsanet_connect__TSANetCase__c>) Trigger.oldMap;
            
            TSANetCaseTriggerHelper.handleAfterUpdate(cases, oldCases);
        }
    }*/
   
}