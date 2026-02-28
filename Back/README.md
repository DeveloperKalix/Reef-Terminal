# Dashboard Backend (Jaclang + Firebase)

Jaclang backend with Firebase support via the Firebase Admin SDK (Python). Public walkers become HTTP API endpoints.

## Prerequisites

- Python 3.10+
- [Jac CLI](https://docs.jaseci.org/) (`pip install jaseci`)
- Firebase project with a **service account** (JSON key)

## Setup

1. **Install dependencies**

   ```bash
   cd Back
   jac install
   ```

2. **Firebase credentials**

   - Download a service account key from [Firebase Console](https://console.firebase.google.com/) → Project settings → Service accounts → Generate new private key.
   - Set one of:

   - `FIREBASE_CREDENTIALS_PATH` — path to the JSON file (e.g. `./serviceAccountKey.json`)
   - or `GOOGLE_APPLICATION_CREDENTIALS` — same meaning, standard Google env var

   Example:

   ```bash
   export FIREBASE_CREDENTIALS_PATH=./serviceAccountKey.json
   ```

   Optional: copy `.env.example` to `.env` and set the path there (you must still export or source it if your runner doesn’t load `.env`).

3. **Run the server**

   ```bash
   jac start main.jac
   ```

   API base: `http://localhost:8000` (port configurable in `jac.toml`).

   API-only (no client):

   ```bash
   jac start main.jac --no_client
   ```

   Dev with HMR:

   ```bash
   jac script dev
   ```

## Endpoints

| Walker           | Purpose                                      |
|------------------|----------------------------------------------|
| `health`         | Health check; reports `firebase: true/false` |
| `init_firebase`  | Initialize Firebase (idempotent)             |
| `firestore_get`  | Get document: `collection`, `document_id`    |
| `firestore_set`  | Set document: `collection`, `document_id`, `data` |

Exact HTTP routes depend on the Jac server (e.g. `/api/health`, `/api/init_firebase`, etc.). Use the server’s generated API docs or routes list.

## Project layout

- `main.jac` — entry point, node definitions, public walkers (API)
- `firebase_app.py` — Firebase Admin init, Firestore/Auth helpers
- `jac.toml` — project config, deps (`firebase-admin`), scripts

## Adding more Firebase features

- **Auth**: use `firebase_app.get_auth()` in walkers (e.g. verify ID tokens, get user by uid).
- **Firestore**: use `firebase_app.get_firestore()` for queries, batches, transactions (see Firebase Admin SDK docs).
- **Other products**: add SDKs in `jac.toml` and wrap them in Python modules or `::py::` blocks in `.jac` files.
