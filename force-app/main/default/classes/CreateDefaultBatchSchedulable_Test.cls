@isTest
public with sharing class CreateDefaultBatchSchedulable_Test {
    @isTest
    public static void schedulableTest() {
        TestUtilitySIXT.initFleetManagementSettings();

        String cronExp = '0 0 0 1 1 ?'; // Set the cron expression based on your requirement
        CreateDefaultBatchSchedulable scheduler = new CreateDefaultBatchSchedulable();
        String jobId = system.schedule('Test Job', cronExp, scheduler);

        Test.startTest();

        // Verify the scheduled job
        System.assert(jobId != null, 'Job not scheduled successfully.');

        Test.stopTest();
    }
}