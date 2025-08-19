public with sharing class CredentialManager {
    
    public class CredentialManagerException extends Exception {}
    
	@AuraEnabled
    public static tsanet_connect__TSANet_Credentials__c getCredentials(){
        tsanet_connect__TSANet_Credentials__c[] credentials = [SELECT Id, Name, tsanet_connect__UserName__c, tsanet_connect__Password__c, tsanet_connect__Environment__c, tsanet_connect__isPrimary__c, tsanet_connect__IntegrationUser__c, tsanet_connect__Token__c, tsanet_connect__CompanyId__c, tsanet_connect__CompanyName__c 
                                                               FROM tsanet_connect__TSANet_Credentials__c 
                                                               WHERE tsanet_connect__isPrimary__c = TRUE];
        
        if(!credentials.isEmpty()){
            return credentials[0];
        } else {
            throw new CredentialManagerException('Username and password can not be empty!');
        }
    }
    
    public static void updateCredentials(TSANetCompanyInfo info){
        tsanet_connect__TSANet_Credentials__c credential = getCredentials();
        credential.tsanet_connect__CompanyName__c = info.company.name;
        credential.tsanet_connect__CompanyId__c = info.company.id;
        Database.update(credential).isSuccess();
    }
    
    public static void updateToken(String token){
        tsanet_connect__TSANet_Credentials__c credential = getCredentials();
        credential.tsanet_connect__Token__c = token;
        Database.update(credential);
    }
}