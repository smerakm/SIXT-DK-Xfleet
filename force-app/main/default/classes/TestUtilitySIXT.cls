/**
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Test utility class.
 * Utility methods to create common data structure for testing.
 *
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-04-01
 * @modified       2022-04-01
 * @systemLayer    Automatization
 * @see            SIX-4
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-04-01      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
@isTest
public with sharing class TestUtilitySIXT {
    public final static String ACCRIS_CODE = 'ECAE';
    public final static String VEHICLE_GROUP_NAME = 'Group Unit Test + ' + ACCRIS_CODE;
    public final static String SERVICE_GROUP_NAME = 'Group Unit SERVICE Test + ' + ACCRIS_CODE;
    public final static String BATCH_DESCRIPTION = 'This is Unit Test 534ui';

    // creates batch together with vehicle group and other required objects
    public static vehicleBatch__c createBatch() {
        // Service and Damage Group
        Service_and_Damage_Group__c sdGroup = createServiceAndDamageSetup(SERVICE_GROUP_NAME);
        // Vehicle Group
        Vehicle_Group__c vGroup = createVehicleGroup(VEHICLE_GROUP_NAME, ACCRIS_CODE, sdGroup.Id);
        // Batch record
        return createBatch(BATCH_DESCRIPTION, vGroup.Id);
    }

    // create batch for specified vehicle group and description
    public static vehicleBatch__c createBatch(String batchDescription, Id vehicleGroupId) {
        // Vehicle batch
        VehicleBatch__c testBatch = new VehicleBatch__c();
        testBatch.Description__c = batchDescription;
        insert testBatch;
        return testBatch;
    }

    // create Service_and_Damage_Group__c and related Service and Damage Costs
    public static Service_and_Damage_Group__c createServiceAndDamageSetup(String groupName) {
        // Service and Damage Group
        Service_and_Damage_Group__c sdGroup = new Service_and_Damage_Group__c();
        sdGroup.Name = groupName;
        insert sdGroup;
        // Service and Damage Costs
        List<ServiceAndDamageCost__c> damageAndServiceMatrix = new List<ServiceAndDamageCost__c>();
        Decimal baseDamage = 1000;
        Decimal baseService = 200;
        for (Integer i = 1; i <= 36; i++) {
            ServiceAndDamageCost__c singleMonth = new ServiceAndDamageCost__c();
            singleMonth.Period_Month__c = i;
            singleMonth.Service_and_Damage_Group__c = sdGroup.Id;
            singleMonth.Damage_Cost__c = baseDamage - (i * 10);
            if (i > 12) {
                singleMonth.Tyres_Service_Cost__c = baseService;
            } else {
                singleMonth.Tyres_Service_Cost__c = 0;
            }
            damageAndServiceMatrix.add(singleMonth);
        }
        insert damageAndServiceMatrix;
        return sdGroup;
    }

    // create a vehicle group with specified accris codes
    public static Vehicle_Group__c createVehicleGroup(String groupName, String codes, Id sdGroupId) {
        Vehicle_Group__c vGroup = new Vehicle_Group__c();
        vGroup.Name = groupName;
        vGroup.Codes__c = codes;
        vGroup.Service_and_Damage_Group__c = sdGroupId;
        insert vGroup;
        return vGroup;
    }

    public static Fleet_Forecast__c createFleetForecast(Id vehicleGroupId, Date firstDay, Date lastDay, Map<String, Object> params) {
        Fleet_Forecast__c ff = new Fleet_Forecast__c();
        ff.Vehicle_Group__c = vehicleGroupId;
        ff.First_Day__c = firstDay;
        ff.Last_Day__c = lastDay;
        for (String fieldName : params.keySet()) {
            ff.put(fieldName, params.get(fieldName));
        }
        // required fields
        ff.Year__c = String.valueOf(firstDay.year());
        Integer theMonth = firstDay.month();
        if (theMonth < 10) {
            ff.Month__c = '0'+theMonth;
        } else {
            ff.Month__c = String.valueOf(theMonth);
        }
        insert ff;
        return ff;
    }

    // tax calculation settings
    public static TaxCalculation__c createTaxCalculationSettings() {
        // custom settings for tax calculation
        TaxCalculation__c taxSetup = new TaxCalculation__c(
            Interest_Rate__c = 2.1,
            Period_1_Length__c = 3,
            Period_1_Rate__c = 2,
            Period_2_Length__c = 33,
            Period_2_Rate__c = 1,
            Last_Period_Rate__c = 0.5
        );
        insert taxSetup;
        return taxSetup;
    }

    // create a vehicle
    public static Vehicle__c createVehicle(Id batchId, Map<String, Object> params) {
        Vehicle__c testVehicle = new Vehicle__c();
        testVehicle.Vehicle_Batch__c = batchId;
        for (String fieldName : params.keySet()) {
            testVehicle.put(fieldName, params.get(fieldName));
        }
        insert testVehicle;
        return testVehicle;
    }
}