trigger TSANetCredentialsTrigger on tsanet_connect__TSANet_Credentials__c (before insert, after insert, before update, before delete) {
    if (Trigger.isBefore) {
        if(Trigger.isInsert) {
            TSANetCredentialsHelper.turnOfPrimaryTSANetCredentials((tsanet_connect__TSANet_Credentials__c[]) Trigger.new);
        }
        
        if(Trigger.isUpdate) {
            TSANetCredentialsHelper.turnOfPrimaryTSANetCredentialsOnUpdate((tsanet_connect__TSANet_Credentials__c[]) Trigger.new, 
                                                                           (Map<Id, tsanet_connect__TSANet_Credentials__c>) Trigger.oldMap);
            TSANetCredentialsHelper.changePrimaryUser((tsanet_connect__TSANet_Credentials__c[]) Trigger.new, 
                                                      (Map<Id, tsanet_connect__TSANet_Credentials__c>) Trigger.oldMap);
        }
        
        if(Trigger.isDelete) {
            TSANetCredentialsHelper.checkPrimaryTSANetCredentialsOnDelete((tsanet_connect__TSANet_Credentials__c[]) Trigger.old);
        }
    }
    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            TSANetCredentialsHelper.getToken((tsanet_connect__TSANet_Credentials__c[]) Trigger.new);
        }
    }
}