/**
 * Invocable action that stamps TSANet notes as notified once their notification has been sent.
 *
 * The notification flow runs after-save on TSANetNote__c and cannot update $Record itself
 * (Code Analyzer SameRecordUpdate), so the flag is set here in one bulk update instead.
 */
global with sharing class TSANetInvocableMarkNotesNotified {

    /** Outcome of marking one note. */
    global class MarkResult {
        /** True when the note was updated. */
        @InvocableVariable
        global Boolean isSuccess;
        /** Descriptive message about the outcome. */
        @InvocableVariable
        global String message;
    }

    /**
     * Sets isNotified__c = true on each note in a single bulk update.
     * @param noteIds Ids of the TSANetNote__c records that were notified
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='TSANet Mark Notes Notified' description='Sets isNotified__c = true on TSANetNote__c records. Returns: isSuccess: boolean, message: string' category='TSANet')
    global static MarkResult[] markNotified(Id[] noteIds) {
        MarkResult[] results = new MarkResult[]{};
        if (noteIds == null) {
            return results;
        }

        tsanetconnect__TSANetNote__c[] updates = new tsanetconnect__TSANetNote__c[]{};
        Integer[] updateIndexes = new Integer[]{};
        for (Integer i = 0; i < noteIds.size(); i++) {
            MarkResult result = new MarkResult();
            results.add(result);

            if (noteIds[i] == null) {
                result.isSuccess = false;
                result.message = 'A note Id is required';
                continue;
            }
            updates.add(new tsanetconnect__TSANetNote__c(Id = noteIds[i], tsanetconnect__isNotified__c = true));
            updateIndexes.add(i);
        }

        applySaveResults(results, updateIndexes, updates);
        return results;
    }

    /** Runs the bulk update and maps each save result back onto its input position. */
    private static void applySaveResults(MarkResult[] results, Integer[] updateIndexes, tsanetconnect__TSANetNote__c[] updates) {
        if (updates.isEmpty()) {
            return;
        }
        Database.SaveResult[] saveResults = Database.update(updates, false, AccessLevel.USER_MODE);
        for (Integer i = 0; i < saveResults.size(); i++) {
            MarkResult result = results[updateIndexes[i]];
            result.isSuccess = saveResults[i].isSuccess();
            result.message = result.isSuccess
                ? 'Note marked as notified'
                : saveResults[i].getErrors()[0].getMessage();
        }
    }
}
