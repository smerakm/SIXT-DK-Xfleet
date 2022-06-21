public with sharing class CobraFleetOverview2VehicleUtility {
    /* MAPPING **
Fleet Overview label	fleet overview API name data type               Vehicle Field Label Vehicle API Name    data type
City name               City_name__c	        Text(255)	            Current city	    Current_city__c	    Text(50)
Description	            Description__c	        Text(255)	            xCar description	Car_description__c	Text(100)
Internal No.	        Internal_No__c	        Number(18, 0)	        ?Internal Number?	?Internal_number__c Number(18, 0) (External ID) (Unique)
KM	                    KM__c	                Number(18, 0)	        Current KM	        Current_KM__c	    Number(18, 0)
Registration	        Registration__c         Text(255) (External ID)	?License plate?	    ?License_plate__c?	Text(18)
Sixt model	            Sixt_model__c	        Number(18, 0)	        COBRA Model #	    COBRA_Model__c	    Number(18, 0)
Veh. status	            Veh_status__c	        Number(18, 0)	        Vehicle status	    Vehicle_status__c	Picklist
*/

    /* update Vehicles from list of Fleet Overview
        first with matching by Internal Number
        if there are Fleet Overviews that have not been matched, we try also matching by License Plate (can be turn on and off)
     * input: list of Fleet_Overview__c
     *          useLicensePlateBackupMatching: if true matching by License Plate can be used for unmatched Fleet Overviews, if false there records are just skipped
     *          runDML: option to run the function with/without save data in DB
     * output: map of Vehicle__c, where key: Internal Number, value Vehicle__c
     */
    public static Map<Decimal, Vehicle__c> updateVehiclesFromFleetOverviewList(
        List<Fleet_Overview__c> fleetOverviews,
        Boolean useLicensePlateBackupMatching,
        Boolean runDML
    ) {
        System.debug(
            LoggingLevel.DEBUG,
            'run update of Vehicles from Fleet Overview where, size: ' +
            fleetOverviews.size() +
            ', useLicensePlateBackupMatching: ' +
            useLicensePlateBackupMatching +
            ', runDML: ' +
            runDML
        );
        // first, matching by Internal Number
        Map<Decimal, Vehicle__c> vehiclesUpdated = updateVehiclesByInternalNumber(fleetOverviews);
        System.debug(LoggingLevel.FINE, 'updated from Fleet Overview just by Internal_No__c, size: ' + vehiclesUpdated.size());
        System.debug(LoggingLevel.FINE, 'list of Fleet Overviews input, size: ' + fleetOverviews.size());
        // do we need to use License Plate too?
        if (useLicensePlateBackupMatching && (vehiclesUpdated.size() != fleetOverviews.size())) {
            System.debug(LoggingLevel.FINE, 'there are some unmatched!');
            // find unmatched Fleet Overviews
            List<Fleet_Overview__c> unmatchedFleetOverviews = new List<Fleet_Overview__c>();
            for (Fleet_Overview__c fleetOverview : fleetOverviews) {
                // has been already matched by Internal Number?
                if (!vehiclesUpdated.containsKey(fleetOverview.Internal_No__c)) {
                    // no, so add it to the unmatched list
                    unmatchedFleetOverviews.add(fleetOverview);
                }
            }
            System.debug(LoggingLevel.FINE, 'unmatched size: ' + unmatchedFleetOverviews.size());
            // update vehicles
            Map<Decimal, Vehicle__c> vehiclesUpdatedFromLicensePlate;
            if (!unmatchedFleetOverviews.isEmpty()) {
                vehiclesUpdatedFromLicensePlate = updateVehiclesByLicensePlate(unmatchedFleetOverviews);
            }
            System.debug(LoggingLevel.FINE, 'updated from Fleet Overview just by LICENSE PLATE, size: ' + vehiclesUpdatedFromLicensePlate.size());
            // merge maps
            if (!vehiclesUpdatedFromLicensePlate?.isEmpty()) {
                vehiclesUpdated.putAll(vehiclesUpdatedFromLicensePlate);
            }
            System.debug(LoggingLevel.FINE, 'updated from Fleet Overview, size after merge: ' + vehiclesUpdated.size());
        }
        // DML?
        if (runDML) {
            update vehiclesUpdated.values();
            System.debug(LoggingLevel.FINE, 'Updates successful!');
        }
        return vehiclesUpdated;
    }

    /* update Vehicles from list of Fleet Overview where we have match by Internal Number
     * input: list of Fleet_Overview__c
     * output: map of Vehicle__c, where key: Internal Number, value Vehicle__c
     */
    public static Map<Decimal, Vehicle__c> updateVehiclesByInternalNumber(List<Fleet_Overview__c> fleetOverviews) {
        Map<Decimal, Vehicle__c> mVehiclesUpdated = new Map<Decimal, Vehicle__c>();
        // get set of Internal Numbers to query vehicles
        Set<Decimal> internalNumbers = new Set<Decimal>();
        for (Fleet_Overview__c fleetOverview : fleetOverviews) {
            internalNumbers.add(fleetOverview.Internal_No__c);
        }
        // get vehicles
        Map<Decimal, Vehicle__c> mVehiclesToUpdate = getVehiclesByInternalNumber(internalNumbers);
        // update vehicles
        for (Fleet_Overview__c fleetOverview : fleetOverviews) {
            if (mVehiclesToUpdate.containsKey(fleetOverview.Internal_No__c)) {
                Vehicle__c singleVehicleUpdated = updateVehicleFromFleetOverview(mVehiclesToUpdate.get(fleetOverview.Internal_No__c), fleetOverview);
                mVehiclesUpdated.put(fleetOverview.Internal_No__c, singleVehicleUpdated);
            }
        }
        return mVehiclesUpdated;
    }

    /* update Vehicles from list of Fleet Overview where we DON'T have match by Internal Number
     *       in this case we try to identify by License Plate and update Internal Number too
     * input: list of Fleet_Overview__c
     * output: map of Vehicle__c, where key: Internal Number, value Vehicle__c
     */
    public static Map<Decimal, Vehicle__c> updateVehiclesByLicensePlate(List<Fleet_Overview__c> fleetOverviews) {
        Map<Decimal, Vehicle__c> mVehiclesUpdated = new Map<Decimal, Vehicle__c>();
        // get set of License plates to query vehicles
        Set<String> licensePlates = new Set<String>();
        for (Fleet_Overview__c fleetOverview : fleetOverviews) {
            licensePlates.add(fleetOverview.Registration__c);
        }
        // get vehicles
        Map<String, Vehicle__c> mVehiclesToUpdate = getVehiclesByLicensePlate(licensePlates);
        // update vehicles
        for (Fleet_Overview__c fleetOverview : fleetOverviews) {
            if (mVehiclesToUpdate.containsKey(fleetOverview.Registration__c)) {
                Vehicle__c singleVehicleUpdated = updateVehicleFromFleetOverview(mVehiclesToUpdate.get(fleetOverview.Registration__c), fleetOverview);
                // update internal number too
                singleVehicleUpdated.Internal_number__c = fleetOverview.Internal_No__c;
                mVehiclesUpdated.put(fleetOverview.Internal_No__c, singleVehicleUpdated);
            }
        }
        return mVehiclesUpdated;
    }

    public static Map<Decimal, Vehicle__c> getVehiclesByInternalNumber(Set<Decimal> internalNumbers) {
        Map<Decimal, Vehicle__c> mVehicles = new Map<Decimal, Vehicle__c>();
        List<Vehicle__c> vehiclesList = getVehicles(internalNumbers, null);
        for (Vehicle__c vehicle : vehiclesList) {
            mVehicles.put(vehicle.Internal_number__c, vehicle);
        }
        return mVehicles;
    }

    public static Map<String, Vehicle__c> getVehiclesByLicensePlate(Set<String> licensePlates) {
        Map<String, Vehicle__c> mVehicles = new Map<String, Vehicle__c>();
        List<Vehicle__c> vehiclesList = getVehicles(null, licensePlates);
        for (Vehicle__c vehicle : vehiclesList) {
            mVehicles.put(vehicle.License_plate__c, vehicle);
        }
        return mVehicles;
    }

    /* get vehicles with all required fields and filtered by input parameters
     * vehicles already defleeted in Cobra (00-) are excluded 
     */ 
    public static List<Vehicle__c> getVehicles(Set<Decimal> internalNumbers, Set<String> licensePlates) {
        return [
            SELECT Current_city__c, Car_description__c, Internal_number__c, Current_KM__c, License_plate__c, COBRA_Model__c, Vehicle_status__c
            FROM Vehicle__c
            WHERE (Internal_number__c IN :internalNumbers OR License_plate__c IN :licensePlates)
            AND Vehicle_status__c != '00-'
        ];
    }

    public static Vehicle__c updateVehicleFromFleetOverview(Vehicle__c vehicle, Fleet_Overview__c fleetOverview) {
        vehicle.Current_city__c = fleetOverview.City_name__c;
        vehicle.Car_description__c = fleetOverview.Description__c;
        vehicle.Current_KM__c = fleetOverview.KM__c;
        vehicle.COBRA_Model__c = fleetOverview.Sixt_model__c;
        vehicle.Vehicle_status__c = String.valueOf(fleetOverview.Veh_status__c);
        return vehicle;
    }
}