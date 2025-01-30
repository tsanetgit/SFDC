public class TSANetNoteTriggerHelper {
    
    public static void handleAfterInsert(tsanet_connect__TSANetNote__c[] notes){
        createTSANetAPINote(notes);
        createFeedItems(notes);
    }
    
    public static void handleAfterUpdate(tsanet_connect__TSANetNote__c[] notes, Map<Id, tsanet_connect__TSANetNote__c> oldNotes){
        createFeedItems(notes);
    }
    
    public static void createFeedItems(tsanet_connect__TSANetNote__c[] notes){
        Id[] tsaNetCaseIds = new Id[]{};
            
        for(tsanet_connect__TSANetNote__c note : notes){
            if(note.tsanet_connect__isCaseFeed__c == true && note.tsanet_connect__isApiNote__c == TRUE){
                tsaNetCaseIds.add(note.tsanet_connect__TSANetCase__c);
            }
        }
        if(tsaNetCaseIds.size() == 0){ return; }
        System.debug('tsaNetCaseIds : ' + tsaNetCaseIds);
        Map<Id, tsanet_connect__TSANetCase__c> tsaNetCases = new Map<Id, tsanet_connect__TSANetCase__c>([SELECT Id, Name, tsanet_connect__Case__c FROM tsanet_connect__TSANetCase__c WHERE Id IN:tsaNetCaseIds]);
    	System.debug('tsaNetCases : ' + tsaNetCases);
        Id[] caseIds = new Id[]{};
        for(tsanet_connect__TSANetCase__c tsaNetCase : tsaNetCases.values()){
            if(tsaNetCase.tsanet_connect__Case__c != NULL){
                caseIds.add(tsaNetCase.tsanet_connect__Case__c);
            }
        }
        System.debug('caseIds : ' + caseIds);
        FeedItem[] items = [SELECT Id, Title, Body FROM FeedItem WHERE ParentId IN:caseIds AND Title LIKE '%TSANet Note - %'];
        System.debug('items : ' + items);
        Map<String, FeedItem> sortedItems = new Map<String, FeedItem>();
        for(FeedItem item : items){
            if(item.Title != NULL){
                String[] strs = item.Title.split(' - ');
                String token = strs[1];
                sortedItems.put(token, item);
            }
        }
        System.debug('sortedItems : ' + sortedItems);
        FeedItem[] feedItems = new FeedItem[]{};
        for(tsanet_connect__TSANetNote__c note : notes){
            if(!sortedItems.containsKey(note.tsanet_connect__Token__c)){
                String summary = note.tsanet_connect__Summary__c;
                String description = note.tsanet_connect__Description__c;
                String priority = note.tsanet_connect__Priority__c;
                String creatorName = note.tsanet_connect__CreatorName__c;
                
                if(description != NULL && description.contains('<strong>')){
                    description = description.replaceAll('<strong>', '<b>');
                    description = description.replaceAll('</strong>', '</b>');
                }
                
                String refactoredDescription = stripHtmlTags(description);
                
                String message = '<p>Note Details:</p>' + 
                    '<p>Created By: ' + creatorName + '</p>' +
                    '<p>Summary: ' + summary + '</p>' +
                    '<p>Description: ' + refactoredDescription + '</p>';
                
                tsanet_connect__TSANetCase__c tsaNetCase = tsaNetCases.get(note.tsanet_connect__TSANetCase__c);
                
                if(tsaNetCase != NULL && tsaNetCase.tsanet_connect__Case__c != NULL){
                    FeedItem f = new FeedItem(
                        ParentId = tsaNetCase.tsanet_connect__Case__c,
                        IsRichText = true,
                        Title = 'TSANet Note - ' + note.tsanet_connect__Token__c,
                        Body = message
                    );
                    
                    feedItems.add(f);
                }
        
            }
        }
        
        System.debug('feedItems : ' + feedItems);
        
        insert feedItems;
    
    }


    public static void createTSANetAPINote(tsanet_connect__TSANetNote__c[] notes) {
        
        String[] caseIds = new String[]{};
        for(tsanet_connect__TSANetNote__c note : notes){
            caseIds.add(note.tsanet_connect__TSANetCase__c);
        }
        
        Map<Id, tsanet_connect__TSANetCase__c> tsaNetCases = new Map<Id, tsanet_connect__TSANetCase__c>([SELECT Id, Name, tsanet_connect__Case__r.Owner.FirstName, tsanet_connect__Case__r.Owner.LastName, tsanet_connect__tsaNetCaseId__c FROM tsanet_connect__TSANetCase__c WHERE Id IN:caseIds]);
        
        for(tsanet_connect__TSANetNote__c note: notes){
            if(note.tsanet_connect__isApiNote__c == FALSE && note.tsanet_connect__TSANetCase__c != NULL){
                
                tsanet_connect__TSANetCase__c tsaNetCase = tsaNetCases.get(note.tsanet_connect__TSANetCase__c);
                
                String creatorFirstName = '';
                String creatorLastName = '';
                
                if(tsaNetCase.tsanet_connect__Case__r.Owner.FirstName != NULL && tsaNetCase.tsanet_connect__Case__r.Owner.LastName != NULL){
                    creatorFirstName = tsaNetCase.tsanet_connect__Case__r.Owner.FirstName;
                    creatorLastName = tsaNetCase.tsanet_connect__Case__r.Owner.LastName;
                } else {
                    User currentUser = [SELECT Id, FirstName, LastName FROM User WHERE Id =:UserInfo.getUserId()];
                    creatorFirstName = currentUser.FirstName;
                    creatorLastName = currentUser.LastName;
                }
                
                String json = '{"summary": "' + 
                    note.tsanet_connect__Summary__c + 
                    '", "description": "' + note.tsanet_connect__Description__c + 
                    '", "priority":"' + note.tsanet_connect__Priority__c + '", ' + 
                    '"submittedBy": { "firstName": "' + creatorFirstName + '", "lastName": "' + creatorLastName + '" }}';
                
                
                createTSANetAPINoteFuture(tsaNetCase.tsanet_connect__tsaNetCaseId__c, json, note.Id);
            }
        }
    }
    
    @future(callout=true)
    public static void createTSANetAPINoteFuture(String caseId, String json, String noteId){
        System.debug('json: ' + json);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TSANetService.endpoint + '/1.0.8/cases/' + caseId + '/notes/create');
        req.setHeader('Authorization', TSANetService.getBearerToken());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        if(res.getBody() == 'The authorization token provided was invalid.'){
            updateAccessTokenAndCreateNote(caseId, json, noteId);
        } else {
            System.debug(res.getStatusCode());
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
    
    public static String stripHtmlTags(String input) {
        if (String.isEmpty(input)) { return ''; }
        Pattern htmlPattern = Pattern.compile('<[^>]+>');
        Matcher htmlMatcher = htmlPattern.matcher(input);
        String sanitizedString = htmlMatcher.replaceAll('');
        return sanitizedString;
    }
}