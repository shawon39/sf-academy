# Module 5 Cheat Sheet — Flow Integrations

One page next to the keyboard. Print me.

## The menu (pick by direction + urgency)

| Need | Method |
|---|---|
| Flow calls out, **needs the answer** | **HTTP Callout** (point-and-click) — or Invocable Apex when it gets gnarly |
| Flow calls out, **fire-and-forget** | Platform Event (publish via Create Records) or Outbound Message (legacy SOAP, auto record ID + retries) |
| **Outside system starts the flow** | REST Actions API — or a Platform Event–Triggered Flow |
| Vendor hands you an **OpenAPI spec** | External Services (register once → actions appear) |

## HTTP Callout recipe (outbound)

1. Named Credential first (no-auth APIs: External Credential **Custom** protocol, empty principal, principal access via permission set; Named Credential URL only, *Generate Authorization Header* unchecked).
2. Flow → **Action → Create HTTP Callout** → name the external service, pick the credential.
3. Method + URL path (no `?`) + query parameter keys declared separately.
4. **Paste a REAL sample response from Postman** → Flow generates typed variables. Clean JSON keys only — keys with spaces break the structure.
5. Outputs live under the **2XX** resource: drill `2XX → rates → EUR`.
6. POST/PUT/PATCH: also paste a sample **request** body → assign the generated body variable with an Assignment element.
7. **Always wire the Fault connector** to a status field / screen (`{!$Flow.FaultMessage}`).

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
| Sample JSON rejected / fields missing | Keys with spaces, or a hand-typed sketch — paste a real full Postman response |
| Value empty at runtime (`rates.X`) | Runtime key ≠ sampled key (dynamic keys) — one action per key, or Apex |
| Inbound 404 | Wrong flow API name (underscored!) or flow not Active |

## When Flow is the wrong tool

High volume, guaranteed delivery, complex retries, heavy payload transforms → Invocable Apex, Platform Events + external subscriber, or middleware. "Can Flow do it?" ≠ "Should it?"
