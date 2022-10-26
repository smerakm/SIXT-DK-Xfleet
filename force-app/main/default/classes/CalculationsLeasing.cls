/**
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Utility class to calculate Leasing Cost.
 *
 * It provides following functionality:
 * - calculate leasing cost per month
 * - algorithm used depends on Leasing Company
 *
 * There are 2 wrappers:
 * - one for inputs (algorithm type, interest rate, period, present value, future value)
 * - one for calculation results
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-10-24
 * @modified       2022-10-24
 * @systemLayer    Utility
 * @see            SIXT-57
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-10-24      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
public inherited sharing class CalculationsLeasing {
    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Invocable wrapper for holding costs calculation method
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    @InvocableMethod(label='Calculate leasing costs' description='Calculate leasing costs for single period' category='Calculation')
    public static List<CalculationLeasingOutputs> calculateLeasingCost(List<CalculationLeasingInputs> costInputs) {
        List<CalculationLeasingOutputs> allResults = new List<CalculationLeasingOutputs>();
        for (CalculationLeasingInputs singleInputs : costInputs) {
            allResults.add(calculateLeasingCost(singleInputs));
        }
        return allResults;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Calculate leasing cost for one period.
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  costInputs CalculationLeasingInputs
     * @return CalculationLeasingOutputs return calculated leasing cost per month
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public static CalculationLeasingOutputs calculateLeasingCost(CalculationLeasingInputs costInputs) {
        // calculate costs
        CalculationLeasingOutputs result = new CalculationLeasingOutputs();
        // switch by algorithm
        switch on costInputs.algorithm {
            when 1 {
                result.leasingCostPerMonth = algorithm1(costInputs);
            }
            when else {
                result.leasingCostPerMonth = algorithm1(costInputs);
            }
        }
        return result;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Algorithm 1 - used originally by AL and Alphabet
     * - use PMT
     * - add tax part for L94
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  calcInputs CalculationLeasingInputs
     * @return Decimal return calculated leasing cost per month
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    private static Decimal algorithm1(CalculationLeasingInputs calcInputs) {
        // calculate PMT part with payments at the beginning of the period
        Decimal results = algorithmPMT(calcInputs.presentValue, calcInputs.futureValue, calcInputs.interestRate, calcInputs.periodLength, 1);

        System.debug(LoggingLevel.FINE, 'PMT calculated: ' + results);

        // add L94 part if needed
        if (calcInputs.taxType.contains('L94')) {
            Decimal l94part = algorithmL94TaxPart(calcInputs.registrationFee, calcInputs.periodLength);
            System.debug(LoggingLevel.FINE, 'L94 per month calculated: ' + l94part);
            results += algorithmL94TaxPart(calcInputs.registrationFee, calcInputs.periodLength);
        }
        return results;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Calculates PMT as in excel,
     * calculates the payment for a loan based on constant payments and a constant interest rate
     * - 𝑃𝑀𝑇=(𝑃𝑉×𝐶−𝐹𝑉)(𝑟/𝑛)/((𝐶−1)*(1+type*r/n)), where C = pow((1+r/n), period)
     * - https://www.quora.com/What-would-be-the-mathematical-equivalent-for-PMT-Excel-Formula-PMT
     *
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  presentValue Decimal, PV
     * @param  futureValue Decimal, FV
     * @param  interestRate Decimal, r
     * @param  periodLength Integer, period length in months
     * @param  type Integer, indicates when payments are due,
     *                          0 = At the end of the period,
     *                          1 = At the beginning of the period
     * @return Decimal return calculated leasing cost per month
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    private static Decimal algorithmPMT(Decimal presentValue, Decimal futureValue, Decimal interestRate, Integer periodLength, Integer type) {
        System.debug(LoggingLevel.FINE, 'Calculate PMT for: PV=' + presentValue + ', FV=' + futureValue + ', rate=' + interestRate + ', period=' + periodLength + ', type=' + type);
        // 𝑛 is the number of payments per year
        Integer n = 12;
        // the compounding factor, C = pow((1+r/n), period)
        Double c = Math.pow(Double.valueOf(1 + interestRate / n), Double.valueOf(periodLength));
        // payments, calculates the payment for a loan based on constant payments and a constant interest rate.
        // 𝑃𝑀𝑇=(𝑃𝑉×𝐶−𝐹𝑉)(𝑟/𝑛)/((𝐶−1)*(1+type*r/n)), where C = pow((1+r/n), period)
        Decimal pmt = ((presentValue * c - futureValue) * (interestRate / n)) / ((c - 1) * (1 + type * interestRate / n));
        return pmt;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Tax part for L94,
     * we need add L94 tax to loan payment, this method calculates L94 part
     *
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  registrationFee Decimal, registration fee - total
     * @param  periodLength Integer, period length in months
     * @return Decimal registration tax - L94 part per month
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    private static Decimal algorithmL94TaxPart(Decimal registrationFee, Integer periodLength) {
        // calculate L94 total for the period + 1
        // (+ extra 1st month, e.g registered in maj for period of 4 moths
        //  = tax is for maj, june, july, august and september)
        CalculationsTax.CalculationTaxInputs taxInputs = new CalculationsTax.CalculationTaxInputs();
        taxInputs.registrationFee = registrationFee;
        taxInputs.leasingPeriodLength = periodLength + 1;
        taxInputs.vehicleAge = 0;
        CalculationsTax.CalculationTaxOutputs taxResults = CalculationsTax.calculateTax(taxInputs);
        System.debug(LoggingLevel.FINE, 'L94 total calculated: ' + taxResults);
        // per month
        return taxResults.totalPayment / periodLength;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Wrapper class for INPUT parameters,
     * so the utility methods can be used from Flows
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class CalculationLeasingInputs {
        @InvocableVariable
        public Integer algorithm; // 1, 2, ...
        @InvocableVariable
        public Decimal presentValue; // Pv / Købspris, samlet
        @InvocableVariable
        public Decimal futureValue; // Fv / Salgspris, delivery confirmation
        @InvocableVariable
        public Decimal interestRate; // Rate / Rente
        @InvocableVariable
        public Integer periodLength; // Nper / leasing period
        @InvocableVariable
        public String taxType; // L94 / Valuta / Full tax
        @InvocableVariable
        public Decimal registrationFee; // Registereringsafgift, total
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Wrapper class for OUTPUT parameters,
     * so the utility methods can be used from Flows and return values to the flow
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class CalculationLeasingOutputs {
        @InvocableVariable
        public Decimal leasingCostPerMonth; // Ydelse
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Custom exception class for Holding cost simulator
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class LeasingCostException extends Exception {
    }
}