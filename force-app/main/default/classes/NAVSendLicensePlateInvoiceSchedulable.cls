public with sharing class NAVSendLicensePlateInvoiceSchedulable implements System.Schedulable {
    private static final String ERROR_MSG_BAD_DATA = 'License plate cost or dealer navision number is missing';
    private static final String QUERY_VEHICLES = Label.Xfleet_Query_Vehicles_for_License_Plate_Invoice;
    private static final String LABEL_INVOICE_DESCRIPTION = Label.Xfleet_Label_License_Plate_Invoice_Description;

    public NAVSendLicensePlateInvoiceSchedulable() {
    }

    public void execute(SchedulableContext sc) {
        // get newly registered vehicles where invoice hasn't been sent yet
        List<Vehicle__c> vehicles = Database.query(QUERY_VEHICLES, AccessLevel.SYSTEM_MODE);
        // and create Integration Request for them
        List<Integration_Request__c> irs = new List<Integration_Request__c>();
        for (Vehicle__c v : vehicles) {
            // do not invoice EUR dealers
            if (v.Dealer__r.EUR_DKK__c == 'EUR') {
                v.License_Plate_Is_Not_Invoiced__c = true;
            } else {
                // create integration request for DK dealers
                irs.add(createLicensePlateInvoiceRequest(v));
            }
            // mark vehicle as processed
            v.License_Plate_Invoice_Sent__c = true;
        }
        insert irs;
        // mark vehicles as License Plate Invoice request sent
        update vehicles;
    }

    public static Integration_Request__c createLicensePlateInvoiceRequest(Vehicle__c v) {
        Integration_Request__c ir = new Integration_Request__c();
        ir.Vehicle__c = v.Id;
        ir.API_Method__c = IntegrationRequestsNAVCars.METHOD_INVOICE;
        // invoice description
        String invoiceDescription = UtilityCommon.mergeFieldsIntoString(LABEL_INVOICE_DESCRIPTION, v);
        NAVCarsObject navCar = new NAVCarsObject(
            v.licensePlateCost__c,
            null,
            v.Dealer__r.Navision_Account__c,
            null,
            1,
            false,
            invoiceDescription,
            null,
            null,
            true
        );
        ir.Data__c = JSON.serialize(navCar, true);
        // if some data are missing mark the requested as failed
        if (v.licensePlateCost__c == null || v.Dealer__c == null || String.isBlank(v.Dealer__r.Navision_Account__c)) {
            ir.Status__c = IntegrationRequestsUtility.STATUS_FAILED;
            ir.Message__c = ERROR_MSG_BAD_DATA;
            ir.Last_Processing_Time__c = System.now();
        }
        return ir;
    }
}