public with sharing class CobraFleetOverview2VehicleBatch implements Database.Batchable<Fleet_Overview__c>, Database.Stateful {
    private Date importDate;
    public Integer numberOfUpdatedVehicles;

    public CobraFleetOverview2VehicleBatch(Date batchImportDate) {
        this.importDate = batchImportDate;
        this.numberOfUpdatedVehicles = 0;
    }

    public List<Fleet_Overview__c> start(Database.BatchableContext bc) {
        // get all from last import
        List<Fleet_Overview__c> fleets = [
            SELECT City_name__c, Description__c, Internal_No__c, KM__c, Registration__c, Sixt_model__c, Veh_status__c
            FROM Fleet_Overview__c
            WHERE Import_Date__c = :this.importDate
        ];
        return fleets;
    }

    public void execute(Database.BatchableContext bc, List<Fleet_Overview__c> scope) {
        // run the update
        Map<Decimal, Vehicle__c> vehicles = CobraFleetOverview2VehicleUtility.updateVehiclesFromFleetOverviewList(scope, true, true);
        numberOfUpdatedVehicles += vehicles.size(); 
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Update from Fleet Overview batch finished, updated ' + this.numberOfUpdatedVehicles + ' updated!');
        
    }
}