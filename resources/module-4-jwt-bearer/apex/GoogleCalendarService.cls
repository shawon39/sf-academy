/**
 * GoogleCalendarService — Module 4 mini-project ("Kickoff Scheduler").
 *
 * Full CRUD on Google Calendar events via the OAuth 2.0 JWT bearer flow:
 * Apex writes the claims (Auth.JWT), signs them with the org's certificate
 * (Auth.JWS — the private key never leaves Salesforce), and exchanges the
 * signed JWT for a Bearer token (Auth.JWTBearerTokenExchange).
 *
 * Contrast with Modules 2–3: no Named Credential here — this class mints its
 * own token and sets the Authorization header itself, which is why the two
 * Google hosts need Remote Site Settings:
 *   https://oauth2.googleapis.com   and   https://www.googleapis.com
 *
 * Prerequisites (guide, Module 4 Project A):
 *   - Salesforce certificate 'GoogleSA' (Certificate and Key Management),
 *     its .crt uploaded to the Google service account as a key
 *   - Calendar API enabled on the Google Cloud project
 *   - The target calendar shared with the service account
 *     ("Make changes to events")
 */
public with sharing class GoogleCalendarService {

    // ── Paste yours — the only configuration this class needs: ──────────
    private static final String SERVICE_ACCOUNT_EMAIL =
        'sf-kickoff-scheduler@YOUR-PROJECT.iam.gserviceaccount.com';
    private static final String CALENDAR_ID = 'you@gmail.com';
    // ─────────────────────────────────────────────────────────────────────

    private static final String CERT_NAME  = 'GoogleSA';
    private static final String TOKEN_URL  = 'https://oauth2.googleapis.com/token';
    private static final String SCOPE      =
        'https://www.googleapis.com/auth/calendar.events';
    private static final String EVENTS_URL =
        'https://www.googleapis.com/calendar/v3/calendars/';

    public class GoogleCalendarException extends Exception {}

    // ─────────────────────────────────────────────── the flow itself
    /**
     * Steps 1–4 of the diagram in four statements: claims → signature →
     * exchange → Bearer token. Google's required claims: iss (service
     * account email), scope (space-delimited APIs), aud (the token URL);
     * exp/iat are handled by the platform (validity defaults are short —
     * exactly what this flow wants).
     */
    private static String getAccessToken() {
        Auth.JWT jwt = new Auth.JWT();
        jwt.setIss(SERVICE_ACCOUNT_EMAIL);
        jwt.setAud(TOKEN_URL);
        jwt.setAdditionalClaims(new Map<String, Object>{ 'scope' => SCOPE });
        Auth.JWS jws = new Auth.JWS(jwt, CERT_NAME);
        return new Auth.JWTBearerTokenExchange(TOKEN_URL, jws).getAccessToken();
    }

    // ─────────────────────────────────────────────── C — CREATE
    /** Creates an event; returns its id. Datetimes are treated as GMT. */
    public static String createEvent(String title, Datetime startAt, Datetime endAt) {
        Map<String, Object> body = new Map<String, Object>{
            'summary' => title,
            'start' => new Map<String, Object>{ 'dateTime' => rfc3339(startAt) },
            'end'   => new Map<String, Object>{ 'dateTime' => rfc3339(endAt) }
        };
        HttpResponse res = send('POST', eventsPath(null), JSON.serialize(body));
        Map<String, Object> ev =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (String) ev.get('id');
    }

    // ─────────────────────────────────────────────── R — READ
    public static Map<String, Object> getEvent(String eventId) {
        HttpResponse res = send('GET', eventsPath(eventId), null);
        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    }

    // ─────────────────────────────────────────────── U — UPDATE
    /** PATCH = partial update: only the fields you send change. */
    public static void updateEventTitle(String eventId, String newTitle) {
        send('PATCH', eventsPath(eventId),
            JSON.serialize(new Map<String, Object>{ 'summary' => newTitle }));
    }

    // ─────────────────────────────────────────────── D — DELETE
    /** Google answers 204 No Content; deleting twice answers 410 Gone. */
    public static void deleteEvent(String eventId) {
        send('DELETE', eventsPath(eventId), null);
    }

    // ─────────────────────────────────────────────── the business method
    /**
     * The Kickoff Scheduler: books a 30-minute kickoff one week after the
     * Opportunity's close date (10:00 GMT) and stores the event's link on
     * the record. Callouts first, DML last — the Module 2 rule.
     * Prerequisite field: Opportunity.Kickoff_Event_Link__c (URL).
     */
    public static String scheduleKickoff(Id opportunityId) {
        Opportunity o = [SELECT Id, Name, CloseDate
                         FROM Opportunity WHERE Id = :opportunityId];

        Datetime startAt = Datetime.newInstanceGmt(
            o.CloseDate.addDays(7), Time.newInstance(10, 0, 0, 0));

        String eventId = createEvent('Kickoff: ' + o.Name,
            startAt, startAt.addMinutes(30));                 // callout 1
        String link = (String) getEvent(eventId).get('htmlLink'); // callout 2

        o.Kickoff_Event_Link__c = link;                        // DML last
        update o;
        return link;
    }

    // ─────────────────────────────────────────────── plumbing

    /** Google wants RFC 3339, e.g. 2026-07-15T10:00:00Z. */
    private static String rfc3339(Datetime dt) {
        return dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    private static String eventsPath(String eventId) {
        String path = EVENTS_URL + EncodingUtil.urlEncode(CALENDAR_ID, 'UTF-8')
            + '/events';
        return eventId == null
            ? path
            : path + '/' + EncodingUtil.urlEncode(eventId, 'UTF-8');
    }

    /** Single door: mint token, build, send, fail loudly. */
    private static HttpResponse send(String method, String endpoint, String jsonBody) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Authorization', 'Bearer ' + getAccessToken());
        if (jsonBody != null) {
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
        }
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() >= 300) {
            throw new GoogleCalendarException(method + ' ' + endpoint
                + ' failed: ' + res.getStatusCode() + ' ' + res.getBody());
        }
        return res;
    }
}
