/**
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Utility class to calculate Holding Cost.
 *
 * It provides following functionality:
 * - calculate holding cost for specific period
 * -- calculate damage and tyre cost
 *
 * There are 2 wrappers:
 * - one for inputs (price and period)
 * - one for calculation results
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-03-15
 * @modified       2022-03-15
 * @systemLayer    Utility
 * @see            SIX-177
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-03-14      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
public inherited sharing class CalculationsHoldingCost {
    // map to hold matrix for damage and service costs
    private static Map<Id, Map<Integer, DamageAndServiceWrapper>> mDamageAndService;

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Invocable wrapper for holding costs calculation method
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    @InvocableMethod(label='Calculate holding costs' description='Calculate holding costs for single period' category='Calculation')
    public static List<CalculationHoldingCostOutputs> calculateHoldingCost(List<CalculationHoldingCostInputs> costInputs) {
        List<CalculationHoldingCostOutputs> allResults = new List<CalculationHoldingCostOutputs>();
        for (CalculationHoldingCostInputs singleInputs : costInputs) {
            allResults.add(calculateHoldingCost(singleInputs));
        }
        return allResults;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Calculate holding cost for one period.
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  costInputs CalculationHoldingCostInputs
     * @return CalculationHoldingCostOutputs return calculated holding cost for the period
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public static CalculationHoldingCostOutputs calculateHoldingCost(CalculationHoldingCostInputs costInputs) {
        // calculate costs
        CalculationHoldingCostOutputs result = new CalculationHoldingCostOutputs();
        // damage and service
        if (String.isNotBlank(costInputs.vehicleDamageGroup)) {
            // read the config
            Map<Integer, DamageAndServiceWrapper> mDamageAndServiceCarGroup = readDamageAndServiceSettings(costInputs.vehicleDamageGroup);
            // calculate damage and service
            DamageAndServiceWrapper damageAndServiceRecord = mDamageAndServiceCarGroup.get(costInputs.periodLength);
            result.damage = damageAndServiceRecord.damageAccumulated;
            result.serviceAndTyres = damageAndServiceRecord.serviceAccumulated;
        }
        // tax
        CalculationsTax.CalculationTaxInputs taxInputs = new CalculationsTax.CalculationTaxInputs();
        taxInputs.leasingPeriodLength = costInputs.periodLength;
        taxInputs.registrationFee = costInputs.registrationFee;
        taxInputs.vehicleAge = costInputs.vehicleAge;
        CalculationsTax.CalculationTaxOutputs taxResults = CalculationsTax.calculateTax(taxInputs);
        result.interestToTax = taxResults.interestOnResidualTax; // E34
        result.proportionalTax = taxResults.totalPayment; // E37
        result.registrationTaxL94 = taxResults.registrationFeeOfAssumedValueLost; // E30

        return result;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Read damage and service cost for a car group
     * and update static map if needed.
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  carGroup name of the car group, e.g. EC
     * @return Map<Integer, DamageAndServiceWrapper> map that holds damage and service cost
     *                   for this car group:
     *                    key: month in the period
     *                    value: wrapper with damage and service cost for the specific month
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public static Map<Integer, DamageAndServiceWrapper> readDamageAndServiceSettings(Id serviceGroupId) {
        System.debug(LoggingLevel.DEBUG, 'read damage and service configuration for group: ' + serviceGroupId);
        if (mDamageAndService == null) {
            mDamageAndService = new Map<Id, Map<Integer, DamageAndServiceWrapper>>();
        }
        if (mDamageAndService.containsKey(serviceGroupId)) {
            return mDamageAndService.get(serviceGroupId);
        } else {
            Map<Integer, DamageAndServiceWrapper> mForTheGroup = new Map<Integer, DamageAndServiceWrapper>();
            Integer actualMonth = 1;
            Decimal accumulatedDamage = 0;
            Decimal accumulatedService = 0;
            for (ServiceAndDamageCost__c singleMonthCost : [
                SELECT Period_Month__c, Damage_Cost__c, Tyres_Service_Cost__c
                FROM ServiceAndDamageCost__c
                WHERE Service_and_Damage_Group__c = :serviceGroupId
                ORDER BY Period_Month__c
            ]) {
                // check that we are on correct month (and there are no holes in configuration)
                if (Integer.valueOf(singleMonthCost.Period_Month__c) != actualMonth) {
                    throw new HoldingCostException(
                        'Error when reading Service and Damage configuration for car group: ' +
                        serviceGroupId +
                        '! Check that there are no missing months in the configuration.'
                    );
                }
                accumulatedDamage += singleMonthCost.Damage_Cost__c;
                accumulatedService += singleMonthCost.Tyres_Service_Cost__c;
                // create wrapper record and store it in the map
                DamageAndServiceWrapper costWrapper = new DamageAndServiceWrapper();
                costWrapper.servicePerMonth = singleMonthCost.Tyres_Service_Cost__c;
                costWrapper.damagePerMonth = singleMonthCost.Damage_Cost__c;
                costWrapper.serviceAccumulated = accumulatedService;
                costWrapper.damageAccumulated = accumulatedDamage;
                mForTheGroup.put(actualMonth, costWrapper);
                // next month
                actualMonth++;
            }

            if (mForTheGroup.isEmpty()) {
                throw new HoldingCostException('No Service and Damage configuration found for the car group: ' + serviceGroupId + '!');
            }
            mDamageAndService.put(serviceGroupId, mForTheGroup);
            return mForTheGroup;
        }
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Wrapper class to hold accumulated cost for damage, service and tyres
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class DamageAndServiceWrapper {
        public Decimal servicePerMonth;
        public Decimal damagePerMonth;
        public Decimal serviceAccumulated;
        public Decimal damageAccumulated;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Wrapper class for INPUT parameters,
     * so the utility methods can be used from Flows
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class CalculationHoldingCostInputs {
        //@InvocableVariable
        //public Decimal licencePlateCost; // Nr. plader
        //@InvocableVariable
        //public Decimal deliveryCost; // Leveringsomkostninger
        //@InvocableVariable
        //public Decimal handlingCost; // Handling
        //@InvocableVariable
        //public Decimal steelPrice; // Stålpris
        //@InvocableVariable
        //public Decimal totalPrice; // Totalpris inkl. afgift
        @InvocableVariable
        public Decimal registrationFee; // Reg.afgift, total
        //@InvocableVariable
        //public Decimal ownershipFee; // Ejerafgift, halvårligt

        //@InvocableVariable
        //public String carGroup; // bilgruppe
        @InvocableVariable
        public String vehicleDamageGroup; // bilgruppe
        //@InvocableVariable
        //public Decimal contractCost; // Kontraktgebyr
        //@InvocableVariable
        //public Decimal insurance; // Forsikring, månedligt
        //@InvocableVariable
        //public Decimal infleetDefleetCost; // In- og defleet, engangsomkostning
        //@InvocableVariable
        //public Decimal financingInterestRate; // rente
        @InvocableVariable
        public Integer vehicleAge;

        @InvocableVariable
        public Integer periodLength; // Driftperiode
        //@InvocableVariable
        //public Decimal salesPrice; // Salgspris, delivery confirmation
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Wrapper class for OUTPUT parameters,
     * so the utility methods can be used from Flows and return values to the flow
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class CalculationHoldingCostOutputs {
        @InvocableVariable
        public Decimal registrationTaxL94; // Reg.afgift, L94
        @InvocableVariable
        public Decimal interestToTax; // Rente til SKAT
        @InvocableVariable
        public Decimal proportionalTax; // Forholdsmæssig registreringsafgift
        @InvocableVariable
        public Decimal serviceAndTyres; // Dæk & Service
        @InvocableVariable
        public Decimal damage; // Skader
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Custom exception class for Holding cost simulator
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class HoldingCostException extends Exception {
    }
}