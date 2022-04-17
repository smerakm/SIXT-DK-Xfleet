/**
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Utility class for Vehicle Group object.
 *
 * It provides following functionality:
 * - mapping from Acriss code to Vehicle_Group__c
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-01-01
 * @modified       2022-04-01
 * @systemLayer    Utility
 * @see            SIX-4
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-04-01      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
public inherited sharing class VehicleGroupUtility {
    // mapping from acriss code to vehicle group
    private static Map<String, Vehicle_Group__c> mAcriss2VehicleGroup;

    public static Map<String, Vehicle_Group__c> getAcriss2VehicleGroupMap() {
        if (mAcriss2VehicleGroup == null) {
            mAcriss2VehicleGroup = new Map<String, Vehicle_Group__c>();
            for (Vehicle_Group__c vehicleGroup : [SELECT Id, Codes__c FROM Vehicle_Group__c]) {
                System.debug(LoggingLevel.FINE, 'creating mapping for Vehicle Group: ' + vehicleGroup);
                List<String> codes = vehicleGroup.Codes__c.split(';');
                for (String singleAcrissCode : codes) {
                    mAcriss2VehicleGroup.put(singleAcrissCode, vehicleGroup);
                }
            }
        }
        System.debug(LoggingLevel.FINE, 'Vehicle Group map: ' + mAcriss2VehicleGroup);
        return mAcriss2VehicleGroup;
    }
}