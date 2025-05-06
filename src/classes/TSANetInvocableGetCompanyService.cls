global class TSANetInvocableGetCompanyService {
    
    global  class TSANetCompanyResult {
        @InvocableVariable 
        global  TSANetCompanyOption[] companies;
    }
    
    @InvocableMethod(label='Get TSANet Companies' description='Returns the list of TSANet Companies' category='TSANet')
    global static TSANetCompanyResult[] getCompanies(String[] companyName) {
        String name = companyName[0];
        String body = '';
        try {
            body = TSANetService.getCompaniesByName(name);
            
            if(body == 'The authorization token provided was invalid.'){
                body = getCompaniesAndUpdateToken(name);
            }
            
        } catch(Exception e){
            body = getCompaniesAndUpdateToken(name);
        }

        TSANetCompanyResult result = new TSANetCompanyResult();
        TSANetCompanyOption[] companies = (TSANetCompanyOption[]) System.JSON.deserialize(body, TSANetCompanyOption[].class);
        for(TSANetCompanyOption company : companies){
            company.value = company.companyId != NULL ? String.valueOf(company.companyId) : String.valueOf(company.departmentId);
        }
        result.companies = companies;
        return new TSANetCompanyResult[]{ result };
    }
    
    global static String getCompaniesAndUpdateToken(String name){
        String token = TSANetService.getBearerAccessToken();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TSANetService.endpoint + TSANetService.companies_path + name);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        String userId = TSANetService.CONFIG.tsanet_connect__IntegrationUser__c == NULL ? UserInfo.getUserId() : TSANetService.CONFIG.tsanet_connect__IntegrationUser__c;
        Database.update(new User(Id = userId, tsanet_connect__tsaNetAccessToken__c = token)).isSuccess();
        
        return res.getBody();
    }
}