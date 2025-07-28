global class TSANetInvocableNoteService {

    global class TSANetInput {
        @InvocableVariable 
        global tsanet_connect__TSANetCase__c caseRecord;
        @InvocableVariable 
        global TSANetNoteForm note;
    }
    
    global class TSANetCollaborationCaseNoteResult {
        @InvocableVariable 
        global TSANetCollaborationCase caseRecord;
    }

    @InvocableMethod(label='Create TSANet Note' description='Returns collaboration case note' category='TSANet')
    global static TSANetCollaborationCaseNoteResult[] createCollaborationCaseNote(TSANetInput[] data) {
        TSANetInput input = data[0];
        String json = JSON.serialize(input.note);
        System.debug('json: ' + json);
        
        createTSANetAPINote(input.caseRecord.tsanet_connect__tsaNetCaseId__c, json);
        System.debug('after: ');
        //String body = TSANetService.createCaseNote(input.caseRecord.tsanet_connect__tsaNetCaseId__c, json);
        //System.debug('body : ' + body);
        if(!Test.isRunningTest()){ TSANetUtils.futureRefresh(null); }
        
        TSANetCollaborationCaseNoteResult result = new TSANetCollaborationCaseNoteResult();
        
        //result.caseRecord = [SELECT Id, Name, tsanet_connect__tsaNetCaseId__c FROM tsanet_connect__TSANetCase__c WHERE tsanet_connect__tsaNetCaseId__c =:input.caseRecord.tsanet_connect__tsaNetCaseId__c];
        return new TSANetCollaborationCaseNoteResult[]{ result };
    }
    
    @future(callout=true)
    public static void createTSANetAPINote(String caseId, String json){
        System.debug('json: ' + json);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TSANetService.endpoint + '/v1/collaboration-requests/' + caseId + '/notes');
        req.setHeader('Authorization', TSANetService.getBearerToken());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(10000);
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        if(res.getBody() == 'The authorization token provided was invalid.'){
            updateAccessTokenAndCreateNote(caseId, json);
        } else {
            System.debug(res.getStatusCode());
            System.debug(res.getBody());
    
            TSANetNoteResponse noteResponse = TSANetNoteResponse.parseOneRecord(res.getBody());
            System.debug('noteResponse.token :' + noteResponse.token);
            System.debug('noteResponse; ' + noteResponse);
            
        }
    }
    
    public static void updateAccessTokenAndCreateNote(String caseId, String json) {
        String token = TSANetService.getBearerAccessToken();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TSANetService.endpoint + '/v1/collaboration-requests/' + caseId + '/notes');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        TSANetNoteResponse noteResponse = TSANetNoteResponse.parseOneRecord(res.getBody());
        System.debug('noteResponse.token :' + noteResponse.token);
        System.debug('noteResponse; ' + noteResponse);
    }
        
}