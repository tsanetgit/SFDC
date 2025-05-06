public class TSANetQueueableJob implements Queueable, Database.AllowsCallouts {
    
    public static Integer EXECUTE_LIMIT = 50;
    
    public Map<String, tsanet_connect__TSANetCase__c> cases = new Map<String, tsanet_connect__TSANetCase__c>();
    public Map<String, tsanet_connect__TSANetResponse__c> responses = new Map<String, tsanet_connect__TSANetResponse__c>();
    public Map<String, tsanet_connect__TSANetNote__c> notes = new Map<String, tsanet_connect__TSANetNote__c>();
    
    public String token;
        
    public Integer currentPage;
    public Integer totalPages;
    
    public TSANetQueueableJob(Integer currentPage,
                              Integer totalPages,
                              Map<String, tsanet_connect__TSANetCase__c> cases, 
                              Map<String, tsanet_connect__TSANetResponse__c> responses, 
                              Map<String, tsanet_connect__TSANetNote__c> notes){
                                  
        this.currentPage = currentPage;
        this.totalPages = totalPages != NULL ? totalPages : 1;
        this.cases = cases != NULL ? cases : new Map<String, tsanet_connect__TSANetCase__c>();
        this.responses = responses != NULL ? responses : new Map<String, tsanet_connect__TSANetResponse__c>();
        this.notes = notes != NULL ? notes : new Map<String, tsanet_connect__TSANetNote__c>();
        this.token = TSANetService.getBearerAccessToken();
    }
    
    
    public void execute(QueueableContext qc) {
        Boolean stopProcessing = false;
        Integer count = 0;

        while (count < EXECUTE_LIMIT) {
            try {
                TSANetData data = getTSANetCollaborationCases(this.token, this.currentPage);

                if (data.cases.isEmpty()) {
                    stopProcessing = true;
                    break;
                }

                for(tsanet_connect__TSANetCase__c caseRecord : data.cases){
                    this.cases.put(caseRecord.tsanet_connect__tsaNetCaseId__c, caseRecord);
                }
                for(tsanet_connect__TSANetResponse__c response : data.responses){
                    this.responses.put(response.tsanet_connect__tsaNetResponseId__c, response);
                }
                for(tsanet_connect__TSANetNote__c note : data.notes){
                    this.notes.put(note.tsanet_connect__Token__c, note);
                }
                
                currentPage++;
                count++;
            } catch (Exception e) {
                stopProcessing = true;
                break;
            }
        }
        
        if (!stopProcessing && !Test.isRunningTest()) {
            System.enqueueJob(new TSANetQueueableJob(currentPage, totalPages, cases, responses, notes));
        } else {
            upsert cases.values() tsanet_connect__tsaNetCaseId__c;
            upsert responses.values() tsanet_connect__tsaNetResponseId__c;
            upsert notes.values() tsanet_connect__Token__c;
        }
    }
    
    public TSANetData getTSANetCollaborationCases(String token, Integer page){
 
        
        String path = TSANetService.endpoint + '/v1/collaboration-requests?paginated=true&page=' + page + '&size=50';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);

        TSANetCaseDataResponse data = TSANetCaseDataResponse.parse(res.getBody());
        
		this.totalPages = data.totalPages;
        
        return parseTSANetCases(System.JSON.serialize(data.content), null);
    }
    
     
    public static TSANetData parseTSANetCases(String json, String caseId){
        List<Object> cases = (List<Object>) System.JSON.deserializeUntyped(json);
        tsanet_connect__TSANetCase__c[] newCases = new tsanet_connect__TSANetCase__c[]{};
        Map<String, tsanet_connect__TSANetResponse__c[]> caseToResponses = new Map<String, tsanet_connect__TSANetResponse__c[]>();
        Map<String, tsanet_connect__TSANetNote__c[]> caseToNotes = new Map<String, tsanet_connect__TSANetNote__c[]>();  
        

        String[] existedCaseNumbers = new String[]{};
		for(Object caseRecord : cases){
            Map<String, Object> record = (Map<String, Object>) caseRecord;
            String externalId = String.valueOf(record.get('id'));
            for(tsanet_connect__TSANetCaseMapping__mdt element : TSANetService.TSANET_MAPPING){
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
                                String fieldName = (String) customerFieldToValue.get('fieldName');
                                String value = (String) customerFieldToValue.get('value');
                                
                                if(fieldName.contains('Customer Case')){
                                    if(value != NULL && value != ''){
                                        existedCaseNumbers.add(value);
                                    }
                                }
                            }
                        }
                }
            }
        }
        
        Map<String, Case> existedCases = TSANetService.getExistedCases(existedCaseNumbers);
        
        String[] existedIds = new String[]{};
        for(Object caseRecord : cases){
            Map<String, Object> record = (Map<String, Object>) caseRecord;
            String externalId = String.valueOf(record.get('id'));

            if(!existedIds.contains(externalId)){
                tsanet_connect__TSANetCase__c newCase = new tsanet_connect__TSANetCase__c();
                newCase.tsanet_connect__isApiCase__c = TRUE;
                for(tsanet_connect__TSANetCaseMapping__mdt element : TSANetService.TSANET_MAPPING){
                    if(element.tsanet_connect__Type__c == 'DATETIME'){
                        try {
                            String datetimeString = (String) record.get(element.tsanet_connect__From__c);
                            if(datetimeString != null){
                                datetimeString = datetimeString.replace('Z', '');
                                DateTime dt = DateTime.valueOf(datetimeString.replace('T', ' '));
                                newCase.put(element.tsanet_connect__To__c, dt);
                            }
                        } catch(Exception e){}
                        
                    } else if(element.tsanet_connect__Type__c == 'BOOLEAN'){
                        newCase.put(element.tsanet_connect__To__c, Boolean.valueOf(record.get(element.tsanet_connect__From__c)));
                    } else if(element.tsanet_connect__Type__c == 'STRING'){
                        newCase.put(element.tsanet_connect__To__c, String.valueOf(record.get(element.tsanet_connect__From__c)));
                    } else if(element.tsanet_connect__Type__c == 'REFERENCE'){
                        String parentCaseId = String.valueOf(record.get(element.tsanet_connect__From__c));
                        String receiverCaseId = String.valueOf(record.get('receiverCaseNumber'));
                        try {
                            Boolean isInbound = String.valueOf(record.get('receiveCompanyId')) == String.valueOf(TSANetService.CONFIG.tsanet_connect__companyId__c);
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
                            
                        } catch(Exception e){}
                        
                    } else if(element.tsanet_connect__Type__c == 'OBJECT'){
                        try {
                        	Map<String, Object> submittedBy = (Map<String, Object>) record.get(element.tsanet_connect__From__c);
                            
                            for(String field : submittedBy.keySet()){
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
                            
						} catch(Exception e){}                        
                    } else if(element.tsanet_connect__Type__c == 'ARRAY' && element.tsanet_connect__From__c == 'caseResponses'){
                        List<Object> caseResponses = (List<Object>) record.get(element.tsanet_connect__From__c);
                        if(caseResponses.size() > 0){
                            tsanet_connect__TSANetResponse__c[] newResponses = new tsanet_connect__TSANetResponse__c[]{};
                            for(Object response : caseResponses){
                                Map<String, Object> caseResponse = ( Map<String, Object> ) response;
                                tsanet_connect__TSANetResponse__c newResponse = new tsanet_connect__TSANetResponse__c();
                                for(String field : caseResponse.keySet()){
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
                                            String datetimeString = (String) caseResponse.get('createdAt');
                                            if(datetimeString != null){
                                                datetimeString = datetimeString.replace('Z', '');
                                                DateTime dt = DateTime.valueOf(datetimeString.replace('T', ' '));
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
                                
                                String fieldName = (String) customerFieldToValue.get('fieldName');
                                String value = (String) customerFieldToValue.get('value');
                                
                                if(fieldName == 'Customer Company'){
                                    newCase.put('tsanet_connect__EngineerCompany__c', value);
                                }  else if(fieldName.contains('Customer Case')){
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
                                
                                for(String field : noteResponse.keySet()){
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
        
        //upsert newCases tsanet_connect__tsaNetCaseId__c;
        
        tsanet_connect__TSANetResponse__c[] responsesToUpsert = new tsanet_connect__TSANetResponse__c[]{};
        for(tsanet_connect__TSANetCase__c tsaNetCase : newCases){
            tsanet_connect__TSANetResponse__c[] responses = caseToResponses.get(tsaNetCase.tsanet_connect__tsaNetCaseId__c);
            if(responses != NULL){
                for(tsanet_connect__TSANetResponse__c response : responses){
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
    
}