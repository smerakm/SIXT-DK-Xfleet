trigger IntegrationRequestTrigger on Integration_Request__c (after insert) {
    if (Trigger.isInsert && Trigger.isAfter) {
        NAVCarsUtility.scheduleNAVCarsIntegrationBatch();
    }
}