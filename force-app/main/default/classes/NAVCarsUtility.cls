public with sharing class NAVCarsUtility {
    public static final String BATCH_JOB_NAV_CARS_APEX_NAME = 'NAVCarsIntegrationBatchable';
    public static final String BATCH_JOB_NAV_CARS_JOB_NAME = 'NAV Cars Integration job';

    public static Id scheduleNAVCarsIntegrationBatch() {
        // is the job already scheduled?
        List<CronJobDetail> cronJobs = [SELECT Id, Name FROM CronJobDetail WHERE Name = :BATCH_JOB_NAV_CARS_JOB_NAME];
        if (cronJobs.size() > 0) {
            return cronJobs.get(0).Id;
        }
        // is the job already in progress?
        List<AsyncApexJob> alreadyScheduledJobs = [
            SELECT ApexClassId, CreatedDate, CronTriggerId, Id, JobType, MethodName, Status
            FROM AsyncApexJob
            WHERE Status != 'Completed' AND JobType = 'BatchApex' AND ApexClass.Name = 'NAVCarsIntegrationBatchable'
        ];
        if (alreadyScheduledJobs.size() > 0) {
            // already scheduled
            return alreadyScheduledJobs.get(0).Id;
        }
        // not already scheduled, schedule NEW
        NAVCarsIntegrationBatchable theBatch = new NAVCarsIntegrationBatchable();
        return System.scheduleBatch(theBatch, BATCH_JOB_NAV_CARS_JOB_NAME, 1);
    }
}
