public class TSANetRefreshUtils {

    public TSANetRefreshUtils(ApexPages.StandardController controller) {}

    public PageReference refresh() {
        try {
            //TSANetService.getRelatedCollaborationCases(null);
            System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null));
            PageReference returnPage = goBack();
            return returnPage; 
            
        } catch(Exception e){
            PageReference returnPage = goBack();
            futureRefresh();
            return returnPage; 
        }
    }
    
    public PageReference goBack() {
        return new PageReference('/lightning/o/tsanet_connect__TSANetCase__c/list'); 
    }
    
    @AuraEnabled
    public static Boolean refreshOnCase(Id caseId) {
        try {
            TSANetService.getRelatedCollaborationCases(caseId);
            return true; 
        } catch(Exception e){
            futureRefresh();
            return true; 
        }
    }
    
    @AuraEnabled
    public static String getAccessToken(){

        tsanet_connect__TSANet_Credentials__c credentials = TSANetService.getCredentials();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TSANetService.endpoint + TSANetService.login_path);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('');
        req.setBody('{"username": "' + credentials.tsanet_connect__UserName__c + '","password": "' + credentials.tsanet_connect__Password__c + '"}');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if(res.getStatusCode() != 200){ return null; }
        
        TSANetService.AccessTokenResponse response = (TSANetService.AccessTokenResponse) System.JSON.deserialize(res.getBody(), TSANetService.AccessTokenResponse.class);
       
        return response.accessToken;
    }
    
    @future(callout=true)
    public static void futureRefresh() {
        getRelatedCollaborationCases(null);
    }
    
    @AuraEnabled
    public static tsanet_connect__TSANetCase__c[] getRelatedCollaborationCases(String caseId){
        
        String token = Test.isRunningTest() ? 'token' : getAccessToken();
        
        String path = TSANetService.endpoint + TSANetService.case_path;
        if(caseId != NULL){
            path += ( '?internalCaseNumber=' + caseId );
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        String userId = TSANetService.CONFIG.tsanet_connect__IntegrationUser__c == NULL ? UserInfo.getUserId() : TSANetService.CONFIG.tsanet_connect__IntegrationUser__c;
        
        Database.update(new User(Id = UserInfo.getUserId(), tsanet_connect__tsaNetAccessToken__c = token)).isSuccess();
        
        if(res.getStatusCode() != 200){
            //TSANetService.handleResponseErrors(res);
            
            return [SELECT Id, Name, tsanet_connect__Name__c, tsanet_connect__customFields__c, tsanet_connect__TSANetContact__c, tsanet_connect__FirstName__c, tsanet_connect__LastName__c, tsanet_connect__Phone__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerEmail__c, tsanet_connect__TSANetEmail__c, tsanet_connect__EngineerPhone__c, tsanet_connect__Email__c, tsanet_connect__Case__c, tsanet_connect__Case__r.CaseNumber, Partner__c, tsanet_connect__SubmittedCompanyName__c, tsanet_connect__SubmittedCompanyId__c, tsanet_connect__receivedCompanyName__c, tsanet_connect__receivedCompanyId__c, tsanet_connect__Summary__c, tsanet_connect__Description__c, tsanet_connect__Status__c, tsanet_connect__Token__c, tsanet_connect__Responded__c, tsanet_connect__FeedbackRequested__c, tsanet_connect__ReminderSent__c, tsanet_connect__Priority__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__RequestDate__c, tsanet_connect__ResponseDate__c, tsanet_connect__PriorityNote__c, tsanet_connect__Type__c,
                    (SELECT Id, Name, tsanet_connect__TSANetCase__c, tsanet_connect__Type__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerPhone__c, tsanet_connect__EngineerEmail__c, tsanet_connect__Note__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__tsaNetResponseId__c FROM tsanet_connect__TSANetResponses__r ORDER BY tsanet_connect__CreatedAt__c DESC)
                    FROM tsanet_connect__TSANetCase__c 
                    WHERE tsanet_connect__Case__c =:caseId 
                    ORDER BY tsanet_connect__RequestDate__c DESC];
        }
        
        return TSANetService.parseTSANetCases(res.getBody(), caseId);
    }

}