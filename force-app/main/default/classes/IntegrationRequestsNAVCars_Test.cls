@isTest
public class IntegrationRequestsNAVCars_Test {
    public static final String TEST_VIN = 'VINUNIT78364';
    public static final String TEST_REG_NUM = 'RN 12345';

    private final static String MOCK_SINGLE_CAR = 'NAVCars_SingleCarResponse';
    private final static String MOCK_MULTIPLE_CARS = 'NAVCars_MultipleCarResponse';
    private final static String MOCK_ERROR = 'NAVCars_ErrorResponse';

    private final static String VEHICLE_QUERY = 'SELECT id, vinNumber__c, License_Plate_System__c, Batch_Distribution__c, Car_description_2__c, Current_KM__c FROM Vehicle__c WHERE vinNumber__c = :TEST_VIN';

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
        mock.setStaticResource(MOCK_SINGLE_CAR);
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        Vehicle__c veh = (Vehicle__c) Database.query(VEHICLE_QUERY);
        Integration_Request__c ir = new Integration_Request__c();
        ir.API_Method__c = IntegrationRequestsNAVCars.METHOD_CREATE;
        ir.Vehicle__c = veh.Id;
        IntegrationRequestsNAVCars testProcessor = new IntegrationRequestsNAVCars();
        Test.startTest();
        ir = testProcessor.process(ir, veh);
        Test.stopTest();
        System.assertEquals(IntegrationRequestsUtility.STATUS_SUCCESS, ir.Status__c, 'Wrong status set!');
    }

    @isTest
    public static void updateMethodTest() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_SINGLE_CAR);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        Vehicle__c veh = (Vehicle__c) Database.query(VEHICLE_QUERY);
        veh.Batch_Distribution__c = 'DK - Tax type not determined';
        Integration_Request__c ir = new Integration_Request__c();
        ir.API_Method__c = IntegrationRequestsNAVCars.METHOD_UPDATE;
        ir.Vehicle__c = veh.Id;
        IntegrationRequestsNAVCars testProcessor = new IntegrationRequestsNAVCars();
        Test.startTest();
        ir = testProcessor.process(ir, veh);
        Test.stopTest();
        System.assertEquals(IntegrationRequestsUtility.STATUS_SUCCESS, ir.Status__c, 'Wrong status set!');
    }

    @isTest
    public static void invoiceMethodTest() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_SINGLE_CAR);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        Vehicle__c veh = (Vehicle__c) Database.query(VEHICLE_QUERY);
        Integration_Request__c ir = new Integration_Request__c();
        ir.API_Method__c = IntegrationRequestsNAVCars.METHOD_INVOICE;
        ir.Vehicle__c = veh.Id;
        // construct data
        NAVCarsObject theData = new NAVCarsObject(
            125000,
            'unittestNAV2367',
            'B028232',
            null,
            1,
            false,
            'This is very long description of the vehicle tha50t shall be invoiced',
            349,
            'Non known dealer, Very long street 1234, New Hampshire, 19600'
        );
        ir.Data__c = JSON.serialize(theData, true);
        // test request processing
        IntegrationRequestsNAVCars testProcessor = new IntegrationRequestsNAVCars();
        Test.startTest();
        ir = testProcessor.process(ir, veh);
        Test.stopTest();
        System.assertEquals(IntegrationRequestsUtility.STATUS_SUCCESS, ir.Status__c, 'Wrong status set!');
    }

    @isTest
    public static void createMethodTestNegative() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_ERROR);
        mock.setStatusCode(401);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        Vehicle__c veh = (Vehicle__c) Database.query(VEHICLE_QUERY);
        Integration_Request__c ir = new Integration_Request__c();
        ir.API_Method__c = IntegrationRequestsNAVCars.METHOD_CREATE;
        ir.Vehicle__c = veh.Id;
        IntegrationRequestsNAVCars testProcessor = new IntegrationRequestsNAVCars();
        Test.startTest();
        ir = testProcessor.process(ir, veh);
        Test.stopTest();
        System.assertEquals(IntegrationRequestsUtility.STATUS_FAILED, ir.Status__c, 'Wrong status set!');
    }

    @isTest
    public static void methodNotSupportedNegative() {
        Vehicle__c veh = (Vehicle__c) Database.query(VEHICLE_QUERY);
        Integration_Request__c ir = new Integration_Request__c();
        ir.API_Method__c = 'UnitTest';
        ir.Vehicle__c = veh.Id;
        IntegrationRequestsNAVCars testProcessor = new IntegrationRequestsNAVCars();
        Test.startTest();
        ir = testProcessor.process(ir, veh);
        Test.stopTest();
        System.assertEquals(IntegrationRequestsUtility.STATUS_FAILED, ir.Status__c, 'Wrong status set!');
    }
}