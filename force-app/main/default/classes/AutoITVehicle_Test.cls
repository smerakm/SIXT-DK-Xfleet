@isTest
public with sharing class AutoITVehicle_Test {
    private final static String TEST_VIN_NO = 'VR3FBYHZTMY528656';
    private final static String TEST_REG_NO = 'DF 75664';
    private final static String TEST_VAT_TYPE = 'VALUTA';
    private final static String TEST_DESCRIPTION = 'Yeti 2023';
    private final static String TEST_AUTODESKTOP_VEHICLE_ID = '1562023';

    private final static String MOCK_OK = 'AutoITVehicles_BasicResponse';

    @isTest
    public static void createCar() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_OK);
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        // test data
        Vehicle__c tstVehicle = new Vehicle__c();
        tstVehicle.vinNumber__c = TEST_VIN_NO;
        tstVehicle.License_plate__c = TEST_REG_NO;
        tstVehicle.First_Registration_Date__c = Date.today();

        // test the call out
        AutoITVehicle autoITApi = new AutoITVehicleCreate();
        AutoITVehicleObject reqParams = new AutoITVehicleObject(tstVehicle);
        HttpRequest autoITApiReq = autoITApi.prepareRequest(reqParams);
        HttpResponse autoITApiResp = autoITApi.call(autoITApiReq);

        System.assertEquals(201, autoITApiResp.getStatusCode(), 'Expected Created/201 response code!');

        autoITApi.processResponse(autoITApiResp.getBody(), tstVehicle.Id);
        // Vehicle__c tstVehicleAfter = [SELECT AutoDesktop_Id__c FROM Vehicle__c WHERE Id = :tstVehicle.Id];
        // System.assert(tstVehicleAfter.AutoDesktop_Id__c != null);
    }

    @isTest
    public static void updateCar() {
        // Use StaticResourceCalloutMock built-in class to set mock response
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(MOCK_OK);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        // test data
        Vehicle__c tstVehicle = new Vehicle__c();
        tstVehicle.vinNumber__c = TEST_VIN_NO;
        tstVehicle.License_plate__c = TEST_REG_NO;
        tstVehicle.First_Registration_Date__c = Date.today();

        // test the call out
        AutoITVehicle autoITApi = new AutoITVehicleUpdate(TEST_AUTODESKTOP_VEHICLE_ID);
        AutoITVehicleObject reqParams = new AutoITVehicleObject(tstVehicle);
        HttpRequest autoITApiReq = autoITApi.prepareRequest(reqParams);
        HttpResponse autoITApiResp = autoITApi.call(autoITApiReq);

        System.assertEquals(200, autoITApiResp.getStatusCode(), 'Expected Updated/200 response code!');
    }

    @isTest
    public static void objectTest() {
        Vehicle__c tstVehicle = new Vehicle__c();
        tstVehicle.vinNumber__c = TEST_VIN_NO;
        tstVehicle.License_plate__c = TEST_REG_NO;
        tstVehicle.Model_Name__c = 'XC60';
        AutoITVehicleObject tstObject = new AutoITVehicleObject(tstVehicle);
        tstObject.absoluteDivestitureAuction = false;
        tstObject.additionalVariantDesignation = 'unitTest';
        tstObject.bodyAdditionalDesignation = 'unitTest';
        tstObject.bodyLengthTypeId = 'unitTest';
        tstObject.bodyTypeId = 1;
        tstObject.bodyTypeName = 'unitTest';
        tstObject.brandId = 1;
        tstObject.brandName = 'unitTest';
        tstObject.colorId = 1;
        tstObject.colorName = 'unitTest';
        tstObject.colorOwnDescription = 'unitTest';
        tstObject.comments = 'unitTest';
        tstObject.commissionNumber = 'unitTest';
        tstObject.currentResponsibleUserId = 1;
        tstObject.dealerReferenceNumber = 'unitTest';
        tstObject.deeplink = 'unitTest';
        tstObject.deliveryCostsRetailDKK = 1.2;
        tstObject.description = 'unitTest';
        tstObject.dkTypeApprovalCertificateNumber = 1;
        tstObject.dkTypeApprovalVariantNumber = 2;
        tstObject.dmrMakeModelVariantTypeId = 'unitTest';
        tstObject.dmrVehicleIdentifier = 'unitTest';
        tstObject.doorCount = 1;
        tstObject.drivingWheelId = 'unitTest';
        tstObject.edbNumber = 'unitTest';
        tstObject.efTypeApprovalNumber = 'unitTest';
        tstObject.engineAdditionalDesignation = 'unitTest';
        tstObject.engineSizeLitresDesignation = 'unitTest';
        tstObject.equipmentLevelDesignation = 'unitTest';
        tstObject.equipmentlist = 'unitTest';
        tstObject.expectedRegistrationTax = 1.2;
        tstObject.externalId = 'unitTest';
        tstObject.exVat = true;
        tstObject.firstRegistrationDay = 1;
        tstObject.firstRegistrationMonth = 1;
        tstObject.firstRegistrationYear = 1970;
        tstObject.fuelTypeId = 'unitTest';
        tstObject.gearCount = 1;
        tstObject.importerCode = 'unitTest';
        tstObject.inventoryDate = Date.today();
        tstObject.isTradeInVehicle = true;
        tstObject.lastVehicleInspection = Date.today().addYears(-1);
        tstObject.makeModelVariant = 'unitTest';
        tstObject.maximumEffectHP = 1;
        tstObject.mileage = 1;
        tstObject.modelAdditionalDesignation = 'unitTest';
        tstObject.modelId = 1;
        tstObject.modelName = 'unitTest';
        tstObject.modelSerieName = 'unitTest';
        tstObject.modelVariantId = 1;
        tstObject.modelYear = 1983;
        tstObject.newOrUsed = 1;
        tstObject.numberplateCostsDKK = 1.2;
        tstObject.priceLowestAuctionDKK = 1.2;
        tstObject.priceRetailDKK = 1.2;
        tstObject.priceRetailExRegistrationTax = 1.2;
        tstObject.priceRetailVatDKK = 1.2;
        tstObject.priceRetailWithoutRegistrationTax = true;
        tstObject.priceWholesaleDKK = 1.2;
        tstObject.regNo = 'unitTest';
        tstObject.repurchasePrice = 1.2;
        tstObject.salesPrice = 1.2;
        tstObject.seatCount = 1;
        tstObject.showOnAftermarketList = false;
        tstObject.showOnSalesList = false;
        tstObject.tecDocKTypeNumber = 1;
        tstObject.transmissionAdditionalDesignation = 'unitTest';
        tstObject.transmissionTypeId = 1;
        tstObject.transmissionTypeName = 'unitTest';
        tstObject.trueToModelVariantRegister = false;
        tstObject.typeId = 1;
        tstObject.typeName = 'unitTest';
        tstObject.vehicleInspectionMonth = 1;
        tstObject.vehicleInspectionPeriodicBasisMonth = 1;
        tstObject.vehicleInspectionPeriodicBasisYear = 1981;
        tstObject.vehicleInspectionPeriodicIntervalMonths = 12;
        tstObject.vehicleInspectionPeriodicRequirement = true;
        tstObject.vehicleInspectionYear = 2023;
        tstObject.vin = TEST_VIN_NO;
        tstObject.vinYear = 2000;
    }
}