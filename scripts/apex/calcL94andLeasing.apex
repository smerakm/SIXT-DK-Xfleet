List<Vehicle__c> vehs = [SELECT Id, Final_tax_after_deduction__c, Leasing_Period__c, Proportional_Registration_Fee__c, Proportional_Registration_Interest__c 
from Vehicle__c 
where Leasing_Period__c != null
and Batch_Distribution__c = 'DK - L94'  
and Proportional_Registration_Fee__c = null
and Proportional_Registration_Interest__c = null
and Final_tax_after_deduction__c != null
limit 500];

for (Vehicle__c v : vehs) {
    CalculationsTax.CalculationTaxInputs inputs = new CalculationsTax.CalculationTaxInputs();
    inputs.registrationFee = v.Final_tax_after_deduction__c;
    inputs.vehicleAge = 0;
    inputs.leasingPeriodLength = (Integer)v.Leasing_Period__c + 1;
    CalculationsTax.CalculationTaxOutputs taxOutputs = CalculationsTax.calculateTax(inputs);
    v.Proportional_Registration_Fee__c = taxOutputs.registrationFeeOfAssumedValueLost;
    v.Proportional_Registration_Interest__c = taxOutputs.interestOnResidualTax;
}

update vehs;
