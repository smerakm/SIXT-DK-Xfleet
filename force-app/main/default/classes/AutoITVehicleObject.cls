/**
 * This class is wrapper object for Vehicle to be sent to AutoIT/AutoDesktop.
 *
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2023-04-05
 * @modified       2023-04-05
 * @systemLayer    CallOuts
 * @see            SIXT-102, SIXT-103
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2023-04-05      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
public with sharing class AutoITVehicleObject {
    public String vin { get; set; }
    public String regNo { get; set; }
    public String dmrVehicleIdentifier { get; set; }
    public String dmrMakeModelVariantTypeId { get; set; }
    public String efTypeApprovalNumber { get; set; }
    public Integer tecDocKTypeNumber { get; set; }
    public Integer dkTypeApprovalCertificateNumber { get; set; }
    public Integer dkTypeApprovalVariantNumber { get; set; }
    public String dealerReferenceNumber { get; set; } // Salesforce record Id
    public Integer firstRegistrationYear { get; set; }
    public Integer firstRegistrationMonth { get; set; }
    public Integer firstRegistrationDay { get; set; }
    public Integer modelYear { get; set; }
    public Integer vehicleInspectionYear { get; set; }
    public Integer vehicleInspectionMonth { get; set; }
    public Boolean vehicleInspectionPeriodicRequirement { get; set; }
    public Integer vehicleInspectionPeriodicIntervalMonths { get; set; }
    public Integer vehicleInspectionPeriodicBasisYear { get; set; }
    public Integer vehicleInspectionPeriodicBasisMonth { get; set; }
    public Integer newOrUsed { get; set; } // 1 or 2
    public Integer modelVariantId { get; set; }
    public Boolean trueToModelVariantRegister { get; set; }
    public Integer typeId { get; set; }
    public String typeName { get; set; }
    public Integer brandId { get; set; }
    public String brandName { get; set; }
    public String modelAdditionalDesignation { get; set; }
    public String modelSerieName { get; set; }
    public Integer modelId { get; set; }
    public String modelName { get; set; }
    public String bodyAdditionalDesignation { get; set; }
    public Integer bodyTypeId { get; set; }
    public String bodyTypeName { get; set; }
    public String bodyLengthTypeId { get; set; }
    public Integer doorCount { get; set; }
    public Integer seatCount { get; set; }
    public String transmissionAdditionalDesignation { get; set; }
    public Integer transmissionTypeId { get; set; }
    public String transmissionTypeName { get; set; }
    public Integer gearCount { get; set; }
    public String drivingWheelId { get; set; }
    public String engineAdditionalDesignation { get; set; }
    public String fuelTypeId { get; set; }
    public String engineSizeLitresDesignation { get; set; }
    public Integer maximumEffectHP { get; set; }
    public String additionalVariantDesignation { get; set; }
    public String equipmentLevelDesignation { get; set; }
    public String makeModelVariant { get; set; }
    public Integer colorId { get; set; }
    public String colorName { get; set; }
    public String colorOwnDescription { get; set; }
    public Integer mileage { get; set; }
    public String equipmentlist { get; set; }
    public String description { get; set; }
    public Boolean exVat { get; set; }
    public Decimal priceRetailDKK { get; set; }
    public Decimal priceRetailVatDKK { get; set; }
    public Decimal deliveryCostsRetailDKK { get; set; }
    public Decimal numberplateCostsDKK { get; set; }
    public Decimal priceWholesaleDKK { get; set; }
    public Decimal priceLowestAuctionDKK { get; set; }
    public Boolean absoluteDivestitureAuction { get; set; }
    public String deeplink { get; set; }
    public Boolean showOnSalesList { get; set; }
    public Boolean showOnAftermarketList { get; set; }
    public Integer currentResponsibleUserId { get; set; }
    public String edbNumber { get; set; }
    public Boolean isTradeInVehicle { get; set; }
    public String importerCode { get; set; }
    public Decimal salesPrice { get; set; }
    public Decimal priceRetailExRegistrationTax { get; set; }
    public Boolean priceRetailWithoutRegistrationTax { get; set; }
    public String comments { get; set; }
    public Date inventoryDate { get; set; }
    public Date lastVehicleInspection { get; set; }
    public Integer vinYear { get; set; }
    public Decimal expectedRegistrationTax { get; set; }
    public String commissionNumber { get; set; }
    // public Boolean import { get; set; } // we cannot send "import" as it is reserved word in Apex
    public Decimal repurchasePrice { get; set; }

    // Convert Xfleet Vehicle__c to API Vehicle object
    // deprecated
    public void updateFromXfleetVehicle(Vehicle__c vehicle) {
        this.dealerReferenceNumber = vehicle.Id;
        this.vin = vehicle.vinNumber__c;
        this.regNo = vehicle.License_Plate_System__c;
        this.mileage = (Integer) vehicle.Current_KM__c;
        this.brandName = vehicle.Brand__c;
        // model
        if (String.isNotBlank(vehicle.Model_Name__c)) {
            this.modelName = vehicle.Model_Name__c;
        } else {
            this.modelName = vehicle.Model__c;
        }
        // registration date
        if (vehicle.First_Registration_Date__c == null && vehicle.Registration_Date__c != null) {
            this.firstRegistrationYear = vehicle.Registration_Date__c?.year();
            this.firstRegistrationMonth = vehicle.Registration_Date__c?.month();
            this.firstRegistrationDay = vehicle.Registration_Date__c?.day();
        } else {
            this.firstRegistrationYear = vehicle.First_Registration_Date__c?.year();
            this.firstRegistrationMonth = vehicle.First_Registration_Date__c?.month();
            this.firstRegistrationDay = vehicle.First_Registration_Date__c?.day();
        }
        // complete the mapping
        this.colorName = vehicle.color__c;
        this.priceRetailDKK = (Integer) vehicle.Retail_Price__c;
        this.fuelTypeId = vehicle.Fuel_type__c;
        this.modelYear = (Integer) vehicle.Model_Year__c;
        this.lastVehicleInspection = vehicle.Last_Vehicle_Inspection__c;
        this.description = vehicle.Car_remark__c;
    }

    public static AutoITVehicleObject createWithDefaults(Vehicle__c xfleetVehicle, String callMethod) {
        AutoITVehicleObject autoItVehicleRecord;
        Map<String, Object> defaultValues = d(callMethod);
        if (defaultValues.size() > 0) {
            autoItVehicleRecord = (AutoITVehicleObject)JSON.deserialize(JSON.serialize(defaultValues), AutoITVehicleObject.class);
        } else {
            autoItVehicleRecord = new AutoITVehicleObject();
        }
        autoItVehicleRecord.updateFromXfleetVehicle(xfleetVehicle);
        return autoItVehicleRecord;
    }

        // TODO: shall have it owns utility class
        public static Map<String, Object> d(String apiCallName) {
            Map<String, Object> defaultProperties = new Map<String, Object>();
            // get all default properties from custom metadata
            List<Integration_Call_Default_Values__mdt> defaultValues = [SELECT Property_Name__c, Property_Type__c, Value__c FROM Integration_Call_Default_Values__mdt WHERE API_Method__c = :apiCallName];
            for (Integration_Call_Default_Values__mdt singleValue : defaultValues) {
                switch on singleValue.Property_Type__c {
                    when 'Boolean' {
                        Boolean v = Boolean.valueOf(singleValue.Value__c);
                        defaultProperties.put(singleValue.Property_Name__c, v);
                    }
                    when 'Integer' {
                        Integer v = Integer.valueOf(singleValue.Value__c);
                        defaultProperties.put(singleValue.Property_Name__c, v);
                    }
                    when 'Decimal' {
                        Decimal v = Decimal.valueOf(singleValue.Value__c);
                        defaultProperties.put(singleValue.Property_Name__c, v);
                    }
                    when else {
                        // String doesn't need casting
                        defaultProperties.put(singleValue.Property_Name__c, singleValue.Value__c);
                    }
                }
            }
            return defaultProperties;
        } 
}