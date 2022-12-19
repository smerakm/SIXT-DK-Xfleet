@isTest
public class IntegrationRequestsUtility_Test {
    private static final Integer BATCH_DELAY = 5;
    private static final Integer BATCH_SIZE = 15;
    private static final Datetime LAST_JOB_RUN = Datetime.newInstance(2022, 11, 28, 5, 30, 0);

    @TestSetup
    static void makeData() {
        IntegrationSettings__c testSettings = new IntegrationSettings__c();
        testSettings.Batch_Job_Delay_in_minutes__c = BATCH_DELAY;
        testSettings.Job_last_run_at__c = LAST_JOB_RUN;
        testSettings.Batch_Size__c = BATCH_SIZE;
        insert testSettings;
    }

    @isTest
    public static void settingsTests() {
        Integer delay = IntegrationRequestsUtility.getJobDelay();
        System.assertEquals(BATCH_DELAY, delay, 'Batch job delay settings not read properly!');

        Integer size = IntegrationRequestsUtility.getBatchSize();
        System.assertEquals(BATCH_SIZE, size, 'Batch Size settings not read properly!');

        Datetime lastRun = IntegrationRequestsUtility.getLastJobRunTime();
        System.assertEquals(LAST_JOB_RUN, lastRun, 'Last job run time settings not read properly!');

        IntegrationRequestsUtility.setLastJobRunTime(System.now());
    }

    @isTest
    public static void scheduleJobTests() {
        // Xfleet dependency on Vehicle__c
        Map<String, Object> vehParams = new Map<String, Object>{ 'vinNumber__c' => 'VINUNIT78364' };
        Vehicle__c testVehicle = TestUtilitySIXT.createVehicle(TestUtilitySIXT.createBatch().Id, vehParams);
        Integration_Request__c irTest = new Integration_Request__c();
        irTest.API_Method__c = 'UnitTest';
        irTest.Vehicle__c = testVehicle.Id;
        insert irTest;
        Test.startTest();
        Id jobId = IntegrationRequestsUtility.scheduleIntegrationBatch();
        Id jobId2nd = IntegrationRequestsUtility.scheduleIntegrationBatch();
        IntegrationRequestsUtility.runNavisionIntegrationJob();
        Test.stopTest();
        System.assert(jobId != null, 'Job has not been scheduled!');
        System.assertEquals(jobId, jobId2nd, '2nd job should not been scheduled and same Id shall be returned!');
    }

    @isTest
    public static void errorNotificationTests() {
        IntegrationRequestsUtility.notifyAdminsAboutFailedRequests(4);
        IntegrationRequestsUtility.notifyAdminsAboutFailedRequests(null);
    }

    @isTest
    public static void rollupsTests() {
        // Xfleet dependency on Vehicle__c
        Map<String, Object> vehParams = new Map<String, Object>{ 'vinNumber__c' => 'VINUNIT78364' };
        Vehicle__c testVehicle = TestUtilitySIXT.createVehicle(TestUtilitySIXT.createBatch().Id, vehParams);

        // prepare integration request for rollups
        Integer notProcessedCount = 4;
        Integer successCount = 13;
        Integer failedCount = 2;

        List<Integration_Request__c> irsTest = new List<Integration_Request__c>();
        // not processed IRs
        for (Integer i = 0; i < notProcessedCount; i++) {
            Integration_Request__c irTest = new Integration_Request__c();
            irTest.API_Method__c = 'UnitTest';
            irTest.Vehicle__c = testVehicle.Id;
            irsTest.add(irTest);
        }
        // successfully processed
        for (Integer i = 0; i < successCount; i++) {
            Integration_Request__c irTest = new Integration_Request__c();
            irTest.API_Method__c = 'UnitTest';
            irTest.Vehicle__c = testVehicle.Id;
            irTest.Status__c = IntegrationRequestsUtility.STATUS_SUCCESS;
            irsTest.add(irTest);
        }
        // failed processed
        for (Integer i = 0; i < failedCount; i++) {
            Integration_Request__c irTest = new Integration_Request__c();
            irTest.API_Method__c = 'UnitTest';
            irTest.Vehicle__c = testVehicle.Id;
            irTest.Status__c = IntegrationRequestsUtility.STATUS_FAILED;
            irsTest.add(irTest);
        }
        insert irsTest;

        Test.startTest();
        IntegrationRequestsUtility.updateIntegrationRequestsRollups();
        Test.stopTest();

        testVehicle = [
            SELECT id, Integration_Requests_Number_Success__c, Integration_Requests_Number_Failed__c, Integration_Requests_Number_Not_Run_Yet__c
            FROM Vehicle__c
            WHERE Id = :testVehicle.Id
        ];

        // asserts
        System.assertEquals(notProcessedCount, testVehicle.Integration_Requests_Number_Not_Run_Yet__c, 'Not processed requests rollup failed!');
        System.assertEquals(successCount, testVehicle.Integration_Requests_Number_Success__c, 'Successfull requests rollup failed!');
        System.assertEquals(failedCount, testVehicle.Integration_Requests_Number_Failed__c, 'Failed requests rollup failed!');
    }
}