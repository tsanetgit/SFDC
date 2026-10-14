/**
 * Invocable action that links a Salesforce Case to a TSANet collaboration request.
 *
 * Record-triggered flows on TSANetCase__c cannot update $Record from an after-save path
 * (Code Analyzer SameRecordUpdate), so the Case itself stays customizable in Flow and
 * only this fixed link step runs in Apex.
 */
global with sharing class TSANetInvocableLinkCaseToRequest {

    /** One collaboration request / Case pair to link. */
    global class LinkInput {
        /** Id of the TSANetCase__c record to update. */
        @InvocableVariable(label='Collaboration Request Id' required=true)
        global Id tsaNetCaseId;
        /** Id of the Salesforce Case to attach. */
        @InvocableVariable(label='Case Id' required=true)
        global Id caseId;
    }

    /** Outcome of linking one pair. */
    global class LinkResult {
        /** True when the link was saved. */
        @InvocableVariable
        global Boolean isSuccess;
        /** Descriptive message about the outcome. */
        @InvocableVariable
        global String message;
    }

    /**
     * Sets Case__c on each collaboration request in a single bulk update.
     * @param inputs the request / Case pairs delivered by the flow
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='TSANet Link Case to Collaboration Request' description='Sets Case__c on TSANetCase__c records. Returns: isSuccess: boolean, message: string' category='TSANet')
    global static LinkResult[] linkCases(LinkInput[] inputs) {
        LinkResult[] results = new LinkResult[]{};
        if (inputs == null) {
            return results;
        }

        tsanetconnect__TSANetCase__c[] updates = new tsanetconnect__TSANetCase__c[]{};
        Integer[] updateIndexes = new Integer[]{};
        for (Integer i = 0; i < inputs.size(); i++) {
            LinkInput input = inputs[i];
            LinkResult result = new LinkResult();
            results.add(result);

            if (input == null || input.tsaNetCaseId == null || input.caseId == null) {
                result.isSuccess = false;
                result.message = 'Both a collaboration request Id and a Case Id are required';
                continue;
            }
            updates.add(new tsanetconnect__TSANetCase__c(Id = input.tsaNetCaseId, tsanetconnect__Case__c = input.caseId));
            updateIndexes.add(i);
        }

        applySaveResults(results, updateIndexes, updates);
        return results;
    }

    /** Runs the bulk update and maps each save result back onto its input position. */
    private static void applySaveResults(LinkResult[] results, Integer[] updateIndexes, tsanetconnect__TSANetCase__c[] updates) {
        if (updates.isEmpty()) {
            return;
        }
        Database.SaveResult[] saveResults = Database.update(updates, false, AccessLevel.USER_MODE);
        for (Integer i = 0; i < saveResults.size(); i++) {
            LinkResult result = results[updateIndexes[i]];
            result.isSuccess = saveResults[i].isSuccess();
            result.message = result.isSuccess
                ? 'Case linked to the collaboration request'
                : saveResults[i].getErrors()[0].getMessage();
        }
    }
}
