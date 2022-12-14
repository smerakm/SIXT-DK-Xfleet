public with sharing class IntegrationRequestsUtility {
    public static final String BATCH_JOB_APEX_NAME = 'IntegrationRequestsBatchable';
    public static final String BATCH_JOB_NAME = 'Xfleet Integration job';

    public static final String STATUS_SUCCESS = 'Success';
    public static final String STATUS_FAILED = 'Failed';

    public static final Set<String> JOB_IN_PROGRESS_STATUSES = new Set<String>{'Queued', 'Preparing', 'Processing'};

    @InvocableMethod(label='Xfleet Integration Job Run' description='Manually trigger Xfleet Integration Job run!')
    public static void runNavisionIntegrationJob() {
        scheduleIntegrationBatch(0);
    }

    public static Id scheduleIntegrationBatch() {
        Integer delay = getJobDelay();
        return scheduleIntegrationBatch(delay);
    }

    public static Id scheduleIntegrationBatch(Integer delay) {
        // are there any integration request to process?
        List<Integration_Request__c> irCheck = [SELECT id FROM Integration_Request__c WHERE Status__c = NULL LIMIT 1];
        if (irCheck.isEmpty()) {
            return null;
        }
        // is the job already scheduled?
        List<CronJobDetail> cronJobs = [SELECT Id, Name FROM CronJobDetail WHERE Name = :BATCH_JOB_NAME];
        if (cronJobs.size() > 0) {
            return cronJobs.get(0).Id;
        }
        // is the job already in progress?
        List<AsyncApexJob> alreadyScheduledJobs = [
            SELECT ApexClassId, CreatedDate, CronTriggerId, Id, JobType, MethodName, Status
            FROM AsyncApexJob
            WHERE Status = 'In Progress' AND JobType = 'BatchApex' AND ApexClass.Name = :BATCH_JOB_APEX_NAME
        ];
        if (alreadyScheduledJobs.size() > 0) {
            // already scheduled
            return alreadyScheduledJobs.get(0).Id;
        }
        // not already scheduled, schedule NEW
        IntegrationRequestsBatchable theBatch = new IntegrationRequestsBatchable();
        // TODO scope size
        return System.scheduleBatch(theBatch, BATCH_JOB_NAME, delay);
    }

    public static void updateIntegrationRequestsRollups() {
        // get all integration request since last job run to get impacted vehicles
        Datetime lastRun = getLastJobRunTime();
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

    public static Integer getJobDelay() {
        IntegrationSettings__c settings = IntegrationSettings__c.getInstance();
        return (Integer) settings.Batch_Job_Delay_in_minutes__c;
    }

    public static Datetime getLastJobRunTime() {
        IntegrationSettings__c settings = IntegrationSettings__c.getInstance();
        return settings.Job_last_run_at__c;
    }

    public static void setLastJobRunTime(Datetime runDatetime) {
        IntegrationSettings__c settings = IntegrationSettings__c.getOrgDefaults();
        settings.Job_last_run_at__c = runDatetime;
        update settings;
    }
}
