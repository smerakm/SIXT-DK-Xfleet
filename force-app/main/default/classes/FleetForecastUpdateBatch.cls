// list all vehicle groups and trigger Fleet Forecast update calculation 1 by 1
global class FleetForecastUpdateBatch implements Database.Batchable<Vehicle_Group__c> {
    global List<Vehicle_Group__c> start(Database.BatchableContext jobId) {
        List<Vehicle_Group__c> recordList = new List<Vehicle_Group__c>();
        // all vehicle groups
        recordList = [SELECT Id, Name FROM Vehicle_Group__c];
        return recordList;
    }

    global void execute(Database.BatchableContext jobId, List<Vehicle_Group__c> recordList) {
        // list of vehicles to update
        List<Fleet_Forecast__c> forecastsToUpdateAll = new List<Fleet_Forecast__c>();
        // go through list of vehicle groups and calculate updates for forecast for each group
        for (Vehicle_Group__c vehicleGroup : recordList) {
            // run utility method
            System.debug(LoggingLevel.DEBUG, 'calculate forecasts for vehicle group: ' + vehicleGroup);
            List<Fleet_Forecast__c> forecastsForTheGroup = FleetForecastUpdateUtility.getFleetForecastUpdates(vehicleGroup.Id);
            forecastsToUpdateAll.addAll(forecastsForTheGroup);
        }
        // any update?
        if (!forecastsToUpdateAll.isEmpty()) {
            update forecastsToUpdateAll;
        }
    }

    global void finish(Database.BatchableContext jobIdParam) {
    }
}