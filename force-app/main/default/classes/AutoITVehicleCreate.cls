public with sharing class AutoITVehicleCreate extends AutoITVehicle {
    public override HttpRequest prepareRequest(Object params) {
        AutoITVehicleObject car = (AutoITVehicleObject) params;
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(car, true));
        return req;
    }

    public override void processResponse(String respBody, Id vehicleId) {
        // parse the response to get AutoDesktop Id
        CreateVehicleResponse resp = (CreateVehicleResponse) JSON.deserialize(respBody, CreateVehicleResponse.class);
        if (resp?.vehicleId != null) {
            Vehicle__c veh = new Vehicle__c(id = vehicleId);
            veh.AutoDesktop_Id__c = resp.vehicleId;
            update veh;
        }
    }

    public class CreateVehicleResponse {
        public String vehicleId {get; set;}
        public String vehicleTechnicalInformationId {get; set;}
    }
}