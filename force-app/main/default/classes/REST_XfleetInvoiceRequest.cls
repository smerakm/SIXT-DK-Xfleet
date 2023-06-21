@RestResource(urlMapping='/Xfleet/v1/InvoiceRequest/*')
global with sharing class REST_XfleetInvoiceRequest {
    private static final String ANONYM_TEXT = 'anonymous-gdpr';

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
            respBody.errorMessage = ex.getMessage();
        } catch (StringException ex) {
            res.statusCode = 400;
            respBody.errorMessage = ex.getMessage();
        } catch (JSONException ex) {
            res.statusCode = 400;
            respBody.errorMessage = ex.getMessage();
        } catch (TypeException ex) {
            res.statusCode = 400;
            respBody.errorMessage = ex.getMessage();
        } catch (QueryException ex) {
            res.statusCode = 404;
            respBody.errorMessage = ex.getMessage();
        } catch (DmlException ex) {
            res.statusCode = 422;
            respBody.errorMessage = ex.getMessage();
        } catch (NavisionInvoiceException ex) {
            res.statusCode = 424;
            respBody.errorMessage = ex.getMessage();
        } catch (Exception ex) {
            res.statusCode = 500;
            respBody.errorMessage = ex.getMessage();
        }
        res.responseBody = Blob.valueOf(JSON.serialize(respBody, true));
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
        public String errorMessage;
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
            exchangeVeh = [
                SELECT id, vinNumber__c, Sixt_steel_purchase_price__c, Car_description_2__c
                FROM Vehicle__c
                WHERE Id = :invoiceReq.exchangeVehicleId
            ];
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
            throw new InvoiceRequestValidationException('Buyer Account missing in Xfleet!');
        }
        return true;
    }

    public class NavisionInvoiceException extends Exception {
    }

    public class InvoiceRequestValidationException extends Exception {
    }
}