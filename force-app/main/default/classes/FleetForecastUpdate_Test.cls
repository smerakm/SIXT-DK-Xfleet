/* test class to test all classes related to FleetForecastUpdate:
 * - FleetForecastUpdateUtility
 * - FleetForecastUpdateBatch
 */
@isTest
public with sharing class FleetForecastUpdate_Test {
    @TestSetup
    static void makeData() {
        VehicleBatch__c testBatch = TestUtilitySIXT.createBatch();
        Vehicle_Group__c vg = [SELECT Id FROM Vehicle_Group__c]; //  there is just one vehicle group
        Map<String, Object> vehicleParams = new Map<String, Object>{
            'Acriss_code__c' => TestUtilitySIXT.ACCRIS_CODE,
            'Planned_Infleet_Date__c' => Date.today().addMonths(1),
            'Vehicle_Group__c' => vg.Id
        };
        TestUtilitySIXT.createVehicle(testBatch.Id, vehicleParams);
    }

    @isTest
    public static void fleetForecastBatch() {
        // test data
        // Fleet forecast - next month
        Vehicle_Group__c vg = [SELECT Id FROM Vehicle_Group__c];
        Date firstDayNextMonth = Date.today().addMonths(1).toStartOfMonth();
        Date lastDayNextMonth = Date.today().addMonths(2).toStartOfMonth().addDays(-1);
        Map<String, Object> ffParams = new Map<String, Object>{
            'Short_Term_DK__c' => 5,
            'Long_Term_DK__c' => 0,
            'Short_Term_Valuta__c' => 0,
            'Long_Term_Valuta__c' => 1
        };
        TestUtilitySIXT.createFleetForecast(vg.Id, firstDayNextMonth, lastDayNextMonth, ffParams);
        Test.startTest();
        Id batchJobId = Database.executeBatch(new FleetForecastUpdateBatch(), 200);
        Test.stopTest();
        Fleet_Forecast__c ffResult = [SELECT Infleet_DK__c, Defleet_DK__c, Current_fleet_DK__c FROM Fleet_Forecast__c LIMIT 1];
        System.assertEquals(1, ffResult.Infleet_DK__c, 'One vehicle shall be infleeted in the period!');
        System.assertEquals(0, ffResult.Current_fleet_DK__c, 'No vehicle at the period start is expected!');
    }
}