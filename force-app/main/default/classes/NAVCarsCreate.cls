public with sharing class NAVCarsCreate extends NAVCars {

    public override HttpRequest prepareRequest(Object params) {
        NAVCarsObject car = (NAVCarsObject)params;
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setBody(JSON.serialize(car, true));
        return req;
    }

    
}
