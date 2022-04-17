/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * test for CalculationsHoldingCost class
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-03-16
 * @modified       2022-03-16
 * @systemLayer    Test
 * @see            SIX-177
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-03-14      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
@isTest
private class CalculationsHoldingCost_Test {
    // test constants
    private static final String DAMAGE_GROUP_NAME = 'Unit test damage group';

    @TestSetup
    static void makeData() {
        TestUtilitySIXT.createTaxCalculationSettings();
        TestUtilitySIXT.createServiceAndDamageSetup(TestUtilitySIXT.SERVICE_GROUP_NAME);
    }

    @isTest
    public static void readDamageAndServiceConfig() {
        Service_and_Damage_Group__c damageGroup = [SELECT Id FROM Service_and_Damage_Group__c WHERE NAME = :TestUtilitySIXT.SERVICE_GROUP_NAME LIMIT 1];
        Map<Integer, CalculationsHoldingCost.DamageAndServiceWrapper> testConfig = CalculationsHoldingCost.readDamageAndServiceSettings(damageGroup.Id);
        System.assert(testConfig != null && !testConfig.isEmpty(), 'failed to read damage and service matrix!');
        // 13th month
        // damage 990+980+970+960+950+940+930+920+910+900+890+880 = 12090
        // service 0...0 + 200 = 200
        System.assertEquals(12090, testConfig.get(13).damageAccumulated);
        System.assertEquals(200, testConfig.get(13).serviceAccumulated);
        // cache test - to test retrieving the config from memory instead of new query
        Map<Integer, CalculationsHoldingCost.DamageAndServiceWrapper> testConfig2 = CalculationsHoldingCost.readDamageAndServiceSettings(damageGroup.Id);
        System.assertEquals(testConfig.size(), testConfig2.size());
    }

    @isTest
    public static void readDamageAndServiceConfigNegativeHole() {
        Service_and_Damage_Group__c damageGroup = [SELECT Id FROM Service_and_Damage_Group__c WHERE NAME = :TestUtilitySIXT.SERVICE_GROUP_NAME LIMIT 1];
        // create a hole in the config
        ServiceAndDamageCost__c fifthMonth = [
            SELECT Period_Month__c, Damage_Cost__c, Tyres_Service_Cost__c
            FROM ServiceAndDamageCost__c
            WHERE Service_and_Damage_Group__c = :damageGroup.Id AND Period_Month__c = 5
        ];
        delete fifthMonth;
        try {
            Map<Integer, CalculationsHoldingCost.DamageAndServiceWrapper> testConfig = CalculationsHoldingCost.readDamageAndServiceSettings(damageGroup.Id);
            System.assert(false, 'Holding Cost Exception should be thrown because of hole in the configuration!');
        } catch (CalculationsHoldingCost.HoldingCostException hce) {
            System.debug(LoggingLevel.DEBUG, 'expected exception: ' + hce.getMessage());
        }
    }

    @isTest
    public static void readDamageAndServiceConfigNegativeDouble() {
        Service_and_Damage_Group__c damageGroup = [SELECT Id FROM Service_and_Damage_Group__c WHERE NAME = :TestUtilitySIXT.SERVICE_GROUP_NAME LIMIT 1];
        // create a hole in the config
        ServiceAndDamageCost__c fifthMonth = [
            SELECT Period_Month__c, Damage_Cost__c, Tyres_Service_Cost__c, Service_and_Damage_Group__c
            FROM ServiceAndDamageCost__c
            WHERE Service_and_Damage_Group__c = :damageGroup.Id AND Period_Month__c = 5
        ];
        ServiceAndDamageCost__c fifthMonthDouble = fifthMonth.clone();
        insert fifthMonthDouble;

        try {
            Map<Integer, CalculationsHoldingCost.DamageAndServiceWrapper> testConfig = CalculationsHoldingCost.readDamageAndServiceSettings(damageGroup.Id);
            System.assert(false, 'Holding Cost Exception should be thrown because of duplicate row!');
        } catch (CalculationsHoldingCost.HoldingCostException hce) {
            System.debug(LoggingLevel.DEBUG, 'expected exception: ' + hce.getMessage());
        }
    }

    @isTest
    public static void readDamageAndServiceConfigNegativeNonExisting() {
        try {
            Map<Integer, CalculationsHoldingCost.DamageAndServiceWrapper> testConfig = CalculationsHoldingCost.readDamageAndServiceSettings(
                Id.valueOf('a1E0Q000001IPFLUA4')
            );
            System.assert(false, 'Holding Cost Exception should be thrown because of config does not exist for the a1E0Q000001IPFLUA4 group!');
        } catch (CalculationsHoldingCost.HoldingCostException hce) {
            System.debug(LoggingLevel.DEBUG, 'expected exception: ' + hce.getMessage());
        }
    }

    @isTest
    static void holdingCostCalculation() {
        Service_and_Damage_Group__c damageGroup = [SELECT Id FROM Service_and_Damage_Group__c WHERE NAME = :TestUtilitySIXT.SERVICE_GROUP_NAME LIMIT 1];
        // values are based on custom settings params in makeData() method, 1st period 3 months 2%, 2nd period 33 months 1%, last period 0.5%
        List<CalculationsHoldingCost.CalculationHoldingCostInputs> testInputsList = new List<CalculationsHoldingCost.CalculationHoldingCostInputs>();
        CalculationsHoldingCost.CalculationHoldingCostInputs testInputs = new CalculationsHoldingCost.CalculationHoldingCostInputs();
        testInputs.periodLength = 13;
        testInputs.registrationFee = 92550;
        testInputs.vehicleAge = 0;
        //testInputs.carGroup = CAR_GROUP;
        testInputs.vehicleDamageGroup = damageGroup.Id;
        testInputsList.add(testInputs);
        // calculate
        CalculationsHoldingCost.CalculationHoldingCostOutputs testResults = CalculationsHoldingCost.calculateHoldingCost(testInputsList).get(0);
        // assertion
        System.assertEquals(12090, testResults.damage, 'Accumulated damage cost shall be 12 090!');
        System.assertEquals(200, testResults.serviceAndTyres, 'Accumulated service cost shall be 200!');
        System.assertEquals(14808, testResults.registrationTaxL94, 'registration fee L94 shall be 14 808!');
    }
}