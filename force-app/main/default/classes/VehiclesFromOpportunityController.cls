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
                Navigation__c,
                Automatic_gears__c,
                Speed_Pilot__c,
                Parking_sensor__c,
                Bluetooth__c,
                Non_standard_Accessories__c,
                Sales_Price_Formula__c,
                Sales_Price_EUR__c
            FROM Vehicle__c
            WHERE Opportunity__c = :oppId
        ];
        return opptyVehicles;
    }

    public Boolean getIsEUR() {
        Boolean isEUR = false;
        if (oppId != null) {
            Opportunity opp = [SELECT Account.EUR_DKK__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
            if (String.isNotBlank(opp.Account.EUR_DKK__c) && opp.Account.EUR_DKK__c == 'EUR') {
                isEUR = true;
            }
        }
        return isEUR;
    }
}