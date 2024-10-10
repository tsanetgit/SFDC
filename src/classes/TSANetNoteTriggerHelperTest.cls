@isTest
public class TSANetNoteTriggerHelperTest {
    
    @testSetup static void testSetup() {
        
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
    public static void createFeedItemsTest(){
        tsanet_connect__TSANetNote__c note = new tsanet_connect__TSANetNote__c();
        note.tsanet_connect__TSANetCase__c = [SELECT Id FROM tsanet_connect__TSANetCase__c LIMIT 1].Id;
        note.tsanet_connect__Token__c = 'test_token';
        note.tsanet_connect__Summary__c = 'Summary';
        note.tsanet_connect__Description__c = '<strong>Description 1</strong>';
        note.tsanet_connect__Priority__c = 'LOW';
        note.tsanet_connect__Status__c = 'OPEN';
        note.tsanet_connect__CreatorUserName__c = 'test_creator';
        
        insert note;
        update note;
    }
}