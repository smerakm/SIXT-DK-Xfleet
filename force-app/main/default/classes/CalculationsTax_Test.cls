/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * 
 * test for CalculationsTax class
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
private class CalculationsTax_Test {
    @TestSetup
    static void makeData() {
        // custom settings for tax calculation
        insert new TaxCalculation__c(
            Interest_Rate__c = 2.1,
            Period_1_Length__c = 3,
            Period_1_Rate__c = 2,
            Period_2_Length__c = 33,
            Period_2_Rate__c = 1,
            Last_Period_Rate__c = 0.5
        );
    }

    @isTest
    static void assumedValueLostPercentage() {
        // values are based on custom settings params in makeData() method, 1st period 3 months 2%, 2nd period 33 months 1%, last period 0.5%
        // age 0, period 4 months, result = 7%
        System.assertEquals(7, CalculationsTax.getAssumedValueLost(0, 4), 'Result shall be 7% for 0 months old vehicle and period of 4 months!');
        // age 0, period 12 months, result = 15%
        System.assertEquals(15, CalculationsTax.getAssumedValueLost(0, 12), 'Result shall be 15% for 0 months old vehicle and period of 12 months!');
        // age 0, period 36 months, result = 39%
        System.assertEquals(39, CalculationsTax.getAssumedValueLost(0, 36), 'Result shall be 39% for 0 months old vehicle and period of 36 months!');
        // age 0, period 37 months, result = 39.5%
        System.assertEquals(39.5, CalculationsTax.getAssumedValueLost(0, 37), 'Result shall be 39.5% for 0 months old vehicle and period of 37 months!');
        // age 0, period 2 months, result = 4%
        System.assertEquals(4, CalculationsTax.getAssumedValueLost(0, 2), 'Result shall be 4% for 0 months old vehicle and period of 2 months!');
        // age 1, period 36 months, result = 37.5%
        System.assertEquals(37.5, CalculationsTax.getAssumedValueLost(1, 36), 'Result shall be 37.5% for 1 months old vehicle and period of 36 months!');
    }

    @isTest
    static void taxCalculation() {
        // values are based on custom settings params in makeData() method, 1st period 3 months 2%, 2nd period 33 months 1%, last period 0.5%
        List<CalculationsTax.CalculationTaxInputs> testInputsList = new List<CalculationsTax.CalculationTaxInputs>();
        CalculationsTax.CalculationTaxInputs testInputs = new CalculationsTax.CalculationTaxInputs();
        testInputs.leasingPeriodLength = 12;
        testInputs.registrationFee = 92550;
        testInputs.vehicleAge = 0;
        testInputsList.add(testInputs);
        // calculate
        CalculationsTax.CalculationTaxOutputs testResults = CalculationsTax.calculateTax(testInputsList).get(0);
        // assertion
        System.assertEquals(15, testResults.assumedValueLostPercent, 'assumed value lost shall be 15%!');
        System.assertEquals(13882.5, testResults.registrationFeeOfAssumedValueLost, 'registration fee assumed value lost shall be 13 882.5!');
        System.assertEquals(78667.5, testResults.residualTaxEndOfLeasing, 'residual tax at the end of leasing period shall be 78668.5!');
        System.assertEquals(1652, testResults.interestOnResidualTax, 'interest on residual tax shall be 1652!');
        System.assertEquals(15534.5, testResults.totalPayment, 'total tax shall be 15 534.5!');

    }


}