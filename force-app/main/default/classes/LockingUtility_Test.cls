/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * test for CalculationsTax class
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-03-16
 * @modified       2022-03-16
 * @systemLayer    Test
 * @see            SIX-177
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-03-14      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
@isTest
public class LockingUtility_Test {
    public static final String BATCH_DESCRIPTION = 'This is Unit Test 534ui';

    @TestSetup
    static void makeData() {
        // Vehicle batch
        VehicleBatch__c testBatch = new VehicleBatch__c();
        testBatch.Description__c = BATCH_DESCRIPTION;
        insert testBatch;

        // it is hard to create any child related records because of different flow automation
    }

    @isTest
    static void testLockUnlock() {
        // get the record
        VehicleBatch__c testRec = [SELECT Id FROM VehicleBatch__c WHERE Description__c = :BATCH_DESCRIPTION LIMIT 1];
        // test lock
        LockingUtility.LockInputs testInputs = new LockingUtility.LockInputs();
        testInputs.recordId = testRec.Id;
        testInputs.lockRecord = true;
        List<LockingUtility.LockInputs> testInputsList = new List<LockingUtility.LockInputs>();
        testInputsList.add(testInputs);

        // test lock - success
        List<LockingUtility.LockOutputs> outputs1 = LockingUtility.lockUnlockRecords(testInputsList);
        LockingUtility.LockOutputs testOutputs1 = outputs1.get(0);
        System.assertEquals(testRec.Id, testOutputs1.recordId, 'wrong record id');
        System.assert(testOutputs1.isSuccess, 'record has not been locked successfully!');
        // test unlock - success
        LockingUtility.LockInputs testInputsUnlock = new LockingUtility.LockInputs();
        testInputsUnlock.recordId = testRec.Id;
        testInputsUnlock.lockRecord = false;
        List<LockingUtility.LockInputs> testInputsListUnlock = new List<LockingUtility.LockInputs>();
        testInputsListUnlock.add(testInputsUnlock);
        List<LockingUtility.LockOutputs> outputs3 = LockingUtility.lockUnlockRecords(testInputsListUnlock);
        LockingUtility.LockOutputs testOutputs3 = outputs3.get(0);
        System.assertEquals(testRec.Id, testOutputs3.recordId, 'wrong record id');
        System.assert(testOutputs3.isSuccess, 'record has not been unlocked successfully!');
    }
}