trigger TSANetCredentialsTrigger on tsanet_connect__TSANet_Credentials__c (before insert, before update, before delete) {
    if (Trigger.isBefore) {
        if(Trigger.isInsert) {
            tsanet_connect__TSANet_Credentials__c[] newCredentials = (tsanet_connect__TSANet_Credentials__c[]) Trigger.new;
            
            TSANetCredentialsHelper.turnOfPrimaryTSANetCredentials(newCredentials);
        }
        
        if(Trigger.isUpdate) {
            tsanet_connect__TSANet_Credentials__c[] newCredentials = (tsanet_connect__TSANet_Credentials__c[]) Trigger.new;
        	Map<Id, tsanet_connect__TSANet_Credentials__c> oldCredentials = (Map<Id, tsanet_connect__TSANet_Credentials__c>) Trigger.oldMap;
            
            TSANetCredentialsHelper.turnOfPrimaryTSANetCredentialsOnUpdate(newCredentials, oldCredentials);
            TSANetCredentialsHelper.changePrimaryUser(newCredentials, oldCredentials);
        }
        
        if(Trigger.isDelete) {
            tsanet_connect__TSANet_Credentials__c[] credentials = (tsanet_connect__TSANet_Credentials__c[]) Trigger.old;

            TSANetCredentialsHelper.checkPrimaryTSANetCredentialsOnDelete(credentials);
        }
    }
}