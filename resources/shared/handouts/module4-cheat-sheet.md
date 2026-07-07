# Module 4 Cheat Sheet — JWT Bearer Flow

One page next to the keyboard. Print me.

## The flow in three lines

1. **Write the claims:** `iss` (app / service account) · `sub` (Salesforce inbound) or `scope` (Google) · `aud` (the token server) · short `exp`.
2. **Sign** with the private key (RSA SHA-256) → the JWT.
3. **Exchange:** `POST <token endpoint>` with `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer` + `assertion=<JWT>` → access token.

**No refresh token** — sign a fresh JWT. **No secret on the wire** — only a signature. **No consent screen** — pre-authorization (Salesforce) / resource sharing (Google) replaces it.

## Inbound checklist (→ Salesforce)

- [ ] `openssl genrsa` → `req -new` → `x509 -req -sha256 -days 365` (key + .crt)
- [ ] ECA: **Enable JWT Bearer Flow** + upload **server.crt** (≤4 KB, never the .key)
- [ ] Permitted Users = **Admin approved users are pre-authorized** + permission set for the `sub` user
- [ ] `sf org login jwt --client-id … --jwt-key-file server.key --username … --instance-url …`
- [ ] Sandboxes: `aud` = test.salesforce.com → pass the sandbox `--instance-url`

## Outbound checklist (Salesforce → Google Calendar)

- [ ] Salesforce cert **GoogleSA** (Certificate and Key Management) → download .crt
- [ ] Google Cloud project (free) + **Calendar API enabled** + service account
- [ ] **Upload the Salesforce .crt** to the SA (IAM → Keys → Upload; RSA-in-X.509 is exactly what Google requires)
- [ ] **Share the calendar** with the SA email — "Make changes to events" (this IS the consent)
- [ ] Remote Site Settings: `https://oauth2.googleapis.com` + `https://www.googleapis.com`
- [ ] Apex: `Auth.JWT` (iss/aud/scope claim) → `Auth.JWS(jwt,'GoogleSA')` → `Auth.JWTBearerTokenExchange(tokenUrl, jws).getAccessToken()`

## Calendar CRUD verb map (base: `/calendar/v3/calendars/{calendarId}/events`)

| Verb | HTTP | Path | Success |
|---|---|---|---|
| Create | POST | `/events` | 200 + id, htmlLink |
| Read | GET | `/events/{eventId}` | 200 |
| Update | PATCH (partial) | `/events/{eventId}` | 200 |
| Delete | DELETE | `/events/{eventId}` | 204 (410 Gone if repeated) |

Datetimes: RFC 3339 — `2026-07-15T10:00:00Z`. Scope: `https://www.googleapis.com/auth/calendar.events`.

## Error decoder (the famous five)

| Error | Fix |
|---|---|
| `user hasn't approved this consumer` | Pre-authorize the `sub` user (Permitted Users + permission set) |
| `audience is invalid` | `aud` mismatch — sandbox vs production, or not exactly Google's token URL |
| Plain `invalid_grant` | Key ↔ certificate mismatch, or clock drift past the skew window |
| `404` on a calendar you can see | The *service account* can't — share it ("Make changes to events") / fix calendar_id |
| `Unauthorized endpoint` (Apex) | Missing Remote Site Settings for the two Google hosts |

## Security rules

1. The private key never travels — Salesforce signs internally; Google holds only the certificate.
2. One certificate per integration; calendar the expiry date (ours: 365 days).
3. Rotation drill: new SF cert → upload to SA → switch CERT_NAME → delete old key. Zero downtime.
