@isTest
public class TSANetCaseTriggerTest {
    
    @testSetup static void testSetup() {
        
        update new User(Id = UserInfo.getUserId(), tsanet_connect__tsaNetAccessToken__c = 'test-token');
        
        tsanet_connect__TSANetConfiguration__c config = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
        config.IntegrationUser__c = UserInfo.getUserId();
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
    public static void triggerTest(){
        tsanet_connect__TSANetCase__c tsaNetCaseRecord = new tsanet_connect__TSANetCase__c(tsanet_connect__tsaNetCaseId__c = 'test');
        insert tsaNetCaseRecord;
        
        
        tsanet_connect__TSANetResponse__c response = new tsanet_connect__TSANetResponse__c(tsanet_connect__TSANetCase__c = tsaNetCaseRecord.Id);
        insert response;
        tsanet_connect__TSANetResponse__c response2 = new tsanet_connect__TSANetResponse__c(tsanet_connect__TSANetCase__c = tsaNetCaseRecord.Id);
        insert response2;
        
        Case casRecord = [SELECT Id FROM Case LIMIT 1];
        tsaNetCaseRecord.tsanet_connect__Case__c = casRecord.Id;
        
        String body = '{ "caseNumber": "123", "engineerName": "Test Name", "engineerPhone": "1242215125", "engineerEmail": "wefhwuef@gmail.com", "nextSteps": "Case Owner has been changed!" }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        update tsaNetCaseRecord;
        Test.stopTest();
        //TSANetCaseTriggerHelper.helpTest();
    }

}