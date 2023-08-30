@isTest
public with sharing class REST_XfleetInvoiceRequest_Test {
    private final static String TEST_VIN_NO = 'VR3FBYHZTMY528656';
    private final static String TEST_REG_NO = 'DF 75664';
    private final static String TEST_VIN_NO_2 = 'VR3FBYHZTMY522222';
    private final static String TEST_REG_NO_2 = 'AB75664';

    private static final Integer BATCH_DELAY = 5;
    private static final Integer BATCH_SIZE = 15;
    private static final Datetime LAST_JOB_RUN = Datetime.newInstance(2022, 11, 28, 5, 30, 0);

    @TestSetup
    static void makeData() {
        // custom settings
        TestUtilitySIXT.initFleetManagementSettings();
        IntegrationSettings__c testSettings = new IntegrationSettings__c();
        testSettings.Batch_Job_Delay_in_minutes__c = BATCH_DELAY;
        testSettings.Job_last_run_at__c = LAST_JOB_RUN;
        testSettings.Batch_Size__c = BATCH_SIZE;
        insert testSettings;

        // vehicles data
        vehicleBatch__c b = TestUtilitySIXT.createBatch();
        Map<String, Object> veh1Params = new Map<String, Object>{ 'vinNumber__c' => TEST_VIN_NO, 'License_Plate__c' => TEST_REG_NO };
        Vehicle__c v1 = TestUtilitySIXT.createVehicle(b.Id, veh1Params);
        Map<String, Object> veh2Params = new Map<String, Object>{ 'vinNumber__c' => TEST_VIN_NO_2, 'License_Plate__c' => TEST_REG_NO_2 };
        Vehicle__c v2 = TestUtilitySIXT.createVehicle(b.Id, veh2Params);
    }

    @isTest
    public static void invoiceRequestTest() {
        // test data
        Vehicle__c v = [SELECT Id FROM Vehicle__c WHERE vinNumber__c = :TEST_VIN_NO];
        Vehicle__c exchangeVeh = [SELECT Id FROM Vehicle__c WHERE vinNumber__c = :TEST_VIN_NO_2];
        Account buyer = TestUtilitySIXT.getDefaultAccount();
        v.Buyer_Account__c = buyer.Id;
        update v;

        // prepare request
        REST_XfleetInvoiceRequest.InvoiceRequestWrapper req = new REST_XfleetInvoiceRequest.InvoiceRequestWrapper();
        req.vehicleId = v.Id;
        req.exchangeVehicleId = exchangeVeh.Id;
        req.customerPriceDKK = 1000;
        req.additionalAccessoriesCostDKK = 24000;
        req.externalInvoiceNumber = 'abc unit';
        req.ownerAddressLine1 = 'Korvgatan 1';
        req.ownerAddressLine2 = 'c/o Lund';
        req.ownerCity = 'Lund';
        req.ownerPostCode = '123 45';

        // REST request
        RestRequest restReq = new RestRequest();
        restReq.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/Xfleet/v1/InvoiceRequest';
        restReq.httpMethod = 'POST';
        //restReq.params.put('vehicle', JSON.serialize(req, true));
        RestContext.request = restReq;
        RestContext.response = new RestResponse();

        Test.startTest();
        // process request
        REST_XfleetInvoiceRequest.doPost(req);
        Test.stopTest();

        System.assertEquals(201, RestContext.response.statusCode);
    }
}