@IsTest
public class TSANetInvocableRefreshCasesServiceTest {

    @TestSetup static void testSetup() {
        User user = TSANetDataFactory.createAdminUser();
        System.runAs(user){
            TSANetDataFactory.createCredentials();
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            Case caseRecord = TSANetDataFactory.createCase(account.Id, contact.Id);
            TSANetDataFactory.createTSANetCase(caseRecord.Id);
        }
	}

    @IsTest
    public static void closeRequestTest(){
        String body = '[ { "label": "Demo - VMware", "companyId": 1072, "departmentId": null } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Case sfCaseRecord = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        TSANetInvocableRefreshCasesService.TSANetRefreshResult[] results =
            TSANetInvocableRefreshCasesService.refreshTSANetCases(new String[]{ sfCaseRecord.Id });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected one result per input');
        System.assertEquals(true, results[0].result, 'Refresh job should have been enqueued');
    }

    @IsTest
    static void bulkInputsRunOneCaseQueryAndOneCredentialQuery(){
        String body = '[ { "label": "Demo - VMware", "companyId": 1072, "departmentId": null } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Case sfCaseRecord = [SELECT Id FROM Case LIMIT 1];
        Id missingId = Case.SObjectType.getDescribe().getKeyPrefix() + '000000000000AAA';
        String[] inputs = new String[]{ sfCaseRecord.Id, null, 'not-an-id', missingId, sfCaseRecord.Id };

        Test.startTest();
            Integer queriesBefore = Limits.getQueries();
            TSANetInvocableRefreshCasesService.TSANetRefreshResult[] results =
                TSANetInvocableRefreshCasesService.refreshTSANetCases(inputs);
            Integer queriesUsed = Limits.getQueries() - queriesBefore;
        Test.stopTest();

        System.assertEquals(inputs.size(), results.size(), 'Expected one result per input, in order');
        System.assertEquals(2, queriesUsed, 'Cases and credentials must each be queried once per batch');
        System.assertEquals(true, results[0].result, 'Valid Id should enqueue');
        System.assertEquals(true, results[1].result, 'Blank Id refreshes all cases');
        System.assertEquals(false, results[2].result, 'Malformed Id must fail without throwing');
        System.assertEquals(false, results[3].result, 'Unknown Id must fail without throwing');
        System.assertEquals(true, results[4].result, 'Duplicate valid Id should enqueue');
    }
}
