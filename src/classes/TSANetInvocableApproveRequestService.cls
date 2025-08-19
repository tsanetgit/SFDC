global without sharing class TSANetInvocableApproveRequestService {

    global static tsanet_connect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
    
    global class TSANetInput {
        @InvocableVariable 
        global tsanet_connect__TSANetCase__c caseRecord;
        @InvocableVariable 
        global TSANetCaseRequest request;
    }
    
	global class TSANetInvocableApproveRequestResult {
        @InvocableVariable 
        global TSANetCollaborationCase caseRecord;
    }
    
    @InvocableMethod(label='Approve TSANet Collaboration Request' description='Returns case request' category='TSANet')
    global static TSANetInvocableApproveRequestResult[] approveCollaborationRequest(TSANetInput[] inputs) {
        
        TSANetInput input = inputs[0];
        String body = System.JSON.serialize(input);
        approve(body);
        TSANetInvocableApproveRequestResult result = new TSANetInvocableApproveRequestResult();
        return new TSANetInvocableApproveRequestResult[]{ result };
    }

    @future(callout=true)
    global static void approve(String json){

        TSANetInput input = (TSANetInput) System.JSON.deserialize(json, TSANetInput.class);

        String body = System.JSON.serialize(input.request);
        String caseToken = input.caseRecord.tsanet_connect__Token__c;
        
        TSANetService.approveIncomingRequest(caseToken, body, null);
    }

    @Deprecated
    global static String approveAndUpdateToken(TSANetInput input){ return null; }
    @Deprecated
    global static void approveAndUpdateToken2(String input){}
}