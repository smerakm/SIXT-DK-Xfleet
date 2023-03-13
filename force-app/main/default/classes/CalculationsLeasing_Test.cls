/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * test for CalculationsLeasing class
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-10-24
 * @modified       2022-10-24
 * @systemLayer    Test
 * @see            SIXT-57
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-10-24      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
@isTest
public with sharing class CalculationsLeasing_Test {
    @isTest
    public static void leasingAlgorithm1() {
        TestUtilitySIXT.createTaxCalculationSettings();

        CalculationsLeasing.CalculationLeasingInputs inputs = new CalculationsLeasing.CalculationLeasingInputs();
        inputs.algorithm = 1;
        inputs.interestRate = 0.0375;
        inputs.presentValue = 254330;

        // 12 months period
        inputs.futureValue = 223810;
        inputs.periodLength = 12;
        CalculationsLeasing.CalculationLeasingOutputs calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(3284.43, calcResult.leasingCostPerMonth.setScale(2), 'algorithm 1, 12 months, leasing cost shall be 3284.43 DKK');
        System.assertEquals(2543.33, calcResult.depricationPerMonth.setScale(2), 'algorithm 1, 12 months, deprication per month shall be 2543.33 DKK');
        System.assertEquals(741.10, calcResult.interestPerMonth.setScale(2), 'algorithm 1, 12 months, interest shall be 741.10 DKK');
    }

    @isTest
    public static void leasingAlgorithm2() {
        CalculationsLeasing.CalculationLeasingInputs inputs = new CalculationsLeasing.CalculationLeasingInputs();
        inputs.algorithm = 2;
        inputs.interestRate = 0.072;
        inputs.presentValue = 202468.76 ;

        // 4 months period
        inputs.futureValue = 183999.00;
        inputs.periodLength = 4;
        CalculationsLeasing.CalculationLeasingOutputs calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(5790.90, calcResult.leasingCostPerMonth.setScale(2), 'algorithm 2, 4 months, leasing cost shall be 5790.90 DKK');
        System.assertEquals(4617.44, calcResult.depricationPerMonth.setScale(2), 'algorithm 2, 4 months, deprication per month shall be 4617.44 DKK');
        System.assertEquals(1173.46, calcResult.interestPerMonth.setScale(2), 'algorithm 2, 4 months, interest shall be 1173.46 DKK');
    }

    @isTest
    public static void leasingInvocable() {
        CalculationsLeasing.CalculationLeasingInputs inputsFullTax = new CalculationsLeasing.CalculationLeasingInputs();
        inputsFullTax.algorithm = 1;
        inputsFullTax.interestRate = 0.0375;
        inputsFullTax.presentValue = 254330;
        // 12 months period
        inputsFullTax.futureValue = 223810;
        inputsFullTax.periodLength = 12;

        CalculationsLeasing.CalculationLeasingInputs inputsValuta = new CalculationsLeasing.CalculationLeasingInputs();
        inputsValuta.algorithm = 2;
        inputsValuta.interestRate = 0.072;
        inputsValuta.presentValue = 202468.76;
        // 4 months period
        inputsValuta.futureValue = 183999;
        inputsValuta.periodLength = 4;

        List<CalculationsLeasing.CalculationLeasingInputs> tstInputs = new List<CalculationsLeasing.CalculationLeasingInputs>();
        tstInputs.add(inputsFullTax);
        tstInputs.add(inputsValuta);

        List<CalculationsLeasing.CalculationLeasingOutputs> tstResults = CalculationsLeasing.calculateLeasingCost(tstInputs);
        System.assertEquals(2, tstResults.size(), 'we are expecting 2 calculated results');
        System.assertEquals(3284.43, tstResults[0].leasingCostPerMonth.setScale(2), 'INVOCABLE - 12 months, algorithm 1, leasing cost shall be 3284.43 DKK');
        System.assertEquals(5790.90, tstResults[1].leasingCostPerMonth.setScale(2), 'INVOCABLE - 4 months, algorithm 2, leasing cost shall be 5790.90 DKK');
    }

    @isTest
    public static void leasingUnspecifiedAlgorithm() {
        CalculationsLeasing.CalculationLeasingInputs inputs = new CalculationsLeasing.CalculationLeasingInputs();
        //inputs.algorithm = 999;
        inputs.interestRate = 0.025;
        inputs.presentValue = 335258;

        // 4 months period
        inputs.futureValue = 335257;
        inputs.periodLength = 4;
        CalculationsLeasing.CalculationLeasingOutputs calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(697, Math.round(calcResult.leasingCostPerMonth), '4 months Full Tax, leasing cost shall be 697 DKK');
    }
}