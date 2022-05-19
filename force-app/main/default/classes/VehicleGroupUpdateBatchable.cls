/**
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Batch Class to update Vehicle Group on Vehicles.
 * Already defleeted vehicles are excluded.
 *
 * It provides following functionality:
 * - mapping from Acriss code to Vehicle_Group__c
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-04-01
 * @modified       2022-04-01
 * @systemLayer    Automatization
 * @see            SIX-4
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-04-01      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
global class VehicleGroupUpdateBatchable implements Database.Batchable<Vehicle__c> {
    
    private static Boolean runForecastUpdate = true;

    global List<Vehicle__c> start(Database.BatchableContext jobId) {
        List<Vehicle__c> recordList = new List<Vehicle__c>();
        recordList = [SELECT ACRISS_Code__c, Vehicle_Group__c FROM Vehicle__c WHERE ACRISS_Code__c != null AND Vehicle_status__c != '00-']; 
        return recordList;
    }

    global void execute(Database.BatchableContext jobId, List<Vehicle__c> recordList) {
        // get Acriss to Vehicle Group map
        Map<String, Vehicle_Group__c> mAcriss2VehicleGroup = VehicleGroupUtility.getAcriss2VehicleGroupMap();
        // list of vehicles to update
        List<Vehicle__c> vehiclesWithUpdatedGroup = new List<Vehicle__c>();
        // go through list of vehicles and set Vehicle group for each
        for (Vehicle__c vehicle : recordList) {
            Id vehicleGroupId;
            // map from acriss code
            if (String.isNotBlank(vehicle.ACRISS_Code__c)) {
                vehicleGroupId = mAcriss2VehicleGroup.get(vehicle.ACRISS_Code__c)?.Id;
            }
            // is vehicle group changed?
            if ((vehicleGroupId != null) && (vehicleGroupId != vehicle.Vehicle_Group__c)) {
                vehicle.Vehicle_Group__c = vehicleGroupId;
                vehiclesWithUpdatedGroup.add(vehicle);
            }
        }
        // any update?
        if (!vehiclesWithUpdatedGroup.isEmpty()) {
            update vehiclesWithUpdatedGroup;
        }
    }

    global void finish(Database.BatchableContext jobIdParam) {
        if (runForecastUpdate) {
            // one group at the time
            Id batchJobId = Database.executeBatch(new FleetForecastUpdateBatch(), 1);
        }
    }
}