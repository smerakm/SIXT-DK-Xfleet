global class VehicleGroupUpdateScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        // execute batch job
        Id batchJobId = Database.executeBatch(new VehicleGroupUpdateBatchable(), 200);
    }
 }