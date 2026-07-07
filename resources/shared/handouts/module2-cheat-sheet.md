# Module 2 Cheat Sheet — Client Credentials Flow

One page next to the keyboard. Print me.

## The flow in two lines (any platform)

1. **Get a key:** `POST <token endpoint>` with `grant_type=client_credentials` + `client_id` + `client_secret` (+ `audience` for Auth0) → `access_token`.
2. **Use the key:** header `Authorization: Bearer <access_token>` on every call.

No refresh token — re-request when it expires. Salesforce token endpoint = **My Domain** only (`https://<MyDomain>/services/oauth2/token`); Auth0 = `https://<tenant>/oauth/token`.

## Inbound checklist (external system → Salesforce)

- [ ] Dedicated **integration user** (minimal profile, API Enabled, API Only in EE)
- [ ] **External Client App**: scope *api*, **Enable Client Credentials Flow** (Settings)
- [ ] **Policies tab**: enable the flow again + **Run As** = integration user (both levels must agree)
- [ ] Consumer **Key + Secret** collected; waited 2–10 min for propagation

## Outbound checklist (Salesforce → Auth0)

- [ ] Auth0 **M2M app** authorized for the Management API, scopes `create/read/update/delete:users`
- [ ] All four verbs proven **in Postman first**
- [ ] **External Auth Identity Provider**: token endpoint + Custom Request Parameter `audience` = `https://<tenant>/api/v2/` (Body Parameter, trailing slash!)
- [ ] **External Credential** (Client Credentials with Client Secret) + **Principal** holding ID/Secret (encrypted)
- [ ] Permission set → **External Credential Principal Access** → assigned to whoever runs the code
- [ ] **Named Credential** `Auth0_Mgmt_API`: URL `https://<tenant>`, Generate Authorization Header ✅
- [ ] Apex uses `callout:Auth0_Mgmt_API/api/v2/users` — zero secrets, zero token code

## The automation pattern ("threading")

**Trigger** (decides WHEN, no callouts allowed) → `System.enqueueJob(...)` → **Queueable** with `Database.AllowsCallouts` (does the callout) → writes id/status back to the record. Monitor at Setup → Apex Jobs.

## CRUD verb map

| Verb | HTTP | Auth0 endpoint | Success code |
|---|---|---|---|
| Create | POST | `/api/v2/users` | 201 |
| Read | GET | `/api/v2/users/{id}` | 200 |
| Update | PATCH | `/api/v2/users/{id}` | 200 |
| Delete | DELETE | `/api/v2/users/{id}` | 204 (empty body) |

## Error decoder (the famous five)

| Error | Fix |
|---|---|
| `invalid_client_id` right after setup | Propagation — wait 2–10 min |
| `invalid_grant` / no CC user enabled (SF) | Enable flow in Settings **and** Policies + set Run As |
| Token OK but Mgmt API 401 (Auth0) | `audience` missing/wrong — trailing slash matters |
| `403 Insufficient scope` (Auth0) | Grant the verb's scope on the M2M app |
| "couldn't access the credential(s)" (Apex) | Missing External Credential Principal Access on your permission set |

## Security rules

1. ID + Secret = the app. Store only in encrypted stores; rotate on any suspected leak.
2. Least privilege: minimal scopes, minimal Run As permissions, one app per integration.
3. Errors land on records/logs where admins see them — never invisible 2 AM failures.
