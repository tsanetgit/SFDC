@isTest
public class TSANetCompanyFormTest {

    @isTest
    public static void TSANetCompanyFormParseTest(){
        String json = '{ "documentId": 2115, "internalCaseNumber": "", "optionalRecieverInternalCaseNumber": "", "problemSummary": "", "problemDescription": "", "casePriority": "", "readonlyAdminNote": "<p>test admin note (description)</p>", "readonlyEscalationInstructions": "<p>test escalation instructions</p>", "testSubmission": false, "customerData": [ { "id": 5558, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": null }, { "id": 5559, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": null }, { "id": 5560, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": null }, { "id": 5561, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": null }, { "id": 5562, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Connect2 Test 01 (Optional)", "value": null } ] }';
        TSANetCompanyForm form = (TSANetCompanyForm) System.JSON.deserialize(json, TSANetCompanyForm.class);
        System.assertEquals(true, 
                            form.documentId == '2115' && 
                            form.internalCaseNumber == '' && 
                            form.optionalRecieverInternalCaseNumber == '' && 
                            form.problemSummary == '' && 
                            form.problemDescription == '' && 
                            form.casePriority == '' && 
                            form.readonlyAdminNote == '<p>test admin note (description)</p>' && 
                            form.readonlyEscalationInstructions == '<p>test escalation instructions</p>' && 
                            form.testSubmission == false && 
                            form.customerData.size() > 0
                           );
    }
}