public class TSANetCredentialsHelper {
    
    public static void getToken(tsanet_connect__TSANet_Credentials__c[] credentials){
        for(tsanet_connect__TSANet_Credentials__c credential : credentials){
            if(credential.tsanet_connect__isPrimary__c == true){
                if(!Test.isRunningTest()){
                    InternalProcessManager.execute(credential);
                }
            }
        }
    }

    public static void turnOfPrimaryTSANetCredentials(tsanet_connect__TSANet_Credentials__c[] newCredentials){
        Boolean isPrimary = false;
        for(tsanet_connect__TSANet_Credentials__c newCredential : newCredentials){
            if(newCredential.tsanet_connect__isPrimary__c == true){
                isPrimary = true;
                if(newCredential.IntegrationUser__c == NULL){
                    newCredential.IntegrationUser__c = UserInfo.getUserId();
                }
            }
        }
        
        if(isPrimary == TRUE){
            tsanet_connect__TSANet_Credentials__c[] credentials = [SELECT Id, Name, tsanet_connect__UserName__c, tsanet_connect__Password__c, tsanet_connect__Environment__c, tsanet_connect__isPrimary__c FROM tsanet_connect__TSANet_Credentials__c];
            tsanet_connect__TSANet_Credentials__c[] credentialsToUpdate = new tsanet_connect__TSANet_Credentials__c[]{};
            for(tsanet_connect__TSANet_Credentials__c credential : credentials){
                if(credential.Id != NULL){
                    credential.tsanet_connect__isPrimary__c = false;
                    credentialsToUpdate.add(credential);
                }
            }
            update credentialsToUpdate;
        }
    }
    
    public static void turnOfPrimaryTSANetCredentialsOnUpdate(tsanet_connect__TSANet_Credentials__c[] newCredentials, Map<Id, tsanet_connect__TSANet_Credentials__c> oldCredentials){
        Boolean isPrimary = false;
        Id[] credentialIds = new Id[]{};
        for(tsanet_connect__TSANet_Credentials__c newCredential : newCredentials){
            if(newCredential.tsanet_connect__isPrimary__c == true && 
               ( oldCredentials.get(newCredential.Id).tsanet_connect__isPrimary__c != newCredential.tsanet_connect__isPrimary__c )){
               	
                isPrimary = true;
               	if(!Test.isRunningTest()){
               		InternalProcessManager.execute(newCredential);
               	}
               	credentialIds.add(newCredential.Id);
            }
            
            if(newCredential.tsanet_connect__isPrimary__c == false && 
               ( oldCredentials.get(newCredential.Id).tsanet_connect__isPrimary__c != newCredential.tsanet_connect__isPrimary__c )){
                ConfigManager.removeConfig();
            }
            
        }
        
        if(isPrimary == TRUE){
            tsanet_connect__TSANet_Credentials__c[] credentials = [SELECT Id, Name, tsanet_connect__UserName__c, tsanet_connect__Password__c, tsanet_connect__Environment__c, tsanet_connect__isPrimary__c FROM tsanet_connect__TSANet_Credentials__c WHERE Id NOT IN:credentialIds];
            for(tsanet_connect__TSANet_Credentials__c credential : credentials){
                credential.tsanet_connect__isPrimary__c = false;
            }
            update credentials;
            
            tsanet_connect__TSANetConfiguration__c CONFIG = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
            update new User(Id = CONFIG.tsanet_connect__IntegrationUser__c, tsanet_connect__tsaNetAccessToken__c = null);
        }
    }
    
    public static void changePrimaryUser(tsanet_connect__TSANet_Credentials__c[] newCredentials, Map<Id, tsanet_connect__TSANet_Credentials__c> oldCredentials){
		Id integrationUser;
        for(tsanet_connect__TSANet_Credentials__c newCredential : newCredentials){
            if(newCredential.tsanet_connect__IntegrationUser__c != NULL &&
               oldCredentials.get(newCredential.Id).tsanet_connect__IntegrationUser__c != newCredential.tsanet_connect__IntegrationUser__c ){
               integrationUser = newCredential.tsanet_connect__IntegrationUser__c;
            }
        }
        
        if(integrationUser != NULL){
            tsanet_connect__TSANetConfiguration__c config = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
            config.tsanet_connect__IntegrationUser__c = integrationUser;
            update config;
        }
    }
    
    public static void checkPrimaryTSANetCredentialsOnDelete(tsanet_connect__TSANet_Credentials__c[] credentials){
        for(tsanet_connect__TSANet_Credentials__c credential : credentials){
            if(credential.tsanet_connect__isPrimary__c == TRUE){
                credential.addError('You can’t remove primary credentials. Please mark them as non-primary and try again!');
            } else {
                ConfigManager.removeConfig();
            }
        }
    }
}