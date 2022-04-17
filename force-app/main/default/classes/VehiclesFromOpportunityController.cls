public with sharing class VehiclesFromOpportunityController {
    public String oppId { get; set; }

    public VehiclesFromOpportunityController() {
    }

    public List<Vehicle__c> getOpportunityVehicles() {
        List<Vehicle__c> opptyVehicles = [
            SELECT
                Production_Number__c,
                vinNumber__c,
                Brand__c,
                Model__c,
                color__c,
                Fuel_type__c,
                kmPrL__c,
                CO2__c,
                Navi__c,
                Automatic_gears__c,
                Speed_Pilot__c,
                Parking_sensor__c,
                Bluetooth__c,
                Non_standard_Accessories__c,
                Sales_Price_Formula__c
            FROM Vehicle__c
            WHERE Opportunity__c = :oppId
        ];
        return opptyVehicles;
    }
}