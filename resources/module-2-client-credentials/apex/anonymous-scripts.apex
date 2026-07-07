// ═══════════════════════════════════════════════════════════════════
// Module 2 mini-project — Anonymous Apex scripts, one block per session.
// Run each block separately: Developer Console > Debug >
// Open Execute Anonymous Window (tick "Open Log").
// ═══════════════════════════════════════════════════════════════════


// ─── SESSION B — CREATE, then READ it back ──────────────────────────
// Watch Auth0 Dashboard > User Management > Users while this runs.

String userId = Auth0UserService.createUser(
    'jamal.apex@example.com', 'TrainingP@ssw0rd2026!');
System.debug('Created Auth0 user: ' + userId);
// ^ Copy this id — Session C's first block needs it.

Map<String, Object> u = Auth0UserService.getUser(userId);
System.debug('Read back → email: ' + u.get('email')
    + ', created: ' + u.get('created_at'));


// ─── SESSION C, block 1 — UPDATE, verify, DELETE ────────────────────
// Paste the id from Session B before running.
/*
String userId = 'auth0|PASTE_THE_ID_FROM_SESSION_B';

Auth0UserService.updateUserPlan(userId, 'gold');
Map<String, Object> u = Auth0UserService.getUser(userId);
System.debug('Metadata now: ' + u.get('user_metadata'));   // {plan=gold}

Auth0UserService.deleteUser(userId);
System.debug('Deleted.');

// Optional: run getUser once more on purpose and READ the exception —
// that 404 message is what "gone" looks like from code.
*/


// ─── SESSION C, block 2 — smoke-test the Queueable without the UI ──
// (After creating the three Contact fields and saving the Queueable + trigger.)
/*
Contact c = [SELECT Id FROM Contact WHERE Email != null LIMIT 1];
System.enqueueJob(new Auth0ProvisioningQueueable(new List<Id>{ c.Id }));
System.debug('Job enqueued for ' + c.Id
    + ' — check Setup > Apex Jobs, then refresh the Contact.');
*/
