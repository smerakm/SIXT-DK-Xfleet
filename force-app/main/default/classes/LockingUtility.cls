/**
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Utility class to enable lock and unlock Salesforce records
 *
 * It provides following functionality:
 * - lock list of records
 * - unlock list of records
 *
 * There are 2 wrappers:
 * - one for inputs (lock/unlock flag, record ids)
 * - one for lock/unlock results
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-03-25
 * @modified       2022-03-25
 * @systemLayer    Utility
 * @see            SIX-90
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-03-90      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
public inherited sharing class LockingUtility {


    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Lock / Unlock records
     * is Invocable
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  List<LockInputs> list of ids of records and flag lock or unlock is requested
     * @return List<LockOutputs> list of result of lock/unlock action for each record
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    @InvocableMethod(label='Lock/Unlock records' description='Lock (lockRecord=true) or Unlock (unlockRecord=false) records' category='Utility')
    public static List<LockOutputs> lockUnlockRecords(List<LockInputs> lockInputs) {
        List<LockOutputs> allResults = new List<LockOutputs>();
        // split to lock and unlock
        List<Id> idsToLock = new List<Id>();
        List<Id> idsToUnlock = new List<Id>();
        for (LockInputs singleInputs : lockInputs) {
            if (singleInputs.lockRecord) {
                idsToLock.add(singleInputs.recordId);
            } else {
                idsToUnlock.add(singleInputs.recordId);
            }
        }
        // perform lock
        allResults.addAll(lockRecords(idsToLock));
        // perfom unlock
        allResults.addAll(unlockRecords(idsToUnlock));

        return allResults;
    }


    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Lock list of records
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  recordIds list of ids of records to be locked
     * @return List<LockOutputs> list of result of lock action
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public static List<LockOutputs> lockRecords(List<Id> recordIds) {
        List<LockOutputs> results = new List<LockOutputs>();
        // lock the records
        List<Approval.LockResult> lockResults = Approval.lock(recordIds);
        // construct response
        for (Approval.LockResult lockResultSingle : lockResults) {
            LockOutputs outputResultSingle = new LockOutputs();
            outputResultSingle.recordId = lockResultSingle.getId();
            outputResultSingle.isSuccess = lockResultSingle.isSuccess();
            if (!lockResultSingle.isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'Error when trying to lock record: ' + lockResultSingle.getId() + ', error: ' + lockResultSingle.getErrors());
            }
            results.add(outputResultSingle);
        }
        return results;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Unlock list of records
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param  recordIds list of ids of records to be unlocked
     * @return List<LockOutputs> list of result of unlock action
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public static List<LockOutputs> unlockRecords(List<Id> recordIds) {
        List<LockOutputs> results = new List<LockOutputs>();
        // unlock the records
        List<Approval.UnlockResult> unlockResults = Approval.unlock(recordIds);
        // construct response
        for (Approval.UnlockResult unlockResultSingle : unlockResults) {
            LockOutputs outputResultSingle = new LockOutputs();
            outputResultSingle.recordId = unlockResultSingle.getId();
            outputResultSingle.isSuccess = unlockResultSingle.isSuccess();
            if (!unlockResultSingle.isSuccess()) {
                System.debug(
                    LoggingLevel.ERROR,
                    'Error when trying to unlock record: ' +
                    unlockResultSingle.getId() +
                    ', error: ' +
                    unlockResultSingle.getErrors()
                );
            }
            results.add(outputResultSingle);
        }
        return results;
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Wrapper class for INPUT parameters,
     * so the utility methods can be used from Flows
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class LockInputs {
        @InvocableVariable
        public String recordId;
        @InvocableVariable
        public Boolean lockRecord; // true = lock action, false = unlock action
    }

    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * Wrapper class for OUTPUT parameters,
     * so the utility methods can be used from Flows and return values to the flow
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    public class LockOutputs {
        @InvocableVariable
        public String recordId;
        @InvocableVariable
        public Boolean isSuccess;
    }
}