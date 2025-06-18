global class TSANetScheduledJob implements Schedulable, Database.AllowsCallouts {
    
    public class TSANetScheduledJobException extends Exception {}
    
    //public static Map<String, Case> existedCases = getExistedCases();
    
    public static String endpoint = getEndpoint(); //'https://connect2.tsanet.us'; //https://connect2.renolab.us
    public static String get_cases_path = '/v1/collaboration-requests/'; //'/0.1.0/cases/'; //
    
    public static tsanet_connect__TSANetCaseMapping__mdt[] TSANET_MAPPING = [SELECT Id, tsanet_connect__Type__c, tsanet_connect__From__c, tsanet_connect__To__c FROM tsanet_connect__TSANetCaseMapping__mdt];
    
    public static tsanet_connect__TSANetConfiguration__c CONFIG = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
    
    public class PaymentScheduledJobException extends Exception {}
    
    global void execute(SchedulableContext sc){
        updateTSANetCases();
    }
    
    //@future(callout=true)
    public static void updateTSANetCases() {  
        try {
            Id jobId = System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null));
			System.debug('jobId : ' + jobId);
        } catch(Exception e){
            System.debug(e.getMessage());
        }
    }
    
    public static String getEndpoint() {
        
        tsanet_connect__TSANet_Credentials__c creds = TSANetService.getCredentials();
        System.debug('creds2 : ' + creds);
        String environment = creds.tsanet_connect__Environment__c + '_env';
        System.debug('environment2 : ' + environment);
        tsanet_connect__TSANetEnvironment__mdt[] environments =[SELECT Id, tsanet_connect__Endpoint__c FROM tsanet_connect__TSANetEnvironment__mdt WHERE DeveloperName =:environment];
        
        if(environments.size() > 0){
            return environments[0].tsanet_connect__Endpoint__c;
        } else { return 'https://connect2.renolab.us'; }
    }
    
    @AuraEnabled
    public static String getAccessTokenByUser(){
        if(CONFIG.tsanet_connect__IntegrationUser__c == NULL){
            throw new TSANetScheduledJobException('Unauthorized');
        }
        return [SELECT Id, tsanet_connect__tsaNetAccessToken__c FROM User WHERE Id =:CONFIG.tsanet_connect__IntegrationUser__c ].tsanet_connect__tsaNetAccessToken__c;
    }
    
    public static String getBearerToken(){
        String token = getAccessTokenByUser();
        if(token == NULL){
			throw new TSANetScheduledJobException('Unauthorized');
        }
        return 'Bearer ' + token;
    }
    
    @AuraEnabled
    public static TSANetData getRelatedCollaborationCases(String caseId, String createdAfter){
        
        String token = TSANetService.getBearerAccessToken();
        
        
        String path = endpoint + get_cases_path;
        if(caseId != NULL){ 
        	path += ( '?internalCaseNumber=' + caseId );
        } else if(createdAfter != NULL) {
            path += '?createdAfter=' + createdAfter;
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        return parseTSANetCases(res.getBody(), caseId);
        
        //return res.getBody();
    }
    
    
     
    public static TSANetData parseTSANetCases(String json, String caseId){
        System.debug(json);
        List<Object> cases = (List<Object>) System.JSON.deserializeUntyped(json);
        System.debug('cases : ' + cases);
        tsanet_connect__TSANetCase__c[] newCases = new tsanet_connect__TSANetCase__c[]{};
        Map<String, tsanet_connect__TSANetResponse__c[]> caseToResponses = new Map<String, tsanet_connect__TSANetResponse__c[]>();
        Map<String, tsanet_connect__TSANetNote__c[]> caseToNotes = new Map<String, tsanet_connect__TSANetNote__c[]>();  
        

        String[] existedCaseNumbers = new String[]{};
		for(Object caseRecord : cases){
            Map<String, Object> record = (Map<String, Object>) caseRecord;
            String externalId = String.valueOf(record.get('id'));
            for(tsanet_connect__TSANetCaseMapping__mdt element : TSANET_MAPPING){
                if(element.tsanet_connect__Type__c == 'REFERENCE'){
                    String parentCaseId = String.valueOf(record.get(element.tsanet_connect__From__c));
                    existedCaseNumbers.add(parentCaseId);
                    
                    if(record.get('receiverCaseNumber') != NULL){
                        existedCaseNumbers.add(String.valueOf(record.get('receiverCaseNumber')));
                    }
                } else if(element.Type__c == 'ARRAY' && element.From__c == 'customFields'){
                        
                        List<Object> customerData = (List<Object>) record.get(element.From__c);
                        if(customerData != NULL && customerData.size() > 0){
                            for(Object customerField : customerData){
                                Map<String, Object> customerFieldToValue = ( Map<String, Object> ) customerField;
                                System.debug('customerFieldToValue :' + customerFieldToValue);
                                
                                String fieldName = (String) customerFieldToValue.get('fieldName');
                                String value = (String) customerFieldToValue.get('value');
                                
                                if(fieldName.contains('Customer Case')){
                                    System.debug('Customer Case Contains - value : ' + value);
                                    if(value != NULL && value != ''){
                                        existedCaseNumbers.add(value);
                                    }
                                }
                            }
                        }
                }
            }
        }
        
        Map<String, Case> existedCases = getExistedCases(existedCaseNumbers);
        
        String[] existedIds = new String[]{};
        for(Object caseRecord : cases){
            Map<String, Object> record = (Map<String, Object>) caseRecord;
            String externalId = String.valueOf(record.get('id'));

            if(!existedIds.contains(externalId)){
                tsanet_connect__TSANetCase__c newCase = new tsanet_connect__TSANetCase__c();
                newCase.tsanet_connect__isApiCase__c = TRUE;
                for(tsanet_connect__TSANetCaseMapping__mdt element : TSANET_MAPPING){
                    if(element.tsanet_connect__Type__c == 'DATETIME'){
                        try {
                            String datetimeString = (String) record.get(element.tsanet_connect__From__c);
                            if(datetimeString != null){
                                datetimeString = datetimeString.replace('Z', '');
                                DateTime dt = DateTime.valueOf(datetimeString.replace('T', ' '));
                                System.debug('Parsed DateTime: ' + dt);
                                newCase.put(element.tsanet_connect__To__c, dt);
                            }
                        } catch(Exception e){}
                        
                    } else if(element.tsanet_connect__Type__c == 'BOOLEAN'){
                        newCase.put(element.tsanet_connect__To__c, Boolean.valueOf(record.get(element.tsanet_connect__From__c)));
                    } else if(element.tsanet_connect__Type__c == 'STRING'){
                        newCase.put(element.tsanet_connect__To__c, String.valueOf(record.get(element.tsanet_connect__From__c)));
                    } else if(element.tsanet_connect__Type__c == 'REFERENCE'){
                        System.debug('REFERENCE : ');
                        String parentCaseId = String.valueOf(record.get(element.tsanet_connect__From__c));
                        String receiverCaseId = String.valueOf(record.get('receiverCaseNumber'));
                        try {
                            System.debug('parentCaseId : ');
                            Boolean isInbound = String.valueOf(record.get('receiveCompanyId')) == String.valueOf(CONFIG.tsanet_connect__companyId__c);
                            System.debug('isInbound : ' + isInbound);
                            if(!isInbound){
                                if(Pattern.compile( '[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}' ).matcher(parentCaseId).matches() &&
                                    Id.valueOf(parentCaseId).getSObjectType() == Schema.Case.SObjectType &&
                                    existedCases.containsKey(parentCaseId)
                                  ){
                                    newCase.put(element.tsanet_connect__To__c, String.valueOf(record.get(element.tsanet_connect__From__c)));
                                } else {
                                    if(existedCases.containsKey(parentCaseId)){
                                        Case relatedCase = existedCases.get(parentCaseId);
                                        newCase.put(element.tsanet_connect__To__c, relatedCase.Id);
                                    }
                                }
                            } else {
                                if(Pattern.compile( '[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}' ).matcher(receiverCaseId).matches() &&
                                    Id.valueOf(receiverCaseId).getSObjectType() == Schema.Case.SObjectType &&
                                    existedCases.containsKey(receiverCaseId)
                                  ){
                                    newCase.put(element.tsanet_connect__To__c, receiverCaseId);
                                } else {
                                    if(existedCases.containsKey(receiverCaseId)){
                                        Case relatedCase = existedCases.get(receiverCaseId);
                                        newCase.put(element.tsanet_connect__To__c, relatedCase.Id);
                                    }
                                }
                            }
                            
                        } catch(Exception e){
                            System.debug(e.getMessage());
                        }
                        
                    } else if(element.tsanet_connect__Type__c == 'OBJECT'){
                        System.debug('OBJECT');
                        try {
                        	Map<String, Object> submittedBy = (Map<String, Object>) record.get(element.tsanet_connect__From__c);
                            
                            System.debug('submittedBy :' + submittedBy);
                            for(String field : submittedBy.keySet()){
                                System.debug('field :' + field);
                                if(field == 'firstName'){
                                    newCase.put('tsanet_connect__FirstName__c', (String) submittedBy.get('firstName'));
                                } else if(field == 'lastName'){
                                    newCase.put('tsanet_connect__LastName__c', (String) submittedBy.get('lastName'));
                                } else if(field == 'email'){
                                    newCase.put('tsanet_connect__Email__c', (String) submittedBy.get('email'));
                                } else if(field == 'phone'){
                                    newCase.put('tsanet_connect__Phone__c', (String) submittedBy.get('phone'));
                                }
                            }
                            
						} catch(Exception e){
                            System.debug('Error ->> ' + e.getMessage());
                        }                        
                    } else if(element.tsanet_connect__Type__c == 'ARRAY' && element.tsanet_connect__From__c == 'caseResponses'){
                        List<Object> caseResponses = (List<Object>) record.get(element.tsanet_connect__From__c);
                        if(caseResponses.size() > 0){
                            tsanet_connect__TSANetResponse__c[] newResponses = new tsanet_connect__TSANetResponse__c[]{};
                            for(Object response : caseResponses){
                                Map<String, Object> caseResponse = ( Map<String, Object> ) response;
                                tsanet_connect__TSANetResponse__c newResponse = new tsanet_connect__TSANetResponse__c();
                                System.debug('caseResponse :' + caseResponse);
                                for(String field : caseResponse.keySet()){
                                    System.debug('field :' + field);
                                    if(field == 'id'){
                                        newResponse.put('tsanet_connect__tsaNetResponseId__c', String.valueOf(caseResponse.get('id')));
                                    } else if(field == 'engineerName'){
                                        newCase.put('tsanet_connect__EngineerName__c', (String) caseResponse.get('engineerName'));
                                        newResponse.put('tsanet_connect__EngineerName__c',(String) caseResponse.get('engineerName'));
                                    } else if(field == 'engineerEmail'){
                                        newCase.put('tsanet_connect__EngineerEmail__c', (String) caseResponse.get('engineerEmail'));
                                        newResponse.put('tsanet_connect__EngineerEmail__c',(String) caseResponse.get('engineerEmail'));
                                    } else if(field == 'engineerPhone'){
                                        newCase.put('tsanet_connect__EngineerPhone__c', (String) caseResponse.get('engineerPhone'));
                                        newResponse.put('tsanet_connect__EngineerPhone__c',(String) caseResponse.get('engineerPhone'));
                                    } else if(field == 'nextSteps'){
                                        newResponse.put('tsanet_connect__Note__c',(String) caseResponse.get('nextSteps'));
                                    } else if(field == 'caseNumber'){
                                        newResponse.put('tsanet_connect__tsaNetCaseId__c',(String) caseResponse.get('caseNumber'));
                                    } else if(field == 'type'){
                                        newResponse.put('tsanet_connect__Type__c',(String) caseResponse.get('type'));
                                    } else if(field == 'createdAt'){
                                        try {
                                            //DateTime createdAt = DateTime.newInstance(Long.valueOf(String.valueOf(caseResponse.get('createdAt'))));
                                            String datetimeString = (String) caseResponse.get('createdAt');
                                            if(datetimeString != null){
                                                datetimeString = datetimeString.replace('Z', '');
                                                DateTime dt = DateTime.valueOf(datetimeString.replace('T', ' '));
                                                System.debug('Parsed DateTime: ' + dt);
                                                newResponse.put('tsanet_connect__CreatedAt__c', dt);
                                            }
                                        } catch(Exception e){}
                                    }
                                }
                                newResponses.add(newResponse);
                            }
                            caseToResponses.put(externalId, newResponses);
                        }
                    } else if(element.Type__c == 'ARRAY' && element.From__c == 'customFields'){
                        
                        List<Object> customerData = (List<Object>) record.get(element.From__c);
                        newCase.put('tsanet_connect__customFields__c', System.JSON.serialize(customerData));
                        if(customerData != NULL && customerData.size() > 0){
                            for(Object customerField : customerData){
                                Map<String, Object> customerFieldToValue = ( Map<String, Object> ) customerField;
                                System.debug('customerFieldToValue :' + customerFieldToValue);
                                
                                String fieldName = (String) customerFieldToValue.get('fieldName');
                                String value = (String) customerFieldToValue.get('value');
                                
                                if(fieldName == 'Customer Company'){
                                    newCase.put('tsanet_connect__EngineerCompany__c', value);
                                }  else if(fieldName.contains('Customer Case')){
                                    System.debug('Customer Case Contains - value : ' + value);
                                    if(value != NULL && value != ''){
                                        if(Pattern.compile( '[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}' ).matcher(value).matches() &&
                                            Id.valueOf(value).getSObjectType() == Schema.Case.SObjectType &&
                                            existedCases.containsKey(value)
                                          ){
                                            newCase.put('tsanet_connect__Case__c', value);
                                        } else {
                                            if(existedCases.containsKey(value)){
                                                Case relatedCase = existedCases.get(value);
                                                newCase.put('tsanet_connect__Case__c', relatedCase.Id);
                                            }
                                        }
                                    }
                                    
                                    System.debug('newCase : ' + newCase);
                                    
                                } else if(fieldName == 'Customer Name'){
                                    //newCase.put('EngineerName__c', value);
                                } else if(fieldName == 'Customer Email'){
                                    //newCase.put('EngineerEmail__c', value);
                                } else if(fieldName == 'Customer Phone Including Country Code'){
                                    //newCase.put('EngineerPhone__c', value);
                                } 
                            }
                        }
                    } else if(element.tsanet_connect__Type__c == 'ARRAY' && element.tsanet_connect__From__c == 'caseNotes'){
                        List<Object> notes = (List<Object>) record.get('caseNotes');
                        
                        if(notes.size() > 0){
                            tsanet_connect__TSANetNote__c[] newNotes = new tsanet_connect__TSANetNote__c[]{};
                            for(Object note : notes){
                                Map<String, Object> noteResponse = ( Map<String, Object> ) note;
                                
                                tsanet_connect__TSANetNote__c newNote = new tsanet_connect__TSANetNote__c();
                                
                                newNote.tsanet_connect__isApiNote__c = TRUE;
                                
                                System.debug('note :' + noteResponse);
                                for(String field : noteResponse.keySet()){
                                    System.debug('field :' + field);
                                    if(field == 'token'){
                                        newNote.put('tsanet_connect__Token__c', String.valueOf(noteResponse.get('token')));
                                    } else if(field == 'summary'){
                                        newNote.put('tsanet_connect__Summary__c', (String) noteResponse.get('summary'));
                                    } else if(field == 'description'){
                                        newNote.put('tsanet_connect__Description__c',(String) noteResponse.get('description'));
                                    } else if(field == 'priority'){
                                        newNote.put('tsanet_connect__Priority__c',(String) noteResponse.get('priority'));
                                    } else if(field == 'status'){
                                        newNote.put('tsanet_connect__Status__c',(String) noteResponse.get('status'));
                                    } else if(field == 'creatorUsername'){
                                        newNote.put('tsanet_connect__CreatorUserName__c', (String) noteResponse.get('creatorUsername'));
                                    } else if(field == 'creatorName'){
                                        newNote.put('tsanet_connect__CreatorName__c', (String) noteResponse.get('creatorName'));
                                    } else if(field == 'creatorEmail'){
                                        newNote.put('tsanet_connect__CreatorEmail__c', (String) noteResponse.get('creatorEmail'));
                                    } else if(field == 'createdAt'){
                                        String datetimeString = (String) noteResponse.get('createdAt');
                                        if(datetimeString != null){
                                            datetimeString = datetimeString.replace('Z', '');
                                            DateTime dt = DateTime.valueOf(datetimeString.replace('T', ' '));
                                            System.debug('Parsed DateTime: ' + dt);
                                            newNote.put('tsanet_connect__CreatedAt__c', dt);
                                        }
                                        
                                    }
                                }
                                if(newNote.tsanet_connect__Summary__c != 'Note removed - Older than 30 days'){
                                    newNotes.add(newNote);
                                }
                            }
                            caseToNotes.put(externalId, newNotes);
                        }
                        
                    }
                }
                
                existedIds.add(externalId);
                newCases.add(newCase);
            }
        }
        
        System.debug('newCases : ' + newCases);

        //upsert newCases tsanet_connect__tsaNetCaseId__c;
        
        tsanet_connect__TSANetResponse__c[] responsesToUpsert = new tsanet_connect__TSANetResponse__c[]{};
        for(tsanet_connect__TSANetCase__c tsaNetCase : newCases){
            tsanet_connect__TSANetResponse__c[] responses = caseToResponses.get(tsaNetCase.tsanet_connect__tsaNetCaseId__c);
            if(responses != NULL){
                for(tsanet_connect__TSANetResponse__c response : responses){
                    System.debug('response : ' + response);
                    response.tsanet_connect__TSANetCase__c = tsaNetCase.Id;
                    responsesToUpsert.add(response);
                }
            }
        }
        
        //upsert responsesToUpsert tsanet_connect__tsaNetResponseId__c;
        
        
        tsanet_connect__TSANetNote__c[] notesToUpsert = new tsanet_connect__TSANetNote__c[]{};
        for(tsanet_connect__TSANetCase__c tsaNetCase : newCases){
            tsanet_connect__TSANetNote__c[] notes = caseToNotes.get(tsaNetCase.tsanet_connect__tsaNetCaseId__c);
            if(notes != NULL){
                for(tsanet_connect__TSANetNote__c note : notes){
                    System.debug('response : ' + note);
                    note.tsanet_connect__TSANetCase__c = tsaNetCase.Id;
                    notesToUpsert.add(note);
                }
            }
        }
        
        TSANetData data = new TSANetData();
        data.cases = newCases;
        data.responses = responsesToUpsert;
        data.notes = notesToUpsert;
        
        return data;
        
        //upsert notesToUpsert tsanet_connect__Token__c;
        
        /*
        if(existedCases.containsKey(caseId)){
            Case caseRec = existedCases.get(caseId);
            caseId = caseRec.Id;
        }
        
        return [SELECT Id, Name, tsanet_connect__Name__c, tsanet_connect__customFields__c, tsanet_connect__TSANetContact__c, tsanet_connect__FirstName__c, tsanet_connect__LastName__c, tsanet_connect__Phone__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerEmail__c, tsanet_connect__TSANetEmail__c, tsanet_connect__EngineerPhone__c, tsanet_connect__Email__c, tsanet_connect__Case__c, tsanet_connect__Case__r.CaseNumber, Partner__c, tsanet_connect__SubmittedCompanyName__c, tsanet_connect__SubmittedCompanyId__c, tsanet_connect__receivedCompanyName__c, tsanet_connect__receivedCompanyId__c, tsanet_connect__Summary__c, tsanet_connect__Description__c, tsanet_connect__Status__c, tsanet_connect__Token__c, tsanet_connect__Responded__c, tsanet_connect__FeedbackRequested__c, tsanet_connect__ReminderSent__c, tsanet_connect__Priority__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__RequestDate__c, tsanet_connect__ResponseDate__c, tsanet_connect__PriorityNote__c, tsanet_connect__Type__c,
                    (SELECT Id, Name, tsanet_connect__TSANetCase__c, tsanet_connect__Type__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerPhone__c, tsanet_connect__EngineerEmail__c, tsanet_connect__Note__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__tsaNetResponseId__c FROM tsanet_connect__TSANetResponses__r ORDER BY tsanet_connect__CreatedAt__c DESC)
                    FROM tsanet_connect__TSANetCase__c 
                    WHERE tsanet_connect__Case__c != NULL AND tsanet_connect__Case__c =:caseId 
                    ORDER BY tsanet_connect__RequestDate__c DESC];
		*/
    }
    
    public class TSANetData {
        public TSANetData(){}
        public tsanet_connect__TSANetCase__c[] cases;
        public tsanet_connect__TSANetResponse__c[] responses;
        public tsanet_connect__TSANetNote__c[] notes;
    }
    
    public static Map<String, Case> getExistedCases(String[] caseNumbers){
        Case[] cases = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber IN:caseNumbers ORDER BY CreatedDate DESC LIMIT 49999];
        Map<String, Case> numberToCase = new Map<String, Case>();
        for(Case caseRecord : cases){
            numberToCase.put(caseRecord.CaseNumber, caseRecord);
        }
        return numberToCase;
    }
}