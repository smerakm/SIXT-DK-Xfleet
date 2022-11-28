/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * test for FixedRateLoanUtility class
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-11-15
 * @modified       2022-11-15
 * @systemLayer    Test
 * @see            SIXT-94
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-11-15      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
@isTest
public with sharing class SixtRegistrationHandlerMicrosoft_Test {
    
    @isTest
    private static void createUserTest() {
        // String identifier, String firstName, String lastName, String fullName, String email, String link, String userName, String locale, String provider, String siteLoginUrl, Map<String,String> attributeMap)
        Auth.UserData testData = new Auth.UserData('123456', 'Test', 'UnitUser', 'Test UnitUser', 'test.testsen@sixt.dk', null, null, null, null, null, null);

        SixtRegistrationHandlerMicrosoft testRegHandler = new SixtRegistrationHandlerMicrosoft();
        User u = testRegHandler.createUser(null, testData);
        System.assertEquals(null, u);
    }

    @isTest
    private static void updateUserTest() {
        // String identifier, String firstName, String lastName, String fullName, String email, String link, String userName, String locale, String provider, String siteLoginUrl, Map<String,String> attributeMap)
        Auth.UserData testData = new Auth.UserData('123456', 'Test', 'UnitUser', 'Test UnitUser', 'test.testsen@sixt.dk', null, null, null, null, null, null);

        SixtRegistrationHandlerMicrosoft testRegHandler = new SixtRegistrationHandlerMicrosoft();
        testRegHandler.updateUser(UserInfo.getUserId(), null, testData);
    }
}