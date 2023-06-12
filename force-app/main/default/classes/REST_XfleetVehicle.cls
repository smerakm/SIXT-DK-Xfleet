@RestResource(urlMapping='/Xfleet/v1/Vehicle/*')
global with sharing class REST_XfleetVehicle {

    global static final String ERROR_NO_BUYER = 'Buyer cannot be found in Xfleet!';
    global static final String ERROR_NO_BATCH = 'Vehicle Batch cannot be found in Xfleet!';


    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        VehicleWrapper respBody;
        try {
            // need vehicle Id from URI
            String vehicleId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
            Vehicle__c xfleetVehicle = queryVehicle(vehicleId);
            respBody = vehicle2Wrapper(xfleetVehicle);
            res.statusCode = 200;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'error in vehicle create processing: ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, 'cause: ' + ex.getCause());
            res.statusCode = 500;
            respBody = new VehicleWrapper();
            respBody.errorMessage = ex.getMessage();
        }
        res.responseBody = Blob.valueOf(JSON.serialize(respBody, true));
    }

    @HttpPost
    global static void doPost(VehicleWrapper vehicle) {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        VehicleResponseWrapper respBody = new VehicleResponseWrapper();
        try {
            System.debug(vehicle.range);
            System.debug(vehicle.firstRegistrationDate);
            Vehicle__c xfleetVehicle = wrapper2Vehicle(vehicle, null);
            // batch assignment;
            xfleetVehicle.Vehicle_Batch__c = getBatchId(vehicle.vehicleBatchName);
            // insert into Xfleet
            insert xfleetVehicle;
            respBody.id = xfleetVehicle.Id;
            res.statusCode = 201;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'error in vehicle create processing: ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, 'cause: ' + ex.getCause());
            res.statusCode = 500;
            respBody.errorMessage = ex.getMessage();
        }
        res.responseBody = Blob.valueOf(JSON.serialize(respBody, true));
    }

    @HttpPatch
    global static void doPatch(VehicleWrapper vehicle) {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        VehicleResponseWrapper respBody = new VehicleResponseWrapper();
        try {
            // need vehicle Id from URI
            String vehicleId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
            Vehicle__c xfleetVehicle = wrapper2Vehicle(vehicle, Id.valueOf(vehicleId));
            System.debug(LoggingLevel.DEBUG, 'vehicle before update: ' + xfleetVehicle);
            update xfleetVehicle;
            respBody.id = xfleetVehicle.Id;
            res.statusCode = 200;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'error in vehicle create processing: ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, 'cause: ' + ex.getCause());
            res.statusCode = 500;
            respBody.errorMessage = ex.getMessage();
        }
        res.responseBody = Blob.valueOf(JSON.serialize(respBody, true));
    }

    private static Vehicle__c queryVehicle(Id vehicleId) {
        Vehicle__c vehicle = [
            SELECT
                ACRISS_Code__c,
                Airbags__c,
                Automatic_gears__c,
                Battery_Capacity_kWh__c,
                Bluetooth__c,
                Brand__c,
                Buyer_Account__r.Name,
                Car_remark__c,
                CO2__c,
                color__c,
                kmPrL__c,
                Speed_Pilot__c,
                Link_to_Retail_Website__c,
                Delivery_cost__c,
                Non_standard_Accessories__c,
                AutoDesktop_Id__c,
                First_Registration_Date__c,
                Fuel_type__c,
                Last_Vehicle_Inspection__c,
                licensePlateCost__c,
                Current_KM__c,
                Model_Name__c,
                Model__c,
                Model_Year__c,
                Navigation__c,
                NCAP__c,
                Parking_sensor__c,
                Range__c,
                License_Plate_System__c,
                Registration_Date__c,
                Re_marketing_Status__c,
                Retail_Price__c,
                Retail_Sales__c,
                Seatbeltalarms__c,
                Service_interval_Years_KM__c,
                Status__c,
                Sixt_steel_purchase_price__c,
                Tank_size_liters__c,
                Tire_type__c,
                Vehicle_Batch__r.Name,
                vinNumber__c
            FROM Vehicle__c
            WHERE Id = :vehicleId
        ];
        return vehicle;
    }

    private static Id getBatchId(String batchName) {
        Id batchId;
        // batch name not defined in the request, get default batch from setting
        if (String.isBlank(batchName)) {
            FleetManagementConfig__c config = FleetManagementConfig__c.getInstance();
            batchId = Id.valueOf(config.DefaultBatchId__c);
        } else {
            List<vehicleBatch__c> batches = [SELECT Id FROM vehicleBatch__c WHERE Name = :batchName LIMIT 1];
            if (batches.isEmpty()) {
                throw new XfleetVehicleException(ERROR_NO_BATCH);
            } 
            batchId = batches.get(0).Id;
        }
        return batchId;
    }

    private static VehicleWrapper vehicle2Wrapper(Vehicle__c vehicle) {
        VehicleWrapper wrapper = new VehicleWrapper();
        wrapper.acrissCode = vehicle.ACRISS_Code__c;
        wrapper.airbagsNumber = (Integer) vehicle.Airbags__c;
        wrapper.automaticGears = vehicle.Automatic_gears__c;
        wrapper.batteryCapacity = (Integer) vehicle.Battery_Capacity_kWh__c;
        wrapper.bluetooth = vehicle.Bluetooth__c;
        wrapper.brandName = vehicle.Brand__c;
        wrapper.buyerAccountName = vehicle.Buyer_Account__r?.Name;
        wrapper.carRemarks = vehicle.Car_remark__c;
        wrapper.co2Emissions = (Integer) vehicle.CO2__c;
        wrapper.colorName = vehicle.color__c;
        wrapper.consumptionKmPerLiter = (Decimal) vehicle.kmPrL__c;
        wrapper.cruiseControl = vehicle.Speed_Pilot__c;
        wrapper.deeplink = vehicle.Link_to_Retail_Website__c;
        wrapper.deliveryCostsRetailDKK = (Integer) vehicle.Delivery_cost__c;
        wrapper.equipmentList = vehicle.Non_standard_Accessories__c;
        wrapper.externalId = vehicle.AutoDesktop_Id__c;
        wrapper.firstRegistrationDate = vehicle.First_Registration_Date__c;
        wrapper.fuelType = vehicle.Fuel_type__c;
        wrapper.lastVehicleInspection = vehicle.Last_Vehicle_Inspection__c;
        wrapper.licensePlateCostsDKK = (Integer) vehicle.licensePlateCost__c;
        wrapper.mileage = (Integer) vehicle.Current_KM__c;
        wrapper.modelName = vehicle.Model_Name__c;
        wrapper.modelXfleet = vehicle.Model__c;
        wrapper.modelYear = (Integer) vehicle.Model_Year__c;
        wrapper.navigation = vehicle.Navigation__c;
        wrapper.ncap = vehicle.NCAP__c;
        wrapper.parkingSensor = vehicle.Parking_sensor__c;
        wrapper.range = (Integer) vehicle.Range__c;
        wrapper.regNo = vehicle.License_Plate_System__c;
        wrapper.registrationDate = vehicle.Registration_Date__c;
        wrapper.remarketingStatus = vehicle.Re_marketing_Status__c;
        wrapper.retailPriceDKK = (Integer) vehicle.Retail_Price__c;
        wrapper.retailSales = vehicle.Retail_Sales__c;
        wrapper.seatbeltAlarmsNumber = (Integer) vehicle.Seatbeltalarms__c;
        wrapper.serviceInterval = vehicle.Service_interval_Years_KM__c;
        wrapper.status = vehicle.Status__c;
        wrapper.steelPriceDKK = (Integer) vehicle.Sixt_steel_purchase_price__c;
        wrapper.tankSize = (Integer) vehicle.Tank_size_liters__c;
        wrapper.tireType = vehicle.Tire_type__c;
        wrapper.vehicleBatchName = vehicle.Vehicle_Batch__r.Name;
        wrapper.vin = vehicle.vinNumber__c;
        return wrapper;
    }

    private static Vehicle__c wrapper2Vehicle(VehicleWrapper wrapper, Id vehicleId) {
        Vehicle__c vehicle;
        if (vehicleId == null) {
            vehicle = new Vehicle__c();
        } else {
            vehicle = new Vehicle__c(Id = vehicleId);
        }
        // set parameters from wrapper
        vehicle.ACRISS_Code__c = wrapper.acrissCode;
        vehicle.Airbags__c = wrapper.airbagsNumber;
        vehicle.Automatic_gears__c = wrapper.automaticGears;
        vehicle.Battery_Capacity_kWh__c = wrapper.batteryCapacity;
        vehicle.Bluetooth__c = wrapper.bluetooth;
        vehicle.Brand__c = wrapper.brandName;
        vehicle.Car_remark__c = wrapper.carRemarks;
        vehicle.CO2__c = wrapper.co2Emissions;
        vehicle.color__c = wrapper.colorName;
        vehicle.kmPrL__c = wrapper.consumptionKmPerLiter;
        vehicle.Speed_Pilot__c = wrapper.cruiseControl;
        vehicle.Link_to_Retail_Website__c = wrapper.deeplink;
        vehicle.Delivery_cost__c = wrapper.deliveryCostsRetailDKK;
        vehicle.Non_standard_Accessories__c = wrapper.equipmentList;
        vehicle.AutoDesktop_Id__c = wrapper.externalId;
        vehicle.First_Registration_Date__c = wrapper.firstRegistrationDate;
        vehicle.Fuel_type__c = wrapper.fuelType;
        vehicle.Last_Vehicle_Inspection__c = wrapper.lastVehicleInspection;
        vehicle.licensePlateCost__c = wrapper.licensePlateCostsDKK;
        vehicle.Current_KM__c = wrapper.mileage;
        vehicle.Model_Name__c = wrapper.modelName;
        vehicle.Model__c = wrapper.modelXfleet;
        vehicle.Model_Year__c = wrapper.modelYear;
        vehicle.Navigation__c = wrapper.navigation;
        vehicle.NCAP__c = wrapper.ncap;
        vehicle.Parking_sensor__c = wrapper.parkingSensor;
        vehicle.Range__c = wrapper.range;
        vehicle.License_Plate_System__c = wrapper.regNo;
        vehicle.Registration_Date__c = wrapper.registrationDate;
        vehicle.Re_marketing_Status__c = wrapper.remarketingStatus;
        vehicle.Retail_Price__c = wrapper.retailPriceDKK;
        vehicle.Retail_Sales__c = wrapper.retailSales;
        vehicle.Seatbeltalarms__c = wrapper.seatbeltAlarmsNumber;
        vehicle.Service_interval_Years_KM__c = wrapper.serviceInterval;
        vehicle.Status__c = wrapper.status;
        vehicle.Sixt_steel_purchase_price__c = wrapper.steelPriceDKK;
        vehicle.Tank_size_liters__c = wrapper.tankSize;
        vehicle.Tire_type__c = wrapper.tireType;
        vehicle.vinNumber__c = wrapper.vin;
        // buyer account defined?
        if (String.isNotBlank(wrapper.buyerAccountName)) {
            List<Account> buyerAccounts = [SELECT Name FROM Account WHERE Name = :wrapper.buyerAccountName LIMIT 1];
            if (buyerAccounts.isEmpty()) {
                throw new XfleetVehicleException(ERROR_NO_BUYER);
            }
            vehicle.Buyer_Account__c = buyerAccounts.get(0).Id;
        }
        // remove null values
        Map<String, Object> allFields = new Map<String, Object>(vehicle.getPopulatedFieldsAsMap());
        Map<String, Object> notNullFields = new Map<String, Object>();
        for (String fieldName : allFields.keySet()) {
            if (allFields.get(fieldName) != null) {
                notNullFields.put(fieldName, allFields.get(fieldName));
            }
        }
        System.debug(LoggingLevel.DEBUG, 'wrapper converted to vehicle, not null values: ' + notNullFields);
        return (Vehicle__c) JSON.deserialize(JSON.serialize(notNullFields), Vehicle__c.class);
    }

    global class VehicleWrapper {
        public String acrissCode;
        public Integer airbagsNumber;
        public Boolean automaticGears;
        public Integer batteryCapacity;
        public Boolean bluetooth;
        public String brandName;
        public String buyerAccountName;
        public String carRemarks;
        public Integer co2Emissions;
        public String colorName;
        public Decimal consumptionKmPerLiter;
        public Boolean cruiseControl;
        public String deeplink;
        public Integer deliveryCostsRetailDKK;
        public String equipmentList;
        public String externalId;
        public Date firstRegistrationDate;
        public String fuelType;
        public Date lastVehicleInspection;
        public Integer licensePlateCostsDKK;
        public Integer mileage;
        public String modelName;
        public String modelXfleet;
        public Integer modelYear;
        public Boolean navigation;
        public String ncap;
        public Boolean parkingSensor;
        public Integer range;
        public String regNo;
        public Date registrationDate;
        public String remarketingStatus;
        public Integer retailPriceDKK;
        public Boolean retailSales;
        public Integer seatbeltAlarmsNumber;
        public String serviceInterval;
        public String status;
        public Integer steelPriceDKK;
        public Integer tankSize;
        public String tireOwnership;
        public String tireSize;
        public String tireType;
        public String vehicleBatchName;
        public String vin;
        // add error message
        public String errorMessage;
    }

    global class VehicleResponseWrapper {
        public String id;
        public String errorMessage;
    }

    global class XfleetVehicleException extends Exception {}
}