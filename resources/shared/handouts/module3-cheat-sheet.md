# Module 3 Cheat Sheet — Web Server Flow + PKCE

One page next to the keyboard. Print me.

## The flow in four lines

1. **Send the user to log in:** `GET <authorize endpoint>?response_type=code&client_id=…&redirect_uri=…&code_challenge=…` (+ scopes).
2. **User logs in & clicks Allow** → browser returns to the **callback URL** with `?code=…` (single-use, short-lived).
3. **Exchange the code:** `POST <token endpoint>` with `grant_type=authorization_code` + code + client_id + client_secret + redirect_uri + `code_verifier` → **access token + refresh token**.
4. **Renew silently:** `grant_type=refresh_token` + refresh_token (+ client credentials).

**PKCE in one line:** invent a random `code_verifier`, send its SHA-256 hash (`code_challenge`) at step 1, present the original at step 3 — a stolen code alone is worthless.

## Endpoints

| | Salesforce | Dropbox |
|---|---|---|
| Authorize | `<MyDomain>/services/oauth2/authorize` | `https://www.dropbox.com/oauth2/authorize?token_access_type=offline` ← offline = refresh token! |
| Token | `<MyDomain>/services/oauth2/token` | `https://api.dropboxapi.com/oauth2/token` |
| API hosts | `<MyDomain>` | `api.dropboxapi.com` (JSON) **and** `content.dropboxapi.com` (file bytes) |

## Inbound checklist (app → Salesforce as a person)

- [ ] Real callback URL on the ECA (exact match, character for character)
- [ ] Scopes: **api** + **refresh_token, offline_access**
- [ ] Require Secret for Web Server Flow ✅ · Require PKCE ✅ (defaults)
- [ ] Policies → Permitted Users: self-authorize (lab) / admin-pre-approved + permission set (production)

## Outbound checklist (Salesforce → Dropbox)

- [ ] Dropbox app: Scoped access, **App folder**, Permissions ticked (`account_info.read`, `files.metadata.read`, `files.content.read/write`, `sharing.write`)
- [ ] Proven in **Postman first** (consent → list → upload → share)
- [ ] **Auth Provider** (OIDC type): App key/secret, authorize URL **with `token_access_type=offline`**, token URL, scopes, **PKCE ✅** → copy generated callback into Dropbox Redirect URIs
- [ ] **External Credential**: OAuth 2.0 → **Browser Flow** → principal (Named or Per-User) → **Authenticate once** (browser consent; tokens stored encrypted)
- [ ] Permission set → External Credential Principal Access
- [ ] **TWO Named Credentials**, one External Credential: `Dropbox_API` (api host) + `Dropbox_Content` (content host), Generate Authorization Header ✅

## Upload pattern (content endpoints)

`POST callout:Dropbox_Content/2/files/upload` · header `Dropbox-API-Arg: {"path":"/x.txt","mode":"add","autorename":true}` (ASCII-safe!) · `Content-Type: application/octet-stream` · body = raw bytes. Callouts first, DML last.

## Error decoder (the famous five)

| Error | Fix |
|---|---|
| `redirect_uri_mismatch` / Invalid redirect_uri | Callback not on the app's allowlist — both Salesforce ECA and Dropbox app enforce this |
| Works today, 401 tomorrow | Missing `token_access_type=offline` → no refresh token → re-authenticate with the fixed URL |
| `missing_scope` | Permission added after consent — tick it, then re-Authenticate (scopes bake in at consent) |
| 400 on `/2/files/upload` | Wrong host (use content.) or params in body instead of `Dropbox-API-Arg` header |
| `shared_link_already_exists` (409) | Not a failure — fetch the existing link (`sharing/list_shared_links`) |

## Kill switches

Per user in Salesforce: user detail → OAuth Connected Apps → Revoke. On Dropbox: Settings → Connected apps → revoke, then re-Authenticate to restore. Rotation retires stolen refresh tokens automatically.
