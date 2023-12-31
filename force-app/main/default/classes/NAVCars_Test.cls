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

    @isTest
    public static void invocableMethods() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_SINGLE_CAR);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        // test the call out
        NAVCarsInvocable.NavisionCarsRequest navRequest = new NAVCarsInvocable.NavisionCarsRequest();
        navRequest.callMethod = 'CREATE';
        navRequest.vinNumber = 'UNITA423452';
        navRequest.registrationNumber = 'LA12344';
        navRequest.vatType = 'Valuta';
        navRequest.vehicleDescription = 'unit test';
        navRequest.currentKm = 100;

        // CREATE
        List<NAVCarsInvocable.NavisionCarsResult> results = NAVCarsInvocable.callNavisionCarsApi(new List<NAVCarsInvocable.NavisionCarsRequest>{ navRequest });
        System.assertEquals(1, results.size());

        // UPDATE
        navRequest.callMethod = 'UPDATE';
        results = NAVCarsInvocable.callNavisionCarsApi(new List<NAVCarsInvocable.NavisionCarsRequest>{ navRequest });
        System.assertEquals(1, results.size());

        // UPDATE - invoice
        navRequest.callMethod = 'UPDATE';
        navRequest.amount = 199;
        navRequest.extDocNo = 'lsf';
        navRequest.addToDoc = false;
        navRequest.accNumberInvoice = 'DF234';
        navRequest.pickupLocation = 'Korvvagen 123';
        results = NAVCarsInvocable.callNavisionCarsApi(new List<NAVCarsInvocable.NavisionCarsRequest>{ navRequest });
        System.assertEquals(1, results.size());

        // GET
        navRequest.callMethod = 'GET';
        results = NAVCarsInvocable.callNavisionCarsApi(new List<NAVCarsInvocable.NavisionCarsRequest>{ navRequest });
        System.assertEquals(1, results.size());

        // GET - params
        navRequest.callMethod = 'GET';
        navRequest.filterValue = 'created eq TODAY';
        results = NAVCarsInvocable.callNavisionCarsApi(new List<NAVCarsInvocable.NavisionCarsRequest>{ navRequest });
        System.assertEquals(1, results.size());
    }

    @isTest
    public static void invocableMethodsError() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_ERROR);
        mock.setStatusCode(400);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        // test the call out
        NAVCarsInvocable.NavisionCarsRequest navRequest = new NAVCarsInvocable.NavisionCarsRequest();
        navRequest.callMethod = 'CREATE';
        navRequest.vinNumber = 'UNITA423452';
        navRequest.registrationNumber = 'LA12344';
        navRequest.vatType = 'Valuta';
        navRequest.vehicleDescription = 'unit test';
        navRequest.currentKm = 100;

        // CREATE
        try {
            List<NAVCarsInvocable.NavisionCarsResult> results = NAVCarsInvocable.callNavisionCarsApi(
                new List<NAVCarsInvocable.NavisionCarsRequest>{ navRequest }
            );
        } catch (NAVCars.NavisionCarsException navException) {
            System.assert(true);
        }
    }

    @isTest
    public static void navCarObjectTest() {
        // basic vehicle update
        NAVCarsObject obj1 = new NAVCarsObject('TESTVIN321khj41', 'DC12121', 'DK - L94', 'unit test', 333);
        System.assertEquals('L94', obj1.vatType, 'wrong conversion of Xlfeet VAT type to NAV VAT Type!');
        System.assertEquals('L94', obj1.convertToNAVVatType(), 'wrong conversion of Xlfeet VAT type to NAV VAT Type! (object method)');
        // normal invoice
        String testAddress = 'This is a very long address, that is over 50 characters, and was created in, Sweden, 112 88';
        NAVCarsObject obj2 = new NAVCarsObject(12345.678, 'myTestDoc1', 'UT1234', null, 2, false, 'unit test desc', 333, testAddress);
        System.assertEquals(50, obj2.createPickupAddr.length(), 'Address is not shortened to 50 chars!');
        // AutoDesktop invoice
        NAVCarsObject obj3 = new NAVCarsObject(
            'myTestDoc1',
            'unit test desc',
            333,
            1422312,
            1232,
            45453,
            3433,
            20000,
            'roof window',
            'EX12345',
            98234,
            'Marek',
            testAddress,
            'c/o Abc',
            '112 88',
            'STLM',
            null,
            null,
            null,
            null,
            null
        );
        System.assertEquals(50, obj3.createOwnerAddress1.length(), 'Owner address line 1 is not shortened to 50 chars!');

        // all vat type conversion
        System.assertEquals('L94', obj1.convertToNAVVatType('DK - L94'), 'wrong VAT Type conversion, L94!');
        System.assertEquals('VALUTA', obj1.convertToNAVVatType('Valuta'), 'wrong VAT Type conversion, VALUTA!');
        System.assertEquals('FULD MOMS', obj1.convertToNAVVatType('DK - Full tax'), 'wrong VAT Type conversion, FULD MOMS!');
        System.assertEquals(null, obj1.convertToNAVVatType('DK - Tax type not determined'), 'wrong VAT Type conversion, DK not determined!');
        System.assertEquals('skip', obj1.convertToNAVVatType('skip'), 'wrong VAT Type conversion, skip conversion!');
        System.assertEquals(null, obj1.convertToNAVVatType(null), 'wrong VAT Type conversion, null value!');
    }
}