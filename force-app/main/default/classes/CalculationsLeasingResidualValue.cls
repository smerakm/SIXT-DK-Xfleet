/**
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Utility class to calculate Residual Value of leasing in specific period.
 *
 * It provides following functionality:
 * - calculate residual value of leasing for month
 * - algorithm used depends on Leasing Company
 *
 * There are 2 wrappers:
 * - one for inputs (algorithm type, interest rate, period, present value, tax type, montly payment)
 * - one for calculation results
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-02-07
 * @modified       2023-02-07
 * @systemLayer    Utility
 * @see            SIXT-54
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-02-07      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
public inherited sharing class CalculationsLeasingResidualValue {
    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Invocable wrapper for residual value calculation method
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    @InvocableMethod(label='Calculate residual value' description='Calculate Leasing Residual Value' category='Calculation')
    public static List<CalculationResidualValueOutputs> calculateResidualValue(List<CalculationResidualValueInputs> costInputs) {
        List<CalculationResidualValueOutputs> allResults = new List<CalculationResidualValueOutputs>();
        for (CalculationResidualValueInputs singleInputs : costInputs) {
            allResults.add(calculateResidualValue(singleInputs));
        }
        return allResults;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Calculate residual value
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  costInputs CalculationLeasingInputs
     * @return CalculationLeasingOutputs return calculated leasing cost per month
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public static CalculationResidualValueOutputs calculateResidualValue(CalculationResidualValueInputs costInputs) {
        // is it L94?
        if (costInputs.isL94) {
            CalculationsTax.CalculationTaxInputs taxInputs = new CalculationsTax.CalculationTaxInputs();
            taxInputs.leasingPeriodLength = costInputs.periodLength + 1;
            taxInputs.registrationFee = costInputs.registrationBaseL94;
            taxInputs.vehicleAge = 0;
            CalculationsTax.CalculationTaxOutputs taxOutput = CalculationsTax.calculateTax(taxInputs);

            System.debug(LoggingLevel.FINE, 'tax calculated in residual value calculation: ' + taxOutput);

            costInputs.presentValue += taxOutput.totalPayment;
        }

        System.debug(LoggingLevel.FINE, 'present value (after L94): ' + costInputs.presentValue);

        CalculationResidualValueOutputs result;
        // switch by algorithm
        switch on costInputs.algorithm {
            when 1 {
                result = algorithm1(costInputs);
            }
            when 2 {
                result = algorithm2(costInputs);
            }
            when else {
                result = algorithm1(costInputs);
            }
        }
        return result;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Algorithm 1 - used originally by AL
     * - use FV, payments are due at the beginning of the period
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  calcInputs CalculationLeasingInputs
     * @return Decimal return calculated residual value
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    private static CalculationResidualValueOutputs algorithm1(CalculationResidualValueInputs calcInputs) {
        System.debug(
            LoggingLevel.FINE,
            'Calculate FV algorithm 1 for: PV=' +
            calcInputs.presentValue +
            ', monthlyPayment=' +
            calcInputs.monthlyPayment +
            ', rate=' +
            calcInputs.interestRate +
            ', period=' +
            calcInputs.periodLength
        );
        // 𝑛 is the number of payments per year
        Integer n = 12;

        Double r = Double.valueOf(calcInputs.interestRate / n);
        Double pv = Double.valueOf(calcInputs.presentValue) * -1; // present value is negative
        Double pmt = Double.valueOf(calcInputs.monthlyPayment);
        // calculate FV part with payments at the BEGINING of the period
        Double fv = FixedRateLoanUtility.fv(r, calcInputs.periodLength, pmt, pv, 1);

        CalculationResidualValueOutputs results = new CalculationResidualValueOutputs();
        results.residualValue = fv;
        return results;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Algorithm 2 - used originally by Alphabet
     * - use FV, payments are due at the end of the period
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  calcInputs CalculationLeasingInputs
     * @return Decimal return calculated residual value
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    private static CalculationResidualValueOutputs algorithm2(CalculationResidualValueInputs calcInputs) {
        System.debug(
            LoggingLevel.FINE,
            'Calculate FV algorithm 1 for: PV=' +
            calcInputs.presentValue +
            ', monthlyPayment=' +
            calcInputs.monthlyPayment +
            ', rate=' +
            calcInputs.interestRate +
            ', period=' +
            calcInputs.periodLength
        );
        // 𝑛 is the number of payments per year
        Integer n = 12;

        Double r = Double.valueOf(calcInputs.interestRate / n);
        Double pv = Double.valueOf(calcInputs.presentValue) * -1; // present value is negative
        Double pmt = Double.valueOf(calcInputs.monthlyPayment);
        // calculate FV part with payments at the END of the period
        Double fv = FixedRateLoanUtility.fv(r, calcInputs.periodLength, pmt, pv, 0);

        CalculationResidualValueOutputs results = new CalculationResidualValueOutputs();
        results.residualValue = fv;
        return results;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Wrapper class for INPUT parameters,
     * so the utility methods can be used from Flows
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class CalculationResidualValueInputs {
        @InvocableVariable(label='Calculation Algorithm' description='Based on Leasing Company')
        public Integer algorithm; // 1, 2, ...
        @InvocableVariable(label='Leasing Amount' description='Leasing amount (Present Value), total value that needs to be loaned' required=true)
        public Decimal presentValue; // Pv / Købspris, samlet
        @InvocableVariable(label='Monthly Payment' description='Total amount paid to leasing company every month (iterest + derpreciation)' required=true)
        public Decimal monthlyPayment; // pvr, ydelse
        @InvocableVariable(label='Interest Rate' description='Interest Rate used in the loan, e.g. 3.75%' required=true)
        public Decimal interestRate; // Rate / Rente
        @InvocableVariable(label='Period Length' description='Leasing period length in months. Period after we want buy out the vehicle' required=true)
        public Integer periodLength; // Nper / leasing period
        @InvocableVariable(label='Is it L94?' description='Do we need to include vehicle L94 tax in the calculation?' required=true)
        public Boolean isL94; // true if vehicle is L94 tax type
        @InvocableVariable(label='Base for L94?' description='If it is L94, we need to know the tax base')
        public Decimal registrationBaseL94; // Endelig afgift efter fradrag 150%
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Wrapper class for OUTPUT parameters,
     * so the utility methods can be used from Flows and return values to the flow
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class CalculationResidualValueOutputs {
        @InvocableVariable
        public Decimal residualValue; // Ydelse
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Custom exception class for Holding cost simulator
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class ResidualValueException extends Exception {
    }
}