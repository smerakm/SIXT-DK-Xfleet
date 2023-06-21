public with sharing class AutoITVehicleDelete extends AutoITVehicle {
    
    public AutoITVehicleDelete(String autoDesktopId) {
        super(autoDesktopId);
    }

    public override HttpRequest prepareRequest(Object params) {
        HttpRequest req = new HttpRequest();
        req.setMethod('DELETE');
        return req;
    }

    @future(callout=true)
    public static void futureDelete(String autoDesktopId) {
        AutoITVehicleDelete api = new AutoITVehicleDelete(autoDesktopId);
        HttpResponse resp = api.call(api.prepareRequest(null));
        System.debug(LoggingLevel.DEBUG, resp.getStatusCode());
    }

    @InvocableMethod(label='Delete Vehicle from AutoDesktop' description='Call future method to use API to delete vehicle in AutoDesktop' category='AutoIT')
    public static List<String> deleteVehicle(List<String> autoDesktopIds) {
        for (String autoDesktopId : autoDesktopIds) {
            futureDelete(autoDesktopId);
        }
        return autoDesktopIds;
    }

}