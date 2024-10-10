@isTest
public class TSANetCustomerDataTest {

    @isTest
    public static void TSANetCompanyFormParseTest(){
        String json = '{ "id":5573, "section":"COMMON_CUSTOMER_SECTION", "fieldName":"Customer Company", "value":"Test" }';
        TSANetCustomerData data = (TSANetCustomerData) System.JSON.deserialize(json, TSANetCustomerData.class);
        System.assertEquals(true, 
                            data.id == '5573' && 
                            data.section == 'COMMON_CUSTOMER_SECTION' && 
                            data.fieldName == 'Customer Company' && 
                            data.value == 'Test');
    }
}