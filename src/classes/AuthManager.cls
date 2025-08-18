public class AuthManager {
    
    public class AuthManagerException extends Exception {}
    
    public static tsanet_connect__TSANetConfiguration__c config = ConfigManager.getConfig();
    public static  tsanet_connect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
    
    public class AccessTokenResponse {
        public String accessToken;
        public String tokenType;
        public Integer expiresIn;
    }
    
    
    @AuraEnabled
    public static String getAccessToken(){
        if(credential.tsanet_connect__Token__c == NULL){
            throw new AuthManagerException('Unauthorized');
        }
        return credential.tsanet_connect__Token__c;
    }
    
    public static String getBearerToken(){
        String token = getAccessToken();
        if(token == NULL && !Test.isRunningTest()){
			throw new AuthManagerException('Unauthorized');
        }
        return 'Bearer ' + token;
    }

    @AuraEnabled
    public static Boolean updateAccessToken(){
        
        String token = TSANetService.getTSANetAccessToken();
        if(token == NULL){ return false; }
        
        InternalProcessManager.execute(credential);
        return Database.update(new tsanet_connect__TSANet_Credentials__c(Id = credential.Id, 
                                                                         tsanet_connect__Token__c = token)).isSuccess();
    }
    
    @future(callout=true)
    public static void updateAccessTokenFuture(){
        updateAccessToken();
    }
    
    
}