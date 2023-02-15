/**
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Calculate tax utility class.
 *
 * It provides following functionality:
 * - calculate tax for car inputs for specific period
 *
 * There are 2 wrappers:
 * - one for inputs (price and period)
 * - one for calculation results
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-03-14
 * @modified       2022-03-14
 * @systemLayer    Utility
 * @see            SIX-177
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-03-14      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
public inherited sharing class CalculationsTax {
    // store the settings parameters for later use in static variable
    private static TaxCalculation__c taxSettings;

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Read tax calculation settings.
     * Settings can be updated based on changes from Tax agency, usually once in 6 months.
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  none
     * @return TaxCalculation__c settings parameters
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public static TaxCalculation__c readTaxCalculationSettings() {
        if (taxSettings == null) {
            taxSettings = TaxCalculation__c.getInstance();
        }
        return taxSettings;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Invocable wrapper for tax calculation method
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    @InvocableMethod(label='Calculate tax' description='Calculate tax for single period' category='Calculation')
    public static List<CalculationTaxOutputs> calculateTax(List<CalculationTaxInputs> taxInputs) {
        List<CalculationTaxOutputs> allResults = new List<CalculationTaxOutputs>();
        for (CalculationTaxInputs singleInputs : taxInputs) {
            allResults.add(calculateTax(singleInputs));
        }
        return allResults;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Calculate tax for specific price and period
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  taxInputs CalculationTaxInputs
     * @return CalculationTaxOutputs return tax calculation
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public static CalculationTaxOutputs calculateTax(CalculationTaxInputs taxInputs) {
        readTaxCalculationSettings();
        CalculationTaxOutputs result = new CalculationTaxOutputs();
        // vehicle registration fee value at the start of the period (it is same as input)
        result.registrationFee = taxInputs.registrationFee;
        // calculate how much value will be lost at the end of the period (in percent)
        result.assumedValueLostPercent = getAssumedValueLost(taxInputs.vehicleAge, taxInputs.leasingPeriodLength);
        // calculate how much value will be lost at the end of the period
        result.registrationFeeOfAssumedValueLost = result.registrationFee * result.assumedValueLostPercent / 100;
        // vehicle registration fee value at the end of the period (original value - value lost)
        result.residualTaxEndOfLeasing = result.registrationFee - result.registrationFeeOfAssumedValueLost;
        // what will be the interest from the value at the end
        Decimal taxInterestRate = taxInputs.taxInterestRate;
        if (taxInterestRate == null) {
            taxInterestRate = taxSettings.Interest_Rate__c;
        }
        result.interestOnResidualTax = result.residualTaxEndOfLeasing * (taxInterestRate / 100) * taxInputs.leasingPeriodLength / 12;
        // total payment for the period (fee of assumed loss + interest)
        result.totalPayment = result.registrationFeeOfAssumedValueLost + result.interestOnResidualTax;
        return result;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * utility method to calculate assumed loss of value for the period
     * - vehicle lose values in different rate base on age of the car
     * - usually value is dropping more for new vehicles
     * - e.g. vehicle lose 2% every month for the first 3 months
     * --     then it lose 1% every month for next 33 months
     * --     and after that it lose 0.5% every month
     *
     * periods length and rates are in custom settings
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  vehicleAge how old is the vehicle at the start of the leasing period
     * @param  leasingPeriodLength length of the leasing period in months
     * @return Decimal how many percent of vehicle value is assumed to lose over the leasing period
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    @TestVisible
    private static Decimal getAssumedValueLost(Integer vehicleAge, Integer leasingPeriodLength) {
        readTaxCalculationSettings();
        // assumed loss of value in assumed
        Decimal valueLostPercent = 0;
        // time for specific period
        Integer timeSpentThisPeriod = 0;
        // vehicle age through different periods, for the 1st period it is the initial age
        Integer vehicleAgeCumulative = vehicleAge;
        // what is left from leasing period during the calculation, for the 1st period it is the initial leasing length
        Integer leasingRemaining = leasingPeriodLength;

        // 1st period 0..X months
        Integer periodLength = Integer.valueOf(taxSettings.Period_1_Length__c);
        Decimal periodRate = taxSettings.Period_1_Rate__c;
        // start month = 0
        Integer periodStart = 0;
        timeSpentThisPeriod = getMonthsSpentInPeriod(vehicleAgeCumulative, leasingRemaining, periodStart, periodLength);
        // calculate value lost in this period and aggregate it
        valueLostPercent += timeSpentThisPeriod * periodRate;
        // update values for next period
        periodStart += periodLength;
        // next period vehicle age is increased by moths spent in this period
        vehicleAgeCumulative += timeSpentThisPeriod;
        // update remaining leasing period with reducing it by time spent in this period
        leasingRemaining -= timeSpentThisPeriod;

        System.debug(LoggingLevel.FINE, 'PERIOD 1: ***************************');
        System.debug(LoggingLevel.FINE, 'vehicleAgeCumulative: ' + vehicleAgeCumulative);
        System.debug(LoggingLevel.FINE, 'leasingRemaining: ' + leasingRemaining);
        System.debug(LoggingLevel.FINE, 'valueLostPercent: ' + valueLostPercent);
        System.debug(LoggingLevel.FINE, 'timeSpentThisPeriod: ' + timeSpentThisPeriod);

        // 2nd period
        // check if there are any leasing period remaining
        // check the 2nd period is configured
        if (leasingRemaining > 0 && taxSettings.Period_2_Length__c != null && taxSettings.Period_2_Rate__c != null) {
            periodLength = Integer.valueOf(taxSettings.Period_2_Length__c);
            periodRate = taxSettings.Period_2_Rate__c;
            timeSpentThisPeriod = getMonthsSpentInPeriod(vehicleAgeCumulative, leasingRemaining, periodStart, periodLength);
            // calculate value lost in this period and aggregate it
            valueLostPercent += timeSpentThisPeriod * periodRate;
            // update values for next period
            periodStart += periodLength;
            // next period vehicle age is increased by moths spent in this period
            vehicleAgeCumulative += timeSpentThisPeriod;
            // update remaining leasing period with reducing it by time spent in this period
            leasingRemaining -= timeSpentThisPeriod;
        }

        System.debug(LoggingLevel.FINE, 'PERIOD 2: ***************************');
        System.debug(LoggingLevel.FINE, 'vehicleAgeCumulative: ' + vehicleAgeCumulative);
        System.debug(LoggingLevel.FINE, 'leasingRemaining: ' + leasingRemaining);
        System.debug(LoggingLevel.FINE, 'valueLostPercent: ' + valueLostPercent);
        System.debug(LoggingLevel.FINE, 'timeSpentThisPeriod: ' + timeSpentThisPeriod);

        // last period
        // check if there are any leasing period remaining
        if (leasingRemaining > 0) {
            // and all remaining will be in this last period
            timeSpentThisPeriod = leasingRemaining;
            periodRate = taxSettings.Last_Period_Rate__c;
            // we don't need to update vehicle age and leasing remaining after last period
            // calculate value lost in this period and aggregate it
            valueLostPercent += timeSpentThisPeriod * periodRate;
        }

        System.debug(LoggingLevel.FINE, 'PERIOD 3: ***************************');
        System.debug(LoggingLevel.FINE, 'valueLostPercent: ' + valueLostPercent);
        System.debug(LoggingLevel.FINE, 'timeSpentThisPeriod: ' + timeSpentThisPeriod);

        return valueLostPercent;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * small utility method to calculate how many moths are used in the single period
     * for value lost calculation.
     * E.g. how many month from the leasing period are in between 4th months and 36th months
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  vehicleAgePeriod   vehicle age at the start of period (e.g. if it is second period
     *                            then the age is original age + time spent in previous periods)
     * @param  leasingPeriodRemaining how many months left from leasing period (e.g. original was 4
     *                                but we already spent 2 months in previous period)
     * @param periodStart first month of the period (e.g. 0, 4, 37, ...)
     * @param periodLength length of the period in months
     * @return Decimal how many months the vehicle stay in this period
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    private static Integer getMonthsSpentInPeriod(Integer vehicleAgePeriod, Integer leasingPeriodRemaining, Integer periodStart, Integer periodLength) {
        Integer periodEnd = periodStart + periodLength;
        Integer timeSpentThisPeriod = 0;
        // check if the vehicle is older then end of the period (for used cars to skip periods)
        if (vehicleAgePeriod < periodEnd) {
            // if it is not older then end of the period
            // check if rest of the leasing period is before end of the period
            if ((vehicleAgePeriod + leasingPeriodRemaining) <= periodEnd) {
                // yes, all rest of the leasing is within this period
                timeSpentThisPeriod = leasingPeriodRemaining;
            } else {
                // no, leasing will continue in next period too
                // how many months is spent in this period depends on age the vehicle enter the period (vehicleAgePeriod)
                // and length or end of the period
                // (e.g. period is between moths 0-3 and vehicle is already 2 months old,
                //  and remaining leasing period is 6 months,
                //  so only 1 month is used in this period)
                timeSpentThisPeriod = periodEnd - vehicleAgePeriod;
            }
        }
        return timeSpentThisPeriod;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Wrapper class for INPUT parameters,
     * so the utility methods can be used from Flows
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class CalculationTaxInputs {
        @InvocableVariable
        public Decimal registrationFee; // Registereringsafgift
        @InvocableVariable
        public Integer vehicleAge; // Alder ved ordningens start, mdr
        @InvocableVariable
        public Integer leasingPeriodLength; // Leasingperiode, mdr.
        @InvocableVariable
        public Decimal taxInterestRate; // Leasingperiode, mdr.
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Wrapper class for OUTPUT parameters,
     * so the utility methods can be used from Flows and return values to the flow
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class CalculationTaxOutputs {
        @InvocableVariable
        public Decimal registrationFee; // Registereringsafgift
        @InvocableVariable
        public Decimal assumedValueLostPercent; // Forudsat værditab, %
        @InvocableVariable
        public Decimal registrationFeeOfAssumedValueLost; // Registreringsafgift af forudsat værditab
        @InvocableVariable
        public Decimal residualTaxEndOfLeasing; // Restafgift ved udløb af leasingperiode
        @InvocableVariable
        public Decimal interestOnResidualTax; // Rente af restafgift
        @InvocableVariable
        public Decimal totalPayment; // Forudbetaling i alt
    }
}