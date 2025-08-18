public class TSANetResponseTriggerHelper {
    
    public static void handleBeforeInsert(tsanet_connect__TSANetResponse__c[] responses){
        findRelationships(responses);
    }

    public static void findRelationships(tsanet_connect__TSANetResponse__c[] responses){
        
        String[] tsaNetExternalCaseIds = new String[]{};
            
        for(tsanet_connect__TSANetResponse__c response : responses){
            tsaNetExternalCaseIds.add(response.tsanet_connect__CaseId__c);
        }
        
        if(tsaNetExternalCaseIds.size() == 0){ return; }

        tsanet_connect__TSANetCase__c[] tsaNetCases = [SELECT Id, Name, tsanet_connect__Case__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__Partner__c FROM tsanet_connect__TSANetCase__c WHERE tsanet_connect__tsaNetCaseId__c IN:tsaNetExternalCaseIds];

        Map<String, tsanet_connect__TSANetCase__c> externalIdToCase = new Map<String, tsanet_connect__TSANetCase__c>();
        for(tsanet_connect__TSANetCase__c tsaNetCase : tsaNetCases){
            externalIdToCase.put(tsaNetCase.tsanet_connect__tsaNetCaseId__c, tsaNetCase);
        }
        
        for(tsanet_connect__TSANetResponse__c response : responses){
            if(externalIdToCase.containsKey(response.tsanet_connect__CaseId__c)){
                tsanet_connect__TSANetCase__c tsaNetCase = externalIdToCase.get(response.tsanet_connect__CaseId__c);
                response.tsanet_connect__TSANetCase__c = tsaNetCase.Id;
            }
        }        
    }
}