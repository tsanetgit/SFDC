global class TSANetScheduledJob implements Schedulable {
    
    public class TSANetScheduledJobException extends Exception {}
    
    public static Map<String, Case> existedCases = getExistedCases();
    
    public static String endpoint = getEndpoint(); //'https://connect2.tsanet.us'; //https://connect2.renolab.us
    public static String get_cases_path = '/0.1.0/cases/';
    
    public static tsanet_connect__TSANetCaseMapping__mdt[] TSANET_MAPPING = [SELECT Id, tsanet_connect__Type__c, tsanet_connect__From__c, tsanet_connect__To__c FROM tsanet_connect__TSANetCaseMapping__mdt];
    
    public static tsanet_connect__TSANetConfiguration__c CONFIG = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
    
    
    public class PaymentScheduledJobException extends Exception {}
    
    global void execute(SchedulableContext sc){
        updateTSANetCases();
    }
    
    public static void updateTSANetCases() {  
        try {
            getRelatedCollaborationCases(NULL);
        } catch(Exception e){
            System.debug(e.getMessage());
        }
    } 
    
    public static String getEndpoint() {
        
        tsanet_connect__TSANetCredentials__c creds = tsanet_connect__TSANetCredentials__c.getOrgDefaults();
        System.debug('creds2 : ' + creds);
        String environment = creds.tsanet_connect__environment__c + '_env';
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
    public static tsanet_connect__TSANetCase__c[] getRelatedCollaborationCases(String caseId){
        
        String path = endpoint + get_cases_path;
        if(caseId != NULL){ path += caseId; }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        return parseTSANetCases(res.getBody(), caseId);
        
        //return res.getBody();
    }
    
    public static tsanet_connect__TSANetCase__c[] parseTSANetCases(String json, String caseId){
        System.debug(json);
        List<Object> cases = (List<Object>) System.JSON.deserializeUntyped(json);
        System.debug('cases : ' + cases);
        tsanet_connect__TSANetCase__c[] newCases = new tsanet_connect__TSANetCase__c[]{};
        Map<String, tsanet_connect__TSANetResponse__c[]> caseToResponses = new Map<String, tsanet_connect__TSANetResponse__c[]>();
            
        String[] existedIds = new String[]{};
        for(Object caseRecord : cases){
            Map<String, Object> record = (Map<String, Object>) caseRecord;
            String externalId = String.valueOf(record.get('id'));

            if(!existedIds.contains(externalId)){
                tsanet_connect__TSANetCase__c newCase = new tsanet_connect__TSANetCase__c();
                    
                for(TSANetCaseMapping__mdt element : TSANET_MAPPING){
                    if(element.tsanet_connect__Type__c == 'DATETIME'){
                        try {
                            DateTime parsed_datetime =  DateTime.newInstance(Long.valueOf(String.valueOf(record.get(element.tsanet_connect__From__c)))); //DateTime.newInstance(String.valueOf(record.get(element.From__c)));
                            //(DateTime) System.JSON.deserialize('"' + record.get(element.From__c) + '"', DateTime.class)
                            newCase.put(element.tsanet_connect__To__c, parsed_datetime);
                        } catch(Exception e){}
                        
                    } else if(element.tsanet_connect__Type__c == 'BOOLEAN'){
                        newCase.put(element.tsanet_connect__To__c, Boolean.valueOf(record.get(element.tsanet_connect__From__c)));
                    } else if(element.tsanet_connect__Type__c == 'STRING'){
                        newCase.put(element.tsanet_connect__To__c, String.valueOf(record.get(element.tsanet_connect__From__c)));
                    } else if(element.tsanet_connect__Type__c == 'REFERENCE'){
                        String parentCaseId = String.valueOf(record.get(element.tsanet_connect__From__c));
                        try {
                            
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
                        } catch(Exception e){}
                        
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
                                        //newCase.put('EngineerName__c', (String) caseResponse.get('engineerName'));
                                        newResponse.put('tsanet_connect__EngineerName__c',(String) caseResponse.get('engineerName'));
                                    } else if(field == 'engineerEmail'){
                                        //newCase.put('EngineerEmail__c ', (String) caseResponse.get('engineerEmail'));
                                        newResponse.put('tsanet_connect__EngineerEmail__c',(String) caseResponse.get('engineerEmail'));
                                    } else if(field == 'engineerPhone'){
                                        //newCase.put('EngineerPhone__c ', (String) caseResponse.get('engineerPhone'));
                                        newResponse.put('tsanet_connect__EngineerPhone__c',(String) caseResponse.get('engineerPhone'));
                                    } else if(field == 'nextSteps'){
                                        newResponse.put('tsanet_connect__Note__c',(String) caseResponse.get('nextSteps'));
                                    } else if(field == 'caseNumber'){
                                        newResponse.put('tsanet_connect__tsaNetCaseId__c',(String) caseResponse.get('caseNumber'));
                                    } else if(field == 'type'){
                                        newResponse.put('tsanet_connect__Type__c',(String) caseResponse.get('type'));
                                    } else if(field == 'createdAt'){
                                        try {
                                            DateTime createdAt = DateTime.newInstance(Long.valueOf(String.valueOf(caseResponse.get('createdAt'))));
                                            newResponse.put('tsanet_connect__CreatedAt__c', createdAt);
                                        } catch(Exception e){}
                                    }
                                }
                                newResponses.add(newResponse);
                            }
                            caseToResponses.put((String) newCase.get('tsanet_connect__tsaNetCaseId__c'), newResponses);
                        }
                    } else if(element.tsanet_connect__Type__c == 'ARRAY' && element.tsanet_connect__From__c == 'customFields'){
                        List<Object> customerData = (List<Object>) record.get(element.tsanet_connect__From__c);
                        if(customerData != NULL && customerData.size() > 0){
                            for(Object customerField : customerData){
                                Map<String, Object> customerFieldToValue = ( Map<String, Object> ) customerField;
                                System.debug('customerFieldToValue :' + customerFieldToValue);
                                
                                String fieldName = (String) customerFieldToValue.get('fieldName');
                                String value = (String) customerFieldToValue.get('value');
                                
                                if(fieldName == 'Customer Company'){
                                    newCase.put('tsanet_connect__EngineerCompany__c', value);
                                }
                            }
                        }
                    }
                }
                existedIds.add(externalId);
                newCases.add(newCase);
            }
        }
        
        System.debug('newCases : ' + newCases);

        upsert newCases tsanet_connect__tsaNetCaseId__c;
        
        
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
        
        upsert responsesToUpsert tsanet_connect__tsaNetResponseId__c;
        
        if(existedCases.containsKey(caseId)){
            Case caseRec = existedCases.get(caseId);
            caseId = caseRec.Id;
        } else {
            caseId = NULL;
        }
        
        return [SELECT Id, Name, tsanet_connect__Name__c, tsanet_connect__customFields__c, tsanet_connect__TSANetContact__c, tsanet_connect__FirstName__c, tsanet_connect__LastName__c, tsanet_connect__Phone__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerEmail__c, tsanet_connect__TSANetEmail__c, tsanet_connect__EngineerPhone__c, tsanet_connect__Email__c, tsanet_connect__Case__c, tsanet_connect__Case__r.CaseNumber, Partner__c, tsanet_connect__SubmittedCompanyName__c, tsanet_connect__SubmittedCompanyId__c, tsanet_connect__receivedCompanyName__c, tsanet_connect__receivedCompanyId__c, tsanet_connect__Summary__c, tsanet_connect__Description__c, tsanet_connect__Status__c, tsanet_connect__Token__c, tsanet_connect__Responded__c, tsanet_connect__FeedbackRequested__c, tsanet_connect__ReminderSent__c, tsanet_connect__Priority__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__RequestDate__c, tsanet_connect__ResponseDate__c, tsanet_connect__PriorityNote__c, tsanet_connect__Type__c,
                (SELECT Id, Name, tsanet_connect__TSANetCase__c, tsanet_connect__Type__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerPhone__c, tsanet_connect__EngineerEmail__c, tsanet_connect__Note__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__tsaNetResponseId__c FROM tsanet_connect__TSANetResponses__r ORDER BY tsanet_connect__CreatedAt__c DESC)
                FROM tsanet_connect__TSANetCase__c 
                WHERE tsanet_connect__Case__c =:caseId 
                ORDER BY tsanet_connect__RequestDate__c DESC];

    }
    
    public static Map<String, Case> getExistedCases(){
        Case[] cases = [SELECT Id, CaseNumber FROM Case ORDER BY CreatedDate DESC LIMIT 50000];
        Map<String, Case> numberToCase = new Map<String, Case>();
        for(Case caseRecord : cases){
            numberToCase.put(caseRecord.CaseNumber, caseRecord);
        }
        return numberToCase;
    }
}