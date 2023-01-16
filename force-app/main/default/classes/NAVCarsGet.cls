public with sharing class NAVCarsGet extends NAVCars {
    private static final String FILTER_HEADER = '$filter';

    // use if we want to retrieve vehicles, filter can be set in prepareRequest() method
    public NAVCarsGet() {
        super();
    }

    // use if we want to retrieve information about 1 vehicle
    public NAVCarsGet(String vinNo) {
        super(vinNo);
    }

    // params - is optional, and it is filter value
    public override HttpRequest prepareRequest(Object params) {
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        // shall we use filter?
        if ((params != null) && (params instanceof String)) {
            String filterValue = EncodingUtil.urlEncode((String) params, 'UTF-8');
            req.setEndpoint('?' + FILTER_HEADER + '=' + filterValue);
        }
        return req;
    }

    // method to get single car information,
    // can be used only if initialized with VIN
    public NAVCarsObject getSingleCar() {
        if (String.isBlank(this.vinNo)) {
            throw new NAVCars.NavisionCarsException('Please provide VIN number to retrieve data from Navision!');
        }
        // get Http response with single vehicle information
        HttpResponse resp = call(prepareRequest(null));
        NAVCarsObject car;
        if (resp.getStatusCode() == 200) {
            car = (NAVCarsObject) JSON.deserialize(resp.getBody(), NAVCarsObject.class);
        } else {
            throw new NAVCars.NavisionCarsException(resp.getBody());
        }
        return car;
    }

    // method to get cars information from NAV
    // no filter
    public Map<String, NAVCarsObject> getCars() {
        return getCars(null);
    }

    // method to get cars information from NAV
    // no filter
    public Map<String, NAVCarsObject> getCarsModifiedAfter(Datetime lastModifiedAt) {
        String lastModifiedAtString = lastModifiedAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        return getCars('modifiedAt gt ' + lastModifiedAtString);
    }

    // method to get cars information from NAV
    // filter value can be specified
    public Map<String, NAVCarsObject> getCars(String filter) {
        // get Http response with single vehicle information
        HttpResponse resp = call(prepareRequest(filter));
        List<NAVCarsObject> cars;
        if (resp.getStatusCode() == 200) {
            String respBody = resp.getBody();
            // contains list?
            if (respBody.contains('"value":[') || respBody.contains('"value": [')) {
                cars = ((NAVCarsListWrapper) JSON.deserialize(resp.getBody(), NAVCarsListWrapper.class)).value;
            } else {
                // single car
                NAVCarsObject car = (NAVCarsObject) JSON.deserialize(resp.getBody(), NAVCarsObject.class);
                cars = new List<NAVCarsObject>{ car };
            }
        } else {
            throw new NAVCars.NavisionCarsException(resp.getBody());
        }
        // construct map, where key = VIN number
        Map<String, NAVCarsObject> mCars;
        if (cars != null && !cars.isEmpty()) {
            mCars = new Map<String, NAVCarsObject>();
            for (NAVCarsObject singleCar : cars) {
                mCars.put(singleCar.Vin_No, singleCar);
            }
        }
        return mCars;
    }

    public class NAVCarsListWrapper {
        public List<NAVCarsObject> value { get; set; }
    }
}