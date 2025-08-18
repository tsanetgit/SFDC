public class TSANetRefreshUtils {

    public static tsanet_connect__TSANet_Credentials__c credential = CredentialManager.getCredentials();

    public TSANetRefreshUtils(ApexPages.StandardController controller) {}

    public PageReference refresh() {
        try {
            //TSANetService.getRelatedCollaborationCases(null);
            System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null));
            PageReference returnPage = goBack();
            System.debug('returnPage : ' + returnPage);
            return returnPage; 
            
        } catch(Exception e){
            System.debug('CATCH');
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
            TSANetService.getRelatedCollaborationCases(caseId, null);
            return true; 
        } catch(Exception e){
            futureRefresh();
            return true; 
        }
    }
    
    @future(callout=true)
    public static void futureRefresh() {
        getRelatedCollaborationCases(null);
    }
    
    @AuraEnabled
    public static void getRelatedCollaborationCases(String caseId){
        
        String token = Test.isRunningTest() ? 'token' : TSANetService.getTSANetAccessToken();
        
        System.debug('token : ' + token);
        String path = EndpointManager.domain + EndpointManager.case_path;
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
        
        System.debug(res.getBody());
        
        String userId = credential.tsanet_connect__IntegrationUser__c == NULL ? UserInfo.getUserId() : credential.tsanet_connect__IntegrationUser__c;
        
        Database.update(new User(Id = UserInfo.getUserId(), tsanet_connect__tsaNetAccessToken__c = token)).isSuccess();
        
        if(res.getStatusCode() != 200){
            //TSANetService.handleResponseErrors(res);
        }
        
        TSANetData data = ParserManager.parseTSANetCases(res.getBody(), caseId);
        upsert data.cases tsanet_connect__tsaNetCaseId__c;
        upsert data.responses tsanet_connect__tsaNetResponseId__c;
        upsert data.notes tsanet_connect__Token__c;
    }

}