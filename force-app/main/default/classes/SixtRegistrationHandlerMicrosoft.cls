/**
 * Registration Handler to be used with Microsoft Auth. Provider.
 * It allows connect Microsoft (Azure) AD user with Salesforce user.
 * Only users with @sixt.dk domain are allowed.
 *
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         Marek Smerak      <marek.smerak@wipro.com>
 * @modifiedBy     Marek Smerak      <marek.smerak@wipro.com>
 * @version        1.0
 * @created        2022-11-15
 * @modified       2022-11-15
 * @systemLayer    Identity
 * @see            SIXT-94
 * ──────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * v1.0            marek.smerak@wipro.com
 * 2022-11-15      initial version
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
@isTest
global class SixtRegistrationHandlerMicrosoft implements Auth.RegistrationHandler {
    private static final String SIXT_DOMAIN = 'sixt.dk';

    global User createUser(Id portalId, Auth.UserData data) {
        System.debug('incoming data: ' + data);
        System.debug('incoming attributes: ' + data.attributeMap);
        // allow only sixt.dk domain
        String emailDomain = data.email.substringAfterLast('@');
        if (emailDomain.equalsIgnoreCase(SIXT_DOMAIN)) {
            List<User> users = [SELECT firstName, lastName, email FROM User WHERE Email = :data.Email];
            // is there just one user?
            if (users.size() == 1) {
                return users.get(0);
            }
        }
        // we are not able to connect the user
        return null;
    }

    global void updateUser(Id userId, Id portalId, Auth.UserData data) {
        // just make sure that user's email is still valid
        User u = new User(id=userId);
        u.email=data.email;
        update(u);
    }
}