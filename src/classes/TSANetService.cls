public class TSANetService {
    
    public class TSANetServiceException extends Exception {}
    
    public static String login_path = '/v1/login'; //'/0.1.0/login/';
    public static String case_path = '/v1/collaboration-requests'; //'/1.0.8/collaboration-request/';
    public static String companies_path = '/v1/partners/'; //'/0.1.0/partners/';
    public static String get_form_company_path = '/v1/forms/company/'; //'/1.0.8/form/company/';
    public static String get_form_department_path = '/v1/forms/department/';
    public static String approve = '/approval'; //v1/collaboration-requests/{token}/approval
    public static String reject = '/rejection'; ///v1/collaboration-requests/{token}/rejection
    public static String informationRequest = '/information-request'; ///v1/collaboration-requests/{token}/information-request
    public static String informationResponse = '/information-response'; ///v1/collaboration-requests/{token}/information-response
    public static String close = '/closure'; ///v1/collaboration-requests/{token}/closure
    public static String me_path = '/v1/me';
    
    public static String endpoint = getEndpoint(); //'https://connect2.renolab.us'; //'https://connect2.tsanet.us'; //https://connect2.renolab.us
    
    public static tsanet_connect__TSANetConfiguration__c CONFIG = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
    public static tsanet_connect__TSANetCaseMapping__mdt[] TSANET_MAPPING = getTSANetMapping();
    //public static Map<String, Case> existedCases = getExistedCases();
    
        
    public static String getEndpoint() {
        tsanet_connect__TSANet_Credentials__c creds = getCredentials();
        System.debug('creds : ' + creds);
        String environment = creds.tsanet_connect__Environment__c + '_env';
        System.debug('environment : ' + environment);
        tsanet_connect__TSANetEnvironment__mdt[] environments =[SELECT Id, tsanet_connect__Endpoint__c FROM tsanet_connect__TSANetEnvironment__mdt WHERE DeveloperName =:environment];
        
        if(environments.size() > 0){
            return environments[0].tsanet_connect__Endpoint__c;
        } else {
            System.debug('NOT FOUND ENVIROMENTS !');
            return 'https://connect2.renolab.us';
        }
    }
    
    public static tsanet_connect__TSANetCaseMapping__mdt[] getTSANetMapping() {
        return [SELECT Id, tsanet_connect__Type__c, tsanet_connect__From__c, tsanet_connect__To__c FROM tsanet_connect__TSANetCaseMapping__mdt];
    }

    public class AccessTokenResponse {
        public String accessToken;
        public String tokenType;
        public Integer expiresIn;
    }
    
    @AuraEnabled
    public static Boolean getAccessToken(){

        tsanet_connect__TSANet_Credentials__c credentials = getCredentials();
        
        SYstem.debug('credentials: ' + credentials);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + login_path);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('');
        req.setBody('{"username": "' + credentials.tsanet_connect__UserName__c + '","password": "' + credentials.tsanet_connect__Password__c + '"}');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        if(res.getStatusCode() != 200){ return null; }
        
        AccessTokenResponse response = (AccessTokenResponse) System.JSON.deserialize(res.getBody(), AccessTokenResponse.class);
        System.debug(response.accessToken);
        
        if(response.accessToken == NULL){ return false; }
        
        String userId = CONFIG.tsanet_connect__IntegrationUser__c == NULL ? UserInfo.getUserId() : CONFIG.tsanet_connect__IntegrationUser__c;
        
        executeInternalProcess(credentials);
        
        return Database.update(new User(Id = userId, tsanet_connect__tsaNetAccessToken__c = response.accessToken)).isSuccess();
    }
    
    @AuraEnabled
    public static String getBearerAccessToken(){

        tsanet_connect__TSANet_Credentials__c credentials = getCredentials();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + login_path);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('');
        req.setBody('{"username": "' + credentials.tsanet_connect__UserName__c + '","password": "' + credentials.tsanet_connect__Password__c + '"}');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        if(res.getStatusCode() != 200){ return null; }
        
        AccessTokenResponse response = (AccessTokenResponse) System.JSON.deserialize(res.getBody(), AccessTokenResponse.class);
        System.debug(response.accessToken);
        
        return response.accessToken;
    }
    
    public static void executeInternalProcess(tsanet_connect__TSANet_Credentials__c credentials){

        if(CONFIG.tsanet_connect__IntegrationUser__c == NULL){
            TSANetUtils.updateUserCredentials(credentials.tsanet_connect__UserName__c, credentials.tsanet_connect__Password__c);
        }
        
        if(CONFIG.tsanet_connect__companyId__c == NULL && !Test.isRunningTest()){
			getCompanyInfo();            
        }
        
        CronTrigger[] crons = [SELECT Id, CronJobDetailId, CronJobDetail.Name, State FROM CronTrigger WHERE CronJobDetail.Name = 'TSANetScheduledJob'];
        if(crons.size() == 0){
            System.schedule('TSANetScheduledJob', '0 0 * * * ?', new TSANetScheduledJob());
        }
    }
    
    @future(callout=true)
    public static void getCompanyInfo(){
    	updateCustomSettingsCredentials();
    }
    

    @AuraEnabled
    public static tsanet_connect__TSANet_Credentials__c getCredentials(){
        /*
        tsanet_connect__TSANetCredentials__c credentials = tsanet_connect__TSANetCredentials__c.getOrgDefaults();
        
        if(credentials == NULL || credentials.tsanet_connect__environment__c == NULL){
            throw new TSANetServiceException('Username and password can not be empty!');
        }
        */
        
        tsanet_connect__TSANet_Credentials__c[] credentials = [SELECT Id, Name, tsanet_connect__UserName__c, tsanet_connect__Password__c, tsanet_connect__Environment__c, tsanet_connect__isPrimary__c FROM tsanet_connect__TSANet_Credentials__c WHERE tsanet_connect__isPrimary__c = TRUE];
        
        if(!credentials.isEmpty()){
            return credentials[0];
        } else {
            throw new TSANetServiceException('Username and password can not be empty!');
        }
    }
    
    @AuraEnabled
    public static String getAccessTokenByUser(){
        if(CONFIG.tsanet_connect__IntegrationUser__c == NULL){
            throw new TSANetServiceException('Unauthorized');
        }
        return [SELECT Id, tsanet_connect__tsaNetAccessToken__c FROM User WHERE Id =:CONFIG.tsanet_connect__IntegrationUser__c].tsanet_connect__tsaNetAccessToken__c;
    }
    
    public static String getBearerToken(){
        String token = getAccessTokenByUser();
        if(token == NULL && !Test.isRunningTest()){
			throw new TSANetServiceException('Unauthorized');
        }
        return 'Bearer ' + token;
    }
    
    public class CompanyUser {
        public String email;
    }
    
    public class Company {
        public String id;
        public String name;
    }
    
    public class CompanyInfo {
        CompanyUser user;
        Company company;
    }
    
    @AuraEnabled
    public static Boolean updateCustomSettingsCredentials(){
		HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + me_path);
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('GET');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        if(res.getStatusCode() != 200){
            handleResponseErrors(res);
        }

        CompanyInfo info = (CompanyInfo) System.JSON.deserialize(res.getBody(), CompanyInfo.class);

        tsanet_connect__TSANetConfiguration__c config = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
        
        config.tsanet_connect__Username__c = info.user.email; 
        config.tsanet_connect__companyName__c = info.company.name;
        config.tsanet_connect__companyId__c = info.company.id;
        
        return Database.upsert(config).isSuccess();
    }
    
    @AuraEnabled
    public static String getCustomFields(String documentId, String fieldId){
        System.debug('documentId : ' + documentId);
        System.debug('fieldId : ' + fieldId);
        String path = endpoint + '/0.1.1/form/' + documentId + '/field/' + fieldId;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        return res.getBody();   
    }
    
    @AuraEnabled
    public static tsanet_connect__TSANetCase__c[] getRelatedCollaborationCasesWithToken(String caseId, String token){
        
        String path = endpoint + case_path;
        if(caseId != NULL){
            path += ( '?internalCaseNumber=' + caseId );
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setHeader('Authorization', token);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        //req.setTimeout(120000);
        
        Http http = new Http();

        HTTPResponse res;
        //if(!Test.isRunningTest()){
             res = http.send(req);
            
            //HTTPResponse res = http.send(req);
            System.debug(res.getBody());
            
            if(res.getStatusCode() != 200){
                handleResponseErrors(res);
                
                return [SELECT Id, Name, tsanet_connect__Name__c, tsanet_connect__customFields__c, tsanet_connect__TSANetContact__c, tsanet_connect__FirstName__c, tsanet_connect__LastName__c, tsanet_connect__Phone__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerEmail__c, tsanet_connect__TSANetEmail__c, tsanet_connect__EngineerPhone__c, tsanet_connect__Email__c, tsanet_connect__Case__c, tsanet_connect__Case__r.CaseNumber, Partner__c, tsanet_connect__SubmittedCompanyName__c, tsanet_connect__SubmittedCompanyId__c, tsanet_connect__receivedCompanyName__c, tsanet_connect__receivedCompanyId__c, tsanet_connect__Summary__c, tsanet_connect__Description__c, tsanet_connect__Status__c, tsanet_connect__Token__c, tsanet_connect__Responded__c, tsanet_connect__FeedbackRequested__c, tsanet_connect__ReminderSent__c, tsanet_connect__Priority__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__RequestDate__c, tsanet_connect__ResponseDate__c, tsanet_connect__PriorityNote__c, tsanet_connect__Type__c,
                    (SELECT Id, Name, tsanet_connect__TSANetCase__c, tsanet_connect__Type__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerPhone__c, tsanet_connect__EngineerEmail__c, tsanet_connect__Note__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__tsaNetResponseId__c FROM tsanet_connect__TSANetResponses__r ORDER BY tsanet_connect__CreatedAt__c DESC)
                    FROM tsanet_connect__TSANetCase__c 
                    WHERE tsanet_connect__Case__c =:caseId 
                    ORDER BY tsanet_connect__RequestDate__c DESC];
            }
        //}
        return parseTSANetCases(res.getBody(), caseId);

        //return res.getBody();
    }
    
    @AuraEnabled
    public static tsanet_connect__TSANetCase__c[] getRelatedCollaborationCases(String caseId){
        
        String path = endpoint + case_path;
        if(caseId != NULL){
            path += ( '?internalCaseNumber=' + caseId );
        }
        
        System.debug('path: ' + path);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        //req.setTimeout(120000);
        
        Http http = new Http();

        HTTPResponse res;
        //if(!Test.isRunningTest()){
             res = http.send(req);
            
            //HTTPResponse res = http.send(req);
            System.debug(res.getBody());
            
            if(res.getStatusCode() != 200){
                handleResponseErrors(res);
                
                return [SELECT Id, Name, tsanet_connect__Name__c, tsanet_connect__customFields__c, tsanet_connect__TSANetContact__c, tsanet_connect__FirstName__c, tsanet_connect__LastName__c, tsanet_connect__Phone__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerEmail__c, tsanet_connect__TSANetEmail__c, tsanet_connect__EngineerPhone__c, tsanet_connect__Email__c, tsanet_connect__Case__c, tsanet_connect__Case__r.CaseNumber, Partner__c, tsanet_connect__SubmittedCompanyName__c, tsanet_connect__SubmittedCompanyId__c, tsanet_connect__receivedCompanyName__c, tsanet_connect__receivedCompanyId__c, tsanet_connect__Summary__c, tsanet_connect__Description__c, tsanet_connect__Status__c, tsanet_connect__Token__c, tsanet_connect__Responded__c, tsanet_connect__FeedbackRequested__c, tsanet_connect__ReminderSent__c, tsanet_connect__Priority__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__RequestDate__c, tsanet_connect__ResponseDate__c, tsanet_connect__PriorityNote__c, tsanet_connect__Type__c,
                    (SELECT Id, Name, tsanet_connect__TSANetCase__c, tsanet_connect__Type__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerPhone__c, tsanet_connect__EngineerEmail__c, tsanet_connect__Note__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__tsaNetResponseId__c FROM tsanet_connect__TSANetResponses__r ORDER BY tsanet_connect__CreatedAt__c DESC)
                    FROM tsanet_connect__TSANetCase__c 
                    WHERE tsanet_connect__Case__c =:caseId 
                    ORDER BY tsanet_connect__RequestDate__c DESC];
            }
        //}
        return parseTSANetCases(res.getBody(), caseId);

        //return res.getBody();
    }
 
    public static tsanet_connect__TSANetCase__c[] parseTSANetCases(String json, String caseId){
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
                                        
                                    } else if(field == 'companyName'){
                                        newNote.put('tsanet_connect__CompanyName__c', (String) noteResponse.get('companyName'));
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
        
        upsert notesToUpsert tsanet_connect__Token__c;
        
        if(existedCases.containsKey(caseId)){
            Case caseRec = existedCases.get(caseId);
            caseId = caseRec.Id;
        }
        
        return [SELECT Id, Name, tsanet_connect__Name__c, tsanet_connect__customFields__c, tsanet_connect__TSANetContact__c, tsanet_connect__FirstName__c, tsanet_connect__LastName__c, tsanet_connect__Phone__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerEmail__c, tsanet_connect__TSANetEmail__c, tsanet_connect__EngineerPhone__c, tsanet_connect__Email__c, tsanet_connect__Case__c, tsanet_connect__Case__r.CaseNumber, Partner__c, tsanet_connect__SubmittedCompanyName__c, tsanet_connect__SubmittedCompanyId__c, tsanet_connect__receivedCompanyName__c, tsanet_connect__receivedCompanyId__c, tsanet_connect__Summary__c, tsanet_connect__Description__c, tsanet_connect__Status__c, tsanet_connect__Token__c, tsanet_connect__Responded__c, tsanet_connect__FeedbackRequested__c, tsanet_connect__ReminderSent__c, tsanet_connect__Priority__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__RequestDate__c, tsanet_connect__ResponseDate__c, tsanet_connect__PriorityNote__c, tsanet_connect__Type__c,
                    (SELECT Id, Name, tsanet_connect__TSANetCase__c, tsanet_connect__Type__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerPhone__c, tsanet_connect__EngineerEmail__c, tsanet_connect__Note__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__tsaNetResponseId__c FROM tsanet_connect__TSANetResponses__r ORDER BY tsanet_connect__CreatedAt__c DESC)
                    FROM tsanet_connect__TSANetCase__c 
                    WHERE tsanet_connect__Case__c != NULL AND tsanet_connect__Case__c =:caseId 
                    ORDER BY tsanet_connect__RequestDate__c DESC];

    }
    
    @AuraEnabled
    public static String getFormByCompanyId(String companyId, String mode){
        System.debug('work');
        
        String localEndpoint = endpoint;
        
        if(mode == 'company'){
            localEndpoint += get_form_company_path;
        } else {
            localEndpoint += get_form_department_path;
        }
        
        localEndpoint += companyId;
        
        System.debug('endpoint : ' + localEndpoint);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(localEndpoint);
        req.setHeader('Authorization', getBearerToken());
        //req.setHeader('User-Agent', 'PostmanRuntime/7.33.0');
        req.setMethod('GET');

        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
        if(res.getStatusCode() != 200){
            
            if(res.getBody() == 'This company does not have a company form, try getting the form for one of the company\'s departments'){
 
                System.debug('work222');
                HttpRequest req2 = new HttpRequest();
                req2.setEndpoint(endpoint + '/1.0.8/form/department/' + companyId);
                req2.setHeader('Authorization', getBearerToken());
                //req.setHeader('User-Agent', 'PostmanRuntime/7.33.0');
                req2.setMethod('GET');
        
                Http http2 = new Http();
                HTTPResponse res2 = http2.send(req2);
                System.debug(res2.getBody());
                
                return res2.getBody();
                    
            } else {
                handleResponseErrors(res);
            }            
        }
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String getCompaniesByName(String companyName){
        companyName = EncodingUtil.urlEncode(companyName, 'UTF-8');
        if(companyName.contains('+')){
            companyName = companyName.replace('+', '%20');
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + companies_path + companyName);
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('GET');
        //req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        /*if(res.getStatusCode() != 200){
            handleResponseErrors(res);
        }*/
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String createCollaborationCase(Id caseId, String json){
        
        System.debug('caseId : ' + caseId);
        System.debug('json : ' + json);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + case_path);
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());

        if(res.getStatusCode() != 200){
            handleResponseErrors(res);
        }
        
        if(!Test.isRunningTest()){
            getRelatedCollaborationCases(NULL);
		}
        
        Map<String, Object> response = (Map<String, Object>) System.JSON.deserializeUntyped(res.getBody());
        System.debug('response 1111: ' + response);
        createCaseFeedItem(caseId, response);
             
        return res.getBody();
		
    }
    
    @AuraEnabled
    public static String approveIncomingRequest(String token, String json){
        
        System.debug('token : ' + token);
        System.debug('json : ' + json);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + case_path + '/' + token + approve);
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
        if(res.getStatusCode() != 200){
            handleResponseErrors(res);
        }
        
        if(!Test.isRunningTest()){
            getRelatedCollaborationCases(null);
        }
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String approveIncomingRequest2(String token, String json){
        
        System.debug('token : ' + token);
        System.debug('json : ' + json);
        
        String accessToken = getBearerAccessToken();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + case_path + '/' + token + approve);
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
        if(res.getStatusCode() != 200){
            handleResponseErrors(res);
        }
        
        if(!Test.isRunningTest()){
            getRelatedCollaborationCases(null);
        }
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String rejectTSANetCase(String tsaNetCaseId, String json){
        
        System.debug('tsaNetCaseId : ' + tsaNetCaseId);
        System.debug('json : ' + json);
        
        tsanet_connect__TSANetCase__c tsaNetCase = [SELECT Id, tsanet_connect__tsaNetCaseId__c, tsanet_connect__Token__c FROM tsanet_connect__TSANetCase__c WHERE Id =:tsaNetCaseId];
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + case_path + '/' + tsaNetCase.tsanet_connect__Token__c + reject);
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
        if(res.getStatusCode() != 200){
            handleResponseErrors(res);
        }
        
        getRelatedCollaborationCases(null);
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String requestAdditionalInformation(String tsaNetCaseId, String json){
        
        System.debug('tsaNetCaseId : ' + tsaNetCaseId);
        System.debug('json : ' + json);
        
        tsanet_connect__TSANetCase__c tsaNetCase = [SELECT Id, tsanet_connect__Token__c, tsanet_connect__tsaNetCaseId__c FROM tsanet_connect__TSANetCase__c WHERE Id =:tsaNetCaseId];
        System.debug('path : ' + endpoint + case_path + '/' + tsaNetCase.tsanet_connect__Token__c + informationRequest);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + case_path + '/' + tsaNetCase.tsanet_connect__Token__c + informationRequest);
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
        if(res.getStatusCode() != 200){
            handleResponseErrors(res);
        }
        
        getRelatedCollaborationCases(null);
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String sendAdditionalInformation(String tsaNetCaseId, String json){
        
        System.debug('tsaNetCaseId : ' + tsaNetCaseId);
        System.debug('json : ' + json);
        
        tsanet_connect__TSANetCase__c tsaNetCase = [SELECT Id, tsanet_connect__Token__c, tsanet_connect__tsaNetCaseId__c FROM tsanet_connect__TSANetCase__c WHERE Id =:tsaNetCaseId];
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + case_path + '/' + tsaNetCase.tsanet_connect__Token__c + informationResponse);
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
        if(res.getStatusCode() != 200){
            handleResponseErrors(res);
        }
        
        getRelatedCollaborationCases(null);
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String closeTSANetCase(String tsaNetCaseId){
        
        System.debug('tsaNetCaseId : ' + tsaNetCaseId);
        
        tsanet_connect__TSANetCase__c tsaNetCase = [SELECT Id, tsanet_connect__Token__c, tsanet_connect__tsaNetCaseId__c FROM tsanet_connect__TSANetCase__c WHERE Id =:tsaNetCaseId];
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + case_path + '/' + tsaNetCase.tsanet_connect__Token__c + close);
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
        if(res.getStatusCode() != 200){
            handleResponseErrors(res);
        }
        
        getRelatedCollaborationCases(null);
        
        return res.getBody();
    }
    
    @future(callout=true)
    public static void approveIncomingRequestFuture(String caseId, String json){
        System.debug('caseId : ' + caseId);
        System.debug('json : ' + json);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + '/0.1.1/cases/' + caseId + '/update/approval');
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
        if(res.getStatusCode() != 200){
            handleResponseErrors(res);
        }        
    }
    
    @future(callout=true)
    public static void getAccessTokenFuture(){
        getAccessToken();
    }
    
    public static Map<String, Case> getExistedCases(String[] caseNumbers){
        Case[] cases = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber IN:caseNumbers ORDER BY CreatedDate DESC LIMIT 49999];
        Map<String, Case> numberToCase = new Map<String, Case>();
        for(Case caseRecord : cases){
            numberToCase.put(caseRecord.CaseNumber, caseRecord);
        }
        return numberToCase;
    }
    
    @AuraEnabled
    public static String createCaseNote(String caseId, String json){
        
        tsanet_connect__TSANetCase__c tsaNetCase = [SELECT Id FROM tsanet_connect__TSANetCase__c WHERE tsanet_connect__tsaNetCaseId__c =:caseId];
        Map<String, Object> data = (Map<String, Object>) System.JSON.deserializeUntyped(json);
        
        tsanet_connect__TSANetNote__c note = new tsanet_connect__TSANetNote__c();
        note.tsanet_connect__TSANetCase__c = tsaNetCase.Id;
        note.tsanet_connect__Summary__c = (String) data.get('summary');
        note.tsanet_connect__Description__c = (String) data.get('description');
        note.tsanet_connect__Priority__c = (String) data.get('priority');
        note.tsanet_connect__isApiNote__c = false;
        
        insert note;
        
        return note.Id;
        
        /*
        System.debug('caseId : ' + caseId);
        System.debug('json : ' + json);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TSANetService.endpoint + '/0.1.0/cases/' + caseId + '/notes/create');
        req.setHeader('Authorization', TSANetService.getBearerToken());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());

        if(!Test.isRunningTest()){ TSANetService.getRelatedCollaborationCases(NULL); }
             
        Map<String, Object> response = (Map<String, Object>) System.JSON.deserializeUntyped(json);
        
        TSANetNoteResponse noteResponse = TSANetNoteResponse.parseOneRecord(res.getBody());
        
        System.debug('respon : ' + noteResponse);
        
        //createNoteCaseFeedItem(caseId, noteResponse);
                
        return res.getBody();*/
    }
    
    @AuraEnabled
    public static String getTierPickListValues(String documentId, String fieldId){
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TSANetService.endpoint + '/0.1.1/form/' + documentId + '/field/' + fieldId + '/selections');
        req.setHeader('Authorization', TSANetService.getBearerToken());
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());

        return res.getBody();     
    }
    
    public static void createCaseFeedItem(ID caseId, Map<String, Object> response){
        
        Map<String, Object> submittedByMap = (Map<String, Object>) response.get('submittedBy');
        String submitCompanyName = (String) response.get('submitCompanyName');
        String receiveCompanyName = (String) response.get('receiveCompanyName');
        String submitterCaseNumber = (String) response.get('submitterCaseNumber');
        String summary = (String) response.get('summary');
        String description = (String) response.get('description');
        String priority = (String) response.get('priority');
        String status = (String) response.get('status');
        DateTime createdAt = (DateTime) Json.deserialize('"'+response.get('createdAt')+'"', DateTime.class);
        String firstName = (String) submittedByMap.get('firstName');
        String lastName = (String) submittedByMap.get('lastName');
        String email = (String) submittedByMap.get('email');
        String phone = (String) submittedByMap.get('phone');
        String phoneCountryCode = (String) submittedByMap.get('phoneCountryCode');
        String priorityNote = (String) response.get('priorityNote');
        String city = (String) submittedByMap.get('city');
        
        System.debug('priorityNote: ' + priorityNote);
        
        priorityNote = stripHtmlTags(priorityNote);
        
        String message = 'Your collaboration request to ' + receiveCompanyName + ' for ' + submitCompanyName + ' Case# ' + submitterCaseNumber + ' has been sent. ' + priorityNote + '. \n' +
            '\n' + 
            'Request Details: \n' + 
            'Summary: ' + summary + ' \n' +
            'Description: ' + description + ' \n' + 
            'Priority: ' + priority + ' \n' + 
            'status: ' + status + ' \n' + 
            'createdAt: ' + createdAt + ' \n' + 
            'firstName: ' + firstName + ' \n' + 
            'lastName: ' + lastName + ' \n' + 
            'email: ' + email + ' \n' + 
            'phone: ' + phone + ' \n' + 
            'phoneCountryCode: ' + phoneCountryCode + ' \n' + 
            'city: ' + city + ' \n';
        
        insert new FeedItem(
            ParentId = caseId,
            Title = 'TSANet FeedItem',
            Body = message
        );
        
    }
    
    public static String stripHtmlTags(String input) {
        if (String.isEmpty(input)) { return ''; }
        Pattern htmlPattern = Pattern.compile('<[^>]+>');
        Matcher htmlMatcher = htmlPattern.matcher(input);
        String sanitizedString = htmlMatcher.replaceAll('');
        return sanitizedString;
    }
    
    public static void handleResponseErrors(HTTPResponse response){
        System.debug('response.getStatusCode() : ' + response.getStatusCode());
        System.debug('response.getStatusCode() : ' + response.getBody());
        if(response.getStatusCode() != 200){
            if(response.getBody().contains('The authorization token provided was invalid.')){
                Database.update(new User(Id = CONFIG.tsanet_connect__IntegrationUser__c, tsanet_connect__tsaNetAccessToken__c = NULL));
                getAccessTokenFuture();
                throw new TSANetServiceException('Unauthorized');
            } else {
                throw new TSANetServiceException((String) response.getBody());
            }
        }
    } 
    
    @AuraEnabled
    public static String getAttachmentConfig(String token){
        
        String path = endpoint + case_path + '/' + token + '/attachments/config';
        
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setHeader('Authorization', getBearerToken());
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        //req.setTimeout(120000);
        
        Http http = new Http();

        HTTPResponse res;
        //if(!Test.isRunningTest()){
             res = http.send(req);
            
            //HTTPResponse res = http.send(req);
            System.debug(res.getBody());
            
        	if(res.getStatusCode() != 200){
                handleResponseErrors(res);
                
            }
        //}
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String sendAttachment(String token, List<Map<String, Object>> files){
        
        tsanet_connect__TSANetCase__c tsaNetCase = [SELECT Id FROM tsanet_connect__TSANetCase__c WHERE tsanet_connect__Token__c =:token];
        
        Id[] contentVersionIds = new Id[]{};
        for(Map<String, Object> fileData : files){
            String base64String = (String) fileData.get('base64');
            if(base64String == NULL){
                String fileId = (String) fileData.get('fileId');
                contentVersionIds.add(fileId);
            }
        }
        
        ContentVersion[] selectedContentVersions = [SELECT Id, Title, FileType, VersionData FROM ContentVersion WHERE Id IN:contentVersionIds];
        
        List<Map<String, Object>> newFiles = new List<Map<String, Object>>();
        for(Map<String, Object> fileData : files){
            String base64String = (String) fileData.get('base64');
            if(base64String == NULL){
                String fileId = (String) fileData.get('fileId');
                for(ContentVersion cv : selectedContentVersions){
                    if(cv.Id == fileId){
                        Map<String, Object> newFileData = new Map<String, Object>();
                        newFileData.put('fileId', fileId);
                        newFileData.put('filename', cv.Title);
                        newFileData.put('base64', EncodingUtil.base64Encode(cv.VersionData));
                        newFileData.put('isCV', true);
                        newFiles.add(newFileData);
                    }
                }
            } else {
                newFiles.add(fileData);
            }
        }
        
        
        String boundary = 'EWG3x2i19rjSk310MA4YWxkTrZu0gW';
        String lineBreak = '\r\n';
        
        String body = '';
        
        body += '--' + boundary + lineBreak;
        body += 'Content-Disposition: form-data; name="description"' + lineBreak + lineBreak;
        body += '' + lineBreak; 
        
        //ContentVersion[] versions = new ContentVersion[]{};
        for(Map<String, Object> fileData : newFiles){
            String base64String = (String) fileData.get('base64');
            String fileName = (String) fileData.get('filename'); 
            
            System.debug('base64String : ' + base64String);
            System.debug('fileName : ' + fileName);
            
            body += '--' + boundary + lineBreak;
            body += 'Content-Disposition: form-data; name="files"; filename="' + fileName + '"' + lineBreak;
            body += 'Content-Type: multipart/form-data' + lineBreak + lineBreak;
            body += EncodingUtil.base64Decode(base64String) + lineBreak;
            
            /*ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64String);
            versions.add(cv);*/
            
        }
        
        body += '--' + boundary + '--' + lineBreak;

        String contentLength = String.valueOf(body.length());
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + '/v1/collaboration-requests/' + token + '/attachments');
        req.setMethod('POST');
        req.setHeader('Authorization', getBearerToken());
        req.setHeader('Accept', 'application/problem+json');
        req.setHeader('Content-Length', contentLength);
        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
        req.setHeader('boundary', boundary);
        req.setHeader('Accept', '*/*');
        req.setBody(body);
        req.setTimeout(120000);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        System.debug('STATUS: ' + res.getStatusCode());
        System.debug('BODY: ' + res.getBody());
        
        TSANetFileUploadResult[] results = TSANetFileUploadResult.parse(res.getBody());
        
        ContentVersion[] versions = new ContentVersion[]{};
        for(Map<String, Object> fileData : newFiles){
            String fileName = (String) fileData.get('filename'); 
            String base64String = (String) fileData.get('base64');
            Boolean isCV = (Boolean) fileData.get('isCV');
            if(isCV == NULL || !isCV){
                for(TSANetFileUploadResult result : results){
                    if(result.receiverStatus == 'SUCCESS' && result.fileName == fileName){
                        ContentVersion cv = new ContentVersion();
                        cv.Title = fileName;
                        cv.PathOnClient = fileName;
                        cv.VersionData = EncodingUtil.base64Decode(base64String);
                        versions.add(cv);
                    }
                }
            }
        	
        }
        
        insert versions;
        
        Id[] versionIds = new Id[]{};
        for(ContentVersion version : versions){
			versionIds.add(version.Id);
        }
        
        ContentVersion[] contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN:versionIds];
		
        ContentDocumentLink[] links = new ContentDocumentLink[]{};
        for(ContentVersion cv : contentVersions){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = tsaNetCase.Id; 
            cdl.ShareType = 'V'; 
            cdl.Visibility = 'AllUsers';
            links.add(cdl);
        }
        
        insert links;
        
        return res.getBody();
    }
   
    
}