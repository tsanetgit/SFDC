public class ErrorManager {
    
    public class ErrorManagerException extends Exception {}
    
    public static  tsanet_connect__TSANet_Credentials__c credential = CredentialManager.getCredentials();

    public static void handleResponseErrors(HTTPResponse response){
        System.debug('response.getStatusCode() : ' + response.getStatusCode());
        System.debug('response.getStatusCode() : ' + response.getBody());
        if(response.getStatusCode() != 200){
            if(response.getBody().contains('The authorization token provided was invalid.')){
                Database.update(new tsanet_connect__TSANet_Credentials__c(Id = credential.Id, tsanet_connect__Token__c = NULL));
                //AuthManager.updateAccessTokenFuture();
                throw new ErrorManagerException('Unauthorized');
            } else {
                throw new ErrorManagerException((String) response.getBody());
            }
        }
    } 
    
    public static Boolean isUnautorized(String body){
        return body.contains('The authorization token provided was invalid');
    }
}