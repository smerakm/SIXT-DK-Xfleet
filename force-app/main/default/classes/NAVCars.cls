public abstract with sharing class NAVCars {
    
    // Named Credentials
    private static final String NAMED_CREDENTIAL_TEST = 'NavisionTEST';
    private static final String NAMED_CREDENTIAL_PROD = 'MareksMockBee';

    //private static final String NAMED_CREDENTIAL_TEST = 'https://178.209.171.36:7048/DynamicsNAV100/ODataV4';
    //private static final String NAMED_CREDENTIAL_TEST = 'https://nav.sixt.dk:7048/DynamicsNAV100/ODataV4';
    //private static final String NAMED_CREDENTIAL_PROD = 'http://178.209.171.36:7048/DynamicsNAV100/ODataV4';

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
        // TODO named credentials: 
        String endpoint = 'callout:';
        //String endpoint = '';
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

    private HttpRequest setBasicAuth(HttpRequest r) {
        String username = 'frp';
        String password = '!Sixt123';
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        r.setHeader('Authorization', authorizationHeader);
        return r;
    }

    public abstract HttpRequest prepareRequest(Object params);

    public virtual HttpResponse call(HttpRequest req) {
        // get any URL parameters set from specific implementations
        String urlParams = req.getEndpoint(); 
        if (String.isNotBlank(urlParams)) {
            System.debug(LoggingLevel.FINE, 'request url params: ' + urlParams);
            req.setEndpoint(this.getEndpoint() + urlParams);    
        } else {
            req.setEndpoint(this.getEndpoint());
        }
        // TODO remove content type with Named Credentials???
        //req.setHeader('Content-Type','application/json');
        //req = setBasicAuth(req);

        req.setTimeout(120000);

        System.debug('req body: ' + req.getBody());

        Http http = new Http();
        HTTPResponse res = http.send(req);

        System.debug('resp status: ' + res.getStatus());
        System.debug('resp body: ' + res.getBody());

        return res;
    }

    public class NavisionCarsException extends Exception {}
}
