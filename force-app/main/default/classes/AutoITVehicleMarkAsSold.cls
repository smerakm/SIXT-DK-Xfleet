public with sharing class AutoITVehicleMarkAsSold extends AutoITVehicle {

    public static final String METHOD_SUFFIX = '/MarkAsSold';

    public static final String TYPE_OF_SALE_DEFAULT = 'Wholesale';
    public static final String BUYER_TYPE_DEFAULT = 'Company';


    public AutoITVehicleMarkAsSold(String autoDesktopId) {
        super(autoDesktopId + METHOD_SUFFIX);
    }

    public override HttpRequest prepareRequest(Object params) {     
        String reqBody;
        if (params instanceOf String) {
            reqBody = JSON.serialize(JSON.deserializeUntyped( (String) params));
        } else {
            Vehicle__c car = (Vehicle__c) params;
            MarkAsSoldRequest reqBodyData = new MarkAsSoldRequest(car);
            reqBody = JSON.serialize(reqBodyData, true);
        }
        HttpRequest req = new HttpRequest();
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(reqBody);
        return req;
    }

    public class MarkAsSoldRequest {
        public Datetime dateOfSale { get; set; } 
        public Integer buyerAge { get; set; }
        public Integer salesPrice { get; set; }
        public String typeOfSale { get; set; }
        public String buyerType { get; set; }

        public MarkAsSoldRequest(Vehicle__c veh) {
            this.dateOfSale = System.now();
            this.typeOfSale = TYPE_OF_SALE_DEFAULT;
            this.buyerType = BUYER_TYPE_DEFAULT;
            this.salesPrice = Integer.valueOf(veh.Confirmed_Remarketing_Price_Converted__c);
        }
    }
}