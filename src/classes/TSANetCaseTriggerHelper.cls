public class TSANetCaseTriggerHelper {
    /*
    public static void handleAfterInsert(tsanet_connect__TSANetCase__c[] cases){
		createTSANetCase(cases);
    }
    
    public static void createTSANetCase(tsanet_connect__TSANetCase__c[] tsaNetCases){
        
        Id[] caseIds = new Id[]{};
        for(tsanet_connect__TSANetCase__c tsaNetCase : tsaNetCases){
            caseIds.add(tsaNetCase.tsanet_connect__Case__c);
        }
        
        Map<Id, Case> cases = new Map<Id, Case>([SELECT Id, Subject, Owner.FirstName, Owner.LastName FROM Case WHERE Id IN:caseIds]);
        
        for(tsanet_connect__TSANetCase__c tsaNetCase: tsaNetCases){
            if(tsaNetCase.tsanet_connect__isApiCase__c == FALSE && tsaNetCase.tsanet_connect__Case__c != NULL){
                
                Case caseRecord = cases.get(tsaNetCase.tsanet_connect__Case__c);
                
                String creatorFirstName = '';
                String creatorLastName = '';
                
                if(caseRecord.Owner.FirstName != NULL && caseRecord.Owner.LastName != NULL){
                    creatorFirstName = caseRecord.Owner.FirstName;
                    creatorLastName = caseRecord.Owner.LastName;
                } else {
                    User currentUser = [SELECT Id, FirstName, LastName FROM User WHERE Id =:UserInfo.getUserId()];
                    creatorFirstName = currentUser.FirstName;
                    creatorLastName = currentUser.LastName;
                }
                
                String json = JSON.serialize(TSANetCaseForm.getFormByTSANetCaseId(tsaNetCase.Id));
                System.debug('TRIGGER JSON: ' + json);
                createTSANetCaseFuture(tsaNetCase.Id, json, caseRecord.Id);
            }
        }
    }
    
    @future(callout=true)
    public static void createTSANetCaseFuture(String tsaNetCaseId, String json, String caseId){
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TSANetService.endpoint + TSANetService.create_case_path);
        req.setHeader('Authorization', TSANetService.getBearerToken());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());

        
        if(res.getBody() == 'The authorization token provided was invalid.'){
            //updateAccessTokenAndCreateNote(caseId, json, noteId);
        } else {
            System.debug(res.getStatusCode());
            System.debug(res.getBody());
      
            Map<String, Object> response = (Map<String, Object>) System.JSON.deserializeUntyped(res.getBody());
            System.debug('response 1111: ' + response);
            //TSANetService.createCaseFeedItem(caseId, response);
        	System.debug('tsaNetCaseId :' + tsaNetCaseId);
            System.debug('tsaNetCaseId :' + response.get('token'));
             
            
            update new tsanet_connect__TSANetCase__c(
                Id = tsaNetCaseId, 
                tsanet_connect__Token__c = (String) response.get('token')
            );
            
        }
    }
    
    public static void updateAccessTokenAndCreateNote(String caseId, String json, String noteId) {
        String token = TSANetService.getBearerAccessToken();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TSANetService.endpoint + '/1.0.8/cases/' + caseId + '/notes/create');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        TSANetNoteResponse noteResponse = TSANetNoteResponse.parseOneRecord(res.getBody());
        System.debug('noteId :' + noteId);
        System.debug('noteResponse.token :' + noteResponse.token);
        System.debug('noteResponse; ' + noteResponse);
        update new tsanet_connect__TSANetNote__c(
            Id = noteId, 
            tsanet_connect__Token__c = noteResponse.token,
            tsanet_connect__Status__c = noteResponse.status,
            tsanet_connect__Priority__c = noteResponse.priority,
            tsanet_connect__CreatorName__c = noteResponse.creatorUsername
        );
    }
    */
/*
    public static void handleAfterUpdate(tsanet_connect__TSANetCase__c[] cases, Map<Id, tsanet_connect__TSANetCase__c> oldCases){

        Id[] ids = new Id[]{};
            for(tsanet_connect__TSANetCase__c caseRecord : cases){
                ids.add(caseRecord.Id);
            }
        
        tsanet_connect__TSANetResponse__c[] responses = [SELECT Id, Name, tsanet_connect__TSANetCase__c, tsanet_connect__TSANetCase__r.Case__r.Owner.Name, tsanet_connect__TSANetCase__r.Case__r.Owner.Email, tsanet_connect__TSANetCase__r.Case__r.Owner.Phone FROM tsanet_connect__TSANetResponse__c WHERE tsanet_connect__TSANetCase__c IN:ids];
        Map<String, tsanet_connect__TSANetResponse__c[]> caseToResponses = new Map<String, tsanet_connect__TSANetResponse__c[]>();
        for(tsanet_connect__TSANetResponse__c res : responses){
            if(caseToResponses.containsKey(res.tsanet_connect__TSANetCase__c)){
                tsanet_connect__TSANetResponse__c[] localRes = caseToResponses.get(res.tsanet_connect__TSANetCase__c);
                localRes.add(res);
                caseToResponses.put(res.tsanet_connect__TSANetCase__c, localRes);
            } else {
                caseToResponses.put(res.tsanet_connect__TSANetCase__c, new tsanet_connect__TSANetResponse__c[]{ res });
            }
        }
        System.debug('caseResponse:  WORK ');
        Id[] tsaNetCaseIds = new String[]{};
            for(tsanet_connect__TSANetCase__c caseRecord : cases){
                if(caseRecord.tsanet_connect__Case__c != oldCases.get(caseRecord.Id).tsanet_connect__Case__c){
                    
                    tsanet_connect__TSANetResponse__c[] caseResponses = caseToResponses.get(caseRecord.Id);
                    System.debug('caseResponses ' + caseResponses);
                    if(caseResponses != NULL && caseResponses.size() > 0){
                        tsanet_connect__TSANetResponse__c caseResponse = caseResponses[0];
                        System.debug('caseResponse:  WORK ');
                        String json = '{ "caseNumber": "' + caseRecord.tsanet_connect__tsaNetCaseId__c + 
                            '", "engineerName": "' + caseResponse.tsanet_connect__TSANetCase__r.Case__r.Owner.Name + 
                            '", "engineerPhone": "' + caseResponse.tsanet_connect__TSANetCase__r.Case__r.Owner.Phone + 
                            '", "engineerEmail": "' + caseResponse.tsanet_connect__TSANetCase__r.Case__r.Owner.Email + 
                            '", "nextSteps": "Case Owner has been changed!" }';
                        TSANetService.approveIncomingRequestFuture(caseRecord.tsanet_connect__Token__c, json);
                    }
                }
            }
    }
*/
}