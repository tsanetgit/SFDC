global class TSANetInvocableApproveRequestService {
    
    global class TSANetInput {
        @InvocableVariable 
        global tsanet_connect__TSANetCase__c caseRecord;
        @InvocableVariable 
        global TSANetCaseRequest request;
    }
    
	global class TSANetInvocableApproveRequestResult {
        @InvocableVariable 
        global TSANetCollaborationCase caseRecord;
    }
    
    @InvocableMethod(label='Approve TSANet Collaboration Request' description='Returns case request' category='TSANet')
    global static TSANetInvocableApproveRequestResult[] approveCollaborationRequest(TSANetInput[] inputs) {
        TSANetInput input = inputs[0];
        String body = '';
        try {
            
            body = TSANetService.approveIncomingRequest(input.caseRecord.tsanet_connect__Token__c, JSON.serialize(input.request));
            
            if(body == 'The authorization token provided was invalid.'){
                body = approveAndUpdateToken(input);
            }
            
        } catch(Exception e){
            if(e.getMessage().contains('Unauthorized')){
                body = approveAndUpdateToken(input);
            }
        }

        if(!Test.isRunningTest()){ TSANetUtils.futureRefresh(NULL); }
        System.debug('body : ' + body);
        TSANetInvocableApproveRequestResult result = new TSANetInvocableApproveRequestResult();
        if(body != ''){
            result.caseRecord = (TSANetCollaborationCase) System.JSON.deserialize(body, TSANetCollaborationCase.class);
        }
        return new TSANetInvocableApproveRequestResult[]{ result };
    }
    
    global static String approveAndUpdateToken(TSANetInput input){
        String token = TSANetService.getBearerAccessToken();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TSANetService.endpoint + '/0.1.0/cases/' + input.caseRecord.tsanet_connect__Token__c + '/approve');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(input.request));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        String userId = TSANetService.CONFIG.tsanet_connect__IntegrationUser__c == NULL ? UserInfo.getUserId() : TSANetService.CONFIG.tsanet_connect__IntegrationUser__c;
        Database.update(new User(Id = userId, tsanet_connect__tsaNetAccessToken__c = token)).isSuccess();
        
        return res.getBody();
    }
}