public with sharing class NAVUpdateVehiclesFromNAVSchedulable implements System.Schedulable {
    private Datetime modifiedAfter;

    public NAVUpdateVehiclesFromNAVSchedulable() {
        this.modifiedAfter = System.now().addHours(-36); // need to run every day!
    }

    public void execute(SchedulableContext sc) {
        updateVehiclesFromNAVCars(this.modifiedAfter);
    }

    @future(callout=true)
    public static void updateVehiclesFromNAVCars(Datetime lastModifiedDatetime) {
        // call the api and get list of NAVCarsObject as a result
        NAVCarsGet navApi = new NAVCarsGet();
        Map<String, NAVCarsObject> navCars = navApi.getCarsModifiedAfter(lastModifiedDatetime);
        // are there any cars returned?
        if (navCars != null && !navCars.isEmpty()) {
            // get all related vehicles and update them
            List<Vehicle__c> vehiclesToUpdate = new List<Vehicle__c>();
            for (Vehicle__c veh : [SELECT vinNumber__c, The_car_is_paid__c FROM Vehicle__c WHERE vinNumber__c IN :navCars.keySet()]) {
                Boolean vehicleUpdated = false;
                NAVCarsObject navCarSingle = navCars.get(veh.vinNumber__c);
                if (navCarSingle.carIsPaid != null && navCarSingle.carIsPaid != veh.The_car_is_paid__c) {
                    veh.The_car_is_paid__c = navCarSingle.carIsPaid;
                    vehicleUpdated = true;
                }
                // update vehicle only if there is a change
                if (vehicleUpdated) {
                    vehiclesToUpdate.add(veh);
                }
            }
            // are there any vehicles to update?
            if (!vehiclesToUpdate.isEmpty()) {
                update vehiclesToUpdate;
            }
        }
    }
}