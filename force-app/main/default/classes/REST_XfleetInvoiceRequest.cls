@RestResource(urlMapping='/Xfleet/v1/InvoiceRequest/*')
global with sharing class REST_XfleetInvoiceRequest {
    private static final String ANONYM_TEXT = 'anonymous-gdpr';

    private static final Map<String, String> MAP_ERROR_CODES = new Map<String, String>{
        'System.QueryException' => 'RESOURCE_NOT_FOUND',
        'System.TypeException' => 'TYPE_ERROR',
        'System.JSONException' => 'JSON_PARSER_ERROR',
        'System.DmlException' => 'DML_ERROR',
        'REST_XfleetInvoiceRequest.BuyerAccountIsMissingException' => 'BUYER_MISSING',
        'REST_XfleetInvoiceRequest.InvoiceRequestValidationException' => 'VALIDATION_ERROR',
        'REST_XfleetInvoiceRequest.NavisionInvoiceException' => 'NAVISION_ERROR',
        'REST_XfleetInvoiceRequest.ExchangeVehicleNotExistException' => 'EXCHANGE_VEHICLE_NOT_FOUND'
    };

    @HttpPost
    global static void doPost(InvoiceRequestWrapper invoiceRequest) {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        // process invoice request and set the response status
        InvoiceRequestResponseWrapper respBody = new InvoiceRequestResponseWrapper();
        try {
            respBody.id = processInvoice(invoiceRequest);
            res.statusCode = 201;
        } catch (InvoiceRequestValidationException ex) {
            res.statusCode = 400;
            respBody.message = ex.getMessage();
            respBody.errorCode = getErrorCode(ex);
        } catch (JSONException ex) {
            res.statusCode = 400;
            respBody.message = ex.getMessage();
            respBody.errorCode = getErrorCode(ex);
        } catch (TypeException ex) {
            res.statusCode = 400;
            respBody.message = ex.getMessage();
            respBody.errorCode = getErrorCode(ex);
        } catch (QueryException ex) {
            res.statusCode = 404;
            respBody.message = ex.getMessage();
            respBody.errorCode = getErrorCode(ex);
        } catch (DmlException ex) {
            res.statusCode = 400;
            respBody.message = ex.getMessage();
            respBody.errorCode = getErrorCode(ex);
        } catch (NavisionInvoiceException ex) {
            res.statusCode = 400;
            respBody.message = ex.getMessage();
            respBody.errorCode = getErrorCode(ex);
        } catch (BuyerAccountIsMissingException ex) {
            res.statusCode = 400;
            respBody.message = ex.getMessage();
            respBody.errorCode = getErrorCode(ex);
        } catch (ExchangeVehicleNotExistException ex) {
            res.statusCode = 400;
            respBody.message = ex.getMessage();
            respBody.errorCode = getErrorCode(ex);
        } catch (Exception ex) {
            res.statusCode = 500;
            respBody.message = ex.getMessage();
            respBody.errorCode = getErrorCode(ex);
        }
        // is it success or error?
        if (respBody.errorCode != null) {
            // error response:
            res.responseBody = Blob.valueOf(JSON.serialize(new List<InvoiceRequestResponseWrapper>{respBody}, true));
        } else {
            // success response
            res.responseBody = Blob.valueOf(JSON.serialize(respBody, true));  
        }
    }

    global class InvoiceRequestWrapper {
        public String vehicleId;
        public Integer customerPriceDKK; // createSalesPrice
        public Integer registrationFeeDKK; // createRegistrationFee
        public Integer additionalAccessoriesCostDKK; // createAdditionalAccessories
        public String accessoryDescription; // createAccessoryDescription
        // owner
        public String ownerName;
        public String ownerAddressLine1;
        public String ownerAddressLine2;
        public String ownerPostCode;
        public String ownerCity;
        // owner
        public String driverName;
        public String driverAddressLine1;
        public String driverAddressLine2;
        public String driverPostCode;
        public String driverCity;
        // exchange car
        public String exchangeVehicleId;
        // invoice req number
        public String externalInvoiceNumber;
    }

    global class InvoiceRequestResponseWrapper {
        public String id;
        public String navisionId;
        public String message;
        public String errorCode;
    }

    private static String processInvoice(InvoiceRequestWrapper invoiceReq) {
        // get Vehicle
        Vehicle__c veh = [
            SELECT id, vinNumber__c, licensePlateCost__c, Delivery_cost__c, Car_description_2__c, Current_KM__c, Buyer_Account__c
            FROM Vehicle__c
            WHERE Id = :invoiceReq.vehicleId
        ];
        vehicleValidation(veh);
        // get Exchange vehicle
        Vehicle__c exchangeVeh;
        if (invoiceReq.exchangeVehicleId != null) {
            List<Vehicle__c> vehs = [
                SELECT id, vinNumber__c, Sixt_steel_purchase_price__c, Car_description_2__c
                FROM Vehicle__c
                WHERE Id = :invoiceReq.exchangeVehicleId
            ];
            if (vehs.isEmpty()) {
                // exchange vehicle not found
                throw new ExchangeVehicleNotExistException('Exchange Vehicle ' + invoiceReq.exchangeVehicleId + ' not found in Xfleet!');
            } else {
                // query by id, there is only one possible vehicle found
                exchangeVeh = vehs.get(0);
            }

        }
        // create NAV request data
        NAVCarsObject navReqData = new NAVCarsObject(
            invoiceReq.externalInvoiceNumber, //createInvoice,
            veh.Car_description_2__c, // description,
            (Integer) veh.Current_KM__c, // km,
            invoiceReq.customerPriceDKK, // salesPrice,
            invoiceReq.registrationFeeDKK, // registrationFee,
            (Integer) veh.Delivery_cost__c, // deliveryCost,
            (Integer) veh.licensePlateCost__c, // licensePlateCost,
            invoiceReq.additionalAccessoriesCostDKK, // additionalAccessoriesCost,
            invoiceReq.accessoryDescription, // accessoryDescription,
            exchangeVeh?.vinNumber__c, // exchangeCarVin,
            (Integer) exchangeVeh?.Sixt_steel_purchase_price__c, // exchangeCarAmount,
            invoiceReq.ownerName,
            invoiceReq.ownerAddressLine1,
            invoiceReq.ownerAddressLine2,
            invoiceReq.ownerPostCode,
            invoiceReq.ownerCity,
            invoiceReq.driverName,
            invoiceReq.driverAddressLine1,
            invoiceReq.driverAddressLine2,
            invoiceReq.driverPostCode,
            invoiceReq.driverCity
        );
        // construct NAV request
        Integration_Request__c navReq = new Integration_Request__c();
        navReq.Vehicle__c = veh.Id;
        navReq.API_Method__c = IntegrationRequestsNAVCars.METHOD_INVOICE_CARS_PRIVATE;
        navReq.Data__c = JSON.serialize(navReqData, true);
        // call NAV
        IntegrationRequestsNAVCars reqProcessor = new IntegrationRequestsNAVCars();
        // skip in Test
        if (Test.isRunningTest()) {
            navReq.Status__c = IntegrationRequestsUtility.STATUS_SUCCESS;
        } else {
            navReq = reqProcessor.process(navReq, veh);
        }
        // anonymise Integration request data (we can't store personal info there)
        navReqData.createOwnerName = invoiceReq.ownerName != null ? ANONYM_TEXT : null;
        navReqData.createOwnerAddress1 = null;
        navReqData.createOwnerAddress2 = null;
        navReqData.createOwnerPostCode = null;
        navReqData.createOwnerCity = null;
        navReqData.createDriverName = invoiceReq.driverName != null ? ANONYM_TEXT : null;
        navReqData.createDriverAddress1 = null;
        navReqData.createDriverAddress2 = null;
        navReqData.createDriverPostCode = null;
        navReqData.createDriverCity = null;
        navReq.Data__c = JSON.serialize(navReqData, true);
        // save Integration request
        insert navReq;
        if (navReq.Status__c == IntegrationRequestsUtility.STATUS_SUCCESS) {
            // save update vehicle with price and exchange car
            veh.Confirmed_Remarketing_Price_Full_Tax_DKK__c = invoiceReq.customerPriceDKK;
            veh.Status__c = 'Sold';
            veh.Re_marketing_Status__c = 'Sold';
            update veh;
            // return Integration request id
            return navReq.Id;
        } else {
            throw new NavisionInvoiceException(navReq.Message__c);
        }
    }

    private static Boolean vehicleValidation(Vehicle__c veh) {
        // buyer must be populated 
        if (veh.Buyer_Account__c == null) {
            throw new BuyerAccountIsMissingException('Buyer Account missing in Xfleet!');
        }
        return true;
    }

    private static String getErrorCode(Exception ex) {
        String exceptionName = ex.getTypeName();
        System.debug('error in Invoice request processing, exception type name: ' + exceptionName);
        if (MAP_ERROR_CODES.containsKey(exceptionName)) {
            return MAP_ERROR_CODES.get(exceptionName);
        }
        return 'UNEXCPECTED_ERROR';
    }

    public class NavisionInvoiceException extends Exception {
    }

    public class InvoiceRequestValidationException extends Exception {
    }

    public class BuyerAccountIsMissingException extends Exception {
    }

    public class ExchangeVehicleNotExistException extends Exception {
    }
}