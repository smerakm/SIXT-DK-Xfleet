public with sharing class CobraFleetOverview2VehicleScheduler implements Schedulable {
    public void execute(SchedulableContext SC) {
        // get last import date
        Fleet_Overview__c lastRecord = [SELECT Import_Date__c FROM Fleet_Overview__c ORDER BY Import_Date__c DESC LIMIT 1];
        System.debug('last Fleet Overview import date: ' + lastRecord.Import_Date__c);
        // execute batch job
        CobraFleetOverview2VehicleBatch updateFromFleetOverviewJob = new CobraFleetOverview2VehicleBatch(lastRecord.Import_Date__c);
        ID batchJobId = Database.executeBatch(updateFromFleetOverviewJob);
    }
}
