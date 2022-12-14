public with sharing class NAVCarsUtility {
    public static final String BATCH_JOB_NAV_CARS_APEX_NAME = 'NAVCarsIntegrationBatchable';
    public static final String BATCH_JOB_NAV_CARS_JOB_NAME = 'NAV Cars Integration job';

    @InvocableMethod(label='Navision Cars Job Run' description='Manually trigger Navision Integration Job run!')
    public static void runNavisionIntegrationJob() {
        scheduleNAVCarsIntegrationBatch(0);
    }

    public static Id scheduleNAVCarsIntegrationBatch() {
        Integer delay = getNavJobDelay();
        return scheduleNAVCarsIntegrationBatch(delay);
    }

    public static Id scheduleNAVCarsIntegrationBatch(Integer delay) {
        // are there any integration request to process?
        List<Integration_Request__c> irCheck = [SELECT id FROM Integration_Request__c WHERE Status__c = null LIMIT 1];
        if (irCheck.isEmpty()) {
            return null;
        }
        // is the job already scheduled?
        List<CronJobDetail> cronJobs = [SELECT Id, Name FROM CronJobDetail WHERE Name = :BATCH_JOB_NAV_CARS_JOB_NAME];
        if (cronJobs.size() > 0) {
            return cronJobs.get(0).Id;
        }
        // is the job already in progress?
        List<AsyncApexJob> alreadyScheduledJobs = [
            SELECT ApexClassId, CreatedDate, CronTriggerId, Id, JobType, MethodName, Status
            FROM AsyncApexJob
            WHERE Status != 'Completed' AND JobType = 'BatchApex' AND ApexClass.Name = :BATCH_JOB_NAV_CARS_APEX_NAME
        ];
        if (alreadyScheduledJobs.size() > 0) {
            // already scheduled
            return alreadyScheduledJobs.get(0).Id;
        }
        // not already scheduled, schedule NEW
        NAVCarsIntegrationBatchable theBatch = new NAVCarsIntegrationBatchable();
        // TODO scope size
        return System.scheduleBatch(theBatch, BATCH_JOB_NAV_CARS_JOB_NAME, delay);
    }

    public static void updateIntegrationRequestsRollups() {
        // get all integration request since last job run to get impacted vehicles
        Datetime lastRun = getLastNavJobRunTime();
        Set<Id> vehicles4UpdateIds = new Set<Id>();
        for (Integration_Request__c req : [SELECT Vehicle__c FROM Integration_Request__c WHERE LastModifiedDate >= :lastRun]) {
            vehicles4UpdateIds.add(req.Vehicle__c);
        }
        // any vehicles for update?
        if (!vehicles4UpdateIds.isEmpty()) {
            List<Vehicle__c> vehicles4Update = new List<Vehicle__c>();
            // get the vehicles
            Map<Id, Vehicle__c> mVehicles = new Map<Id, Vehicle__c>();
            // clear the current counters, so we set the correct value later
            for (Vehicle__c veh : [
                SELECT id, Integration_Requests_Number_Success__c, Integration_Requests_Number_Failed__c, Integration_Requests_Number_Not_Run_Yet__c
                FROM Vehicle__c
                WHERE Id IN :vehicles4UpdateIds
            ]) {
                veh.Integration_Requests_Number_Failed__c = 0;
                veh.Integration_Requests_Number_Not_Run_Yet__c = 0;
                veh.Integration_Requests_Number_Success__c = 0;
                mVehicles.put(veh.Id, veh);
            }
            // get the aggregated roll-ups for Integration Requests on these vehicles
            AggregateResult[] groupedIntegrationResults = [
                SELECT Vehicle__c, Status__c, count(id)
                FROM Integration_Request__c
                WHERE Vehicle__c IN :vehicles4UpdateIds
                GROUP BY Vehicle__c, Status__c
            ];
            for (AggregateResult ar : groupedIntegrationResults) {
                Id vehicleId = (Id) ar.get('Vehicle__c');
                Vehicle__c veh = mVehicles.get(vehicleId);
                String status = (String) ar.get('Status__c');
                Integer count = (Integer) ar.get('expr0');
                if (status == null) {
                    veh.Integration_Requests_Number_Not_Run_Yet__c = count;
                } else if (status.endsWithIgnoreCase('Success')) {
                    veh.Integration_Requests_Number_Success__c = count;
                } else if (status.endsWithIgnoreCase('Failed')) {
                    veh.Integration_Requests_Number_Failed__c = count;
                }
                mVehicles.put(vehicleId, veh);
            }
            // update vehicles
            update mVehicles.values();
        }
    }

    public static Integer getNavJobDelay() {
        NavisionIntegrationSettings__c settings = NavisionIntegrationSettings__c.getInstance();
        return (Integer) settings.Batch_Job_Delay_in_minutes__c;
    }

    public static Datetime getLastNavJobRunTime() {
        NavisionIntegrationSettings__c settings = NavisionIntegrationSettings__c.getInstance();
        return settings.NAV_job_last_run__c;
    }

    public static void setLastNavJobRunTime(Datetime runDatetime) {
        NavisionIntegrationSettings__c settings = NavisionIntegrationSettings__c.getOrgDefaults();
        settings.NAV_job_last_run__c = runDatetime;
        update settings;
    }
}
