trigger TSANetResponseTrigger on tsanet_connect__TSANetResponse__c (before insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            TSANetResponseTriggerHelper.handleBeforeInsert((tsanet_connect__TSANetResponse__c[]) Trigger.new);
        }
    }
}