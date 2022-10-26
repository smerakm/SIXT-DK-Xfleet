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
    public static void leasingL94() {
        TestUtilitySIXT.createTaxCalculationSettings();

        CalculationsLeasing.CalculationLeasingInputs inputs = new CalculationsLeasing.CalculationLeasingInputs();
        inputs.algorithm = 1;
        inputs.interestRate = 0.025;
        inputs.presentValue = 160816;
        inputs.registrationFee = 134238;
        inputs.taxType = 'DK - L94';

        // 4 months period
        inputs.futureValue = 160815;
        inputs.periodLength = 4;
        CalculationsLeasing.CalculationLeasingOutputs calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(3290, Math.round(calcResult.leasingCostPerMonth), '4 months L94, leasing cost shall be 3290 DKK');

        // 6 months period
        inputs.futureValue = 151167;
        inputs.periodLength = 6;
        calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(4415, Math.round(calcResult.leasingCostPerMonth), '6 months L94, leasing cost shall be 4415 DKK');

        // 9 months period
        inputs.futureValue = 146343;
        inputs.periodLength = 9;
        calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(4092, Math.round(calcResult.leasingCostPerMonth), '9 months L94, leasing cost shall be 4092 DKK');

        // 12 months period
        inputs.futureValue = 141518;
        inputs.periodLength = 12;
        calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(3924, Math.round(calcResult.leasingCostPerMonth), '12 months L94, leasing cost shall be 3924 DKK');
    }

    @isTest
    public static void leasingValuta() {
        CalculationsLeasing.CalculationLeasingInputs inputs = new CalculationsLeasing.CalculationLeasingInputs();
        inputs.algorithm = 1;
        inputs.interestRate = 0.025;
        inputs.presentValue = 160816;
        //inputs.registrationFee = 134238;
        inputs.taxType = 'Valuta';

        // 4 months period
        inputs.futureValue = 160815;
        inputs.periodLength = 4;
        CalculationsLeasing.CalculationLeasingOutputs calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(335, Math.round(calcResult.leasingCostPerMonth), '4 months Valuta, leasing cost shall be 335 DKK');

        // 6 months period
        inputs.futureValue = 151167;
        inputs.periodLength = 6;
        calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(1931, Math.round(calcResult.leasingCostPerMonth), '6 months Valuta, leasing cost shall be 1931 DKK');

        // 9 months period
        inputs.futureValue = 146343;
        inputs.periodLength = 9;
        calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(1926, Math.round(calcResult.leasingCostPerMonth), '9 months Valuta, leasing cost shall be 1926 DKK');

        // 12 months period
        inputs.futureValue = 141518;
        inputs.periodLength = 12;
        calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(1921, Math.round(calcResult.leasingCostPerMonth), '12 months Valuta, leasing cost shall be 1921 DKK');
    }

    @isTest
    public static void leasingFullTax() {
        CalculationsLeasing.CalculationLeasingInputs inputs = new CalculationsLeasing.CalculationLeasingInputs();
        inputs.algorithm = 1;
        inputs.interestRate = 0.025;
        inputs.presentValue = 335258;
        //	inputs.registrationFee = 134238;
        inputs.taxType = 'DK - Full tax';

        // 4 months period
        inputs.futureValue = 335257;
        inputs.periodLength = 4;
        CalculationsLeasing.CalculationLeasingOutputs calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(697, Math.round(calcResult.leasingCostPerMonth), '4 months Full Tax, leasing cost shall be 697 DKK');

        // 6 months period
        inputs.futureValue = 315143;
        inputs.periodLength = 6;
        calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(4025, Math.round(calcResult.leasingCostPerMonth), '6 months Full Tax, leasing cost shall be 4025 DKK');

        // 9 months period
        inputs.futureValue = 305085;
        inputs.periodLength = 9;
        calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(4015, Math.round(calcResult.leasingCostPerMonth), '9 months Full Tax, leasing cost shall be 4015 DKK');

        // 12 months period
        inputs.futureValue = 295027;
        inputs.periodLength = 12;
        calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(4004, Math.round(calcResult.leasingCostPerMonth), '12 months Full Tax, leasing cost shall be 4004 DKK');
    }

    @isTest
    public static void leasingInvocable() {
        CalculationsLeasing.CalculationLeasingInputs inputsFullTax = new CalculationsLeasing.CalculationLeasingInputs();
        inputsFullTax.algorithm = 1;
        inputsFullTax.interestRate = 0.025;
        inputsFullTax.presentValue = 335258;
        //	inputs.registrationFee = 134238;
        inputsFullTax.taxType = 'DK - Full tax';
        // 4 months period
        inputsFullTax.futureValue = 335257;
        inputsFullTax.periodLength = 4;

        CalculationsLeasing.CalculationLeasingInputs inputsValuta = new CalculationsLeasing.CalculationLeasingInputs();
        inputsValuta.algorithm = 1;
        inputsValuta.interestRate = 0.025;
        inputsValuta.presentValue = 160816;
        //inputs.registrationFee = 134238;
        inputsValuta.taxType = 'Valuta';
        // 9 months period
        inputsValuta.futureValue = 146343;
        inputsValuta.periodLength = 9;

        List<CalculationsLeasing.CalculationLeasingInputs> tstInputs = new List<CalculationsLeasing.CalculationLeasingInputs>();
        tstInputs.add(inputsFullTax);
        tstInputs.add(inputsValuta);

        List<CalculationsLeasing.CalculationLeasingOutputs> tstResults = CalculationsLeasing.calculateLeasingCost(tstInputs);
        System.assertEquals(2, tstResults.size(), 'we are expecting 2 calculated results');
        System.assertEquals(697, Math.round(tstResults[0].leasingCostPerMonth), 'INVOCABLE - 4 months Full Tax, leasing cost shall be 697 DKK');
        System.assertEquals(1926, Math.round(tstResults[1].leasingCostPerMonth), 'INVOCABLE - 9 months Valuta, leasing cost shall be 1926 DKK');
    }

    @isTest
    public static void leasingUnspecifiedAlgorithm() {
        CalculationsLeasing.CalculationLeasingInputs inputs = new CalculationsLeasing.CalculationLeasingInputs();
        //inputs.algorithm = 999;
        inputs.interestRate = 0.025;
        inputs.presentValue = 335258;
        //	inputs.registrationFee = 134238;
        inputs.taxType = 'DK - Full tax';

        // 4 months period
        inputs.futureValue = 335257;
        inputs.periodLength = 4;
        CalculationsLeasing.CalculationLeasingOutputs calcResult = CalculationsLeasing.calculateLeasingCost(inputs);
        System.assertEquals(697, Math.round(calcResult.leasingCostPerMonth), '4 months Full Tax, leasing cost shall be 697 DKK');
    }
}