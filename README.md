# Salesforce Integration Academy — OAuth Flows Curriculum

**[Open the live site →](https://shawon39.github.io/sf-academy/)**

Hands-on curriculum for a Salesforce admin learning integrations, verified against official Salesforce / Auth0 / Dropbox / Google documentation (July 2026). Free to use, fork, and adapt.

## Start here

Open **[index.html](index.html)** in a browser. It's a single self-contained app:

- **Collapsible sidebar** — one group per module; click a topic to show it in the main view; ☰ hides the sidebar; works offline (all diagrams are embedded SVG).
- **Module 1 · Foundation** — big picture, filterable jargon decoder (50+ terms), the three flows compared (interactive tabs), decision flowchart, External Client App deep-dive, patterns & ground rules, legacy flows.
- **Module 2 · Client Credentials** — the flow, inbound Salesforce setup, Postman verification, real-world use cases, and the **mini-project**: a "Portal User Provisioner" doing full CRUD from Apex against Auth0's free Management API, in three ~1-hour sessions (A: Auth0 + Postman CRUD → B: declarative Salesforce plumbing + Apex service → C: update/delete + trigger→Queueable automation).
- **Module 3 · Web Server + PKCE** — browser logins, authorization codes, PKCE, refresh tokens; inbound labs via Postman's OAuth helper, and the **mini-project**: a "Document Filer" (A: Dropbox app + Postman consent/list/upload/share → B: Auth Provider with PKCE + Browser-Flow External Credential + one-time Authenticate + TWO Named Credentials for Dropbox's two hosts → C: Apex uploads an account summary and writes the shared link back; automation is the do-it-yourself capstone).
- **Module 4 · JWT Bearer** — certificates instead of secrets: signed claims, pre-authorization, the sandbox-audience trap; inbound verification via `sf org login jwt`, and the **mini-project**: a "Kickoff Scheduler" doing full CRUD on **Google Calendar events** (A: Cloud project + service account + upload the *Salesforce* certificate to Google + share the calendar + Postman CRUD with an Apex-minted token → B: `GoogleCalendarService.cls` using `Auth.JWT`/`Auth.JWS`/`Auth.JWTBearerTokenExchange` → C: update/delete + book a kickoff event from an Opportunity with the link written back; Closed-Won automation is the do-it-yourself capstone).

## Folder map

```
sf-academy/
├── index.html                          ← THE APP (all modules, sidebar navigation)
├── README.md
├── resources/
│   ├── module-2-client-credentials/
│   │   ├── postman/Module2-Client-Credentials.postman_collection.json
│   │   │       (Inbound—Salesforce folder + Project—Auth0 CRUD folder, auto-saving tokens/ids)
│   │   ├── apex/Auth0UserService.cls            ← the CRUD service (no secrets, no token code)
│   │   ├── apex/Auth0ProvisioningQueueable.cls  ← async callout job ("threading")
│   │   ├── apex/ContactTrigger.trigger          ← enqueues the job when the checkbox is ticked
│   │   ├── apex/anonymous-scripts.apex          ← run-blocks for Sessions B and C
│   │   └── diagrams/salesforce-to-auth0-crud.(mmd|svg)
│   ├── module-3-web-server-pkce/
│   │   ├── postman/Module3-Web-Server-PKCE.postman_collection.json
│   │   │       (Inbound folder + Project—Dropbox folder; OAuth-helper setup in the description)
│   │   ├── apex/DropboxFileService.cls          ← list/upload/share + fileAccountSummary()
│   │   ├── apex/anonymous-scripts.apex          ← run-blocks for Sessions B and C
│   │   └── diagrams/salesforce-to-dropbox-browser-flow.(mmd|svg)
│   ├── module-4-jwt-bearer/
│   │   ├── postman/Module4-Google-Calendar-CRUD.postman_collection.json
│   │   │       (event CRUD + list; token minted via the Session A Apex block)
│   │   ├── apex/GoogleCalendarService.cls       ← JWT mint + full event CRUD + scheduleKickoff()
│   │   ├── apex/anonymous-scripts.apex          ← run-blocks for Sessions A, B and C
│   │   ├── scripts/jwt-inbound-commands.sh      ← openssl cert + sf org login jwt
│   │   └── diagrams/salesforce-to-google-calendar-jwt.(mmd|svg)
│   └── shared/
│       ├── diagrams/  (decision flowchart + client-credentials / web-server / jwt-bearer sequences — mmd + svg)
│       └── handouts/  (module2 / module3 / module4 cheat sheets)
├── LICENSE
└── .nojekyll                           ← tells GitHub Pages to serve the plain HTML as-is
```

## Instructor notes

- **Order matters:** Module 1 topics 1–7, then Module 2 topics 1–9. Every topic has Prev/Next buttons following that path.
- **Golden habit taught throughout:** verify every third-party API in Postman *before* configuring Salesforce.
- **Project prerequisites:** free Dev org, Postman, free Auth0 account (created live in Session A — the "register an app on a second platform" moment is the biggest aha).
- Custom fields needed: Module 2 Session C — `Provision_Portal_Access__c` (Checkbox), `Auth0_User_Id__c` (Text 100), `Provisioning_Status__c` (Text 255) on Contact; Module 3 Session C — `Dropbox_Link__c` (URL) on Account; Module 4 Session C — `Kickoff_Event_Link__c` (URL) on Opportunity.
- Module 3 project prerequisites: free Dropbox account; the app is created live in Session A (App-folder access = built-in least privilege).
- Module 4 project prerequisites: free Google account (Calendar API needs no billing); Salesforce CLI installed for the inbound labs; Remote Site Settings for `https://oauth2.googleapis.com` and `https://www.googleapis.com`. Caution: corporate Google orgs can block service-account key upload by policy — personal accounts are fine.
- UI labels drift between Salesforce releases — the guide teaches matching fields by role and links the official doc everywhere.

## License

MIT — see [LICENSE](LICENSE). Use it, fork it, adapt it for your own team.
