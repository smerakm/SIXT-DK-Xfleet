public with sharing class CalculationsLeasingResidualValueBatch implements Schedulable, Database.Batchable<SObject>, Database.Stateful {
    @TestVisible
    private static final String DEFAULT_QUERY = Label.Xfleet_Query_Vehicles_for_Residual_Value_Update;

    private String query;
    public Integer numberOfUpdatedVehicles;

    public CalculationsLeasingResidualValueBatch(String query) {
        this.query = query;
        this.numberOfUpdatedVehicles = 0;
    }

    public CalculationsLeasingResidualValueBatch() {
        this.query = DEFAULT_QUERY;
        this.numberOfUpdatedVehicles = 0;
    }

    // schedulable execute
    public void execute(SchedulableContext param1) {
        Database.executeBatch(new CalculationsLeasingResidualValueBatch());
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    // batchable execute
    public void execute(Database.BatchableContext bc, List<Vehicle__c> scope) {
        // get calculation inputs and calculate residual value
        List<CalculationsLeasingResidualValue.CalculationResidualValueInputs> calcInputs = convertVehicleToCalcInputs(scope);
        List<CalculationsLeasingResidualValue.CalculationResidualValueOutputs> calcOutputs = CalculationsLeasingResidualValue.calculateResidualValue(
            calcInputs
        );
        for (Integer i = 0; i < scope.size(); i++) {
            Vehicle__c v = scope.get(i);
            v.Redemption_Price_to_Leasing_Account__c = calcOutputs.get(i).residualValue;
        }
        // update vehicles in scope
        update scope;
        this.numberOfUpdatedVehicles += scope.size();
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Update Residual Value finished, updated ' + this.numberOfUpdatedVehicles + ' updated!');
    }

    private List<CalculationsLeasingResidualValue.CalculationResidualValueInputs> convertVehicleToCalcInputs(List<Vehicle__c> vehs) {
        List<CalculationsLeasingResidualValue.CalculationResidualValueInputs> inputs = new List<CalculationsLeasingResidualValue.CalculationResidualValueInputs>();
        for (Vehicle__c v : vehs) {
            CalculationsLeasingResidualValue.CalculationResidualValueInputs singleInput = new CalculationsLeasingResidualValue.CalculationResidualValueInputs();
            singleInput.algorithm = Integer.valueOf(v.leasing_Account__r.Leasing_Algorithm__c);
            singleInput.interestRate = v.Leasing_Rate_Contract__c / 100;
            singleInput.isL94 = v.Batch_Distribution__c == 'DK - L94';
            singleInput.monthlyPayment = v.Leasing_Cost_Per_Month__c;
            singleInput.periodLength = Integer.valueOf(v.Current_Month_in_Leasing__c);
            singleInput.presentValue = v.Total_Buy_Price__c;
            singleInput.registrationBaseL94 = v.Final_tax_after_deduction__c;
            inputs.add(singleInput);
        }
        return inputs;
    }
}