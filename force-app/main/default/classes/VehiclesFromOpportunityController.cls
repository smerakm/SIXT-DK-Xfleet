public with sharing class VehiclesFromOpportunityController {
    public String oppId { get; set; }

    public VehiclesFromOpportunityController() {
    }

    public List<Vehicle__c> OpportunityVehicles {
        get {
            if (this.OpportunityVehicles == null || this.OpportunityVehicles.isEmpty()) {
                this.OpportunityVehicles = [
                    SELECT
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
                        Confirmed_Remarketing_Price_DKK__c,
                        Confirmed_Remarketing_Price_Full_Tax_DKK__c,
                        Confirmed_Remarketing_Price_EUR__c,
                        Registration_Date__c
                    FROM Vehicle__c
                    WHERE Opportunity__c = :oppId
                ];
            }
            return OpportunityVehicles;
        }
        set;
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

    public Boolean getHasFullTaxVehicles() {
        List<Vehicle__c> vehs = this.OpportunityVehicles;
        for (Vehicle__c v : vehs) {
            if (v.Confirmed_Remarketing_Price_Full_Tax_DKK__c != null && v.Confirmed_Remarketing_Price_Full_Tax_DKK__c > 0) {
                return true;
            }
        }
        return false;
    }

    public Boolean getHasDKKVehicles() {
        List<Vehicle__c> vehs = this.OpportunityVehicles;
        for (Vehicle__c v : vehs) {
            if (v.Confirmed_Remarketing_Price_DKK__c != null && v.Confirmed_Remarketing_Price_DKK__c > 0) {
                return true;
            }
        }
        return false;
    }
}