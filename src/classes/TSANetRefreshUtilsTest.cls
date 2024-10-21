@isTest
public class TSANetRefreshUtilsTest {
    
    @testSetup static void testSetup() {
        
        update new User(Id = UserInfo.getUserId(), tsanet_connect__tsaNetAccessToken__c = 'test-token'); 
        
        tsanet_connect__TSANetConfiguration__c config = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
        config.tsanet_connect__IntegrationUser__c = UserInfo.getUserId();
        upsert config;
        
        tsanet_connect__TSANetCredentials__c credentials = tsanet_connect__TSANetCredentials__c.getOrgDefaults();
        credentials.tsanet_connect__username__c = 'username@gmail.com';
        credentials.tsanet_connect__password__c = 'password111';
        credentials.tsanet_connect__environment__c = 'dev';
        upsert credentials;

        Account account = new Account(Name = 'Test Account');
        insert account;
        
        Contact contact = new Contact(LastName = 'Test Contact', Email = 'test@gmail.com', Phone = 'Test Phone', accountId = account.Id);
        insert contact;
        
        Case caseRecord = new Case(
            ContactId = contact.Id,
            AccountId = account.Id,
            Subject = 'test',
            Status = 'Working',
            Origin = 'Phone');
        
        insert caseRecord;
        
        tsanet_connect__TSANetCase__c tsaNetCase = new tsanet_connect__TSANetCase__c(tsanet_connect__Token__c = 'test-token', tsanet_connect__Case__c = caseRecord.Id);
        insert tsaNetCase;
	}

    @isTest
    public static void refreshTest(){
        String body = '[ { "id": 2718, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1072, "submitterCaseNumber": "00001036", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1071, "receiverCaseNumber": "2718", "summary": "Beta Summer 2024 release unit test", "description": "Beta Summer 2024 release unit test", "priority": "LOW", "status": "ACCEPTED", "token": "Pp8DCQVVHkkVvd0rpn", "createdAt": "2024-06-19T17:17:00Z", "updatedAt": "2024-06-28T04:54:26Z", "deletedAt": null, "responded": true, "respondBy": "2024-06-20T17:17:00Z", "feedbackRequested": false, "reminderSent": false, "priorityNote": "<p>Priority 3 (24 Hours)</p>", "escalationInstructions": "test", "testCase": false, "customFields": [ { "id": 17465, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": "Dickenson plc" }, { "id": 17466, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": "sean jones" }, { "id": 17467, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": "sean@bur.com" }, { "id": 17468, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": "4155551212" }, { "id": 17469, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Demo - Cisco (Optional)", "value": "9876" } ], "submittedBy": { "id": 8706, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }, { "id": 154, "caseId": 2718, "creatorUsername": null, "creatorEmail": "sue.test@vmware.com", "summary": "New note from Paul", "description": "<p>Testing</p>", "priority": "low", "status": "entered", "token": "RoI4TxVcrnirlKLxVNiK", "createdAt": "2024-06-28T04:54:25Z", "updatedAt": "2024-06-28T04:54:26Z" } ], "caseResponses": [ { "id": 2136, "type": "APPROVAL", "caseNumber": "2718", "engineerName": "John Smith", "engineerPhone": "+12122241255", "engineerEmail": "John.Smith@cisco.com", "nextSteps": "Our assigned engineer will contact you.", "createdAt": null } ] } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        
        Test.startTest();
        	TSANetRefreshUtils controller = new TSANetRefreshUtils(new ApexPages.StandardController(new tsanet_connect__TSANetCase__c()));
    		controller.refresh();
        Test.stopTest();
    }
    
     @isTest
    public static void testCatch(){
        String body = '{ "accessToken": "test.eyJpc3MiOiJodHRwOi8vY29ubmVjdDEucmVub2xhYi51cy9hcGkvYXV0aC9sb2dpbiIsImlhdCI6MTcyMDc3ODk0MiwiZXhwIjoxNzIwNzgyNTQyLCJuYmYiOjE3MjA3Nzg5NDIsImp0aSI6ImJrcDBGZ0k4T2ViNXdxU28iLCJzdWIiOiI4NzA1IiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.YbmRLRwdzcua0lh3mCawfb7dvx5LQqJwrboZG4wGFEo", "tokenType": "bearer", "expiresIn": 3600 }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, body, null));
        
        Test.startTest();
        try	{
            TSANetRefreshUtils.getAccessToken();
            update new User(Id = UserInfo.getUserId(), tsanet_connect__tsaNetAccessToken__c = NULL);
            TSANetRefreshUtils controller = new TSANetRefreshUtils(new ApexPages.StandardController(new tsanet_connect__TSANetCase__c()));
    		controller.refresh();
        } catch(Exception e){
            System.debug('ERRRR 1' + e.getMessage());
            System.assertEquals(true, e.getMessage() != NULL);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void refreshTest2(){
        String body = '[ { "id": 2718, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1072, "submitterCaseNumber": "00001036", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1071, "receiverCaseNumber": "2718", "summary": "Beta Summer 2024 release unit test", "description": "Beta Summer 2024 release unit test", "priority": "LOW", "status": "ACCEPTED", "token": "Pp8DCQVVHkkVvd0rpn", "createdAt": "2024-06-19T17:17:00Z", "updatedAt": "2024-06-28T04:54:26Z", "deletedAt": null, "responded": true, "respondBy": "2024-06-20T17:17:00Z", "feedbackRequested": false, "reminderSent": false, "priorityNote": "<p>Priority 3 (24 Hours)</p>", "escalationInstructions": "test", "testCase": false, "customFields": [ { "id": 17465, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": "Dickenson plc" }, { "id": 17466, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": "sean jones" }, { "id": 17467, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": "sean@bur.com" }, { "id": 17468, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": "4155551212" }, { "id": 17469, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Demo - Cisco (Optional)", "value": "9876" } ], "submittedBy": { "id": 8706, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }, { "id": 154, "caseId": 2718, "creatorUsername": null, "creatorEmail": "sue.test@vmware.com", "summary": "New note from Paul", "description": "<p>Testing</p>", "priority": "low", "status": "entered", "token": "RoI4TxVcrnirlKLxVNiK", "createdAt": "2024-06-28T04:54:25Z", "updatedAt": "2024-06-28T04:54:26Z" } ], "caseResponses": [ { "id": 2136, "type": "APPROVAL", "caseNumber": "2718", "engineerName": "John Smith", "engineerPhone": "+12122241255", "engineerEmail": "John.Smith@cisco.com", "nextSteps": "Our assigned engineer will contact you.", "createdAt": null } ] } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        
        Test.startTest();
        	TSANetRefreshUtils.getRelatedCollaborationCases(null);
        Test.stopTest();
    }
}