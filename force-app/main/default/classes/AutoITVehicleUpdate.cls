public with sharing class AutoITVehicleUpdate extends AutoITVehicle {

    public AutoITVehicleUpdate(String autoDesktopId) {
        super(autoDesktopId);
    }

    public override HttpRequest prepareRequest(Object params) {
        AutoITVehicleObject car = (AutoITVehicleObject) params;
        HttpRequest req = new HttpRequest();
        req.setMethod('PATCH');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(car, true));
        return req;
    }
}