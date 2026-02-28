# Backend — Walkers, Firebase & AI Agents

## Overview

The backend is a **Jaclang** application running inside a Docker container. It exposes HTTP endpoints via the **walker** pattern — each walker is a class that becomes a `POST /walker/{name}` endpoint. All persistent data lives in **Google Cloud Firestore**, accessed through the Firebase Admin SDK. AI-powered features use **Google Gemini 2.0 Flash** via Vertex AI.

---

## Directory Structure

```
Back/
├── main.jac                # Walker definitions (API endpoints)
├── firebase_app.py         # Firebase Admin SDK initialisation & helpers
├── llm_agent.py            # Gemini LLM client & prompt engineering
├── jac.toml                # Project config & Python dependencies
├── Dockerfile              # Container build definition
├── docker-compose.yml      # Service orchestration with secrets
└── seed_firestore.py       # Database seeding script (development)
```

---

## Module Responsibilities

### `main.jac` — API Endpoints

Defines all walker endpoints. Each walker is a class with typed `has` fields (request parameters) and a `can fetch/create with entry` method (handler).

```
Walker Endpoint Map:
│
├── Health
│   ├── health              → GET system status
│   └── init_firebase       → Trigger Firebase initialisation
│
├── Personnel CRUD
│   ├── list_personnel      → List all team members
│   ├── create_personnel    → Add new team member
│   ├── update_personnel    → Edit team member
│   └── delete_personnel    → Remove team member
│
├── Roles
│   └── list_roles          → List/initialise roles
│
├── Cases
│   ├── list_cases          → List all misinformation cases
│   └── update_case         → Update case outcome
│
├── Actors
│   └── list_actors         → List all bad actor profiles
│
├── Policies CRUD
│   ├── list_policies       → List all enforcement policies
│   ├── create_policy       → Create new policy
│   ├── update_policy       → Edit existing policy
│   └── delete_policy       → Delete policy
│
├── Analytics
│   └── get_analytics       → Fetch chart data + theme slices
│
├── Actor Trends
│   └── get_actor_trends    → Fetch per-actor trend intelligence
│
├── AI Agents
│   ├── triage_case         → AI-recommended action for a case
│   ├── summarize_actor     → AI-generated intelligence brief for an actor
│   └── assess_actor        → AI-recommended enforcement action for an actor
│
└── Generic Firestore
    ├── firestore_get       → Read any document by collection/id
    └── firestore_set       → Write any document by collection/id
```

### `firebase_app.py` — Firebase Initialisation

Manages the Firebase Admin SDK lifecycle:

```
_get_credentials_path()     → Resolves FIREBASE_CREDENTIALS_PATH or
                               GOOGLE_APPLICATION_CREDENTIALS env var

init_firebase()             → Initialises Firebase app with service account
                               certificate (idempotent — safe to call repeatedly)

get_firestore()             → Returns Firestore client instance
get_auth()                  → Returns Firebase Auth client
server_timestamp()          → Returns Firestore SERVER_TIMESTAMP sentinel
```

### `llm_agent.py` — AI Agent Logic

Encapsulates all LLM interaction, separated from the Jaclang walkers for maintainability:

```
_get_client()               → Initialises google-genai client with Vertex AI
                               credentials (singleton pattern)

_call_gemini(system, msg)   → Makes API call to Gemini 2.0 Flash
                               (temperature: 0.3, max tokens: 2048)

_parse_json_response(text)  → Robustly parses JSON from LLM output
                               (handles markdown fences)

triage_case(case, actor,    → Constructs detailed prompt with case metrics,
  policies) → dict            actor profile, and policies; returns
                               {action, rationale, confidence}

summarize_actor(actor,      → Constructs prompt with actor data, trends,
  trends, cases) → dict       insights, and cases; returns
                               {brief, key_findings}
```

---

## AI Agent Detail

### Case Triage Agent

**Purpose**: Recommend an enforcement action for misinformation cases flagged as "Needs Review".

**Input Data Assembled by Walker**:
1. Case record from `cases` collection (title, metrics, engagement, media type)
2. Actor profile from `actors` collection (handle, type, risk score)
3. All policies from `policies` collection (name, description, restriction, rank)

**Prompt Design**:
- System prompt instructs the model to act as a senior Trust & Safety analyst
- Requires structured JSON output: `{action, rationale, confidence}`
- Rationale must explain **why** the content is problematic, reference real-world harm, and cite established disinformation research from verifiable institutions (Pew Research Center, Stanford Internet Observatory, Reuters Institute, Oxford Internet Institute, etc.)
- If recommending a policy, must justify why that specific policy matches the case characteristics

**Output**:
```json
{
  "action": "Policy: Deepfake Takedown",
  "rationale": "The case exhibits a factuality score of 78/100, indicating significant fabrication. According to research from the Stanford Internet Observatory, synthetic media impersonating public figures has a 3.2x higher engagement rate than organic content, amplifying real-world harm. The actor @TruthLegion_Intel (risk: 92/100) has a documented pattern of deploying AI-generated content across 240+ coordinated accounts. The Deepfake Takedown policy directly addresses AI-generated synthetic media and mandates immediate removal, which is the appropriate enforcement mechanism given the content's verified synthetic origin and the actor's high-risk classification.",
  "confidence": 87
}
```

### Actor Intelligence Summary Agent

**Purpose**: Generate a comprehensive intelligence brief for bad actor profiles.

**Input Data Assembled by Walker**:
1. Actor profile from `actors` collection
2. Trend data from `actor_trends` collection (threat level, audience growth, monthly metrics, insights)
3. All associated cases from `cases` collection (matched by actor handle)

**Prompt Design**:
- System prompt instructs the model to act as a senior intelligence analyst
- Requires structured JSON output: `{brief, key_findings}`
- Brief must reference specific data points and contextualise threats using research from institutions such as the Atlantic Council's DFRLab, Oxford Internet Institute, or EU DisinfoLab
- Must identify disinformation tactics using established frameworks (AMITT, ABC)
- Key findings must be actionable and reference specific data patterns

**Output**:
```json
{
  "brief": "Actor @TruthLegion_Intel represents a HIGH-threat state-linked disinformation operation with a risk score of 92/100 and 42% year-over-year audience growth. The operation has produced 2,500 posts in the most recent reporting period with a reach exceeding 1.68 million...",
  "key_findings": [
    "The actor's coordinated amplification network of 240+ accounts mirrors patterns documented by the Atlantic Council's DFRLab in their analysis of state-sponsored IO campaigns...",
    "Audience growth of 42% YoY with 68% bot-like followers suggests artificial inflation consistent with findings from the Oxford Internet Institute's Computational Propaganda Project...",
    "Recommend cross-platform referral to the Global Internet Forum to Counter Terrorism (GIFCT) shared hash database given the actor's multi-platform operational footprint...",
    "Implement velocity-based detection triggers: the actor's 90-second posting synchronisation window is a high-fidelity behavioural indicator for automated network disruption..."
  ]
}
```

### Actor Enforcement Assessment Agent

**Purpose**: Recommend the most proportional enforcement action for a bad actor based on their full threat profile, with a graduated response philosophy ranging from educational interventions to permanent bans.

**Input Data Assembled by Walker**:
1. Actor profile from `actors` collection
2. Trend data from `actor_trends` collection
3. All associated cases from `cases` collection
4. All available enforcement policies from `policies` collection

**Prompt Design**:
- System prompt instructs the model to act as a senior enforcement specialist
- Follows a **graduated escalation philosophy** with four tiers:
  1. **Educational** (risk ≤ 25): Content advisories, fact-check labels, guidelines reminders
  2. **Restrictions** (risk 25-50): De-amplification, monetisation removal, sharing limits
  3. **Temporary Suspensions** (risk 50-75): 7-day or 30-day bans for ToS violations
  4. **Permanent Actions** (risk ≥ 75): Bans for coordinated influence operations or psy-ops
- Each tier references specific research from institutions (Pew Research, Stanford Internet Observatory, Oxford Internet Institute, MIT Media Lab, Atlantic Council DFRLab, EU DisinfoLab)
- Requires structured JSON output: `{recommended_action, rationale, escalation_path, confidence}`

**Output**:
```json
{
  "recommended_action": "Restrict: Reduce Reach",
  "rationale": "The actor @ClimateTruth_99 is classified as an ideological amplifier with a moderate risk score of 38/100. Their 12 associated cases show a pattern of sharing misleading environmental claims, though case outcomes indicate this appears to be unwitting amplification rather than coordinated disinformation...",
  "escalation_path": [
    "If content violations continue after reach reduction: Disable monetisation to remove financial incentive",
    "If 3+ additional confirmed cases within 30 days: Issue 7-day temporary suspension with clear reinstatement criteria",
    "If pattern resumes post-suspension: Escalate to 30-day suspension with mandatory appeals review",
    "If coordinated behaviour detected: Refer to permanent ban review board"
  ],
  "confidence": 78
}
```

---

## Docker Configuration

### Dockerfile

```dockerfile
FROM python:3.12-slim
RUN pip install --no-cache-dir uv && \
    uv tool install "jaclang==0.11.2" && \
    ln -s /root/.local/bin/jac /usr/local/bin/jac
WORKDIR /app
COPY jac.toml ./
RUN jac install              # Installs firebase-admin, google-genai
COPY main.jac firebase_app.py llm_agent.py ./
EXPOSE 6000
CMD ["jac", "start", "main.jac", "--no_client"]
```

### docker-compose.yml

```yaml
services:
  panel-reef-media:
    build: .
    container_name: Panel-Reef-Media-Back
    restart: unless-stopped
    ports:
      - "127.0.0.1:6002:6000"      # Localhost only — Nginx proxies externally
    environment:
      FIREBASE_CREDENTIALS_PATH: /run/secrets/firebase_credentials
    secrets:
      - firebase_credentials

secrets:
  firebase_credentials:
    file: ./reef-media-trust-panel-firebase-adminsdk-fbsvc-*.json
```

### Rebuild & Restart

```bash
cd Back
docker-compose down
docker-compose up -d --build

# Verify
docker logs Panel-Reef-Media-Back --tail 20
curl http://127.0.0.1:6002/walker/health
```

---

## Dependencies (jac.toml)

| Package | Version | Purpose |
|---------|---------|---------|
| `firebase-admin` | ~=6.0 | Firebase Admin SDK (Firestore, Auth) |
| `google-genai` | >=1.0 | Google Gemini API client (Vertex AI) |

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `FIREBASE_CREDENTIALS_PATH` | Yes | Path to Firebase service account JSON (Docker secret mount) |
| `GOOGLE_APPLICATION_CREDENTIALS` | Fallback | Alternative credentials path (standard GCP convention) |
| `GEMINI_MODEL_ID` | No | Override Gemini model (default: `gemini-2.0-flash`). e.g. `gemini-2.5-flash` for faster, `gemini-1.5-pro` for more capable. |

---

## Troubleshooting

**404 on `/walker/assess_actor` (or other walkers)**  
- Ensure the reverse proxy (e.g. Nginx) forwards **all** `/walker/*` requests to the backend (e.g. `proxy_pass http://127.0.0.1:6002;` for the path `/walker` or the same path as the frontend’s API base).  
- Rebuild and restart the backend container after adding new walkers: `docker-compose up -d --build`.

**`Exception is not defined` in browser console**  
- The Jac client runtime used `Exception` instead of JavaScript’s `Error`. The project patches this after build; run `node scripts/patch-runtime.js` after `jac build` if you see it again, or use the `build` script in `jac.toml` which runs the patch automatically.

---

## Seed Script (`seed_firestore.py`)

Populates Firestore with initial demonstration data:

```bash
cd Back
python3 seed_firestore.py
```

Seeds 7 collections: `cases` (55 records), `actors` (12), `policies` (7), `personnel` (10), `roles` (3), `analytics` (2 documents: theme_slices + chart_data), and `actor_trends` (12).
