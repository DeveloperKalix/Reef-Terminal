# Frontend — Structure & Data Flow

## Overview

The frontend is a single-page application built with **Jaclang** and **React/TypeScript**. Jaclang's client plugin compiles `.jac` files into React components and `.tsx` files into standard TypeScript modules. The result is a Vite-bundled SPA deployed as a single hashed JS file.

---

## Directory Structure

```
Front/
├── main.jac                          # App entry point — wraps children in root div
├── jac.toml                          # Project config, npm deps, path aliases
│
├── pages/
│   ├── index.jac                     # Login / registration page (public)
│   └── (protected)/
│       └── dashboard.jac             # Dashboard — state orchestrator (900 lines)
│
├── components/
│   ├── Charts.tsx                    # MiniChart, FullScreenChart, ThemePieChart
│   ├── ActorTrendsChart.tsx          # Dual-axis line chart for actor trends
│   └── tabs/                         # Tab-level UI components
│       ├── index.tsx                 # Barrel exports
│       ├── DashboardTab.tsx          # Cases/actors list, search, pagination, viz
│       ├── AnalyticsTab.tsx          # Themes pie, trends, impact, actor profiles
│       ├── HistoryTab.tsx            # History table + investigation report modal
│       ├── PoliciesTab.tsx           # Policies table + add/edit modals
│       ├── PersonnelTab.tsx          # Personnel table + add/edit modals
│       └── SettingsTab.tsx           # Role permissions grid (stateless)
│
├── lib/
│   ├── helpers.tsx                   # Shared utility functions (CSS classes, formatting)
│   └── sorting.tsx                   # Generic sorting logic for tables
│
├── styles/
│   ├── global.css                    # CSS reset, variables, typography
│   └── dashboard.css                 # All dashboard component styles
│
└── assets/
    └── icons/                        # SVG icons used throughout the UI
        ├── dashboard.svg
        ├── policy.svg
        ├── history.svg
        ├── analytics.svg
        ├── personnel.svg
        ├── green_check.svg
        ├── red_close.svg
        └── ... (search, chevron, close, etc.)
```

---

## State Management Pattern

The frontend follows a **centralised state + prop-drilling** architecture, matching standard React patterns within Jaclang's compilation model.

```
dashboard.jac (State Orchestrator)
│
├── has declarations       ←  All reactive state (Jaclang `has` = React useState)
├── Data loaders           ←  Async functions calling jacSpawn() to fetch from backend
├── Action handlers        ←  Functions that mutate state (apply actions, CRUD, sorting)
├── Viz list helpers       ←  Compute chart data lists from timescale state
│
└── Render (JSX)
    ├── <Sidebar />        ←  Inline — navigation, user info, logout
    │
    ├── <DashboardTab      ←  Props: state values + setter callbacks
    │     ...props />
    ├── <PoliciesTab />
    ├── <HistoryTab />
    ├── <AnalyticsTab />
    ├── <PersonnelTab />
    ├── <SettingsTab />     ←  Stateless — no props needed
    │
    ├── <UserModal />       ←  Add/Edit personnel modal (controlled via props)
    ├── <PolicyModal />     ←  Add/Edit policy modal (controlled via props)
    ├── <ReportModal />     ←  Case investigation modal with AI triage
    └── <ActorModal />      ←  Actor investigation modal with AI enforcement assessment
```

### Why This Pattern?

Jaclang's `has` keyword creates reactive state variables scoped to the `def:pub page()` function. Only code **within that same scope** can assign to these variables. This means state mutations cannot be moved to external `.jac` files. The solution:

1. **State + mutations** stay in `dashboard.jac`
2. **Rendering logic** is extracted to `.tsx` components
3. Components receive **data as props** and **callbacks for mutations**

---

## Data Flow

### Page Load Sequence

```
1. User navigates to /dashboard
2. Jaclang auth check (jacIsLoggedIn)
3. useEffect → fetch /user/info → set my_username
4. can with entry → trigger all data loaders in parallel:
   │
   ├── load_actors()    → jacSpawn("list_actors")     → fake_actors
   ├── load_cases()     → jacSpawn("list_cases")      → all_cases, fake_cases, history_records
   ├── load_users()     → jacSpawn("list_personnel")  → users
   ├── load_roles()     → jacSpawn("list_roles")      → roles
   ├── load_policies()  → jacSpawn("list_policies")   → policies
   └── load_analytics() → jacSpawn("get_analytics")   → chart data + theme_slices
```

### Case Action Flow (Policy Application)

```
1. User opens case from History tab or Dashboard "Investigate"
2. ReportModal renders with case details, metrics, actor profile
3. User selects action from dropdown (e.g. "Policy: Deepfake Takedown")
   — or —
   User clicks "Run AI Triage" → backend calls Gemini → recommendation card appears
   User clicks "Apply Recommendation" → action auto-selected
4. User clicks "Save Decision"
5. apply_case_action():
   a. jacSpawn("update_case", {id, outcome}) → updates Firestore
   b. reorder_cases(updated_all) → rebuilds fake_cases + history_records
   c. history_selected = updated copy → triggers re-render with new outcome
6. History tab now shows the updated outcome immediately
```

### AI Triage Flow

```
ReportModal "Run AI Triage" button
    │
    ▼
run_triage(case_id)
    │ triage_loading = True
    ▼
jacSpawn("triage_case", {case_id})
    │
    ▼
Backend: fetch case + actor + policies from Firestore
    │
    ▼
llm_agent.triage_case() → Gemini 2.0 Flash
    │
    ▼
JSON response: {action, rationale, confidence}
    │
    ▼
triage_result = response → triage_loading = False
    │
    ▼
ReportModal renders:
    ├── Recommended action badge
    ├── Confidence score (colour-coded: high/mid/low)
    ├── Rationale text (with research citations)
    └── "Apply Recommendation" button
```

---

## Component Prop Interface Summary

| Component | Key Props In | Key Callbacks |
|-----------|-------------|---------------|
| `DashboardTab` | fakeCases, fakeActors, vizList, dashPill, dashSearch, dashPage | onSetDashPill, onSetDashSearch, onInvestigateCase |
| `AnalyticsTab` | fakeActors, allCases, themeSlices, analyticsVizList, actorTrendsData, actorBrief | onSetAnalyticsPill, onSetActorProfileOpen, onLoadActorTrends, onRunActorBrief |
| `HistoryTab` | historyRecords, openHistoryMenu, isExecutive | onSelectCase, onSetOpenHistoryMenu |
| `ReportModal` | record, fakeActors, policies, triageResult, reportAction, rankOrder | onClose, onToggleMetric, onSetReportAction, onApplyAction, onRunTriage |
| `PoliciesTab` | policies, sortKey, sortAsc, isExecutive | onToggleSort, onOpenAddModal, onOpenEditModal, onDeletePolicy |
| `PersonnelTab` | users, usersLoaded, sortKey, sortAsc, isExecutive | onToggleSort, onOpenAddModal, onOpenEditModal, onDeleteUser |
| `SettingsTab` | *(none — fully stateless)* | *(none)* |
| `UserModal` | mode, formFirst..formRank, formError, formSaving | onSetFirst..onSetRank, onSubmit, onClose |
| `PolicyModal` | mode, polName..polRank, polError, polSaving | onSetName..onSetRank, onSubmit, onClose |
| `ActorModal` | actor, allCases, policies, actorAssessment, actorAction, rankOrder | onClose, onSetActorAction, onApplyActorAction, onRunActorAssessment, onLoadActorTrends |

---

## Path Aliases (jac.toml)

| Alias | Resolves To | Example |
|-------|------------|---------|
| `@styles/*` | `./styles/*` | `import "@styles/dashboard.css"` |
| `@components/*` | `./components/*` | `import { DashboardTab } from "@components/tabs"` |
| `@lib/*` | `./lib/*` | `import { scoreColor } from "@lib/helpers"` |
| `@assets/*` | `./assets/*` | — |
| `@pages/*` | `./pages/*` | — |

---

## Build & Deploy

```bash
# Build frontend bundle
cd Front && jac build

# Output: Front/.jac/client/dist/client.{HASH}.js

# Deploy to web server
cp Front/.jac/client/dist/client.{HASH}.js /var/www/panel-reefmedia/

# Update index.html with new bundle filename
# (update the <script src="client.{HASH}.js"> tag)
```
