@isTest
public with sharing class NAVCars_Test {
    private final static String TEST_VIN_NO = 'VR3FBYHZTMY528656';
    private final static String TEST_REG_NO = 'DF 75664';
    private final static String TEST_VAT_TYPE = 'VALUTA';
    private final static String TEST_DESCRIPTION = 'Yeti 2023';

    private final static String MOCK_SINGLE_CAR = 'NAVCars_SingleCarResponse';
    private final static String MOCK_MULTIPLE_CARS = 'NAVCars_MultipleCarResponse';
    private final static String MOCK_ERROR = 'NAVCars_ErrorResponse';

    @isTest
    public static void createCar() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_SINGLE_CAR);
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        // test the call out
        NAVCars navApi = new NAVCarsCreate();
        NAVCarsObject reqParams = new NAVCarsObject(TEST_VIN_NO, null, null, null, null);
        HttpRequest navApiReq = navApi.prepareRequest(reqParams);
        HttpResponse navApiResp = navApi.call(navApiReq);

        System.assertEquals(201, navApiResp.getStatusCode(), 'Expected Created/201 response code!');
    }

    @isTest
    public static void updateCar() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_SINGLE_CAR);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        // test the call out
        NAVCars navApi = new NAVCarsUpdate(TEST_VIN_NO);
        NAVCarsObject reqParams = new NAVCarsObject(TEST_VIN_NO, TEST_REG_NO, TEST_VAT_TYPE, TEST_DESCRIPTION, null);
        HttpRequest navApiReq = navApi.prepareRequest(reqParams);
        HttpResponse navApiResp = navApi.call(navApiReq);

        System.assertEquals(200, navApiResp.getStatusCode(), 'Expected OK Success/200 response code!');
    }

    @isTest
    public static void updateCarError() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_ERROR);
        mock.setStatusCode(400);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        // test the call out
        NAVCars navApi = new NAVCarsUpdate(TEST_VIN_NO);
        NAVCarsObject reqParams = new NAVCarsObject(TEST_VIN_NO, TEST_REG_NO, TEST_VAT_TYPE, TEST_DESCRIPTION, 5);
        HttpRequest navApiReq = navApi.prepareRequest(reqParams);
        HttpResponse navApiResp = navApi.call(navApiReq);

        System.assertEquals(400, navApiResp.getStatusCode(), 'Expected OK Success/200 response code!');
    }

    @isTest
    public static void getSingleCar() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_SINGLE_CAR);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        // test the call out
        NAVCarsGet navApi = new NAVCarsGet(TEST_VIN_NO);
        NAVCarsObject respParams = navApi.getSingleCar();

        System.assertEquals(TEST_VIN_NO, respParams.Vin_No, 'Expected VIN number in response(mock) is the same as requested!');
    }

    @isTest
    public static void getMultipleCars() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_MULTIPLE_CARS);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        // test the call out
        NAVCarsGet navApi = new NAVCarsGet();
        // get all cars
        Map<String, NAVCarsObject> respCars = navApi.getCars();
        System.assert(respCars.size() > 1, 'Expected more than 1 car!');

        // get cars using filter
        Map<String, NAVCarsObject> respCars2 = navApi.getCarsModifiedAfter(System.now().addDays(-7));
        System.assert(respCars2.size() > 1, 'Expected more than 1 car!');
    }

    @isTest
    public static void getMultipleCarsJustSingle() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_SINGLE_CAR);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        // test the call out
        NAVCarsGet navApi = new NAVCarsGet();
        // get all cars
        Map<String, NAVCarsObject> respCars = navApi.getCars();
        System.assertEquals(1, respCars.size(), 'Expected just 1 car!');
    }

    @isTest
    public static void getCarsErrors() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_ERROR);
        mock.setStatusCode(400);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        // test the call out
        NAVCarsGet navApi = new NAVCarsGet();
        // get all cars with Error
        try {
            Map<String, NAVCarsObject> respCars = navApi.getCars();
        } catch (NAVCars.NavisionCarsException navException) {
            System.assert(true);
        }
        // if any other exception is thrown then it is failed test

        // get single cars without providing VIN Error
        try {
            NAVCarsObject respCar = navApi.getSingleCar();
        } catch (NAVCars.NavisionCarsException navException) {
            System.assert(true);
        }
        // if any other exception is thrown then it is failed test

        // get single cars with API Error
        navApi = new NAVCarsGet(TEST_VIN_NO);
        try {
            NAVCarsObject respCar = navApi.getSingleCar();
        } catch (NAVCars.NavisionCarsException navException) {
            System.assert(true);
        }
        // if any other exception is thrown then it is failed test
    }
}