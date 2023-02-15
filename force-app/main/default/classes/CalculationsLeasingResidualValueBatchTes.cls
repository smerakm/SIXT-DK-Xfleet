@isTest
public with sharing class CalculationsLeasingResidualValueBatchTes {
    @isTest
    public static void residualValueBatch() {
        // prepare data
        Account testLeasingAccount = new Account(Name = 'Test Unit Leasing ACC1', Leasing_Algorithm__c = '1', Leasing_Rate__c = 3.75);
        insert testLeasingAccount;
        VehicleBatch__c testBatch = TestUtilitySIXT.createBatch();
        Map<String, Object> params = new Map<String, Object>();
        params.put('Batch_Distribution__c', 'Valuta');
        params.put('Leasing_Cost_Per_Month__c', 3284.43);
        params.put('Registration_Date__c', Date.today().addMonths(-1));
        params.put('Sixt_steel_purchase_price__c', 254330);
        Vehicle__c testVehicle = TestUtilitySIXT.createVehicle(testBatch.id, params);
        testVehicle.leasing_Account__c = testLeasingAccount.id;
        update testVehicle;

        // run test
        Test.startTest();
        SchedulableContext context;
        new CalculationsLeasingResidualValueBatch().execute(context);
        Test.stopTest();

        Vehicle__c testVehicleAfter = [SELECT Redemption_Price_to_Leasing_Account__c FROM Vehicle__c WHERE Id = :testVehicle.Id LIMIT 1];
        System.assertEquals(251830.1, testVehicleAfter.Redemption_Price_to_Leasing_Account__c.setScale(1));
    }
}
