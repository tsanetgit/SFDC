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
        System.debug('1 : ' + body);
        System.debug('input : ' + input);
        
        String data = JSON.serialize(input);
        
        System.debug('data : ' + data);
        
        try {
            
            approveAndUpdateToken2(data); //TSANetService.approveIncomingRequest(input.caseRecord.tsanet_connect__Token__c, JSON.serialize(input.request));
            //System.debug('1 : ' + body);
            if(body == 'The authorization token provided was invalid.'){
                approveAndUpdateToken2(data);
            }
            System.debug('2 : ' + body);
        } catch(Exception e){
            System.debug('e : ' + e.getMessage());
            if(e.getMessage().contains('Unauthorized')){
                approveAndUpdateToken2(data);
                System.debug('3 : ' + body);
            }
        }

        //if(!Test.isRunningTest()){ TSANetUtils.futureRefresh(NULL); }
        System.debug('body : ' + body);
        TSANetInvocableApproveRequestResult result = new TSANetInvocableApproveRequestResult();
        if(body != ''){
            result.caseRecord = (TSANetCollaborationCase) System.JSON.deserialize(body, TSANetCollaborationCase.class);
        }
        return new TSANetInvocableApproveRequestResult[]{ result };
    }
    
    global static String approveAndUpdateToken(TSANetInput input){ 
                
        String token = TSANetService.getBearerAccessToken();
        
        System.debug('token : ' + token);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TSANetService.endpoint + '/0.1.0/cases/' + input.caseRecord.tsanet_connect__Token__c + '/approve');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(input.request));
        System.debug('req : ' + req);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('res : ' + res.getStatusCode());
        System.debug(res.getBody());
        
        String userId = TSANetService.CONFIG.tsanet_connect__IntegrationUser__c == NULL ? UserInfo.getUserId() : TSANetService.CONFIG.tsanet_connect__IntegrationUser__c;
        Database.update(new User(Id = userId, tsanet_connect__tsaNetAccessToken__c = token)).isSuccess();
        
        return res.getBody();
    }
    
    @future(callout=true)
    global static void approveAndUpdateToken2(String json){ // TSANetInput input
        System.debug('approveAndUpdateToken2 : ' + json);
        TSANetInput input = (TSANetInput) System.JSON.deserialize(json, TSANetInput.class);
        System.debug('input : ' + input);
        String body = System.JSON.serialize(input.request);
        System.debug('body : ' + body);
        String token = TSANetService.getBearerAccessToken();
        System.debug('token : ' + token);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TSANetService.endpoint + '/0.1.0/cases/' + input.caseRecord.tsanet_connect__Token__c + '/approve');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(body);
        System.debug('req : ' + req);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('res : ' + res.getStatusCode());
        System.debug(res.getBody());
        
        if(!Test.isRunningTest()){
            TSANetService.getRelatedCollaborationCases(null);
        }
        
        //String userId = TSANetService.CONFIG.tsanet_connect__IntegrationUser__c == NULL ? UserInfo.getUserId() : TSANetService.CONFIG.tsanet_connect__IntegrationUser__c;
        //Database.update(new User(Id = userId, tsanet_connect__tsaNetAccessToken__c = token)).isSuccess();
        
        //return res.getBody();
    }
}