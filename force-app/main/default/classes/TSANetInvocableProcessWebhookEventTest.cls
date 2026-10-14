/** Unit tests for TSANetInvocableProcessWebhookEvent — covers bulk batches and job count. */
@IsTest
public class TSANetInvocableProcessWebhookEventTest {

    @TestSetup
    static void testSetup() {
        User admin = TSANetDataFactory.createAdminUser();
        System.runAs(admin) {
            TSANetDataFactory.createCredentials();
        }
    }

    @IsTest
    static void testBatchOfEventsNotifiesWithoutEnqueue() {
        TSANetInvocableProcessWebhookEvent.WebhookEventInput[] inputs = new TSANetInvocableProcessWebhookEvent.WebhookEventInput[]{};
        for(Integer i = 0; i < 10; i++){
            inputs.add(buildInput('collaboration-request.created', 'token-' + i));
        }

        Test.startTest();
            TSANetInvocableProcessWebhookEvent.WebhookEventResult[] results = TSANetInvocableProcessWebhookEvent.processEvents(inputs);
            System.assertEquals(0, Limits.getQueueableJobs(), 'PE subscriber must not enqueue; REST owns the queueable');
        Test.stopTest();

        System.assertEquals(10, results.size(), 'Expected one result per input');
        for(TSANetInvocableProcessWebhookEvent.WebhookEventResult result : results){
            System.assertEquals(true, result.isSuccess, 'Every event should be accepted: ' + result.message);
            System.assertEquals('Event accepted', result.message, 'Accepted events notify only');
        }
    }

    @IsTest
    static void testBatchResolvesCasesInOneQueryAndPublishesOnce() {
        Account account = TSANetDataFactory.createAccount();
        Contact contact = TSANetDataFactory.createContact(account.Id);
        Case caseRecord = TSANetDataFactory.createCase(account.Id, contact.Id);
        TSANetDataFactory.createTSANetCase(caseRecord.Id);

        TSANetInvocableProcessWebhookEvent.WebhookEventInput[] inputs = new TSANetInvocableProcessWebhookEvent.WebhookEventInput[]{
            buildInput('collaboration-request.created', 'test-token'),
            buildInput('collaboration-request.created', 'unknown-token'),
            buildInput('collaboration-request.created', null),
            buildInput('collaboration-request.created', 'test-token')
        };

        Test.startTest();
            Integer queriesBefore = Limits.getQueries();
            Integer dmlBefore = Limits.getDmlStatements();
            TSANetInvocableProcessWebhookEvent.WebhookEventResult[] results = TSANetInvocableProcessWebhookEvent.processEvents(inputs);
            Integer queriesUsed = Limits.getQueries() - queriesBefore;
            Integer dmlUsed = Limits.getDmlStatements() - dmlBefore;
        Test.stopTest();

        System.assertEquals(inputs.size(), results.size(), 'Expected one result per input, in order');
        System.assertEquals(1, queriesUsed, 'Tokens must be resolved in a single query per batch');
        System.assertEquals(1, dmlUsed, 'Events must be published in a single EventBus.publish call');
        System.assertEquals(true, results[0].isSuccess, 'Known token accepted');
        System.assertEquals(true, results[1].isSuccess, 'Unknown token is still accepted, just not notified');
        System.assertEquals(false, results[2].isSuccess, 'Missing token rejected');
        System.assertEquals(true, results[3].isSuccess, 'Duplicate token accepted');
    }

    @IsTest
    static void testMissingRequestTokenIsRejected() {
        Test.startTest();
            TSANetInvocableProcessWebhookEvent.WebhookEventResult[] results = TSANetInvocableProcessWebhookEvent.processEvents(
                new TSANetInvocableProcessWebhookEvent.WebhookEventInput[]{ buildInput('collaboration-request.created', null) }
            );
            System.assertEquals(0, Limits.getQueueableJobs(), 'An event without a token must not be queued');
        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess, 'An event without a token must be rejected');
        System.assertEquals('Missing request token', results[0].message, 'A rejected event must explain why');
    }

    private static TSANetInvocableProcessWebhookEvent.WebhookEventInput buildInput(String eventType, String requestToken){
        TSANetInvocableProcessWebhookEvent.WebhookEventInput input = new TSANetInvocableProcessWebhookEvent.WebhookEventInput();
        input.eventType = eventType;
        input.requestToken = requestToken;
        return input;
    }
}
