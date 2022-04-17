public with sharing class FleetForecastUpdateUtility {
    // calculate updates for all fleet forecast for one group of vehicles
    public static List<Fleet_Forecast__c> getFleetForecastUpdates(Id vehicleGroupId) {
        System.debug('getting fleet forecast for group: ' + vehicleGroupId);
        // get all fleet forecast that are not in the past or archived
        List<Fleet_Forecast__c> forecasts = [
            SELECT
                Vehicle_Group__c,
                First_Day__c,
                Last_Day__c,
                Current_fleet_DK__c,
                Infleet_DK__c,
                Defleet_DK__c,
                Current_fleet_Valuta__c,
                Infleet_Valuta__c,
                Defleet_Valuta__c
            FROM Fleet_Forecast__c
            WHERE Status__c != 'Archived' AND Last_Day__c > :Date.today() AND Vehicle_Group__c = :vehicleGroupId
        ];
        // get all active or infleet cars for the vehicle group
        List<Vehicle__c> vehicles = [
            SELECT Id, Planned_Infleet_Date__c, Expected_Defleet_Date__c, Registration_Date__c, Valuta_Vehicle__c
            FROM Vehicle__c
            WHERE
                (Vehicle_Group__c = :vehicleGroupId
                OR (Vehicle_Group__c = NULL
                AND Vehicle_Batch__r.Vehicle_Group__c = :vehicleGroupId))
                AND Vehicle_Status__c != 99
            ORDER BY Expected_Defleet_Date__c ASC NULLS FIRST
        ];
        // calculate updates for each period
        List<Fleet_Forecast__c> forecastsUpdated = new List<Fleet_Forecast__c>();
        for (Fleet_Forecast__c singleForecast : forecasts) {
            Fleet_Forecast__c singleForecastUpdated = updateFleetForecast(singleForecast, vehicles);
            // update only if there are changes
            if (singleForecastUpdated != null) {
                forecastsUpdated.add(singleForecastUpdated);
            }
        }
        // TODO - remove
        for (Fleet_Forecast__c ff : forecastsUpdated) {
            System.debug('forecast period (updated): ' + ff);
        }
        return forecastsUpdated;
    }

    public static Fleet_Forecast__c updateFleetForecast(Fleet_Forecast__c singlePeriod, List<Vehicle__c> vehicles) {
        System.debug(LoggingLevel.DEBUG, 'forecast period (before): ' + singlePeriod);
        System.debug(LoggingLevel.DEBUG, 'number of vehicles: ' + vehicles?.size());
        System.debug(LoggingLevel.FINE, 'vehicles: ' + vehicles);
        Integer numberActiveDK = 0;
        Integer numberInfleetDK = 0;
        Integer numberDefleetDK = 0;
        Integer numberActiveValuta = 0;
        Integer numberInfleetValuta = 0;
        Integer numberDefleetValuta = 0;
        // go through the list of vehicles
        for (Vehicle__c vehicle : vehicles) {
            // is the car DK or Valuta??
            // vehicle.Valuta_Vehicle__c

            // infleet - would be this vehicle infleeted in this period
            if (
                vehicle.Planned_Infleet_Date__c != null &&
                vehicle.Planned_Infleet_Date__c >= singlePeriod.First_Day__c &&
                vehicle.Planned_Infleet_Date__c <= singlePeriod.Last_Day__c
            ) {
                if (vehicle.Valuta_Vehicle__c) {
                    numberInfleetValuta++;
                } else {
                    numberInfleetDK++;
                }
            }
            // defleet - would be this vehicle defleeted in this period
            if (
                vehicle.Expected_Defleet_Date__c != null &&
                vehicle.Expected_Defleet_Date__c >= singlePeriod.First_Day__c &&
                vehicle.Expected_Defleet_Date__c <= singlePeriod.Last_Day__c
            ) {
                if (vehicle.Valuta_Vehicle__c) {
                    numberDefleetValuta++;
                } else {
                    numberDefleetDK++;
                }
            }
            // active - it is active at the period first day? OR would it be infleeted before period first day AND would NOT be defleeted before period first day
            // was it registered before the period start? Else is it planned to be infleeted before the period first day?
            Boolean isActive = false;
            if (vehicle.Registration_Date__c != null && vehicle.Registration_Date__c < singlePeriod.First_Day__c) {
                isActive = true;
            } else if (vehicle.Planned_Infleet_Date__c != null && vehicle.Planned_Infleet_Date__c < singlePeriod.First_Day__c) {
                isActive = true;
            }
            // is it planned to be defleeted before the period first day?
            if (vehicle.Expected_Defleet_Date__c != null && vehicle.Expected_Defleet_Date__c < singlePeriod.First_Day__c) {
                isActive = false;
            }
            // increase the count if is active before the first day
            if (isActive) {
                if (vehicle.Valuta_Vehicle__c) {
                    numberActiveValuta++;
                } else {
                    numberActiveDK++;
                }
            }
        }
        // any updates needed
        if (
            singlePeriod.Current_fleet_DK__c != numberActiveDK ||
            singlePeriod.Infleet_DK__c != numberInfleetDK ||
            singlePeriod.Defleet_DK__c != numberDefleetDK ||
            singlePeriod.Current_fleet_Valuta__c != numberActiveValuta ||
            singlePeriod.Infleet_Valuta__c != numberInfleetValuta ||
            singlePeriod.Defleet_Valuta__c != numberDefleetValuta
        ) {
            // update required
            singlePeriod.Current_fleet_DK__c = numberActiveDK;
            singlePeriod.Infleet_DK__c = numberInfleetDK;
            singlePeriod.Defleet_DK__c = numberDefleetDK;
            singlePeriod.Current_fleet_Valuta__c = numberActiveValuta;
            singlePeriod.Infleet_Valuta__c = numberInfleetValuta;
            singlePeriod.Defleet_Valuta__c = numberDefleetValuta;
        } else {
            // update not required - return null
            return null;
        }

        return singlePeriod;
    }
}