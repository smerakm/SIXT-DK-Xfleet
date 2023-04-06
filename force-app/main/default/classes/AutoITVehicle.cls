/**
 * This is abstract definition for AutoIT/AutoDesktop API implementation.
 *
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2023-04-06
 * @modified       2023-04-06
 * @systemLayer    CallOuts
 * @see            SIXT-102, SIXT-103
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2023-04-06      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
public abstract with sharing class AutoITVehicle {
    
    // Named Credentials
    private static final String NAMED_CREDENTIAL_TEST = 'AutoDesktopTEST';
    private static final String NAMED_CREDENTIAL_PROD = 'AutoDesktopPROD';
    // API suffix
    private static final String CARS_API = 'Vehicle';

    public String externalId;

    // empty constructor is allowed 
    public AutoITVehicle() {
        // just set Vin number to null to avoid empty block
        this.externalId = null;
    }

    public AutoITVehicle(String externalId) {
        this.externalId = externalId;
    }

    public virtual String getEndpoint() {
        // named credentials: 
        String endpoint = 'callout:';
        // is it sandbox?
        if ([SELECT IsSandbox FROM Organization].IsSandbox) {
            endpoint += NAMED_CREDENTIAL_TEST;
        } else {
            endpoint += NAMED_CREDENTIAL_PROD;
        }
        // API name / suffix:
        endpoint += '/' + CARS_API;
        // is it for specific vehicle?
        if (String.isNotBlank(this.externalId)) {
            endpoint += '(\'' + this.externalId + '\')';
        }

        System.debug(LoggingLevel.DEBUG, 'AutoIT endpoint: ' + endpoint);
        return endpoint;
    }

    public abstract HttpRequest prepareRequest(Object params);

    public virtual HttpResponse call(HttpRequest req) {
        // get any URL parameters set from specific implementations (passed in req endpoint)
        String urlParams = req.getEndpoint(); 
        if (String.isNotBlank(urlParams)) {
            System.debug(LoggingLevel.FINE, 'request url params: ' + urlParams);
            req.setEndpoint(this.getEndpoint() + urlParams);    
        } else {
            req.setEndpoint(this.getEndpoint());
        }

        req.setTimeout(120000);

        System.debug('req body: ' + req.getBody());

        Http http = new Http();
        HTTPResponse res = http.send(req);

        System.debug('resp status: ' + res.getStatus());
        System.debug('resp body: ' + res.getBody());

        return res;
    }

    public class AutoITVehicleException extends Exception {}
}