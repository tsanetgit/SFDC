/**
 * Publishes TSANetCaseUpdated__e notifications for inbound webhook processing so subscribed
 * LWCs can show a typing indicator while the refresh runs and clear it once it completes.
 */
public with sharing class TSANetWebhookNotifier {

    /**
     * Resolves the Salesforce Case behind a collaboration request token.
     * @param requestToken the collaboration request token
     * @return the related Case Id, or null when the case is not linked locally
     */
    public static Id getCaseIdByToken(String requestToken){
        if(requestToken == null){
            return null;
        }
        return getCaseIdsByTokens(new Set<String>{ requestToken }).get(requestToken);
    }

    /**
     * Resolves the Salesforce Cases behind a batch of collaboration request tokens in one query.
     * @param requestTokens the collaboration request tokens
     * @return map of token to related Case Id; tokens without a linked case are absent
     */
    public static Map<String, Id> getCaseIdsByTokens(Set<String> requestTokens){
        Map<String, Id> caseIdsByToken = new Map<String, Id>();
        if(requestTokens == null){
            return caseIdsByToken;
        }
        // A null token would otherwise match cases with no token at all.
        requestTokens.remove(null);
        if(requestTokens.isEmpty()){
            return caseIdsByToken;
        }
        for(tsanetconnect__TSANetCase__c tsaNetCase : [
            SELECT tsanetconnect__Token__c, tsanetconnect__Case__c
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Token__c IN :requestTokens
            WITH USER_MODE
        ]){
            if(tsaNetCase.tsanetconnect__Case__c != null){
                caseIdsByToken.put(tsaNetCase.tsanetconnect__Token__c, tsaNetCase.tsanetconnect__Case__c);
            }
        }
        return caseIdsByToken;
    }

    /**
     * Publishes the typing indicator for the related case; never throws to callers.
     * @param requestToken the collaboration request token being processed
     */
    public static void notifyProcessingStarted(String requestToken){
        notifyProcessingStarted(new Set<String>{ requestToken });
    }

    /**
     * Publishes the typing indicator for every related case in one query and one publish;
     * never throws to callers.
     * @param requestTokens the collaboration request tokens being processed
     */
    public static void notifyProcessingStarted(Set<String> requestTokens){
        try {
            Map<String, Id> caseIdsByToken = getCaseIdsByTokens(requestTokens);
            tsanetconnect__TSANetCaseUpdated__e[] events = new tsanetconnect__TSANetCaseUpdated__e[]{};
            for(String requestToken : caseIdsByToken.keySet()){
                events.add(buildCaseUpdated(caseIdsByToken.get(requestToken), requestToken, false));
            }
            if(!events.isEmpty()){
                EventBus.publish(events);
            }
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_WEBHOOK_EVENT_HANDLER', new Map<String, String>{ 'requestTokens' => String.valueOf(requestTokens) });
        }
    }

    /**
     * Publishes a case-updated notification for the given Case.
     * @param caseId the Salesforce Case the notification belongs to
     * @param requestToken the collaboration request token being processed
     * @param isSync false when processing starts, true once the data is refreshed
     */
    public static void publishCaseUpdated(Id caseId, String requestToken, Boolean isSync){
        EventBus.publish(buildCaseUpdated(caseId, requestToken, isSync));
    }

    /** Builds a case-updated platform event without publishing it. */
    private static tsanetconnect__TSANetCaseUpdated__e buildCaseUpdated(Id caseId, String requestToken, Boolean isSync){
        return new tsanetconnect__TSANetCaseUpdated__e(
            tsanetconnect__CaseId__c = caseId,
            tsanetconnect__RequestToken__c = requestToken,
            tsanetconnect__IsSync__c = isSync
        );
    }
}
