/* test class to test all classes related to VehicleGroupUpdate:
 * - VehicleGroupUtility
 * - VehicleGroupUpdateBatchable
 * - VehicleGroupUpdateScheduler
 */
@isTest
public with sharing class VehicleGroupUpdate_Test {
    @TestSetup
    static void makeData() {
        VehicleBatch__c testBatch = TestUtilitySIXT.createBatch();
        Map<String, Object> vehicleParams = new Map<String, Object>{ 'Acriss_code__c' => TestUtilitySIXT.ACCRIS_CODE };
        TestUtilitySIXT.createVehicle(testBatch.Id, vehicleParams);
    }

    // utility class test
    @isTest
    public static void calculateGroup() {
        Vehicle_Group__c testGroup = [SELECT Id FROM Vehicle_Group__c WHERE Name = :TestUtilitySIXT.VEHICLE_GROUP_NAME LIMIT 1];
        Map<String, Vehicle_Group__c> testMap = VehicleGroupUtility.getAcriss2VehicleGroupMap();
        System.assertEquals(testGroup.Id, testMap.get(TestUtilitySIXT.ACCRIS_CODE).Id, 'map from Acriss code to Vehicle Group is not correct');
    }

    // scheduler
    @isTest
    public static void vehicleGroupUpdateSchedulerTest() {
        String nextYear = String.valueOf(Date.today().year() + 1);
        Test.startTest();
        Id schedulerJobId = System.schedule('unitTestVehicleGroupUpdate', '0 0 0 1 1 ? ' + nextYear, new VehicleGroupUpdateScheduler());
        Test.stopTest();
    }

    // test of batch class and process
    @isTest
    public static void vehicleGroupUpdateBatchTest() {
        Test.startTest();
        Id testBatchJobId = Database.executeBatch(new VehicleGroupUpdateBatchable(), 200);
        Test.stopTest();
        Vehicle__c veh = [SELECT Vehicle_Group__r.Name FROM Vehicle__c WHERE ACRISS_Code__c = :TestUtilitySIXT.ACCRIS_CODE LIMIT 1];
        System.assertEquals(TestUtilitySIXT.VEHICLE_GROUP_NAME, veh.Vehicle_Group__r.Name, 'Vehicle Group has not been assigned or wrongly assigned!');
    }
}