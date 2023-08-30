public with sharing class IntegrationRequestsBatchable implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public Map<String, String> SUPPORTED_API_CALLS;
    public Boolean isAnyFailedRequest = false;
    public Integer failedRequestCount = 0;

    public static final String ERROR_NO_VEHICLE = 'Vehicle has not been assigned to the request!';
    public static final String ERROR_WRONG_METHOD = 'Method undefinied!';

    public static final String VEHICLE_FIELDS = Label.Xfleet_Integration_Request_Vehicle_Fields;

    public IntegrationRequestsBatchable() {
        // get supported calls
        SUPPORTED_API_CALLS = new Map<String, String>();
        for (Integration_Requests_Processor__mdt irProcessorSetting : [SELECT API_Method__c, Apex_Process__c FROM Integration_Requests_Processor__mdt]) {
            SUPPORTED_API_CALLS.put(irProcessorSetting.API_Method__c, irProcessorSetting.Apex_Process__c);
        }
        System.debug(LoggingLevel.FINE, 'initialize integration job for these methods: ' + SUPPORTED_API_CALLS?.keySet());
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        System.debug(LoggingLevel.FINE, 'query integration requests for these methods: ' + SUPPORTED_API_CALLS?.keySet());
        return Database.getQueryLocator(
            [
                SELECT Status__c, Vehicle__c, API_Method__c, Data__c
                FROM Integration_Request__c
                WHERE Status__c = NULL AND API_Method__c IN :SUPPORTED_API_CALLS.keySet()
            ]
        );
    }

    public void execute(Database.BatchableContext context, List<Integration_Request__c> scope) {
        System.debug(LoggingLevel.DEBUG, 'execute integration requests: ' + scope);
        Map<Id, Id> mVehicle2Request = new Map<Id, Id>();
        for (Integration_Request__c ir : scope) {
            if (ir.Vehicle__c != null) {
                mVehicle2Request.put(ir.Vehicle__c, ir.Id);
            }
        }
        // query vehicles data
        String vehiclesQuery = 'SELECT ' + String.escapeSingleQuotes(VEHICLE_FIELDS) + ' FROM Vehicle__c WHERE Id IN :vehIds';
        Map<String, Object> vehiclesQueryParams = new Map<String, Object>{ 'vehIds' => mVehicle2Request.keySet() };
        Map<Id, Vehicle__c> mVehicles = new Map<Id, Vehicle__c>((List<Vehicle__c>)Database.queryWithBinds(vehiclesQuery, vehiclesQueryParams, AccessLevel.SYSTEM_MODE));
        System.debug(LoggingLevel.DEBUG, 'execute integration requests with these vehicles: ' + mVehicles);
        for (Integration_Request__c ir : scope) {
            // set Integration Request processed timestamp
            ir.Last_Processing_Time__c = System.now();
            if (ir.Vehicle__c != null) {
                // process API calls one-by-one
                ir = processSingleRequest(ir, mVehicles.get(ir.Vehicle__c));
            } else {
                // ERROR there is no vehicle assigned to the request
                ir.Status__c = IntegrationRequestsUtility.STATUS_FAILED;
                ir.Message__c = ERROR_NO_VEHICLE;
            }
            if (ir.Status__c.equals(IntegrationRequestsUtility.STATUS_FAILED) && !isAnyFailedRequest) {
                isAnyFailedRequest = true;
                failedRequestCount++;
            }
        }
        update scope;
    }

    public void finish(Database.BatchableContext context) {
        // update count of integration request on a vehicle
        IntegrationRequestsUtility.updateIntegrationRequestsRollups();
        // any post actions?
        IntegrationRequestsUtility.postProcessActions();
        // set the timestamp when the job was finished
        IntegrationRequestsUtility.setLastJobRunTime(System.now());
        // any failed request?
        if (isAnyFailedRequest) {
            IntegrationRequestsUtility.notifyAdminsAboutFailedRequests(failedRequestCount);
        }
    }

    private Integration_Request__c processSingleRequest(Integration_Request__c req, Vehicle__c veh) {
        IntegrationRequestsProcess irProcess;
        if (SUPPORTED_API_CALLS.containsKey(req.API_Method__c)) {
            // Find the right implmenation of IR processor
            String apexProcessorType = SUPPORTED_API_CALLS.get(req.API_Method__c);
            // Get the Type corresponding to the class name
            Type t = Type.forName(apexProcessorType);
            // instantiate the process class
            irProcess = (IntegrationRequestsProcess) t.newInstance();
            // process the Integration Request
            req = irProcess.process(req, veh);
        } else {
            // FAILED - method not supported
            req.Status__c = IntegrationRequestsUtility.STATUS_FAILED;
            req.Message__c = ERROR_WRONG_METHOD;
        }
        return req;
    }
}