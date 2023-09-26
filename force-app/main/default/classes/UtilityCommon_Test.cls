@isTest
public with sharing class UtilityCommon_Test {
    @isTest
    public static void mergeFieldsToStringTest() {
        Account tstAcc = new Account(Name = 'Wonderland');
        insert tstAcc;
        Contact tstContact = new Contact(FirstName = 'Peter', LastName = 'Pann', AccountId = tstAcc.Id);
        insert tstContact;
        tstContact = [SELECT LastName, Account.Name, Account.Owner.LastName FROM Contact WHERE Id = :tstContact.Id];

        String labelInput = 'test contact and owner: {{LastName}} and {{Account.Name}} ruled by {{Account.Owner.LastName}}';
        String labelOutputExpected = 'test contact and owner: Pann and Wonderland ruled by ' + UserInfo.getLastName();
        String labelOutput = UtilityCommon.mergeFieldsIntoString(labelInput, tstContact);

        System.assertEquals(labelOutputExpected, labelOutput);
    }
}