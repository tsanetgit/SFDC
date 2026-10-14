/** Invocable service that enqueues a refresh job for TSANet cases. */
global with sharing class TSANetInvocableRefreshCasesService {

    /** @deprecated Credentials are now resolved internally by TSANetService. */
    @Deprecated
    global static tsanetconnect__TSANet_Credentials__c credential;

    /** Result wrapper containing the refresh operation outcome. */
	global class TSANetRefreshResult {
        /** True if the refresh job was enqueued successfully. */
        @InvocableVariable
        global Boolean result;
    }

    /**
     * Enqueues an asynchronous job to refresh TSANet cases, optionally filtered by Case Id.
     * Cases and the credential state are resolved once per batch so no SOQL runs in the loop.
     * @param caseId list containing an optional Salesforce Case Id to scope the refresh
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='Refresh TSANet Cases' description='Returns the result as boolean' category='TSANet')
    global static TSANetRefreshResult[] refreshTSANetCases(String[] caseId) {
        TSANetRefreshResult[] results = new TSANetRefreshResult[]{};
        if (caseId == null) {
            return results;
        }

        Map<Id, Case> casesById = CaseSelector.getByIds(collectValidIds(caseId));
        Boolean connected = CredentialManager.isConnected();

        for (String caseRecordId : caseId) {
            TSANetRefreshResult refreshResult = new TSANetRefreshResult();
            try {
                String caseNumber = resolveCaseNumber(caseRecordId, casesById);
                refreshResult.result = connected && TSANetQueueableJob.enqueue(caseNumber);
            } catch (Exception e) {
                ErrorLogger.logError(e, 'TSANET_INVOCABLE_REFRESH_ERROR');
                refreshResult.result = false;
            }
            results.add(refreshResult);
        }
        return results;
    }

    /** Collects the well-formed Ids from the raw input; malformed values are rejected per item later. */
    private static Set<Id> collectValidIds(String[] rawIds) {
        Set<Id> ids = new Set<Id>();
        for (String rawId : rawIds) {
            if (String.isNotBlank(rawId) && rawId instanceof Id) {
                ids.add(rawId);
            }
        }
        return ids;
    }

    /**
     * Returns the case number for one input, or null when the input is blank (refresh all).
     * Throws when the Id is malformed or does not resolve so the caller reports a failure.
     */
    private static String resolveCaseNumber(String caseRecordId, Map<Id, Case> casesById) {
        if (String.isBlank(caseRecordId)) {
            return null;
        }
        Case sfCase = casesById.get(caseRecordId);
        if (sfCase == null) {
            throw new QueryException('Case not found: ' + caseRecordId);
        }
        return sfCase.CaseNumber;
    }
}
