# Reef Media — Trust & Safety Panel

A real-time misinformation monitoring and enforcement dashboard for the Reef Media platform. Trust & Safety analysts use it to investigate flagged content, assess bad-actor threat profiles, apply graduated enforcement policies, and receive AI-driven recommendations powered by Google Gemini.

**Live instance:** [https://panel.reefmedia.ai](https://panel.reefmedia.ai)

---

## What It Does

The panel gives Trust & Safety teams a single workspace to:

- **Triage misinformation cases** — review flagged content with engagement metrics, confidence scores, and category labels (deepfake, fabricated document, coordinated inauthentic behaviour, etc.).
- **Investigate bad actors** — inspect actor profiles, associated cases, reach/share/comment statistics, threat assessments, and audience growth trends.
- **Run AI analysis** — click "Run AI Triage" on a case or "Run AI Assessment" on an actor to get a Gemini-generated recommendation with a policy action, detailed rationale citing platform policies and research sources, a confidence score, and an escalation path.
- **Apply enforcement actions** — choose from graduated responses (content advisory, fact-check labels, reach reduction, monetisation suspension, temporary bans, permanent bans) tied to specific platform policies.
- **Monitor analytics** — track misinformation flow rates, engagement trends, and thematic breakdowns across daily, weekly, and monthly windows.
- **Manage personnel & policies** — add team members, assign roles (Operator / Administrator / Executive), and create or edit enforcement policies with rank-gated permissions.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Jaclang 0.11.2 |
| Frontend | React 18 + TypeScript, Recharts, Vite |
| Backend | Jaclang Walkers (HTTP endpoints) |
| Database | Google Cloud Firestore |
| AI / LLM | Google Gemini 2.5 Flash (Vertex AI) |
| Auth | Jaclang built-in JWT auth |
| Container | Docker + Docker Compose |
| Web Server | Nginx (reverse proxy, SSL, SPA serving) |
| Hosting | Linux VPS with Let's Encrypt TLS |

---

## Project Structure

```
Dashboard/
├── Front/                  # Frontend SPA (Jaclang + React/TSX)
│   ├── pages/              # Route-level Jaclang files (login, dashboard)
│   ├── components/         # React components (charts, tabs, modals)
│   ├── styles/             # CSS (global + dashboard)
│   ├── assets/             # Icons, logos, SVGs
│   └── jac.toml            # Frontend config & npm dependencies
│
├── Back/                   # Backend API (Jaclang + Python)
│   ├── main.jac            # Walker endpoint definitions
│   ├── llm_agent.py        # Gemini prompt engineering & API calls
│   ├── firebase_app.py     # Firebase Admin SDK initialisation
│   ├── Dockerfile          # Container build
│   ├── docker-compose.yml  # Service orchestration
│   └── seed_firestore.py   # Database seeding (dev)
│
└── docs/                   # Detailed documentation
    ├── ARCHITECTURE.md      # System architecture & deployment topology
    ├── FRONTEND.md          # Component tree, props, data flow
    └── BACKEND.md           # Walker API, AI agent prompts, env vars
```

---

## Testing the Live Instance

### 1. Open the panel

Navigate to **[https://panel.reefmedia.ai](https://panel.reefmedia.ai)** in any modern browser.

### 2. Log in or register

Create an account on the login screen, or use an existing one. Authentication is handled by Jaclang's built-in JWT system.

### 3. Explore the Dashboard tab

- **Cases** — scroll through flagged misinformation cases. Each card shows the title, content type, analysis count, status, and a confidence score.
- **Bad Actors** — switch to the Bad Actors sub-tab to see flagged user accounts with risk scores and classifications.
- **Analytics** — the right panel shows mini-charts (Misinformation Monitor, Engagement Monitor) with axis labels. Click "open" to view full-screen.

### 4. Investigate a case

Click the **menu icon** (three dots) on any case card, then select **Investigate**. The investigation modal shows:

- Evidence details and engagement metrics
- An **"AI Triage"** button — click it to run a Gemini analysis that recommends an enforcement action with a rationale and confidence score
- A policy dropdown to apply an enforcement action manually or accept the AI recommendation

### 5. Investigate a bad actor

Switch to **Bad Actors**, open the menu on any actor, and select **Investigate**. The actor modal shows:

- Actor profile (handle, classification, risk score, post count)
- Case summary, threat assessment, engagement stats
- Associated cases with their statuses
- An **"Run AI Assessment"** button — click it to get a detailed Gemini analysis with a recommended enforcement action, rationale citing research and platform policies, confidence level, and a multi-step escalation path
- A graduated enforcement dropdown (warnings → restrictions → suspensions → permanent bans → policy applications)

### 6. Browse other tabs

| Tab | What to look for |
|-----|------------------|
| **Policies** | Platform enforcement policies — admins can add and edit |
| **History** | Audit log of all enforcement actions applied to cases |
| **Analytics** | Full-screen charts, theme breakdown pie chart, actor trend analysis |
| **Personnel** | Team member management with role assignments |
| **Settings** | Read-only permission matrix showing what each role can do |

---

## Local Development

### Backend

```bash
cd Back
export FIREBASE_CREDENTIALS_PATH=./your-service-account.json
jac install          # install Python dependencies
jac start main.jac   # start API on port 6000
```

### Frontend

```bash
cd Front
jac install          # install npm + Python dependencies
jac script dev       # start Vite dev server with HMR
```

### Docker (backend only)

```bash
cd Back
docker compose up -d --build
```

The container maps port 6002 → 6000 internally and mounts the Firebase credentials as a Docker secret.

---

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `FIREBASE_CREDENTIALS_PATH` | — | Path to Firebase service account JSON |
| `GOOGLE_APPLICATION_CREDENTIALS` | — | Alternative to the above (standard GCP env var) |
| `GEMINI_MODEL_ID` | `gemini-2.5-flash` | Vertex AI model for AI analysis |

---

## Further Documentation

- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — system architecture diagram, request flows, security model, Firestore collections
- **[docs/FRONTEND.md](docs/FRONTEND.md)** — component tree, prop interfaces, state management, build pipeline
- **[docs/BACKEND.md](docs/BACKEND.md)** — walker API reference, AI agent prompt design, troubleshooting
