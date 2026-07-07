/**
 * Auth0UserService — Module 2 mini-project ("Portal User Provisioner").
 *
 * Full CRUD against the Auth0 Management API via the client credentials flow.
 * All authentication is handled by the Named Credential 'Auth0_Mgmt_API'
 * (External Credential 'Auth0' + Principal 'ProvisionerApp') — which is why
 * you will find NO token requests and NO secrets anywhere in this class.
 *
 * Naming conventions on display:
 *  - Class named for what it serves:  Auth0UserService
 *  - Methods named for what they do:  createUser / getUser / updateUserPlan / deleteUser
 *  - One private send() holds all plumbing, so public methods read like English.
 */
public with sharing class Auth0UserService {

    private static final String USERS_PATH = 'callout:Auth0_Mgmt_API/api/v2/users';

    /** Thrown whenever Auth0 answers with a non-success status code. */
    public class Auth0Exception extends Exception {}

    // ─────────────────────────────────────────────── C — CREATE
    /** Creates a user in Auth0's default database. Returns the new id ("auth0|…"). */
    public static String createUser(String email, String password) {
        Map<String, Object> body = new Map<String, Object>{
            'email'      => email,
            'password'   => password,
            'connection' => 'Username-Password-Authentication'
        };
        HttpResponse res = send('POST', USERS_PATH, JSON.serialize(body));
        Map<String, Object> user =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (String) user.get('user_id');
    }

    // ─────────────────────────────────────────────── R — READ
    /** Reads one user by id. Throws Auth0Exception (404) if it doesn't exist. */
    public static Map<String, Object> getUser(String userId) {
        HttpResponse res = send('GET', userPath(userId), null);
        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    }

    // ─────────────────────────────────────────────── U — UPDATE
    /** Stores a plan name in user_metadata — Auth0's "custom fields" bucket. */
    public static void updateUserPlan(String userId, String plan) {
        String body = JSON.serialize(new Map<String, Object>{
            'user_metadata' => new Map<String, Object>{ 'plan' => plan }
        });
        send('PATCH', userPath(userId), body);
    }

    // ─────────────────────────────────────────────── D — DELETE
    /** Deletes the user. Auth0 answers 204 No Content on success. */
    public static void deleteUser(String userId) {
        send('DELETE', userPath(userId), null);
    }

    // ─────────────────────────────────────────────── plumbing

    /** Auth0 ids contain a pipe ("auth0|abc…"), so they must be URL-encoded. */
    private static String userPath(String userId) {
        return USERS_PATH + '/' + EncodingUtil.urlEncode(userId, 'UTF-8');
    }

    /** The single door every request goes through: build, send, fail loudly. */
    private static HttpResponse send(String method, String endpoint, String jsonBody) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        if (jsonBody != null) {
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
        }
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() >= 300) {
            throw new Auth0Exception(method + ' ' + endpoint + ' failed: '
                + res.getStatusCode() + ' ' + res.getBody());
        }
        return res;
    }
}
