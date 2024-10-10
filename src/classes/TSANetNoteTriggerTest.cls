@isTest
public class TSANetNoteTriggerTest {

    @isTest
    public static void methodTest(){
        
        TSANetNote__c note = new TSANetNote__c(Summary__c = 'Test');
        
        insert note;
    }
}