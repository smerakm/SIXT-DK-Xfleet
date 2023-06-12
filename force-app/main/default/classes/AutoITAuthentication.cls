public with sharing class AutoITAuthentication {
    private static final String AUTH_PARAM_CACHE_KEY = 'autodesktopAuthParams';
    // buffer to define how long token is valid even after cached value expired,
    // i.e. if token expiration time is 1000, we want to expire cache in 1000 - BUFFER
    private static final Integer TTL_BUFFER = 60;
    // min number of seconds for cache TTL (platform defined, do not change unless Salesforce change the limit)
    private static final Integer MIN_TTL = 300;

    private static final String ERROR_LABEL = 'Authentication Exception: ';

    public static HttpRequest addAuthenticationHeader(HttpRequest req) {
        AuthenticationResponse authParams = getAuthParams();
        req.setHeader('Authorization', authParams.token_type + ' ' + authParams.access_token);
        return req;
    }

    public static AuthenticationResponse getAuthParams() {
        // read it from org cache
        AuthenticationResponse params = (AuthenticationResponse) Cache.Org.get(AUTH_PARAM_CACHE_KEY);
        System.debug('auth params from cache: ' + params);
        if (params == null) {
            // not stored in the cache, call token endpoint
            params = getAuthTokenCall();
            System.debug('auth params from call, expires_in: ' + params.expires_in);
            System.debug('auth params from call, token_type: ' + params.token_type);
            // store in the cache for next call (only if token not expire soon)
            if (params.expires_in != null) {
                Integer cacheTTL = params.expires_in - TTL_BUFFER;
                System.debug('cacheTTL: ' + cacheTTL);
                if (cacheTTL > MIN_TTL) {
                    Cache.Org.put(AUTH_PARAM_CACHE_KEY, params, cacheTTL);
                    System.debug('stored in cache!');
                }
            }
        }
        return params;
    }

    public static AuthenticationResponse getAuthTokenCall() {
        AuthenticationResponse tokenResp;
        Client_Credentials_Auth__mdt authParams = [
            SELECT clientId__c, clientSecret__c, tokenEndpoint__c
            FROM Client_Credentials_Auth__mdt
            WHERE DeveloperName = 'AutoDesktopCC'
        ];
        String clientId = authParams.clientId__c;
        String clientSecret = authParams.clientSecret__c;
        String authUrl = authParams.tokenEndpoint__c;
        Map<String, String> authJson = new Map<String, String>();
        // Get the Access Token using the Refresh Token.
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(authUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String payload =
            'client_id=' +
            EncodingUtil.urlEncode(clientId, 'UTF-8') +
            '&client_secret=' +
            EncodingUtil.urlEncode(clientSecret, 'UTF-8') +
            '&grant_type=client_credentials';
        System.debug(payload);

        request.setBody(payload);
        if (Test.isRunningTest()) {
            // TEST flow
            String testAuthRespone = '{"access_token":"unit-test-235h","expires_in":3600,"token_type":"Bearer","scope":"unittest"}';
            tokenResp = (AuthenticationResponse) JSON.deserialize(testAuthRespone, AuthenticationResponse.class);
        } else {
            // standard http process, when not in test
            HttpResponse response = http.send(request);
            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                System.debug(LoggingLevel.ERROR, 'The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
                throw new AutoITVehicle.AutoITVehicleException(ERROR_LABEL + response.getBody());
            } else {
                System.debug(response.getBody());
                tokenResp = (AuthenticationResponse) JSON.deserialize(response.getBody(), AuthenticationResponse.class);
            }
        }
        return tokenResp;
    }

    public class AuthenticationResponse {
        public String access_token { get; set; } // Salesforce record Id
        public Integer expires_in { get; set; }
        public String token_type { get; set; }
        public String scope { get; set; }
    }
}