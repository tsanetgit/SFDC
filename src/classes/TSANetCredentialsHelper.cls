public class TSANetCredentialsHelper {

    public static void turnOfPrimaryTSANetCredentials(tsanet_connect__TSANet_Credentials__c[] newCredentials){
        Boolean isPrimary = false;
        for(tsanet_connect__TSANet_Credentials__c newCredential : newCredentials){
            if(newCredential.tsanet_connect__isPrimary__c == true){
                isPrimary = true;
            }
        }
        
        if(isPrimary == TRUE){
            tsanet_connect__TSANet_Credentials__c[] credentials = [SELECT Id, Name, tsanet_connect__UserName__c, tsanet_connect__Password__c, tsanet_connect__Environment__c, tsanet_connect__isPrimary__c FROM tsanet_connect__TSANet_Credentials__c];
            for(tsanet_connect__TSANet_Credentials__c credential : credentials){
                credential.tsanet_connect__isPrimary__c = false;
            }
            update credentials;
        }
    }
    
    public static void turnOfPrimaryTSANetCredentialsOnUpdate(tsanet_connect__TSANet_Credentials__c[] newCredentials, Map<Id, tsanet_connect__TSANet_Credentials__c> oldCredentials){
        Boolean isPrimary = false;
        Id[] credentialIds = new Id[]{};
        for(tsanet_connect__TSANet_Credentials__c newCredential : newCredentials){
            if(newCredential.tsanet_connect__isPrimary__c == true && 
               ( oldCredentials.get(newCredential.Id).tsanet_connect__isPrimary__c != newCredential.tsanet_connect__isPrimary__c )){
               isPrimary = true;
               credentialIds.add(newCredential.Id);
            }
        }
        
        if(isPrimary == TRUE){
            tsanet_connect__TSANet_Credentials__c[] credentials = [SELECT Id, Name, tsanet_connect__UserName__c, tsanet_connect__Password__c, tsanet_connect__Environment__c, tsanet_connect__isPrimary__c FROM tsanet_connect__TSANet_Credentials__c WHERE Id NOT IN:credentialIds];
            for(tsanet_connect__TSANet_Credentials__c credential : credentials){
                credential.tsanet_connect__isPrimary__c = false;
            }
            update credentials;
        }
    }
    
    public static void checkPrimaryTSANetCredentialsOnDelete(tsanet_connect__TSANet_Credentials__c[] credentials){
        for(tsanet_connect__TSANet_Credentials__c credential : credentials){
            if(credential.tsanet_connect__isPrimary__c == TRUE){
                credential.addError('You can’t remove primary credentials. Please mark them as non-primary and try again!');
            }
        }
    }
}