@isTest
public class TSANetNoteResponseTest {

    @isTest
    public static void parseTest(){
        TSANetConfiguration__c c = TSANetConfiguration__c.getOrgDefaults();
        c.IntegrationUser__c = UserInfo.getUserId();
        upsert c;
        
        String json = '[{ "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }]';
        String oneRecord = '{ "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }';
        TSANetNoteResponse.parse(json);
        TSANetNoteResponse.parseOneRecord(oneRecord);
    }
}