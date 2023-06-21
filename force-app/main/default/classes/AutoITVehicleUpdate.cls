public with sharing class AutoITVehicleUpdate extends AutoITVehicle {

    private static final Map<String, String> fieldsMapping = new Map<String, String>{
        'Current_KM__c' => 'mileage',
        'Retail_Price__c' => 'priceRetailDKK',
        'License_Plate_System__c' => 'regNo'
    };

    private static final Set<String> specialFields = new Set<String>{'First_Registration_Date__c'};

    private static final String OPERATION = 'Replace';
    private static final String PATH_PREFIX = '/';

    public AutoITVehicleUpdate(String autoDesktopId) {
        super(autoDesktopId);
    }

    public override HttpRequest prepareRequest(Object params) {     
        String reqBody;
        if (params instanceOf String) {
            reqBody = JSON.serialize(JSON.deserializeUntyped( (String) params));
        } else {
            AutoITVehicleObject car = (AutoITVehicleObject) params;
            reqBody = JSON.serialize(car, true);
        }
        HttpRequest req = new HttpRequest();
        req.setMethod('PATCH');
        req.setHeader('Content-Type', 'application/json-patch+json');
        req.setBody(reqBody);
        return req;
    }


    public class VehiclePatchData {
        @InvocableVariable(required=true)
        public Vehicle__c veh;
        @InvocableVariable(required=true)
        public List<String> updatedFields;
    }

    public class PatchRequest {
        public String op { get; set; }
        public String path { get; set; }
        public Object value { get; set; }
    }

    @InvocableMethod(label='Create Request Body for Vehicle Update in AutoDesktop' description='creates body for API call to update vehicle in AutoDesktop, API is not called in this method' category='AutoIT')
    public static List<String> createPatchBody(List<VehiclePatchData> data) {
        List<String> reqBodies = new List<String>();
        for (VehiclePatchData singleCarData : data) {
            List<PatchRequest> patchRequests = new List<PatchRequest>();
            for (String fieldName : singleCarData.updatedFields) {
                if (fieldsMapping.containsKey(fieldName)) {
                    PatchRequest singlePatchRequest = createSinglePatchRequest(fieldsMapping.get(fieldName), singleCarData.veh.get(fieldName));
                    if (singlePatchRequest.value != null) { 
                        patchRequests.add(singlePatchRequest);
                    }
                } else if (specialFields.contains(fieldName)) {
                    patchRequests.addAll(processSpecialFields(fieldName, singleCarData.veh));
                }
            }
            reqBodies.add(JSON.serialize(patchRequests, true));
        }
        return reqBodies;
    }

    private static PatchRequest createSinglePatchRequest(String autoDesktopFieldName, Object value) {
        PatchRequest singlePatchRequest = new PatchRequest();
        singlePatchRequest.op = OPERATION;
        singlePatchRequest.path = PATH_PREFIX + autoDesktopFieldName;
        singlePatchRequest.value = value;
        return singlePatchRequest;
    }

    private static List<PatchRequest> processSpecialFields(String fieldName, Vehicle__c veh) {
        List<PatchRequest> patchRequests = new List<PatchRequest>();
        if (fieldName.equalsIgnoreCase('First_Registration_Date__c')) {
            Date firstRegDate = (Date) veh.get(fieldName);
            if (firstRegDate != null) {
                patchRequests.add(createSinglePatchRequest('firstRegistrationYear', firstRegDate.year()));
                patchRequests.add(createSinglePatchRequest('firstRegistrationMonth', firstRegDate.month()));
                patchRequests.add(createSinglePatchRequest('firstRegistrationDay', firstRegDate.day()));    
            }
        }
        return patchRequests;
    }

}