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
                
        String body = System.JSON.serialize(input);
        createTSANetNote(body);
        
        TSANetCollaborationCaseNoteResult result = new TSANetCollaborationCaseNoteResult();
        return new TSANetCollaborationCaseNoteResult[]{ result };
    }
    
    @future(callout=true)
    public static void createTSANetNote(String json){
        
        TSANetInput input = (TSANetInput) System.JSON.deserialize(json, TSANetInput.class);
        
        String caseToken = input.caseRecord.tsanet_connect__Token__c;
        String note = System.JSON.serialize(input.note);
        
        TSANetService.createTSANetNote(caseToken, note, null);
    }
}