/**
 * Invocable that processes inbound TSANetWebhookEvent__e platform events.
 *
 * Kept for cloned Flow callers. Typing-indicator notification also runs from
 * TSANetWebhookRestService so the Integration User owns that DML.
 */
global with sharing class TSANetInvocableProcessWebhookEvent {

    /** A single inbound webhook event delivered by the platform event flow. */
    global class WebhookEventInput {
        /** Webhook event type, e.g. collaboration-request.created. */
        @InvocableVariable
        global String eventType;
        /** Collaboration request token the event refers to. */
        @InvocableVariable
        global String requestToken;
        /** Note token, when the event refers to a note. */
        @InvocableVariable
        global String noteToken;
    }

    /** Outcome of processing a single webhook event. */
    global class WebhookEventResult {
        /** True when the event was accepted for processing. */
        @InvocableVariable
        global Boolean isSuccess;
        /** Descriptive message about the outcome. */
        @InvocableVariable
        global String message;
    }

    /**
     * Notifies the UI for a batch of inbound webhook events with one query and one publish.
     * Queueable refresh is started by TSANetWebhookRestService so it inherits the Integration User.
     * @param inputs the webhook events delivered by the flow
     * @return one result per input, in the same order
     */
    @InvocableMethod(label='Process TSANet Webhook Event' description='Notifies the UI for inbound TSANet webhook events. Data refresh is enqueued by the REST endpoint.' category='TSANet')
    global static WebhookEventResult[] processEvents(WebhookEventInput[] inputs){
        WebhookEventResult[] results = new WebhookEventResult[]{};
        if(inputs == null){
            return results;
        }

        Set<String> requestTokens = new Set<String>();
        for(WebhookEventInput input : inputs){
            WebhookEventResult result = accept(input);
            if(result.isSuccess){
                requestTokens.add(input.requestToken);
            }
            results.add(result);
        }

        TSANetWebhookNotifier.notifyProcessingStarted(requestTokens);

        return results;
    }

    /**
     * Validates one event; the UI notification itself is sent once for the whole batch.
     * @param input the event to validate
     * @return the result for this event
     */
    private static WebhookEventResult accept(WebhookEventInput input){
        WebhookEventResult result = new WebhookEventResult();

        if(input == null || String.isBlank(input.requestToken)){
            result.isSuccess = false;
            result.message = 'Missing request token';
            return result;
        }

        result.isSuccess = true;
        result.message = 'Event accepted';
        return result;
    }
}
