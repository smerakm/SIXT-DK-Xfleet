public with sharing class NAVSendLicensePlateInvoceSchedulable implements System.Schedulable {
    public NAVSendLicensePlateInvoceSchedulable() {
    }

    public void execute(SchedulableContext sc) {
        // get newly registered vehicles where invoice hasn't been sent yet
        List<Vehicle__c> vehicles = [
            SELECT LicensePlateCost__c, License_Plate_Invoice_Sent__c, Dealer__r.Navision_Account__c
            FROM Vehicle__c
            WHERE License_plate__c != NULL AND License_Plate_Invoice_Sent__c = FALSE
            LIMIT 5000
        ];
        // and create Integration Request for them
        List<Integration_Request__c> irs = new List<Integration_Request__c>();
        for (Vehicle__c v : vehicles) {
            irs.add(createLicensePlateInvoiceRequest(v));
            v.License_Plate_Invoice_Sent__c = true;
        }
        insert irs;
        // mark vehicles as License Plate Invoice request sent
        update vehicles;
    }

    public static Integration_Request__c createLicensePlateInvoiceRequest(Vehicle__c v) {
        Integration_Request__c ir = new Integration_Request__c();
        ir.Vehicle__c = v.Id;
        ir.API_Method__c = NAVCarsIntegrationBatchable.METHOD_INVOICE;
        NAVCarsObject navCar = new NAVCarsObject(v.licensePlateCost__c, null, v.Dealer__r.Navision_Account__c, null, 1, true);
        ir.Data__c = JSON.serialize(navCar, true);
        return ir;
    }
}
