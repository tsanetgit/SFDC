global class TSANetInvocableNoteService {

    global class TSANetInput {
        @InvocableVariable 
        global tsanet_connect__TSANetCase__c caseRecord;
        @InvocableVariable 
        global TSANetNoteForm note;
    }
    
    global class TSANetCollaborationCaseNoteResult {
        @InvocableVariable 
        global TSANetCollaborationCase caseRecord;
    }

    @InvocableMethod(label='Create TSANet Note' description='Returns collaboration case note' category='TSANet')
    global static TSANetCollaborationCaseNoteResult[] createCollaborationCaseNote(TSANetInput[] data) {
        TSANetInput input = data[0];
        String json = JSON.serialize(input.note);
        
        String body = TSANetService.createCaseNote(input.caseRecord.tsanet_connect__tsaNetCaseId__c, json);
        
        if(!Test.isRunningTest()){ TSANetUtils.futureRefresh(null); }
        
        TSANetCollaborationCaseNoteResult result = new TSANetCollaborationCaseNoteResult();
        result.caseRecord = (TSANetCollaborationCase) System.JSON.deserialize(body, TSANetCollaborationCase.class);
        return new TSANetCollaborationCaseNoteResult[]{ result };
    }
        
}