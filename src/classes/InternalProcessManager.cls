public with sharing class InternalProcessManager {
    
    public static tsanet_connect__TSANetConfiguration__c CONFIG = ConfigManager.getConfig();

    public static void execute(tsanet_connect__TSANet_Credentials__c credential){

        if(credential.tsanet_connect__IntegrationUser__c == NULL){
            TSANetUtils.updateUserCredentials(credential.tsanet_connect__UserName__c, credential.tsanet_connect__Password__c);
        }
        
        if(credential.tsanet_connect__CompanyId__c == NULL){
			setConfig();            
        }
        
        CronTrigger[] crons = [SELECT Id, CronJobDetailId, CronJobDetail.Name, State FROM CronTrigger WHERE CronJobDetail.Name = 'TSANetScheduledJob'];
        if(crons.size() == 0){
            //System.schedule('TSANetScheduledJob', '0 0 * * * ?', new TSANetScheduledJob());
        }
    }
    
    @future(callout=true)
    public static void setConfig(){
    	ConfigManager.updateConfig();
    }
}