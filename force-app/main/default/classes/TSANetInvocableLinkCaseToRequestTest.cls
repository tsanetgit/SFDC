/** Unit tests for TSANetInvocableLinkCaseToRequest — bulk linking, ordering and bad input handling. */
@IsTest
public class TSANetInvocableLinkCaseToRequestTest {

    @TestSetup
    static void testSetup() {
        User admin = TSANetDataFactory.createAdminUser();
        System.runAs(admin) {
            TSANetDataFactory.createCredentials();
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            TSANetDataFactory.createCase(account.Id, contact.Id);
            tsanetconnect__TSANetCase__c[] requests = new tsanetconnect__TSANetCase__c[]{};
            for (Integer i = 0; i < 5; i++) {
                requests.add(new tsanetconnect__TSANetCase__c(tsanetconnect__Token__c = 'link-token-' + i));
            }
            insert requests;
        }
    }

    @IsTest
    static void linksAllRequestsInOneDmlAndKeepsInputOrder() {
        Case sfCase = [SELECT Id FROM Case LIMIT 1];
        tsanetconnect__TSANetCase__c[] requests = [SELECT Id FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__Case__c = null];

        TSANetInvocableLinkCaseToRequest.LinkInput[] inputs = new TSANetInvocableLinkCaseToRequest.LinkInput[]{};
        for (tsanetconnect__TSANetCase__c request : requests) {
            inputs.add(buildInput(request.Id, sfCase.Id));
        }
        inputs.add(buildInput(null, sfCase.Id));
        inputs.add(buildInput(requests[0].Id, null));

        Test.startTest();
            Integer dmlBefore = Limits.getDmlStatements();
            TSANetInvocableLinkCaseToRequest.LinkResult[] results = TSANetInvocableLinkCaseToRequest.linkCases(inputs);
            Integer dmlUsed = Limits.getDmlStatements() - dmlBefore;
        Test.stopTest();

        System.assertEquals(inputs.size(), results.size(), 'Expected one result per input, in order');
        System.assertEquals(1, dmlUsed, 'All links must be saved in a single DML');
        for (Integer i = 0; i < requests.size(); i++) {
            System.assertEquals(true, results[i].isSuccess, 'Valid pair should link: ' + results[i].message);
        }
        System.assertEquals(false, results[requests.size()].isSuccess, 'Missing request Id must fail');
        System.assertEquals(false, results[requests.size() + 1].isSuccess, 'Missing Case Id must fail');

        Integer linked = [SELECT COUNT() FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__Case__c = :sfCase.Id];
        System.assertEquals(requests.size(), linked, 'Every valid request must now point at the Case');
    }

    @IsTest
    static void nullInputReturnsEmptyResults() {
        System.assertEquals(0, TSANetInvocableLinkCaseToRequest.linkCases(null).size(), 'Null input yields no results');
    }

    private static TSANetInvocableLinkCaseToRequest.LinkInput buildInput(Id tsaNetCaseId, Id caseId) {
        TSANetInvocableLinkCaseToRequest.LinkInput input = new TSANetInvocableLinkCaseToRequest.LinkInput();
        input.tsaNetCaseId = tsaNetCaseId;
        input.caseId = caseId;
        return input;
    }
}
