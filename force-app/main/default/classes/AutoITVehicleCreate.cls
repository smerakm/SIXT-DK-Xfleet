public with sharing class AutoITVehicleCreate extends AutoITVehicle {
    public override HttpRequest prepareRequest(Object params) {
        String reqBody;
        if (params instanceOf String) {
            reqBody = JSON.serialize(JSON.deserializeUntyped( (String) params));
        } else {
            AutoITVehicleObject car = (AutoITVehicleObject) params;
            reqBody = JSON.serialize(car, true);
        }
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(reqBody);
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