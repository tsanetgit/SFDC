public class TSANetCaseTriggerHelper {

    public static void handleAfterUpdate(tsanet_connect__TSANetCase__c[] cases, Map<Id, tsanet_connect__TSANetCase__c> oldCases){

        Id[] ids = new Id[]{};
            for(tsanet_connect__TSANetCase__c caseRecord : cases){
                ids.add(caseRecord.Id);
            }
        
        tsanet_connect__TSANetResponse__c[] responses = [SELECT Id, Name, tsanet_connect__TSANetCase__c, tsanet_connect__TSANetCase__r.Case__r.Owner.Name, tsanet_connect__TSANetCase__r.Case__r.Owner.Email, tsanet_connect__TSANetCase__r.Case__r.Owner.Phone FROM tsanet_connect__TSANetResponse__c WHERE tsanet_connect__TSANetCase__c IN:ids];
        Map<String, tsanet_connect__TSANetResponse__c[]> caseToResponses = new Map<String, tsanet_connect__TSANetResponse__c[]>();
        for(tsanet_connect__TSANetResponse__c res : responses){
            if(caseToResponses.containsKey(res.tsanet_connect__TSANetCase__c)){
                tsanet_connect__TSANetResponse__c[] localRes = caseToResponses.get(res.tsanet_connect__TSANetCase__c);
                localRes.add(res);
                caseToResponses.put(res.tsanet_connect__TSANetCase__c, localRes);
            } else {
                caseToResponses.put(res.tsanet_connect__TSANetCase__c, new tsanet_connect__TSANetResponse__c[]{ res });
            }
        }
        System.debug('caseResponse:  WORK ');
        Id[] tsaNetCaseIds = new String[]{};
            for(tsanet_connect__TSANetCase__c caseRecord : cases){
                if(caseRecord.tsanet_connect__Case__c != oldCases.get(caseRecord.Id).tsanet_connect__Case__c){
                    
                    tsanet_connect__TSANetResponse__c[] caseResponses = caseToResponses.get(caseRecord.Id);
                    System.debug('caseResponses ' + caseResponses);
                    if(caseResponses != NULL && caseResponses.size() > 0){
                        tsanet_connect__TSANetResponse__c caseResponse = caseResponses[0];
                        System.debug('caseResponse:  WORK ');
                        String json = '{ "caseNumber": "' + caseRecord.tsanet_connect__tsaNetCaseId__c + 
                            '", "engineerName": "' + caseResponse.tsanet_connect__TSANetCase__r.Case__r.Owner.Name + 
                            '", "engineerPhone": "' + caseResponse.tsanet_connect__TSANetCase__r.Case__r.Owner.Phone + 
                            '", "engineerEmail": "' + caseResponse.tsanet_connect__TSANetCase__r.Case__r.Owner.Email + 
                            '", "nextSteps": "Case Owner has been changed!" }';
                        TSANetService.approveIncomingRequestFuture(caseRecord.tsanet_connect__Token__c, json);
                    }
                }
            }
    }
}