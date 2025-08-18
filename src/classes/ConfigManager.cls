public class ConfigManager {
    
	public static tsanet_connect__TSANetConfiguration__c CONFIG = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
    
    public static tsanet_connect__TSANetConfiguration__c getConfig(){
        return CONFIG;
    }
    
    @AuraEnabled
    public static Boolean updateConfig(){
        
        String token = TSANetService.getTSANetAccessToken();
        TSANetCompanyInfo info = TSANetService.getCompanyInformation(token);

        tsanet_connect__TSANetConfiguration__c config = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();

        config.tsanet_connect__Username__c = info.user.email; 
        config.tsanet_connect__companyName__c = info.company.name;
        config.tsanet_connect__companyId__c = info.company.id;
        
        tsanet_connect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
        credential.tsanet_connect__CompanyName__c = info.company.name;
        credential.tsanet_connect__CompanyId__c = info.company.id;
        credential.tsanet_connect__Token__c = token;
        Database.update(credential).isSuccess();
        
        return Database.upsert(config).isSuccess();
    }
    
    @AuraEnabled
    public static Boolean removeConfig(){
        
        tsanet_connect__TSANetConfiguration__c config = tsanet_connect__TSANetConfiguration__c.getOrgDefaults();
        
        config.tsanet_connect__Username__c = null; 
        config.tsanet_connect__companyName__c = null;
        config.tsanet_connect__companyId__c = null;
        
        return Database.upsert(config).isSuccess();
    }
}