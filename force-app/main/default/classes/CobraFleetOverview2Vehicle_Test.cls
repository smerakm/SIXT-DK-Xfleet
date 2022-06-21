@isTest
public with sharing class CobraFleetOverview2Vehicle_Test {
    private static final Decimal INTERNAL_NUMBER_1 = 100;
    private static final String LICENSE_PLATE_1 = 'ABC001';
    private static final Decimal CURRENT_KM_1 = 1200;

    private static final Decimal INTERNAL_NUMBER_2 = 101;
    private static final String LICENSE_PLATE_2 = 'MRK007';
    private static final Decimal CURRENT_KM_2 = 2500;

    private static final Decimal INTERNAL_NUMBER_3 = 102;
    private static final String LICENSE_PLATE_3 = 'MRK10A';
    private static final Decimal CURRENT_KM_3 = 2500;
    private static final String COBRA_DEFLEETED_STATUS = '00-';

    @TestSetup
    static void makeData() {
        // Vehicles
        VehicleBatch__c testBatch = TestUtilitySIXT.createBatch();
        Map<String, Object> testVehicleParams = new Map<String, Object>{ 'Internal_Number__c' => INTERNAL_NUMBER_1 };
        TestUtilitySIXT.createVehicle(testBatch.Id, testVehicleParams);
        Map<String, Object> test2ndVehicleParams = new Map<String, Object>{ 'License_Plate__c' => LICENSE_PLATE_2 };
        TestUtilitySIXT.createVehicle(testBatch.Id, test2ndVehicleParams);
        // 3rd vehicle is in Cobra defleeted status already
        Map<String, Object> test3rdVehicleParams = new Map<String, Object>{
            'Internal_Number__c' => INTERNAL_NUMBER_3,
            'Current_KM__c' => CURRENT_KM_3,
            'License_Plate__c' => LICENSE_PLATE_3,
            'Vehicle_Status__c' => COBRA_DEFLEETED_STATUS
        };
        TestUtilitySIXT.createVehicle(testBatch.Id, test3rdVehicleParams);

        // Fleet Overviews
        Date importDate = Date.today();

        Fleet_Overview__c fo1 = new Fleet_Overview__c();
        fo1.City_name__c = 'Praha ha ha';
        fo1.KM__c = CURRENT_KM_1;
        fo1.Description__c = 'unit test car 100';
        fo1.Internal_No__c = INTERNAL_NUMBER_1;
        fo1.Registration__c = LICENSE_PLATE_1;
        fo1.Sixt_model__c = 123;
        fo1.Veh_status__c = 0;
        fo1.Import_Date__c = importDate;
        insert fo1;

        Fleet_Overview__c fo2 = new Fleet_Overview__c();
        fo2.City_name__c = 'Praha hi hi';
        fo2.KM__c = CURRENT_KM_2;
        fo2.Description__c = 'unit test car MRK007';
        fo2.Internal_No__c = INTERNAL_NUMBER_2;
        fo2.Registration__c = LICENSE_PLATE_2;
        fo2.Sixt_model__c = 123;
        fo2.Veh_status__c = 0;
        fo2.Import_Date__c = importDate;
        insert fo2;

        Fleet_Overview__c fo3 = new Fleet_Overview__c();
        fo3.City_name__c = 'Praha hi hi';
        fo3.KM__c = CURRENT_KM_3 - 100;
        fo3.Description__c = 'unit test car MRK10A';
        fo3.Internal_No__c = INTERNAL_NUMBER_3;
        fo3.Registration__c = LICENSE_PLATE_3;
        fo3.Sixt_model__c = 123;
        fo3.Veh_status__c = 0;
        fo3.Import_Date__c = importDate;
        insert fo3;
    }

    @isTest
    public static void onlyByInternalNumber() {
        List<Fleet_Overview__c> testFleetOverviews = [
            SELECT City_name__c, Description__c, Internal_No__c, KM__c, Registration__c, Sixt_model__c, Veh_status__c
            FROM Fleet_Overview__c
        ];

        Map<Decimal, Vehicle__c> testResults = CobraFleetOverview2VehicleUtility.updateVehiclesFromFleetOverviewList(testFleetOverviews, false, false);
        System.assertEquals(1, testResults.size());
        System.assert(testResults.containsKey(INTERNAL_NUMBER_1));
    }

    @isTest
    public static void usingLisencePlateToo() {
        List<Fleet_Overview__c> testFleetOverviews = [
            SELECT City_name__c, Description__c, Internal_No__c, KM__c, Registration__c, Sixt_model__c, Veh_status__c
            FROM Fleet_Overview__c
        ];

        Map<Decimal, Vehicle__c> testResults = CobraFleetOverview2VehicleUtility.updateVehiclesFromFleetOverviewList(testFleetOverviews, true, false);
        System.assertEquals(2, testResults.size());
        System.assert(testResults.containsKey(INTERNAL_NUMBER_1));
        System.assert(testResults.containsKey(INTERNAL_NUMBER_2));
    }

    // scheduler
    @isTest
    public static void cobraUpdateFromFleetOverviewScheduler() {
        String nextYear = String.valueOf(Date.today().year() + 1);
        Test.startTest();
        Id schedulerJobId = System.schedule('unitTestCobraFromFOUpdate', '0 0 0 1 1 ? ' + nextYear, new CobraFleetOverview2VehicleScheduler());
        Test.stopTest();
    }

    // test of batch class and process
    @isTest
    public static void cobraUpdateFromFleetOverviewBatch() {
        Test.startTest();
        Id testBatchJobId = Database.executeBatch(new CobraFleetOverview2VehicleBatch(Date.today()), 200);
        Test.stopTest();
        Vehicle__c veh1 = [SELECT Current_city__c, Current_KM__c FROM Vehicle__c WHERE Internal_number__c = :INTERNAL_NUMBER_1];
        System.assertEquals(CURRENT_KM_1, veh1.Current_KM__c, 'Kilometers not updated correctly on Vehicle 1');
        Vehicle__c veh2 = [SELECT Current_city__c, Current_KM__c FROM Vehicle__c WHERE Internal_number__c = :INTERNAL_NUMBER_2];
        System.assertEquals(CURRENT_KM_2, veh2.Current_KM__c, 'Kilometers not updated correctly on Vehicle 2');
        Vehicle__c veh3 = [SELECT Vehicle_Status__c, Current_KM__c FROM Vehicle__c WHERE Internal_number__c = :INTERNAL_NUMBER_3];
        System.assertEquals(CURRENT_KM_3, veh3.Current_KM__c, 'Kilometers shall not be updated on Vehicle 3');
        System.assertEquals(COBRA_DEFLEETED_STATUS, veh3.Vehicle_Status__c, 'Vehicle Status shall not be updated on Vehicle 3');
    }
}