public class TSANetUtils {
    
    public static String ADMIN_PERMISSION_SET_NAME = 'TSANetConnectPermissionsAdmin';
    
    public class CaseInfo {
        @AuraEnabled
        public Boolean isAdmin = getUserPermission();
        @AuraEnabled
        public tsanet_connect__TSANetConfiguration__c config = TSANetConfiguration__c.getOrgDefaults();
        @AuraEnabled
        public Case caseRecord;
        @AuraEnabled
        public tsanet_connect__TSANetCase__c[] relatedCases;
        @AuraEnabled
        public User currentUser = getCurrentUserInfo();
        
        public CaseInfo(Case caseRecord){
            this.caseRecord = caseRecord;
            this.relatedCases = TSANetService.getRelatedCollaborationCases(caseRecord == NULL ? NULL : caseRecord.CaseNumber);
        }
    }

    @AuraEnabled
    public static CaseInfo getCaseInformation(Id caseId){
        
        if(caseId == NULL){ return new CaseInfo(null); }
        
        Case caseRecord = [SELECT Id, Subject, CaseNumber, Description, Owner.Name, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email, AccountId, Account.Name, ContactId, Contact.Name, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone FROM Case WHERE Id =:caseId];
        return new CaseInfo(caseRecord);
    }
    
     public class CaseInformation {
        @AuraEnabled
        public Boolean isAdmin = getUserPermission();
        @AuraEnabled
        public tsanet_connect__TSANetConfiguration__c config = TSANetConfiguration__c.getOrgDefaults();
        @AuraEnabled
        public Case caseRecord;
        @AuraEnabled
        public tsanet_connect__TSANetCase__c[] relatedCases;
        
        public CaseInformation(Case caseRecord){
            this.caseRecord = caseRecord;
            this.relatedCases = getTSANetCasesByCaseId(caseRecord.Id);
        }
    }
    
    @AuraEnabled
    public static CaseInformation getSFCaseInformation(Id caseId){
        
        Case caseRecord = [SELECT Id, Subject, CaseNumber, Description, Owner.Name, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email, AccountId, Account.Name, ContactId, Contact.Name, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone FROM Case WHERE Id =:caseId];
        return new CaseInformation(caseRecord);
    }
    
    @AuraEnabled
    public static tsanet_connect__TSANetCase__c[] getTSANetCasesByCaseId(Id caseId){

        return [SELECT Id, Name, tsanet_connect__Name__c, tsanet_connect__customFields__c, tsanet_connect__TSANetContact__c, tsanet_connect__FirstName__c, tsanet_connect__LastName__c, tsanet_connect__Phone__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerEmail__c, tsanet_connect__TSANetEmail__c, tsanet_connect__EngineerPhone__c, tsanet_connect__Email__c, tsanet_connect__Case__c, tsanet_connect__Case__r.CaseNumber, Partner__c, tsanet_connect__SubmittedCompanyName__c, tsanet_connect__SubmittedCompanyId__c, tsanet_connect__receivedCompanyName__c, tsanet_connect__receivedCompanyId__c, tsanet_connect__Summary__c, tsanet_connect__Description__c, tsanet_connect__Status__c, tsanet_connect__Token__c, tsanet_connect__Responded__c, tsanet_connect__FeedbackRequested__c, tsanet_connect__ReminderSent__c, tsanet_connect__Priority__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__RequestDate__c, tsanet_connect__ResponseDate__c, tsanet_connect__PriorityNote__c, tsanet_connect__Type__c,
                    (SELECT Id, Name, tsanet_connect__TSANetCase__c, tsanet_connect__Type__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerPhone__c, tsanet_connect__EngineerEmail__c, tsanet_connect__Note__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__tsaNetResponseId__c FROM tsanet_connect__TSANetResponses__r ORDER BY tsanet_connect__CreatedAt__c DESC)
                    FROM tsanet_connect__TSANetCase__c 
                    WHERE tsanet_connect__Case__c =:caseId 
                    ORDER BY tsanet_connect__RequestDate__c DESC];
    }
    
    @AuraEnabled
    public static Boolean getUserPermission(){
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        if(profile.Id == UserInfo.getProfileId()){
            return true;
        }
        PermissionSetAssignment[] assigments = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name =:ADMIN_PERMISSION_SET_NAME AND AssigneeId =:UserInfo.getUserId()];
        
        return assigments.size() > 0;
    }
    
    @AuraEnabled
    public static tsanet_connect__TSANetCase__c[] getTSANetCases(Id caseId){
        return TSANetService.getRelatedCollaborationCases(caseId);
    }
    
    @future(callout=true)
    public static void futureRefresh(Id caseId){ 
        TSANetService.getRelatedCollaborationCases(caseId);
    }
    
    @AuraEnabled
    public static Boolean updateUserCredentials(String username, String password){
        
        if(username != NULL && password != NULL) {
      
            tsanet_connect__TSANetConfiguration__c config = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
            config.tsanet_connect__IntegrationUser__c = UserInfo.getUserId();
            
            upsert config;
            
            tsanet_connect__TSANet_Credentials__c credentials = TSANetService.getCredentials();
            credentials.tsanet_connect__UserName__c = username;
            credentials.tsanet_connect__Password__c = password;
            
            update credentials;
            
        } else {

            tsanet_connect__TSANetConfiguration__c config = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
            
            config.tsanet_connect__Username__c = NULL; 
            config.tsanet_connect__companyName__c = NULL;
            config.tsanet_connect__companyId__c = NULL;
            config.tsanet_connect__IntegrationUser__c = NULL;
            
            tsanet_connect__TSANet_Credentials__c credentials = TSANetService.getCredentials();
            credentials.tsanet_connect__UserName__c = NULL;
            credentials.tsanet_connect__Password__c = NULL;
            
            update credentials;
            
            return Database.upsert(config).isSuccess();
        }
        
        return true;
    }
    
    public class TSANetCaseInfo {
        @AuraEnabled
        public Case caseRecord;
        @AuraEnabled
        public tsanet_connect__TSANetCase__c record;
        @AuraEnabled
        public tsanet_connect__TSANetConfiguration__c config = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
        @AuraEnabled
        public User currentUser = getCurrentUserInfo();
        
        public TSANetCaseInfo(tsanet_connect__TSANetCase__c tsaNetCase, Case caseRecord){
            this.caseRecord = caseRecord;
            this.record = tsaNetCase;
        }
    }
    
    @AuraEnabled
    public static User getCurrentUserInfo(){
        return [SELECT Id, Name, FirstName, LastName, Email, Phone FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
    }

    @AuraEnabled
    public static TSANetCaseInfo getTSANetInfo(Id recordId){
        tsanet_connect__TSANetCase__c[] tsaNetCase = [SELECT Id, tsanet_connect__SubmittedCompanyName__c, tsanet_connect__receivedCompanyName__c, tsanet_connect__Case__c, tsanet_connect__Token__c, tsanet_connect__tsaNetCaseId__c FROM tsanet_connect__TSANetCase__c WHERE Id =:recordId];
    	Case caseRecord;
        if(tsaNetCase.size() > 0 && tsaNetCase[0].tsanet_connect__Case__c != NULL){
             caseRecord = [SELECT Id, Subject, CaseNumber, Description, 
                            Owner.Name, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email,
                            AccountId, Account.Name, ContactId, Contact.Name, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone
                            FROM Case 
                            WHERE Id =:tsaNetCase[0].tsanet_connect__Case__c];
        }
    
        return new TSANetCaseInfo(tsaNetCase[0], caseRecord);
    }
    
    @AuraEnabled
    public static Boolean getNewAccessToken(){
        return TSANetService.getAccessToken();
    }
    
    @AuraEnabled
    public static tsanet_connect__TSANetCase__c getTSANetRecordPageInfo(Id caseId){
        return [SELECT Id, Name, tsanet_connect__tsaNetCaseId__c, tsanet_connect__customFields__c, tsanet_connect__Case__r.Id, tsanet_connect__Case__r.CaseNumber FROM tsanet_connect__TSANetCase__c WHERE Id =:caseId];    
    }
    
    @AuraEnabled
    public static Case[] getCases(String searchText){
        Case[] cases = new Case[]{};
        if(searchText == NULL || searchText == ''){
            cases = [SELECT Id, CaseNumber, Subject FROM Case ORDER BY LastViewedDate DESC LIMIT 10];    
        } else {
            cases = [SELECT Id, CaseNumber, Subject FROM Case WHERE (CaseNumber =:searchText OR Subject =:searchText)];    
        }
        return cases;
    }
    
    @AuraEnabled
    public static Boolean updateTSANetCase(tsanet_connect__TSANetCase__c tsaNetCase){
        return Database.update(tsaNetCase).isSuccess();
    }
    
    @AuraEnabled
    public static tsanet_connect__TSANetCase__c getOneTSANetCase(Id caseId){
        return [SELECT Id, tsanet_connect__tsaNetCaseId__c FROM tsanet_connect__TSANetCase__c WHERE Id =:caseId];
    }

}