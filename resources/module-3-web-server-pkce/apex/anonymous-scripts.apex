// ═══════════════════════════════════════════════════════════════════
// Module 3 mini-project — Anonymous Apex scripts, one block per session.
// Developer Console > Debug > Open Execute Anonymous Window ("Open Log").
// Prereqs: Auth Provider + External Credential (Browser Flow, principal
// AUTHENTICATED) + Named Credentials Dropbox_API and Dropbox_Content,
// and DropboxFileService.cls saved.
// ═══════════════════════════════════════════════════════════════════


// ─── SESSION B — who's connected, what's in the app folder ──────────

System.debug('Connected as: ' + DropboxFileService.whoAmI());
for (String name : DropboxFileService.listRootFolder()) {
    System.debug('Found file: ' + name);   // hello-from-postman.txt from Session A!
}


// ─── SESSION C — the Document Filer, end to end ─────────────────────
// Prereq: URL field Dropbox_Link__c on Account.
/*
Account a = [SELECT Id, Name FROM Account LIMIT 1];
String link = DropboxFileService.fileAccountSummary(a.Id);
System.debug('Filed! Shareable link: ' + link);
// Now open the Account and click the Dropbox Link field.
*/


// ─── SESSION C, step C4 (homework) — automation skeleton ────────────
// Port Module 2's pattern yourself. The pieces to build:
//   1. Checkbox on Account:  Export_To_Dropbox__c
//   2. Queueable 'DropboxFilingQueueable' implements Queueable,
//      Database.AllowsCallouts — loops ids, calls fileAccountSummary(),
//      try/catch writing failures to a status field.
//   3. AccountTrigger (after update): checkbox just ticked &&
//      Dropbox_Link__c == null  → System.enqueueJob(...)
// Reference implementation of the same pattern: Module 2, Session C
// (Auth0ProvisioningQueueable + ContactTrigger).
