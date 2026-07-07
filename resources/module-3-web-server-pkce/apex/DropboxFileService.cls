/**
 * DropboxFileService — Module 3 mini-project ("Document Filer").
 *
 * Talks to Dropbox through TWO Named Credentials backed by ONE External
 * Credential (Browser Flow, authenticated once via the principal's
 * Authenticate action):
 *   - Dropbox_API      → https://api.dropboxapi.com      (JSON endpoints)
 *   - Dropbox_Content  → https://content.dropboxapi.com  (file bytes)
 *
 * No tokens, no secrets, no refresh logic in this class — the Named
 * Credential engine refreshes silently with the stored refresh token
 * (which exists because the authorize URL carried token_access_type=offline).
 */
public with sharing class DropboxFileService {

    public class DropboxException extends Exception {}

    // ─────────────────────────────────────────────── identity & listing

    /** Display name of the Dropbox account Salesforce is connected as. */
    public static String whoAmI() {
        HttpResponse res = send('POST', 'callout:Dropbox_API/2/users/get_current_account',
            null, null);
        Map<String, Object> acct =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> name = (Map<String, Object>) acct.get('name');
        return name.get('display_name') + ' (' + acct.get('email') + ')';
    }

    /** File/folder names in the app folder's root ("" = app folder root). */
    public static List<String> listRootFolder() {
        HttpResponse res = send('POST', 'callout:Dropbox_API/2/files/list_folder',
            JSON.serialize(new Map<String, Object>{ 'path' => '' }), 'application/json');
        List<String> names = new List<String>();
        Map<String, Object> body =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        for (Object o : (List<Object>) body.get('entries')) {
            names.add((String) ((Map<String, Object>) o).get('name'));
        }
        return names;
    }

    // ─────────────────────────────────────────────── upload & share

    /**
     * Uploads plain text as a file. Returns the path Dropbox stored it under.
     * Content endpoints put parameters in the Dropbox-API-Arg HEADER because
     * the body carries the raw file bytes.
     */
    public static String uploadTextFile(String path, String content) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Dropbox_Content/2/files/upload');   // content host!
        req.setMethod('POST');
        req.setHeader('Dropbox-API-Arg', JSON.serialize(new Map<String, Object>{
            'path' => path, 'mode' => 'add', 'autorename' => true }));
        req.setHeader('Content-Type', 'application/octet-stream');
        req.setBody(content);
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() >= 300) {
            throw new DropboxException('Upload failed: '
                + res.getStatusCode() + ' ' + res.getBody());
        }
        Map<String, Object> meta =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (String) meta.get('path_display');
    }

    /**
     * Creates (or fetches) a shareable link for a path.
     * Dropbox links are create-once: a second call answers 409
     * shared_link_already_exists — we treat that as success and look it up.
     */
    public static String createSharedLink(String path) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Dropbox_API/2/sharing/create_shared_link_with_settings');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{ 'path' => path }));
        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() == 409
                && res.getBody().contains('shared_link_already_exists')) {
            return getExistingSharedLink(path);
        }
        if (res.getStatusCode() >= 300) {
            throw new DropboxException('Share failed: '
                + res.getStatusCode() + ' ' + res.getBody());
        }
        Map<String, Object> link =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (String) link.get('url');
    }

    // ─────────────────────────────────────────────── the end-to-end story

    /**
     * The Document Filer: builds a text summary of an Account, uploads it,
     * creates a shared link, and saves the link on the record.
     * Note the order: ALL callouts first, DML last — reversed, you'd meet
     * System.CalloutException: uncommitted work pending.
     */
    public static String fileAccountSummary(Id accountId) {
        Account a = [SELECT Id, Name, Industry, Phone, Website, Description
                     FROM Account WHERE Id = :accountId];

        String content =
              'ACCOUNT SUMMARY — generated from Salesforce\n'
            + '===========================================\n'
            + 'Name:     ' + a.Name + '\n'
            + 'Industry: ' + blankIfNull(a.Industry) + '\n'
            + 'Phone:    ' + blankIfNull(a.Phone) + '\n'
            + 'Website:  ' + blankIfNull(a.Website) + '\n'
            + 'Notes:    ' + blankIfNull(a.Description) + '\n'
            + 'Exported: ' + System.now().format('yyyy-MM-dd HH:mm') + '\n';

        String path   = '/' + safeFileName(a.Name) + '-summary.txt';
        String stored = uploadTextFile(path, content);   // callout 1
        String url    = createSharedLink(stored);        // callout 2

        a.Dropbox_Link__c = url;                         // DML last
        update a;
        return url;
    }

    // ─────────────────────────────────────────────── plumbing

    /** Dropbox-API-Arg must be ASCII-safe → keep file names plain. */
    private static String safeFileName(String raw) {
        String cleaned = raw.replaceAll('[^a-zA-Z0-9 _-]', '').trim()
                            .replaceAll('\\s+', '-');
        return String.isBlank(cleaned) ? 'account' : cleaned;
    }

    private static String blankIfNull(String s) { return s == null ? '—' : s; }

    private static String getExistingSharedLink(String path) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Dropbox_API/2/sharing/list_shared_links');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{
            'path' => path, 'direct_only' => true }));
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() >= 300) {
            throw new DropboxException('Link lookup failed: '
                + res.getStatusCode() + ' ' + res.getBody());
        }
        Map<String, Object> body =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> links = (List<Object>) body.get('links');
        if (links.isEmpty()) {
            throw new DropboxException('No shared link found for ' + path);
        }
        return (String) ((Map<String, Object>) links[0]).get('url');
    }

    /** Single door for the simple JSON requests: build, send, fail loudly. */
    private static HttpResponse send(String method, String endpoint,
                                     String jsonBody, String contentType) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        if (jsonBody != null) {
            req.setHeader('Content-Type', contentType);
            req.setBody(jsonBody);
        }
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() >= 300) {
            throw new DropboxException(method + ' ' + endpoint + ' failed: '
                + res.getStatusCode() + ' ' + res.getBody());
        }
        return res;
    }
}
