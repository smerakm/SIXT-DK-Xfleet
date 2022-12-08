// shall be used with constructor with VIN Number!
// PATCH method
// can be used for Update Car or create Invoice or Quote/Advi
public with sharing class NAVCarsUpdate extends NAVCars {

    public NAVCarsUpdate(String vinNo) {
        super(vinNo);
    }

    public override HttpRequest prepareRequest(Object params) {
        NAVCarsObject car = (NAVCarsObject) params;
        HttpRequest req = new HttpRequest();
        req.setMethod('PATCH');
        req.setBody(JSON.serialize(car, true));
        req.setHeader('if-match', '*');
        return req;
    }
}
