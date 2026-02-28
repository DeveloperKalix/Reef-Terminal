# Reef Media Trust & Safety Panel — Architecture

## Overview

The Reef Media Trust & Safety Panel is a full-stack misinformation monitoring and enforcement platform. Analysts use it to investigate flagged content, assess bad-actor threat profiles, apply enforcement policies, and leverage AI-driven triage recommendations powered by Google Gemini.

---

## System Architecture Diagram

```
                              INTERNET
                                 │
                           ┌─────┴─────┐
                           │   HTTPS    │
                           │  (port 443)│
                           └─────┬─────┘
                                 │
                    ┌────────────┴────────────┐
                    │     Nginx Reverse Proxy  │
                    │   panel.reefmedia.ai     │
                    │                          │
                    │  ┌──────────────────┐    │
                    │  │  SSL Termination │    │
                    │  └──────────────────┘    │
                    │                          │
                    │  ROUTING:                │
                    │  /api/*  ──► Backend     │
                    │  /user/* ──► Backend     │
                    │  /walker/*──► Backend    │
                    │  /*      ──► Static SPA  │
                    └──────┬─────────┬─────────┘
                           │         │
               ┌───────────┘         └───────────┐
               ▼                                  ▼
    ┌─────────────────────┐          ┌───────────────────────┐
    │   Frontend (SPA)    │          │    Backend (Docker)    │
    │                     │          │                        │
    │  Jaclang + React    │          │  Jaclang Walkers       │
    │  TypeScript / TSX   │          │  Python Modules        │
    │  Recharts           │          │  Port 6002 (internal)  │
    │                     │          │                        │
    │  Served as static   │          │  Container:            │
    │  files from:        │          │  Panel-Reef-Media-Back │
    │  /var/www/           │          │                        │
    │  panel-reefmedia/   │          └──────┬─────────┬───────┘
    └─────────────────────┘                 │         │
                                            │         │
                                ┌───────────┘         └──────────┐
                                ▼                                 ▼
                   ┌────────────────────┐          ┌──────────────────────┐
                   │  Google Cloud      │          │  Google Gemini       │
                   │  Firestore         │          │  (Vertex AI)         │
                   │                    │          │                      │
                   │  Collections:      │          │  Model:              │
                   │  • cases           │          │  gemini-2.0-flash    │
                   │  • actors          │          │                      │
                   │  • policies        │          │  Features:           │
                   │  • personnel       │          │  • Case Triage       │
                   │  • roles           │          │  • Actor Intel Brief │
                   │  • analytics       │          │                      │
                   │  • actor_trends    │          │  Auth: Service Acct  │
                   └────────────────────┘          └──────────────────────┘
                          ▲                                  ▲
                          │                                  │
                          └──────────┬───────────────────────┘
                                     │
                          ┌──────────┴──────────┐
                          │  Firebase Service   │
                          │  Account (JSON)     │
                          │                     │
                          │  Mounted as Docker  │
                          │  Secret at:         │
                          │  /run/secrets/      │
                          │  firebase_credentials│
                          └─────────────────────┘
```

---

## Request Flow

### 1. User Authentication

```
Browser ──► Nginx ──► Backend /user/register or /user/login
                          │
                          ▼
                    Jaclang Auth
                    (SQLite local DB)
                          │
                          ▼
                    JWT Token returned
                          │
                          ▼
                    Stored in localStorage
```

Jaclang's built-in authentication manages user accounts in a local SQLite database (`main.db`) inside the Docker container. The JWT token is stored client-side and sent as a `Bearer` token on all subsequent API calls.

### 2. Data Operations (CRUD)

```
Browser ──► jacSpawn("list_cases") ──► POST /walker/list_cases
                                            │
                                            ▼
                                      Backend Walker
                                            │
                                            ▼
                                      Firebase Admin SDK
                                            │
                                            ▼
                                      Firestore Query
                                            │
                                            ▼
                                      JSON Response ──► Browser
```

All data operations go through Jaclang **walkers** — serverless function-like endpoints. The frontend calls them via `jacSpawn(walkerName, "", params)`, which internally makes authenticated `POST` requests to `/walker/{name}`.

### 3. AI Agent Workflow

```
Browser ──► jacSpawn("triage_case") ──► Backend Walker
                                             │
                                    ┌────────┴────────┐
                                    ▼                  ▼
                              Firestore            Firestore
                              (fetch case)         (fetch policies)
                                    │                  │
                                    └────────┬─────────┘
                                             ▼
                                       llm_agent.py
                                             │
                                             ▼
                                    Construct prompt with
                                    case data + metrics +
                                    actor profile + policies
                                             │
                                             ▼
                                    Gemini 2.0 Flash
                                    (Vertex AI API)
                                             │
                                             ▼
                                    Parse JSON response
                                    {action, rationale,
                                     confidence}
                                             │
                                             ▼
                                    Return to Browser
```

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Language** | Jaclang 0.11.2 | AI-native full-stack language for both frontend and backend |
| **Frontend Runtime** | React 18 + TypeScript | UI rendering via Jaclang's `cl {}` client blocks |
| **Charts** | Recharts 3.7 | Data visualisation (line, area, pie charts) |
| **Build Tool** | Vite 6.4 | Frontend bundling via Jaclang's client plugin |
| **Backend Runtime** | Jaclang Walkers | HTTP endpoints (walker pattern) |
| **Database** | Google Cloud Firestore | NoSQL document database for all application data |
| **Auth (Users)** | Jaclang Built-in Auth | JWT-based authentication with SQLite user store |
| **Auth (Services)** | Firebase Service Account | Server-to-server auth for Firestore + Vertex AI |
| **AI/LLM** | Google Gemini 2.0 Flash | Case triage recommendations and actor intelligence briefs |
| **Container** | Docker | Backend containerisation |
| **Web Server** | Nginx | Reverse proxy, SSL termination, SPA serving |
| **SSL** | Let's Encrypt | TLS certificates for panel.reefmedia.ai |

---

## Deployment Topology

```
VPS (Linux)
├── Nginx (host)
│   ├── SSL termination (port 443)
│   ├── Static SPA files (/var/www/panel-reefmedia/)
│   └── Reverse proxy → Docker (port 6002)
│
├── Docker Container: Panel-Reef-Media-Back
│   ├── Jaclang runtime (port 6000, mapped to 6002)
│   ├── Firebase Admin SDK
│   ├── Gemini client (google-genai)
│   └── Docker Secret: firebase_credentials
│
└── Frontend Build Artefacts
    └── /root/apps/production/Dashboard/Front/
        └── jac build → .jac/client/dist/client.{hash}.js
        └── Copied to /var/www/panel-reefmedia/
```

---

## Security Model

1. **Transport**: All traffic encrypted via TLS 1.2+ (Nginx SSL)
2. **Authentication**: JWT tokens issued by Jaclang auth; validated on every walker invocation
3. **Authorisation**: Role-based (Operator / Administrator / Executive) enforced in the UI and wallet-level
4. **Credentials**: Firebase service account JSON mounted as a Docker secret — never baked into images
5. **Network Isolation**: Backend Docker port bound to `127.0.0.1:6002` — not reachable externally
6. **CORS**: Handled by Nginx; only `panel.reefmedia.ai` origin served

---

## Data Collections (Firestore)

| Collection | Documents | Purpose |
|------------|-----------|---------|
| `cases` | ~55 | Misinformation case records with metrics, outcomes, engagement data |
| `actors` | 12 | Bad actor profiles (handle, type, risk score, post count) |
| `policies` | 7 | Enforcement policies with name, description, restriction, rank requirement |
| `personnel` | 10 | Team members (name, email, rank) |
| `roles` | 3 | Role definitions (Operator, Administrator, Executive) |
| `analytics` | 2 | Chart data (theme_slices, chart_data with daily/weekly/monthly series) |
| `actor_trends` | 12 | Per-actor trend intelligence (threat level, insights, time-series data) |
