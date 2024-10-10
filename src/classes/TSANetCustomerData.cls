global class TSANetCustomerData {
    @AuraEnabled 
    global String id { get; set; }
    @AuraEnabled 
    global String section { get; set; }
    @AuraEnabled 
    global String fieldName { get; set; }
    @AuraEnabled 
    global String value { get; set; }
}