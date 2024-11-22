global class TSANetInvocableRefreshCasesService {
	global class TSANetRefreshResult {
        @InvocableVariable 
        global Boolean result;
    }
    
    @InvocableMethod(label='Refresh TSANet Cases' description='Returns the result as boolean' category='TSANet')
    global static TSANetRefreshResult[] refreshTSANetCases(String[] caseId) {
        String caseRecordId = null;
        if(caseId.size() > 0){
            caseRecordId = caseId[0];
        }
        Boolean result = false;
        try {
            TSANetService.getRelatedCollaborationCases(caseRecordId);   
            result = true;
        } catch(Exception e){
            refreshCasesAndUpdateToken(caseRecordId);
            result = true;
        }

        TSANetRefreshResult refreshResult = new TSANetRefreshResult();
        refreshResult.result = result;
        return new TSANetRefreshResult[]{ refreshResult };
    }
    
    global static Boolean refreshCasesAndUpdateToken(String caseId){
        String token = TSANetService.getBearerAccessToken();
        TSANetService.getRelatedCollaborationCasesWithToken(caseId, token);
        
        String userId = TSANetService.CONFIG.tsanet_connect__IntegrationUser__c == NULL ? UserInfo.getUserId() : TSANetService.CONFIG.tsanet_connect__IntegrationUser__c;
        Database.update(new User(Id = userId, tsanet_connect__tsaNetAccessToken__c = token)).isSuccess();
        
        return true;
    }
}