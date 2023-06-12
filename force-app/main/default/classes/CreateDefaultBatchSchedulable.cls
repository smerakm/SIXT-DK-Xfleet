/**
 * This is a scheduled process that will create new vehicle batch record
 * and set this as new default batch for vehicles coming from non-standard process,
 * e.g. from AutoDesktop
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2023-04-25
 * @modified       2023-04-25
 * @systemLayer    Scheduled Apex
 * @see            SIXT-106
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2023-04-25      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
public with sharing class CreateDefaultBatchSchedulable implements System.Schedulable {
    private static final String LABEL_FOR_DESCRIPTION = Label.Xfleet_Label_Default_Batch_Description;
    private static final String OPEN_BRACKET = '{{';
    private static final String CLOSE_BRACKET = '}}';

    public void execute(SchedulableContext sc) {
        // read the label
        // add Date part
        String dateFormat = LABEL_FOR_DESCRIPTION.substringBetween(OPEN_BRACKET, CLOSE_BRACKET);
        String dateString = System.now().format(dateFormat);
        String batchDescription = LABEL_FOR_DESCRIPTION.replace(OPEN_BRACKET + dateFormat + CLOSE_BRACKET, dateString);
        // crate a batch
        vehicleBatch__c newDefaultBatch = new vehicleBatch__c();
        newDefaultBatch.Description__c = batchDescription;
        newDefaultBatch.Type__c = 'Other';
        FleetManagementConfig__c config = FleetManagementConfig__c.getOrgDefaults();
        newDefaultBatch.Vehicle_Group__c = config.ExchangeVehicleGroupId__c; 
        insert newDefaultBatch;
        // update custom metadata
        config.DefaultBatchId__c = newDefaultBatch.Id;
        update config;
    }
}