/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * test for CalculationsLeasingResidualValue class
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2023-02-07
 * @modified       2023-02-07
 * @systemLayer    Test
 * @see            SIXT-54
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2023-02-07      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
@isTest
public with sharing class CalculationsLeasingResidualValue_Test {
    @isTest
    public static void algorithm1Test() {
        CalculationsLeasingResidualValue.CalculationResidualValueInputs tstInputs = new CalculationsLeasingResidualValue.CalculationResidualValueInputs();
        tstInputs.algorithm = 1;
        tstInputs.interestRate = 0.0375;
        tstInputs.isL94 = false;
        tstInputs.monthlyPayment = 3284.43;
        tstInputs.presentValue = 254330.00;

        CalculationsLeasingResidualValue.CalculationResidualValueOutputs tstOutputs;
        // 0 months
        tstInputs.periodLength = 0;
        tstOutputs = CalculationsLeasingResidualValue.calculateResidualValue(tstInputs);
        System.assertEquals(254330.00, tstOutputs.residualValue.setScale(2), 'Residual value after 0 months shall be 254330 DKK! Alg 1');

        // 6 months
        tstInputs.periodLength = 6;
        tstOutputs = CalculationsLeasingResidualValue.calculateResidualValue(tstInputs);
        System.assertEquals(239212.85, tstOutputs.residualValue.setScale(2), 'Residual value after 6 months shall be 239212.84 DKK! Alg 1');

        // 12 months
        tstInputs.periodLength = 12;
        tstOutputs = CalculationsLeasingResidualValue.calculateResidualValue(tstInputs);
        System.assertEquals(223810.03, tstOutputs.residualValue.setScale(2), 'Residual value after 12 months shall be 223810 DKK! Alg 1');
    }

    @isTest
    public static void algorithm2Test() {
        CalculationsLeasingResidualValue.CalculationResidualValueInputs tstInputs = new CalculationsLeasingResidualValue.CalculationResidualValueInputs();
        tstInputs.algorithm = 2;
        tstInputs.interestRate = 0.072;
        tstInputs.isL94 = false;
        tstInputs.monthlyPayment = 5662.78;
        tstInputs.presentValue = 183999;

        CalculationsLeasingResidualValue.CalculationResidualValueOutputs tstOutputs;
        // 0 months
        tstInputs.periodLength = 0;
        tstOutputs = CalculationsLeasingResidualValue.calculateResidualValue(tstInputs);
        System.assertEquals(183999.00, tstOutputs.residualValue.setScale(2), 'Residual value after 0 months shall be 254330 DKK! Alg 2');

        // 2 months
        tstInputs.periodLength = 2;
        tstOutputs = CalculationsLeasingResidualValue.calculateResidualValue(tstInputs);
        System.assertEquals(174854.08, tstOutputs.residualValue.setScale(2), 'Residual value after 2 months shall be 174854.08 DKK! Alg 2');

        // 4 months
        tstInputs.periodLength = 4;
        tstOutputs = CalculationsLeasingResidualValue.calculateResidualValue(tstInputs);
        System.assertEquals(165599.08, tstOutputs.residualValue.setScale(2), 'Residual value after 4 months shall be 165599.08 DKK! Alg 2');
    }

    @isTest
    public static void algorithm2L94Test() {
        TestUtilitySIXT.createTaxCalculationSettings();

        CalculationsLeasingResidualValue.CalculationResidualValueInputs tstInputs = new CalculationsLeasingResidualValue.CalculationResidualValueInputs();
        tstInputs.algorithm = 2;
        tstInputs.interestRate = 0.072;
        tstInputs.isL94 = true;
        tstInputs.monthlyPayment = 5832.07;
        tstInputs.registrationBaseL94 = 211607.00;

        CalculationsLeasingResidualValue.CalculationResidualValueOutputs tstOutputs;
        // 0 months
        tstInputs.presentValue = 183999; // without L94, need to re-set for each run
        tstInputs.periodLength = 1;
        tstOutputs = CalculationsLeasingResidualValue.calculateResidualValue(tstInputs);
        System.assertEquals(188501.26, tstOutputs.residualValue.setScale(2), 'Residual value after 1 months shall be 188501.26 DKK! Alg 2 L94');

        // 2 months
        tstInputs.presentValue = 183999; // without L94, need to re-set for each run
        tstInputs.periodLength = 2;
        tstOutputs = CalculationsLeasingResidualValue.calculateResidualValue(tstInputs);
        System.assertEquals(188420.56, tstOutputs.residualValue.setScale(2), 'Residual value after 2 months shall be 188420.56 DKK! Alg 2 L94');

        // 4 months
        tstInputs.presentValue = 183999; // without L94, need to re-set for each run
        tstInputs.periodLength = 4;
        tstOutputs = CalculationsLeasingResidualValue.calculateResidualValue(tstInputs);
        System.assertEquals(183999.01, tstOutputs.residualValue.setScale(2), 'Residual value after 4 months shall be 183999.01 DKK! Alg 2 L94');
    }

    @isTest
    public static void invocableTest() {
        List<CalculationsLeasingResidualValue.CalculationResidualValueInputs> allInputs = new List<CalculationsLeasingResidualValue.CalculationResidualValueInputs>();

        CalculationsLeasingResidualValue.CalculationResidualValueInputs tstInputs = new CalculationsLeasingResidualValue.CalculationResidualValueInputs();
        tstInputs.algorithm = 1;
        tstInputs.interestRate = 0.0375;
        tstInputs.isL94 = false;
        tstInputs.monthlyPayment = 3284.43;
        tstInputs.presentValue = 254330.00;
        tstInputs.periodLength = 0;
        allInputs.add(tstInputs);

        CalculationsLeasingResidualValue.CalculationResidualValueInputs tstInputs2 = tstInputs.clone();
        tstInputs2.periodLength = 6;
        allInputs.add(tstInputs2);

        List<CalculationsLeasingResidualValue.CalculationResidualValueOutputs> allOutputs = CalculationsLeasingResidualValue.calculateResidualValue(allInputs);

        System.assertEquals(2, allOutputs.size(), 'We are expecting 2 results of the calcualtions!');
        System.assert(
            allOutputs.get(0).residualValue > allOutputs.get(1).residualValue,
            'Residual value at the begining of leasing shall be greater then in later months!'
        );
    }
}