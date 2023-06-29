@isTest
public class IntegrationRequestsAutoITVehicle_Test {
    public static final String TEST_VIN = 'VINUNIT78364';
    public static final String TEST_REG_NUM = 'RN 12345';
    public static final String TEST_VEHICLE_AUTODESKTOP_ID = '4987912345';

    private final static String MOCK_OK = 'AutoITVehicles_BasicResponse';

    private final static String VEHICLE_QUERY = 'SELECT ' + Label.Xfleet_Integration_Request_Vehicle_Fields + ' FROM Vehicle__c WHERE vinNumber__c = :TEST_VIN';

    @TestSetup
    static void makeData() {
        // Xfleet dependency on Vehicle__c
        Map<String, Object> vehParams = new Map<String, Object>{ 'vinNumber__c' => TEST_VIN, 'license_plate__c' => TEST_REG_NUM };
        Vehicle__c testVehicle = TestUtilitySIXT.createVehicle(TestUtilitySIXT.createBatch().Id, vehParams);
    }

    @isTest
    public static void createMethodTest() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_OK);
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        Vehicle__c veh = (Vehicle__c) Database.query(VEHICLE_QUERY);
        Integration_Request__c ir = new Integration_Request__c();
        ir.API_Method__c = IntegrationRequestsAutoITVehicle.METHOD_INSERT;
        ir.Vehicle__c = veh.Id;
        IntegrationRequestsAutoITVehicle testProcessor = new IntegrationRequestsAutoITVehicle();
        Test.startTest();
        ir = testProcessor.process(ir, veh);
        Test.stopTest();
        System.assertEquals(IntegrationRequestsUtility.STATUS_SUCCESS, ir.Status__c, 'Wrong status set!');
    }

    @isTest
    public static void updateMethodTest() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_OK);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        Vehicle__c veh = (Vehicle__c) Database.query(VEHICLE_QUERY);
        veh.AutoDesktop_Id__c = TEST_VEHICLE_AUTODESKTOP_ID;
        Integration_Request__c ir = new Integration_Request__c();
        ir.API_Method__c = IntegrationRequestsAutoITVehicle.METHOD_UPDATE;
        ir.Vehicle__c = veh.Id;
        IntegrationRequestsAutoITVehicle testProcessor = new IntegrationRequestsAutoITVehicle();
        Test.startTest();
        ir = testProcessor.process(ir, veh);
        Test.stopTest();
        System.assertEquals(IntegrationRequestsUtility.STATUS_SUCCESS, ir.Status__c, 'Wrong status set!');
    }

    @isTest
    public static void markAsSoldTest() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_OK);
        mock.setStatusCode(204);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        Vehicle__c veh = (Vehicle__c) Database.query(VEHICLE_QUERY);
        veh.AutoDesktop_Id__c = TEST_VEHICLE_AUTODESKTOP_ID;
        Integration_Request__c ir = new Integration_Request__c();
        ir.API_Method__c = IntegrationRequestsAutoITVehicle.METHOD_STATUS_UPDATE;
        ir.Vehicle__c = veh.Id;
        IntegrationRequestsAutoITVehicle testProcessor = new IntegrationRequestsAutoITVehicle();
        Test.startTest();
        ir = testProcessor.process(ir, veh);
        Test.stopTest();
        System.assertEquals(IntegrationRequestsUtility.STATUS_SUCCESS, ir.Status__c, 'Wrong status set!');
    }

    @isTest
    public static void deleteTest() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_OK);
        mock.setStatusCode(204);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        Vehicle__c veh = (Vehicle__c) Database.query(VEHICLE_QUERY);
        veh.AutoDesktop_Id__c = TEST_VEHICLE_AUTODESKTOP_ID;
        Integration_Request__c ir = new Integration_Request__c();
        ir.API_Method__c = IntegrationRequestsAutoITVehicle.METHOD_DELETE;
        ir.Vehicle__c = veh.Id;
        IntegrationRequestsAutoITVehicle testProcessor = new IntegrationRequestsAutoITVehicle();
        Test.startTest();
        ir = testProcessor.process(ir, veh);
        Test.stopTest();
        System.assertEquals(IntegrationRequestsUtility.STATUS_SUCCESS, ir.Status__c, 'Wrong status set!');
    }
}
