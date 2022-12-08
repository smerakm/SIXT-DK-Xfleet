public with sharing class NAVCarsInvocable {
    @InvocableMethod(label='Navision Cars API' description='Call Navision API different methods like Create or Update car, create Invoice/Quote')
    public static List<NavisionCarsResult> callNavisionCarsApi(List<NavisionCarsRequest> requests) {
        List<NavisionCarsResult> results = new List<NavisionCarsResult>();
        for (NavisionCarsRequest singleReq : requests) {
            results.add(callNavisionCarsApi(singleReq));
        }
        return results;
    }

    public static NavisionCarsResult callNavisionCarsApi(NavisionCarsRequest req) {
        NAVCars navApi;
        Object reqParams;
        // CREATE
        if (req.callMethod.equalsIgnoreCase('CREATE')) {
            navApi = new NAVCarsCreate();
            reqParams = new NAVCarsObject(req.vinNumber, req.registrationNumber, req.vatType);
        } else if (req.callMethod.equalsIgnoreCase('UPDATE')) {
            // UPDATE
            navApi = new NAVCarsUpdate(req.vinNumber);
            req.vinNumber = null;
            reqParams = req.convertToNAVCarsObject();
        } else if (req.callMethod.equalsIgnoreCase('GET')) {
            // GET
            if (String.isNotBlank(req.filterValue)) {
                navApi = new NAVCarsGet();
                reqParams = req.filterValue;    
            } else {
                navApi = new NAVCarsGet(req.vinNumber);
            }
        }
        // initialize response
        NavisionCarsResult theResult = new NavisionCarsResult();
        theResult.isSuccess = false;
        // is method supported?
        if (navApi != null) {
            // prepare data and call API
            HttpRequest navApiReq = navApi.prepareRequest(reqParams);
            HttpResponse navApiResp = navApi.call(navApiReq);
            // is it success?
            theResult.statusCode = navApiResp.getStatusCode();
            if ((theResult.statusCode == 200) || (theResult.statusCode == 201)) {
                // SUCCESS
                theResult.isSuccess = true;
            }
            theResult.statusMessage = navApiResp.getStatus();
            theResult.message = navApiResp.getBody();
        }
        // is it a failure?
        if (!theResult.isSuccess) {
            String errorMessage = 'Error in Navision integration: ';
            if (String.isBlank(theResult.statusMessage)) {
                errorMessage += 'Wrong method selected - contact admin!';
            } else {
                errorMessage += theResult.statusMessage + ' (' + theResult.statusCode + ')!';
                if (String.isNotBlank(theResult.message)) {
                    errorMessage += ' ' + theResult.message;
                }
            }
            // throw the exeption
            throw new NAVCars.NavisionCarsException(errorMessage);
        }
        // return the result
        return theResult;
    }

    public class NavisionCarsRequest {
        @InvocableVariable(label='call method' description='CREATE or UPDATE are available values' required=true)
        public String callMethod;

        @InvocableVariable
        public String vinNumber;

        @InvocableVariable
        public String registrationNumber;

        @InvocableVariable
        public String vatType;

        @InvocableVariable(label='amount' description='Invoice or Advi/Quote amount')
        public Decimal amount;

        @InvocableVariable(label='External Documber Number' description='External Document Number for Invoice or Advi')
        public String extDocNo;

        @InvocableVariable(label='Navision Account Number for Invoice' description='used for Invoice')
        public String accNumberInvoice;

        @InvocableVariable(label='Navision Account Number for Quote' description='used for Quote/Advi')
        public String accNumberQuote;

        @InvocableVariable(label='Query Filter' description='value of filter for Query/GET request')
        public String filterValue;

        // convert this instance of NavisionCarsRequest to NAVCarsObject for API calls
        public NAVCarsObject convertToNAVCarsObject() {
            NAVCarsObject navCar = new NAVCarsObject(this.vinNumber, this.registrationNumber, this.vatType);
            //navCar.Vin_No = this.vinNumber;
            //navCar.regNo = this.registrationNumber;
            //navCar.vatType = this.vatType;
            navCar.createAmount = this.amount;
            if (String.isNotBlank(this.extDocNo)) navCar.creatExtDocNo = this.extDocNo;
            if (String.isNotBlank(this.accNumberInvoice)) navCar.createInvoice = this.accNumberInvoice;
            if (String.isNotBlank(this.accNumberQuote)) navCar.createQuote = this.accNumberQuote;
            return navCar;
        }
    }

    public class NavisionCarsResult {
        @InvocableVariable
        public String statusMessage;

        @InvocableVariable
        public Integer statusCode;

        @InvocableVariable
        public String message;

        @InvocableVariable
        public Boolean isSuccess;
    }
}
