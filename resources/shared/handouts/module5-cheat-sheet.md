# Module 5 Cheat Sheet — Flow Integrations

One page next to the keyboard. Print me.

## The menu (pick by direction + urgency)

| Need | Method |
|---|---|
| Flow calls out, **needs the answer** | **HTTP Callout** (point-and-click) — or Invocable Apex when it gets gnarly |
| Flow calls out, **fire-and-forget** | Platform Event (publish via Create Records) or Outbound Message (legacy SOAP, auto record ID + retries) |
| **Outside system starts the flow** | REST Actions API — or a Platform Event–Triggered Flow |
| Vendor hands you an **OpenAPI spec** | External Services (register once → actions appear) |

## HTTP Callout recipe (outbound, real OAuth — the Travel Desk pattern)

1. **Credential chain first** (Module 2's pattern): External Credential `OAuth 2.0` → `Client Credentials with Client Secret` → Identity Provider URL = the token endpoint (Amadeus: `https://test.api.amadeus.com/v1/security/oauth2/token`; creds in request body ON) → Principal with API Key/Secret → permission-set principal access → Named Credential (base URL, Generate Authorization Header ✅). The engine caches ~30-min tokens and renews them — the flow never sees one.
   *No-auth public APIs (e.g. Frankfurter): External Credential **Custom** protocol, empty principal — still gates who may call out.*
2. Flow → **Action → Create HTTP Callout** → name the external service, pick the credential.
3. Method + URL path (no `?`) + query parameter keys declared separately (`keyword`, `max`).
4. **Paste a REAL sample response from Postman** → Flow generates typed variables (collections for arrays, numbers for numerics). Clean JSON keys only — spaces or *dynamic* keys (Amadeus's `include=AIRPORTS` airports-keyed-by-code) break the structure.
5. **Parse arrays with a Loop + Assignment** — in Flow, that pair IS the JSON parser (`data[]` → CityName, iataCode, geoCode.latitude…). Outputs live under the **2XX** resource.
6. POST/PUT/PATCH: also paste a sample **request** body → assign the generated body variable with an Assignment element.
7. **Always wire the Fault connector** (from the action AND from Update Records) to a status field / screen (`{!$Flow.FaultMessage}`).
8. Write back with Update Records; put the flow where people work (record page + `recordId` input variable).

## The async rule (record-triggered flows)

Callouts can't share the record-save transaction — build callout steps on the **Run Asynchronously** path. Same physics as Module 2's trigger→Queueable rule, zero code.

## Inbound recipe (your flow as an API)

- Flow must be **Autolaunched**, **Active**, variables checked **Available for input / output** (that checkbox = the API contract).
- `POST <MyDomain>/services/data/vXX.0/actions/custom/flow/Flow_API_Name`
- Body: `{ "inputs": [ { "VarName": "value" } ] }` — multiple objects = multiple runs.
- Response: `[ { "isSuccess": true, "outputValues": { … } } ]`
- Caller = the token's user (Module 2's integration user) → its permission set gates what the flow may touch.

## Error decoder (the famous five)

| Error | Fix |
|---|---|
| Callout won't run in record-triggered flow | It's not on the Run Asynchronously path |
| Credential missing from the picklist | External Credential Principal Access not assigned (or not Enabled for Callouts) |
| `invalid_client` from the token endpoint | Re-copy Key/Secret on the principal; "pass client credentials in request body" ON for Amadeus |
| Sampled value empty at runtime | Dynamic keys (e.g. `include=AIRPORTS`) or a hand-typed sample — paste a real full Postman response |
| Inbound 404 | Wrong flow API name (underscored!) or flow not Active |

## When Flow is the wrong tool

High volume, guaranteed delivery, complex retries, heavy payload transforms → Invocable Apex, Platform Events + external subscriber, or middleware. "Can Flow do it?" ≠ "Should it?"
