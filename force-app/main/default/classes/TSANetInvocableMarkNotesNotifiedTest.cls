/** Unit tests for TSANetInvocableMarkNotesNotified — bulk flagging, ordering and bad input handling. */
@IsTest
public class TSANetInvocableMarkNotesNotifiedTest {

    @TestSetup
    static void testSetup() {
        User admin = TSANetDataFactory.createAdminUser();
        System.runAs(admin) {
            TSANetDataFactory.createCredentials();
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            Case caseRecord = TSANetDataFactory.createCase(account.Id, contact.Id);
            tsanetconnect__TSANetCase__c tsaNetCase = TSANetDataFactory.createTSANetCase(caseRecord.Id);

            tsanetconnect__TSANetNote__c[] notes = new tsanetconnect__TSANetNote__c[]{};
            for (Integer i = 0; i < 5; i++) {
                notes.add(new tsanetconnect__TSANetNote__c(
                    tsanetconnect__TSANetCase__c = tsaNetCase.Id,
                    tsanetconnect__Token__c = 'notify-token-' + i,
                    tsanetconnect__Summary__c = 'Summary ' + i,
                    tsanetconnect__CreatedAt__c = DateTime.now()
                ));
            }
            insert notes;
        }
    }

    @IsTest
    static void marksAllNotesInOneDmlAndKeepsInputOrder() {
        // The active notification flow may already have flagged these on insert, so reset explicitly.
        tsanetconnect__TSANetNote__c[] notes = [SELECT Id FROM tsanetconnect__TSANetNote__c];
        for (tsanetconnect__TSANetNote__c note : notes) {
            note.tsanetconnect__isNotified__c = false;
        }
        update notes;

        Id[] noteIds = new Id[]{};
        for (tsanetconnect__TSANetNote__c note : notes) {
            noteIds.add(note.Id);
        }
        noteIds.add(null);

        Test.startTest();
            Integer dmlBefore = Limits.getDmlStatements();
            TSANetInvocableMarkNotesNotified.MarkResult[] results = TSANetInvocableMarkNotesNotified.markNotified(noteIds);
            Integer dmlUsed = Limits.getDmlStatements() - dmlBefore;
        Test.stopTest();

        System.assertEquals(noteIds.size(), results.size(), 'Expected one result per input, in order');
        System.assertEquals(1, dmlUsed, 'All notes must be flagged in a single DML');
        for (Integer i = 0; i < notes.size(); i++) {
            System.assertEquals(true, results[i].isSuccess, 'Valid note should be flagged: ' + results[i].message);
        }
        System.assertEquals(false, results[notes.size()].isSuccess, 'Null Id must fail without aborting the batch');

        Integer stillPending = [SELECT COUNT() FROM tsanetconnect__TSANetNote__c WHERE tsanetconnect__isNotified__c = false];
        System.assertEquals(0, stillPending, 'Every note must now be marked as notified');
    }

    @IsTest
    static void nullInputReturnsEmptyResults() {
        System.assertEquals(0, TSANetInvocableMarkNotesNotified.markNotified(null).size(), 'Null input yields no results');
    }
}
