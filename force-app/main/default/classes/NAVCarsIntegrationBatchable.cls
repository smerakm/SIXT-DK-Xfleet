public with sharing class NAVCarsIntegrationBatchable implements Database.Batchable<sObject>, Database.AllowsCallouts {
    public static final String METHOD_CREATE = 'NAV-createCar';
    public static final String METHOD_UPDATE = 'NAV-updateCar';
    public static final List<String> SUPPORTED_API_CALLS = new List<String>{ METHOD_CREATE, METHOD_UPDATE };
    public static final String STATUS_SUCCESS = 'Success';
    public static final String STATUS_FAILED = 'Failed';

    public static final String ERROR_NO_VEHICLE = 'Vehicle has not been assigned to the request!';
    public static final String ERROR_WRONG_METHOD = 'Method undefinied!';

    public NAVCarsIntegrationBatchable() {
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            [SELECT Status__c, Vehicle__c, API_Method__c FROM Integration_Request__c WHERE Status__c = NULL AND API_Method__c IN :SUPPORTED_API_CALLS]
        );
    }

    public void execute(Database.BatchableContext context, List<Integration_Request__c> scope) {
        Map<Id, Id> mVehicle2Request = new Map<Id, Id>();
        for (Integration_Request__c ir : scope) {
            if (ir.Vehicle__c != null) {
                mVehicle2Request.put(ir.Vehicle__c, ir.Id);
            }
        }
        // query vehicles data
        Map<Id, Vehicle__c> mVehicles = new Map<Id, Vehicle__c>(
            [SELECT vinNumber__c, License_plate__c, Batch_Distribution__c FROM Vehicle__c WHERE Id IN :mVehicle2Request.keySet()]
        );
        for (Integration_Request__c ir : scope) {
            // set Integration Request processed timestamp
            ir.Last_Processing_Time__c = System.now();
            if (ir.Vehicle__c != null) {
                // process API calls one-by-one
                ir = processSingleRequest(ir, mVehicles.get(ir.Vehicle__c));
            } else {
                // ERROR there is no vehicle assigned to the request
                ir.Status__c = STATUS_FAILED;
                ir.Message__c = ERROR_NO_VEHICLE;
            }
        }
        update scope;
    }

    public void finish(Database.BatchableContext context) {
    }

    private Integration_Request__c processSingleRequest(Integration_Request__c req, Vehicle__c veh) {
        NAVCars navApi;
        // CREATE
        if (req.API_Method__c.equals(METHOD_CREATE)) {
            navApi = new NAVCarsCreate();
        } else if (req.API_Method__c.equals(METHOD_UPDATE)) {
            // UPDATE
            navApi = new NAVCarsUpdate(veh.vinNumber__c);
        }
        // is method supported?
        if (navApi != null) {
            // prepare data and call API
            NAVCarsObject theCar = new NAVCarsObject(veh.vinNumber__c, veh.License_plate__c, veh.Batch_Distribution__c);
            HttpRequest navApiReq = navApi.prepareRequest(theCar);
            HttpResponse navApiResp = navApi.call(navApiReq);
            // is it success?
            Integer statusCode = navApiResp.getStatusCode();
            if ((statusCode == 200) || (statusCode == 201)) {
                // SUCCESS
                req.Status__c = STATUS_SUCCESS;
            } else {
                req.Status__c = STATUS_FAILED;
            }
            // add message
            req.Message__c = constructResponseMessage(navApiResp);
        } else {
            req.Status__c = STATUS_FAILED;
            req.Message__c = ERROR_WRONG_METHOD;
        }
        // return the updated req
        return req;
    }

    private String constructResponseMessage(HttpResponse httpResp) {
        String message = '[' + httpResp.getStatusCode() + ', ' + httpResp.getStatus() + ']';
        if (String.isNotBlank(httpResp.getBody())) {
            message += '\n' + httpResp.getBody();
        }
        return message;
    }
}
