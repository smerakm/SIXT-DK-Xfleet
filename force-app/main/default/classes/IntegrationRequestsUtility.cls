public with sharing class IntegrationRequestsUtility {
    public static final String BATCH_JOB_APEX_NAME = 'IntegrationRequestsBatchable';
    public static final String BATCH_JOB_NAME = 'Xfleet Integration job';

    public static final String STATUS_SUCCESS = 'Success';
    public static final String STATUS_FAILED = 'Failed';

    public static final Set<String> JOB_IN_PROGRESS_STATUSES = new Set<String>{ 'Queued', 'Preparing', 'Processing' };

    public static final String FAILED_REQUESTS_REPORT_NAME = 'Failed_Integration_Requests_ksj';
    public static final String ADMIN_GROUP_NAME = 'Xfleet_Admins';
    public static final String NOTIFICATION_TITLE_FAILED_REQS = 'Failed Integration Requests';
    public static final String NOTIFICATION_BODY_FAILED_REQS_PART_1 = 'Integration job processed with ';
    public static final String NOTIFICATION_BODY_FAILED_REQS_PART_2 = ' Failed Integration Requests';

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
        Integer batchSize = getBatchSize();
        return System.scheduleBatch(theBatch, BATCH_JOB_NAME, delay, batchSize);
    }

    public static void updateIntegrationRequestsRollups() {
        // get all integration request since last job run to get impacted vehicles
        Datetime lastRun = getLastJobRunTime();
        Set<Id> vehicles4UpdateIds = new Set<Id>();
        for (Integration_Request__c req : [SELECT Vehicle__c FROM Integration_Request__c WHERE LastModifiedDate >= :lastRun AND Vehicle__c != null]) {
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

    // process any vehicle (or other object) updates that are needed as result of the calls
    // implementation of the method is Xfleet specific and needs to be re-written if the framework is used outside of Xfleet
    public static void postProcessActions() {
        // API methods with post-process actions
        Set<String> methodsWithAction = new Set<String>{ IntegrationRequestsNAVCars.METHOD_CREATE };
        // get all integration request since last job run to get impacted vehicles
        Datetime lastRun = getLastJobRunTime();
        // vehicles for update
        Map<Id, Vehicle__c> mVehicles = new Map<Id, Vehicle__c>();
        for (Integration_Request__c req : [SELECT Vehicle__c, API_Method__c, Status__c, Last_Processing_Time__c FROM Integration_Request__c WHERE API_Method__c IN :methodsWithAction AND Status__c != null AND LastModifiedDate >= :lastRun AND Vehicle__c != null]) {
            Vehicle__c veh;
            Boolean updatedByAction = false;
            if (mVehicles.containsKey(req.Vehicle__c)) {
                veh = mVehicles.get(req.Vehicle__c);
            } else {
                veh = new Vehicle__c(id = req.Vehicle__c);
            }
            // NAV CREATE
            if (req.API_Method__c.equals(IntegrationRequestsNAVCars.METHOD_CREATE)) {
                if (req.Status__c.endsWithIgnoreCase('Success')) {
                    veh.Created_in_Navision_at__c = req.Last_Processing_Time__c;
                    updatedByAction = true;
                }
            }
            // only put into the map if updated
            if (updatedByAction) {
                mVehicles.put(req.Vehicle__c, veh);
            }
        }
        // any vehicles for update?
        if (!mVehicles.isEmpty()) {
            // update vehicles
            update mVehicles.values();
        }
    }

    public static void notifyAdminsAboutFailedRequests(Integer failedReqCount) {
        // Get the Id for our custom notification type
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'Xfleet_Notification'];

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        // Set the contents for the notification
        notification.setTitle(NOTIFICATION_TITLE_FAILED_REQS);
        String notificationBody = NOTIFICATION_BODY_FAILED_REQS_PART_1;
        if (failedReqCount != null) {
            notificationBody += String.valueOf(failedReqCount) + NOTIFICATION_BODY_FAILED_REQS_PART_2;
        }  else {
            notificationBody += '?' + NOTIFICATION_BODY_FAILED_REQS_PART_2;
        }
        notification.setBody(notificationBody);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        // set target to failed requests report
        try {
            Id targetId = [SELECT Id, DeveloperName FROM Report WHERE DeveloperName = :FAILED_REQUESTS_REPORT_NAME LIMIT 1].Id;
            notification.setTargetId(targetId);
        } catch (System.QueryException qe) {
            String targetRef = '{"type": "standard__objectPage","attributes": {"objectApiName": "Integration_Request__c","actionName": "list"},"state": {"filterName": "Recent"}}';
            notification.setTargetPageRef(targetRef);
        }

        // Actually send the notification
        Id receiverId;
        try {
            receiverId = [SELECT Id FROM Group WHERE NAME = :ADMIN_GROUP_NAME LIMIT 1].Id;
        } catch (System.QueryException qe) {
            receiverId = UserInfo.getUserId();
        }
        notification.send(new Set<String>{ receiverId });
    }

    public static Integer getJobDelay() {
        IntegrationSettings__c settings = IntegrationSettings__c.getInstance();
        return (Integer) settings.Batch_Job_Delay_in_minutes__c;
    }

    public static Integer getBatchSize() {
        IntegrationSettings__c settings = IntegrationSettings__c.getInstance();
        return (Integer) settings.Batch_Size__c;
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