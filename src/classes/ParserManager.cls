public class ParserManager {
    
    public static tsanet_connect__TSANetConfiguration__c CONFIG = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
    public static tsanet_connect__TSANetCaseMapping__mdt[] TSANET_MAPPING = MappingManager.getTSANetMapping();
    
    public static TSANetData parseTSANetCases(String json, String caseId){
        List<Object> cases = (List<Object>) System.JSON.deserializeUntyped(json);
        tsanet_connect__TSANetCase__c[] tsaNetCases = new tsanet_connect__TSANetCase__c[]{};
        tsanet_connect__TSANetResponse__c[] tsaNetResponses = new tsanet_connect__TSANetResponse__c[]{};
        tsanet_connect__TSANetNote__c[] tsaNetNotes = new tsanet_connect__TSANetNote__c[]{};
 
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
                                newCase.put(element.tsanet_connect__To__c, dt);
                            }
                        } catch(Exception e){
                            System.debug('DATETIME PARSING ERROR : ' + e.getMessage());
                        }
                        
                    } else if(element.tsanet_connect__Type__c == 'BOOLEAN'){
                        newCase.put(element.tsanet_connect__To__c, Boolean.valueOf(record.get(element.tsanet_connect__From__c)));
                    } else if(element.tsanet_connect__Type__c == 'STRING'){
                        newCase.put(element.tsanet_connect__To__c, String.valueOf(record.get(element.tsanet_connect__From__c)));
                    } else if(element.tsanet_connect__Type__c == 'REFERENCE'){
                        String parentCaseId = String.valueOf(record.get(element.tsanet_connect__From__c));
                        String receiverCaseId = String.valueOf(record.get('receiverCaseNumber'));
                        try {
                            Boolean isInbound = String.valueOf(record.get('receiveCompanyId')) == String.valueOf(CONFIG.tsanet_connect__companyId__c);
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
                            System.debug('CASE ID FIELD MAPPING ERROR : ' + e.getMessage());
                        }
                        
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
                            
						} catch(Exception e){
                            System.debug('SUBMITTED BY MAPPING ERROR : ' + e.getMessage());
                        }                        
                    } else if(element.tsanet_connect__Type__c == 'ARRAY' && element.tsanet_connect__From__c == 'caseResponses'){
                        List<Object> caseResponses = (List<Object>) record.get(element.tsanet_connect__From__c);
                        if(caseResponses.size() > 0){
                            tsanet_connect__TSANetResponse__c[] newResponses = new tsanet_connect__TSANetResponse__c[]{};
                            for(Object response : caseResponses){
                                Map<String, Object> caseResponse = ( Map<String, Object> ) response;
                                tsanet_connect__TSANetResponse__c newResponse = new tsanet_connect__TSANetResponse__c();
                                newResponse.put('tsanet_connect__CaseId__c', externalId);
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
                                            //DateTime createdAt = DateTime.newInstance(Long.valueOf(String.valueOf(caseResponse.get('createdAt'))));
                                            String datetimeString = (String) caseResponse.get('createdAt');
                                            if(datetimeString != null){
                                                datetimeString = datetimeString.replace('Z', '');
                                                DateTime dt = DateTime.valueOf(datetimeString.replace('T', ' '));
                                                newResponse.put('tsanet_connect__CreatedAt__c', dt);
                                            }
                                        } catch(Exception e){
                                            System.debug('DATETIME PARSING ERROR : ' + e.getMessage());
                                        }
                                    }
                                }
                                tsaNetResponses.add(newResponse);
                            }
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
                                        newNote.put('tsanet_connect__FullSummary__c', (String) noteResponse.get('summary'));
                                    } else if(field == 'description'){
                                        newNote.put('tsanet_connect__Description__c',(String) noteResponse.get('description'));
                                    } else if(field == 'caseId'){
                                        newNote.put('tsanet_connect__CaseId__c', String.valueOf(noteResponse.get('caseId')));
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
                                        try {
                                            String datetimeString = (String) noteResponse.get('createdAt');
                                            if(datetimeString != null){
                                                datetimeString = datetimeString.replace('Z', '');
                                                DateTime dt = DateTime.valueOf(datetimeString.replace('T', ' '));
                                                newNote.put('tsanet_connect__CreatedAt__c', dt);
                                            }
                                        } catch(Exception e){
                                            System.debug('DATETIME PARSING ERROR : ' + e.getMessage());
                                        }
                                    } else if(field == 'companyName'){
                                        newNote.put('tsanet_connect__CompanyName__c', (String) noteResponse.get('companyName'));
                                    }
                                }
                                if(newNote.tsanet_connect__FullSummary__c != 'Note removed - Older than 30 days'){
                                    tsaNetNotes.add(newNote);
                                }
                            }
                        }
                        
                    }
                }
                
                existedIds.add(externalId);
                tsaNetCases.add(newCase);
            }
        }
        
        System.debug('tsaNetCases : ' + tsaNetCases);
        System.debug('tsaNetResponses : ' + tsaNetResponses);
        System.debug('tsaNetNotes : ' + tsaNetNotes);

       
        TSANetData data = new TSANetData();
        data.cases = tsaNetCases;
        data.responses = tsaNetResponses;
        data.notes = tsaNetNotes;
        
        return data;
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