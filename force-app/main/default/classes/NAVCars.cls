public abstract with sharing class NAVCars {
    
    private static final String NAMED_CREDENTIAL_TEST = 'MareksMockBee';
    private static final String NAMED_CREDENTIAL_PROD = 'MareksMockBee';

    public String vinNo;

    // empty constructor is allowed 
    public NAVCars() {
        // just set Vin number to null to avoid empty block
        this.vinNo = null;
    }

    public NAVCars(String vinNo) {
        this.vinNo = vinNo;
    }

    public virtual String getEndpoint() {
        String endpoint = 'callout:';
        // is it sandbox?
        if ([SELECT IsSandbox FROM Organization].IsSandbox) {
            endpoint += NAMED_CREDENTIAL_TEST;
        } else {
            endpoint += NAMED_CREDENTIAL_PROD;
        }
        // add constant 'Sixt' organization
        endpoint += '/Company(\'Sixt\')';
        // is it for specific vehicle?
        if (String.isNotBlank(this.vinNo)) {
            endpoint += '/Cars(\'' + this.vinNo + '\')';
        } else {
            endpoint += '/Cars';   
        }
        System.debug(LoggingLevel.DEBUG, 'Navision endpoint: ' + endpoint);
        return endpoint;
    }

    public abstract HttpRequest prepareRequest(Object params);

    public virtual HttpResponse call(HttpRequest req) {
        req.setEndpoint(this.getEndpoint());
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res;
    }

}
