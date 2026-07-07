// ═══════════════════════════════════════════════════════════════════
// Module 4 mini-project — Anonymous Apex scripts, one block per session.
// Developer Console > Debug > Open Execute Anonymous Window ("Open Log").
// Prereqs: certificate 'GoogleSA' created + its .crt uploaded to the
// Google service account; calendar shared with the SA; Remote Site
// Settings for https://oauth2.googleapis.com and https://www.googleapis.com;
// GoogleCalendarService.cls saved with YOUR two constants pasted in.
// ═══════════════════════════════════════════════════════════════════


// ─── SESSION A — mint a token for Postman (the 6-line flow) ─────────
// Copy the debugged TOKEN into Postman's google_access_token variable.
// It lives ~1 hour; mint again when it dies — that IS the flow.

Auth.JWT jwt = new Auth.JWT();
jwt.setIss('sf-kickoff-scheduler@YOUR-PROJECT.iam.gserviceaccount.com');
jwt.setAud('https://oauth2.googleapis.com/token');
jwt.setAdditionalClaims(new Map<String, Object>{
    'scope' => 'https://www.googleapis.com/auth/calendar.events' });
Auth.JWS jws = new Auth.JWS(jwt, 'GoogleSA');
System.debug('TOKEN: ' + new Auth.JWTBearerTokenExchange(
    'https://oauth2.googleapis.com/token', jws).getAccessToken());


// ─── SESSION B — CREATE tomorrow 10:00–10:30 GMT, then READ ────────
// Watch calendar.google.com while this runs.
/*
Datetime startAt = Datetime.newInstanceGmt(
    Date.today().addDays(1), Time.newInstance(10, 0, 0, 0));

String eventId = GoogleCalendarService.createEvent(
    'Kickoff — created from Apex', startAt, startAt.addMinutes(30));
System.debug('Created event: ' + eventId);   // ← copy for Session C

Map<String, Object> ev = GoogleCalendarService.getEvent(eventId);
System.debug('Read back → ' + ev.get('summary'));
System.debug('Open it:   ' + ev.get('htmlLink'));
*/


// ─── SESSION C, block 1 — UPDATE, verify, DELETE ────────────────────
/*
String eventId = 'PASTE_THE_ID_FROM_SESSION_B';

GoogleCalendarService.updateEventTitle(eventId, 'Kickoff — RESCHEDULED by Apex');
System.debug('Now: ' + GoogleCalendarService.getEvent(eventId).get('summary'));

GoogleCalendarService.deleteEvent(eventId);
System.debug('Deleted. Delete again on purpose → read the 410 Gone.');
*/


// ─── SESSION C, block 2 — the Kickoff Scheduler, end to end ─────────
// Prereq: URL field Kickoff_Event_Link__c on Opportunity.
/*
Opportunity o = [SELECT Id, Name FROM Opportunity LIMIT 1];
String link = GoogleCalendarService.scheduleKickoff(o.Id);
System.debug('Booked! ' + link);
// Open the Opportunity → click Kickoff Event Link.
*/


// ─── SESSION C, step C4 (capstone) — automation skeleton ────────────
// Third rep of the pattern — build it yourself:
//   1. OpportunityTrigger (after update): StageName just became
//      'Closed Won' && Kickoff_Event_Link__c == null → collect ids
//   2. KickoffSchedulerQueueable implements Queueable,
//      Database.AllowsCallouts — loops ids, calls scheduleKickoff(),
//      try/catch writing failures to a status field.
// References: Module 2 Session C (full walkthrough) + your Module 3 capstone.
