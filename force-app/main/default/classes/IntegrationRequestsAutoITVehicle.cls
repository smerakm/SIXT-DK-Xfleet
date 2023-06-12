public with sharing class IntegrationRequestsAutoITVehicle implements IntegrationRequestsProcess {
    
    public static final String METHOD_INSERT = 'AutoIT-createCar';
    public static final String METHOD_UPDATE = 'AutoIT-updateCar';
    public static final String METHOD_STATUS_UPDATE = 'AutoIT-carStatusUpdate';

    public Integration_Request__c process(Integration_Request__c req, Vehicle__c veh) {
        AutoITVehicle autoItApi;
        // CREATE / UPDATE = UPSERT vehicle
        if (req.API_Method__c.equals(METHOD_INSERT)) {
            autoItApi = new AutoITVehicleCreate();
        } else if (req.API_Method__c.equals(METHOD_UPDATE)) {
            autoItApi = new AutoITVehicleUpdate (veh.AutoDesktop_Id__c);
        } else if (req.API_Method__c.equals(METHOD_STATUS_UPDATE)) {
            // STATUS UPDATE
            // TODO status update
        }
        // is method supported?
        if (autoItApi != null) {
            // prepare data and call API
            AutoITVehicleObject theCar;
            // are data already prepared in the request record?
            if (String.isNotBlank(req.Data__c)) {
                theCar = (AutoITVehicleObject) JSON.deserialize(req.Data__c, AutoITVehicleObject.class);
            } else {
                // clone the vehicle to skip "SObject row was retrieved via SOQL without querying the requested field" error
                Vehicle__c tempVehicle = veh.clone();
                theCar = new AutoITVehicleObject(tempVehicle);
                req.Data__c = JSON.serialize(theCar, true);
            }
            HttpRequest apiReq = autoItApi.prepareRequest(theCar);
            HttpResponse apiResp = autoItApi.call(apiReq);
            // is it success?
            Integer statusCode = apiResp.getStatusCode();
            if ((statusCode == 200) || (statusCode == 201)) {
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