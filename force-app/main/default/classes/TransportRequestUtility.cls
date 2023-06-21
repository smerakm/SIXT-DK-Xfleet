public with sharing class TransportRequestUtility {
    @InvocableMethod(
        label='Calculate Transport Request Formulas'
        description='Returns the list of transport requests with their formulas calculated'
        category='Transport Request'
    )
    public static List<Transport_Request__c> calculateTransportRequestsFormulasInvocable(List<Transport_Request__c> trs) {
        return calculateTransportRequestsFormulas(trs);
    }

    public static List<Transport_Request__c> calculateTransportRequestsFormulas(List<Transport_Request__c> trs) {
        List<Transport_Request__c> newTRS = new List<Transport_Request__c>();
        List<FormulaRecalcResult> results = Formula.recalculateFormulas(trs);
        for (FormulaRecalcResult result : results) {
            if (result.isSuccess()) {
                newTRS.add((Transport_Request__c) result.getSObject());
            } else {
                System.debug(LoggingLevel.ERROR, result.getErrors());
            }
        }
        return newTRS;
    }
}
