public with sharing class IntegrationRequestsAutoITVehicle implements IntegrationRequestsProcess {
    
    public static final String METHOD_INSERT = 'AutoIT-createCar';
    public static final String METHOD_UPDATE = 'AutoIT-updateCar';
    public static final String METHOD_DELETE = 'AutoIT-delete';
    public static final String METHOD_STATUS_UPDATE = 'AutoIT-markAsSold';

    public Integration_Request__c process(Integration_Request__c req, Vehicle__c veh) {
        AutoITVehicle autoItApi;
        // CREATE / UPDATE = UPSERT vehicle
        if (req.API_Method__c.equals(METHOD_INSERT)) {
            autoItApi = new AutoITVehicleCreate();
        } else if (req.API_Method__c.equals(METHOD_UPDATE)) {
            autoItApi = new AutoITVehicleUpdate (veh.AutoDesktop_Id__c);
        } else if (req.API_Method__c.equals(METHOD_DELETE)) {
            autoItApi = new AutoITVehicleDelete (veh.AutoDesktop_Id__c);
        } else if (req.API_Method__c.equals(METHOD_STATUS_UPDATE)) {
            autoItApi = new AutoITVehicleMarkAsSold(veh.AutoDesktop_Id__c);
        }
        // is method supported?
        if (autoItApi != null) {
            // prepare data and call API
            HttpRequest apiReq;
            // are data already prepared in the request record?
            if (String.isNotBlank(req.Data__c)) {
                apiReq = autoItApi.prepareRequest(req.Data__c);
            } else if (req.API_Method__c.equals(METHOD_INSERT)) {
                AutoITVehicleObject theCar;
                theCar = AutoITVehicleObject.createWithDefaults(veh, req.API_Method__c);
                req.Data__c = JSON.serialize(theCar, true);
                apiReq = autoItApi.prepareRequest(theCar);
            } else if (req.API_Method__c.equals(METHOD_UPDATE)) {
                // TODO
                apiReq = autoItApi.prepareRequest(null);
            } else if (req.API_Method__c.equals(METHOD_STATUS_UPDATE)) {
                apiReq = autoItApi.prepareRequest(veh);
                req.Data__c = apiReq.getBody();
            } else {
                apiReq = autoItApi.prepareRequest(null);
            }

            HttpResponse apiResp = autoItApi.call(apiReq);
            // is it success?
            Integer statusCode = apiResp.getStatusCode();
            if ((statusCode >= 200) && (statusCode < 300)) {
                // SUCCESS
                req.Status__c = IntegrationRequestsUtility.STATUS_SUCCESS;
                // process respone after create a vehicle, to store Autodesktop Id in Salesforce
                if (req.API_Method__c.equals(METHOD_INSERT)) {
                    autoItApi.processResponse(apiResp.getBody(), veh.Id);
                }
            } else {
                req.Status__c = IntegrationRequestsUtility.STATUS_FAILED;
            }
            // add message
            req.Message__c = constructResponseMessage(apiResp);
        } else {
            req.Status__c = IntegrationRequestsUtility.STATUS_FAILED;
            req.Message__c = IntegrationRequestsBatchable.ERROR_WRONG_METHOD;
        }
        // set Integration Request processed timestamp
        req.Last_Processing_Time__c = System.now();
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