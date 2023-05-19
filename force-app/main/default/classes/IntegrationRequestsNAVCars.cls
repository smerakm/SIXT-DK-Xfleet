public with sharing class IntegrationRequestsNAVCars implements IntegrationRequestsProcess{

    public static final String METHOD_CREATE = 'NAV-createCar';
    public static final String METHOD_UPDATE = 'NAV-updateCar';
    public static final String METHOD_INVOICE = 'NAV-createInvoiceQuote';
    public static final String METHOD_INVOICE_CARS_PRIVATE = 'NAV-createInvoicePrivate';

    
    public Integration_Request__c process(Integration_Request__c req, Vehicle__c veh) {
        NAVCars navApi;
        // CREATE
        if (req.API_Method__c.equals(METHOD_CREATE)) {
            navApi = new NAVCarsCreate();
        } else if (req.API_Method__c.equals(METHOD_UPDATE)) {
            // UPDATE
            navApi = new NAVCarsUpdate(veh.vinNumber__c);
        } else if (req.API_Method__c.equals(METHOD_INVOICE)) {
            // UPDATE - Create Invoice or Quote
            navApi = new NAVCarsUpdate(veh.vinNumber__c);
        } else if (req.API_Method__c.equals(METHOD_INVOICE_CARS_PRIVATE)) {
            // UPDATE - Create Invoice or Quote
            navApi = new NAVCarsUpdate(veh.vinNumber__c, NAVCars.CARS_PRIVATE_API);
        }

        // is method supported?
        if (navApi != null) {
            // prepare data and call API
            NAVCarsObject theCar;
            // are data already prepared in the request record?
            if (String.isNotBlank(req.Data__c)) {
                theCar = (NAVCarsObject)JSON.deserialize(req.Data__c, NAVCarsObject.class);
            } else {
                theCar = new NAVCarsObject(veh.vinNumber__c, veh.License_Plate_System__c, veh.Batch_Distribution__c, veh.Car_description_2__c, (Integer)veh.Current_KM__c);
                req.Data__c = JSON.serialize(theCar, true);
            }
            HttpRequest navApiReq = navApi.prepareRequest(theCar);
            HttpResponse navApiResp = navApi.call(navApiReq);
            // is it success?
            Integer statusCode = navApiResp.getStatusCode();
            if ((statusCode == 200) || (statusCode == 201)) {
                // SUCCESS
                req.Status__c = IntegrationRequestsUtility.STATUS_SUCCESS;
            } else {
                req.Status__c = IntegrationRequestsUtility.STATUS_FAILED;
            }
            // add message
            req.Message__c = constructResponseMessage(navApiResp);
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