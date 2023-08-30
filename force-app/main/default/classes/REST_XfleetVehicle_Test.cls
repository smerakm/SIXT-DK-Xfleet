@isTest
public class REST_XfleetVehicle_Test {
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

        FleetManagementConfig__c config = FleetManagementConfig__c.getOrgDefaults();
        config.DefaultBatchId__c = b.Id;
        update config;
    }

    @isTest
    public static void createVehicle() {
        // prepare request
        REST_XfleetVehicle.VehicleWrapper req = new REST_XfleetVehicle.VehicleWrapper();
        req.vin = TEST_VIN_NO_2;

        // REST request
        RestRequest restReq = new RestRequest();
        restReq.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/Xfleet/v1/Vehicle';
        restReq.httpMethod = 'POST';
        //restReq.params.put('vehicle', JSON.serialize(req, true));
        RestContext.request = restReq;
        RestContext.response = new RestResponse();

        Test.startTest();
        // process request
        REST_XfleetVehicle.doPost(req);
        Test.stopTest();

        System.assertEquals(201, RestContext.response.statusCode);
    }

    @isTest
    public static void getVehicle() {
        // vehicle id
        Vehicle__c v = [SELECT Id FROM Vehicle__c WHERE vinNumber__c = :TEST_VIN_NO];

        // REST request
        RestRequest restReq = new RestRequest();
        restReq.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/Xfleet/v1/Vehicle/' + v.Id;
        restReq.httpMethod = 'GET';
        //restReq.params.put('vehicle', JSON.serialize(req, true));
        RestContext.request = restReq;
        RestContext.response = new RestResponse();

        Test.startTest();
        // process request
        REST_XfleetVehicle.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    public static void updateVehicle() {
        // vehicle id
        Vehicle__c v = [SELECT Id FROM Vehicle__c WHERE vinNumber__c = :TEST_VIN_NO];

        // prepare request
        REST_XfleetVehicle.VehicleWrapper req = new REST_XfleetVehicle.VehicleWrapper();
        req.modelName = 'XC60';

        // REST request
        RestRequest restReq = new RestRequest();
        restReq.requestUri = 'https://yourInstance.my.salesforce.com/services/apexrest/Xfleet/v1/Vehicle/' + v.Id;
        restReq.httpMethod = 'PATCH';
        //restReq.params.put('vehicle', JSON.serialize(req, true));
        RestContext.request = restReq;
        RestContext.response = new RestResponse();

        Test.startTest();
        // process request
        REST_XfleetVehicle.doPatch(req);
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }
}