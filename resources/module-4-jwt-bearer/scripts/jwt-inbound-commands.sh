#!/bin/bash
# Module 4 — inbound JWT bearer flow lab commands (guide topics 2–3).
# Run ONE AT A TIME and read what each does.
# macOS/Linux have openssl built in; Windows: use Git Bash.

# ─────────────────────────────────────────────────────────────
# STEP 1 — Generate the certificate pair
# ─────────────────────────────────────────────────────────────

mkdir -p ~/jwt-lab && cd ~/jwt-lab

# 1a. PRIVATE key — the signet ring. Never leaves this machine.
openssl genrsa -out server.key 2048

# 1b. Certificate request (Enter through the questions for a lab).
openssl req -new -key server.key -out server.csr

# 1c. Self-sign into an X.509 certificate valid 365 days.
#     server.crt is the ONLY file you upload to the External Client App.
openssl x509 -req -sha256 -days 365 -in server.csr -signkey server.key -out server.crt

# Sanity check:
openssl x509 -in server.crt -noout -subject -dates

# ─────────────────────────────────────────────────────────────
# STEP 2 — Salesforce Setup (guide topic 2)
#   * ECA > OAuth Settings: Enable JWT Bearer Flow + upload server.crt (≤4 KB)
#   * Scopes: api + refresh_token/offline_access
#   * Policies: Permitted Users = "Admin approved users are pre-authorized"
#     + grant the sub user access via permission set / profile
#   * Copy the Consumer Key (the secret is never used by this flow)
# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# STEP 3 — Log in with a signature (guide topic 3)
#   Flags map to claims: --client-id → iss, --username → sub,
#   --instance-url steers aud (sandboxes need their own URL!).
# ─────────────────────────────────────────────────────────────

sf org login jwt \
  --client-id  PASTE_CONSUMER_KEY_HERE \
  --jwt-key-file server.key \
  --username   postman.integration@yourorg.demo \
  --instance-url https://YOURCOMPANY.my.salesforce.com \
  --alias jwt-demo

sf org display --target-org jwt-demo
sf data query --query "SELECT Id, Name FROM Account LIMIT 5" --target-org jwt-demo

# Repeat at will — that's the point of the flow:
# sf org logout --target-org jwt-demo
