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
 * @version        2.0
 * @created        2022-10-24
 * @modified       2023-02-06
 * @systemLayer    Utility
 * @see            SIXT-57
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v2.0            marek.smerak@wipro.com
 * 2022-10-24      removed tax part (tax part moved to Total Buy Price calculation), 
 *                  algorithm2 added
 *                  add deprication and interest as output attributes
 *
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
     * - use PMT, payments are due at the beginning of the period
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  calcInputs CalculationLeasingInputs
     * @return Decimal return calculated leasing cost per month
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    private static CalculationLeasingOutputs algorithm1(CalculationLeasingInputs calcInputs) {
        // calculate PMT part with payments at the beginning of the period
        CalculationLeasingOutputs results = algorithmPMT(calcInputs.presentValue, calcInputs.futureValue, calcInputs.interestRate, calcInputs.periodLength, 1);
        return results;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Algorithm 2 - used originally by Alphabet
     * - use PMT, payments are due at the end of the period
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  calcInputs CalculationLeasingInputs
     * @return Decimal return calculated leasing cost per month
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    private static CalculationLeasingOutputs algorithm2(CalculationLeasingInputs calcInputs) {
        // calculate PMT part with payments at the beginning of the period
        CalculationLeasingOutputs results = algorithmPMT(calcInputs.presentValue, calcInputs.futureValue, calcInputs.interestRate, calcInputs.periodLength, 0);
        return results;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Calculates PMT as in excel,
     * calculates the payment for a loan based on constant payments and a constant interest rate
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
    private static CalculationLeasingOutputs algorithmPMT(Decimal presentValue, Decimal futureValue, Decimal interestRate, Integer periodLength, Integer type) {
        System.debug(LoggingLevel.FINE, 'Calculate PMT for: PV=' + presentValue + ', FV=' + futureValue + ', rate=' + interestRate + ', period=' + periodLength + ', type=' + type);
        // 𝑛 is the number of payments per year
        Integer n = 12;
        
        Double r = Double.valueOf(interestRate/n);
        Double pv = Double.valueOf(presentValue)*-1; // present value is negative
        Double fv = Double.valueOf(futureValue);
        
        Decimal pmt = FixedRateLoanUtility.pmt(r, periodLength, pv, fv, type);

        System.debug(LoggingLevel.FINE, 'PMT calculated as: ' + pmt);

        Decimal deprication = presentValue - futureValue;
        Decimal depricationPerMonth = deprication / periodLength;
        Decimal interestPerMonth = pmt - depricationPerMonth;

        CalculationLeasingOutputs results = new CalculationLeasingOutputs();
        results.leasingCostPerMonth = pmt;
        results.depricationPerMonth = depricationPerMonth;
        results.interestPerMonth = interestPerMonth;

        System.debug(LoggingLevel.FINE, 'leasing calc results are: ' + results);
        return results;
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
        @InvocableVariable
        public Decimal depricationPerMonth; // Afskrivninger
        @InvocableVariable
        public Decimal interestPerMonth; // Rente
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Custom exception class for Holding cost simulator
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class LeasingCostException extends Exception {
    }
}