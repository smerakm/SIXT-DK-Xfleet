public with sharing class AutoITVehicleUpsert extends AutoITVehicle {

    public override HttpRequest prepareRequest(Object params) {
        AutoITVehicleObject car = (AutoITVehicleObject)params;
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setBody(JSON.serialize(car, true));
        return req;
    }
    
}