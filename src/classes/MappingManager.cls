public with sharing class MappingManager {
    
    public static tsanet_connect__TSANetCaseMapping__mdt[] TSANET_MAPPING = getTSANetMapping();
    
	public static tsanet_connect__TSANetCaseMapping__mdt[] getTSANetMapping() {
        return [SELECT Id, tsanet_connect__Type__c, tsanet_connect__From__c, tsanet_connect__To__c FROM tsanet_connect__TSANetCaseMapping__mdt];
    }
}