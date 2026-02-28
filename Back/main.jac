# Dashboard Backend - Jaclang + Firebase
#
# Backend entry: walkers and functions become HTTP endpoints.
# Firebase is used via the firebase_app Python module (Firestore).
#
# Setup:
#   1. Set FIREBASE_CREDENTIALS_PATH or GOOGLE_APPLICATION_CREDENTIALS.
#   2. cd Back && jac install && jac start main.jac

import firebase_app;
import llm_agent;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def ensure_firebase() -> bool {
    if not firebase_app.is_initialized() {
        firebase_app.init_firebase();
    }
    return firebase_app.is_initialized();
}

# ---------------------------------------------------------------------------
# Health
# ---------------------------------------------------------------------------

walker:pub health {
    can fetch with entry {
        report {"status": "ok", "firebase": firebase_app.is_initialized()};
    }
}

walker:pub init_firebase {
    can fetch with entry {
        report {"initialized": ensure_firebase()};
    }
}

# ---------------------------------------------------------------------------
# Personnel CRUD (Firestore collection: "personnel")
# ---------------------------------------------------------------------------

walker:pub list_personnel {
    can fetch with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        docs = db.collection("personnel").stream();
        users = [];
        for doc in docs {
            data = doc.to_dict();
            data["id"] = doc.id;
            users.append(data);
        }
        report {"users": users};
    }
}

walker:pub create_personnel {
    has first_name: str;
    has last_name: str;
    has email: str;
    has username: str;
    has rank: str = "Operator";

    can create with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        doc_ref = db.collection("personnel").document();
        user_data = {
            "first_name": self.first_name,
            "last_name": self.last_name,
            "email": self.email,
            "username": self.username,
            "rank": self.rank,
            "created_at": firebase_app.server_timestamp()
        };
        doc_ref.set(user_data);
        user_data["id"] = doc_ref.id;
        report {"success": True, "user": user_data};
    }
}

walker:pub update_personnel {
    has id: str;
    has first_name: str = "";
    has last_name: str = "";
    has email: str = "";
    has username: str = "";
    has rank: str = "";

    can create with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        doc_ref = db.collection("personnel").document(self.id);
        updates = {};
        if self.first_name { updates["first_name"] = self.first_name; }
        if self.last_name  { updates["last_name"]  = self.last_name; }
        if self.email      { updates["email"]      = self.email; }
        if self.username   { updates["username"]   = self.username; }
        if self.rank       { updates["rank"]       = self.rank; }
        doc_ref.update(updates);
        report {"success": True};
    }
}

walker:pub delete_personnel {
    has id: str;

    can create with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        db.collection("personnel").document(self.id).delete();
        report {"success": True};
    }
}

# ---------------------------------------------------------------------------
# Roles (Firestore collection: "roles")
# ---------------------------------------------------------------------------

walker:pub list_roles {
    can fetch with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        docs = db.collection("roles").stream();
        roles = [];
        for doc in docs {
            data = doc.to_dict();
            data["id"] = doc.id;
            roles.append(data);
        }
        if not roles {
            defaults = ["Operator", "Administrator", "Executive"];
            for r in defaults {
                ref = db.collection("roles").document();
                ref.set({"name": r});
                roles.append({"id": ref.id, "name": r});
            }
        }
        report {"roles": roles};
    }
}

# ---------------------------------------------------------------------------
# Cases CRUD (Firestore collection: "cases")
# ---------------------------------------------------------------------------

walker:pub list_cases {
    can fetch with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        docs = db.collection("cases").stream();
        cases = [];
        for doc in docs {
            data = doc.to_dict();
            if not data.get("id") {
                data["id"] = doc.id;
            }
            cases.append(data);
        }
        report {"cases": cases};
    }
}

walker:pub update_case {
    has id: str;
    has outcome: str = "";

    can create with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        doc_ref = db.collection("cases").document(self.id);
        updates = {};
        if self.outcome { updates["outcome"] = self.outcome; }
        doc_ref.update(updates);
        report {"success": True};
    }
}

# ---------------------------------------------------------------------------
# Actors CRUD (Firestore collection: "actors")
# ---------------------------------------------------------------------------

walker:pub list_actors {
    can fetch with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        docs = db.collection("actors").stream();
        items = [];
        for doc in docs {
            data = doc.to_dict();
            if not data.get("id") {
                data["id"] = doc.id;
            }
            items.append(data);
        }
        report {"actors": items};
    }
}

# ---------------------------------------------------------------------------
# Policies CRUD (Firestore collection: "policies")
# ---------------------------------------------------------------------------

walker:pub list_policies {
    can fetch with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        docs = db.collection("policies").stream();
        items = [];
        for doc in docs {
            data = doc.to_dict();
            if not data.get("id") {
                data["id"] = doc.id;
            }
            items.append(data);
        }
        report {"policies": items};
    }
}

walker:pub create_policy {
    has name: str;
    has description: str;
    has restriction: str;
    has rank: str = "Operator";

    can create with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        doc_ref = db.collection("policies").document();
        pol_data = {
            "name": self.name,
            "description": self.description,
            "restriction": self.restriction,
            "rank": self.rank,
            "created_at": firebase_app.server_timestamp()
        };
        doc_ref.set(pol_data);
        pol_data["id"] = doc_ref.id;
        report {"success": True, "policy": pol_data};
    }
}

walker:pub update_policy {
    has id: str;
    has name: str = "";
    has description: str = "";
    has restriction: str = "";
    has rank: str = "";

    can create with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        doc_ref = db.collection("policies").document(self.id);
        updates = {};
        if self.name        { updates["name"]        = self.name; }
        if self.description { updates["description"] = self.description; }
        if self.restriction { updates["restriction"] = self.restriction; }
        if self.rank        { updates["rank"]        = self.rank; }
        doc_ref.update(updates);
        report {"success": True};
    }
}

walker:pub delete_policy {
    has id: str;

    can create with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        db.collection("policies").document(self.id).delete();
        report {"success": True};
    }
}

# ---------------------------------------------------------------------------
# Analytics (Firestore collection: "analytics")
# ---------------------------------------------------------------------------

walker:pub get_analytics {
    can fetch with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        slices_doc = db.collection("analytics").document("theme_slices").get();
        chart_doc = db.collection("analytics").document("chart_data").get();
        result = {};
        if slices_doc.exists {
            result["theme_slices"] = slices_doc.to_dict().get("slices", []);
        }
        if chart_doc.exists {
            result["chart_data"] = chart_doc.to_dict();
        }
        report result;
    }
}

# ---------------------------------------------------------------------------
# Actor Trends (Firestore collection: "actor_trends")
# ---------------------------------------------------------------------------

walker:pub get_actor_trends {
    has actor_id: str;

    can fetch with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        doc = db.collection("actor_trends").document(self.actor_id).get();
        if doc.exists {
            report {"trends": doc.to_dict()};
        } else {
            report {"trends": None};
        }
    }
}

# ---------------------------------------------------------------------------
# AI Agent: Case Triage (Gemini 2.0 Flash)
# ---------------------------------------------------------------------------

walker:pub triage_case {
    has case_id: str;

    can fetch with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();

        case_doc = db.collection("cases").document(self.case_id).get();
        if not case_doc.exists {
            report {"error": "Case not found"};
            return;
        }
        case_data = case_doc.to_dict();

        actor_data = {};
        actor_id = case_data.get("actor_id", "");
        if actor_id {
            actor_doc = db.collection("actors").document(actor_id).get();
            if actor_doc.exists {
                actor_data = actor_doc.to_dict();
            }
        }

        pol_docs = db.collection("policies").stream();
        pol_list = [];
        for pdoc in pol_docs {
            pol_list.append(pdoc.to_dict());
        }

        result = llm_agent.triage_case(case_data, actor_data, pol_list);
        report {"triage": result};
    }
}

# ---------------------------------------------------------------------------
# AI Agent: Actor Intelligence Summary (Gemini 2.0 Flash)
# ---------------------------------------------------------------------------

walker:pub summarize_actor {
    has actor_id: str;

    can fetch with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();

        actor_doc = db.collection("actors").document(self.actor_id).get();
        if not actor_doc.exists {
            report {"error": "Actor not found"};
            return;
        }
        actor_data = actor_doc.to_dict();

        trends_data = {};
        trends_doc = db.collection("actor_trends").document(self.actor_id).get();
        if trends_doc.exists {
            trends_data = trends_doc.to_dict();
        }

        case_docs = db.collection("cases").stream();
        actor_cases = [];
        handle = actor_data.get("handle", "");
        for cdoc in case_docs {
            c = cdoc.to_dict();
            if c.get("actor") == handle {
                actor_cases.append(c);
            }
        }

        result = llm_agent.summarize_actor(actor_data, trends_data, actor_cases);
        report {"summary": result};
    }
}

# ---------------------------------------------------------------------------
# AI Agent: Actor Enforcement Assessment (Gemini 2.0 Flash)
# ---------------------------------------------------------------------------

walker:pub assess_actor {
    has actor_id: str;

    can fetch with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();

        actor_doc = db.collection("actors").document(self.actor_id).get();
        if not actor_doc.exists {
            report {"error": "Actor not found"};
            return;
        }
        actor_data = actor_doc.to_dict();

        trends_data = {};
        trends_doc = db.collection("actor_trends").document(self.actor_id).get();
        if trends_doc.exists {
            trends_data = trends_doc.to_dict();
        }

        case_docs = db.collection("cases").stream();
        actor_cases = [];
        handle = actor_data.get("handle", "");
        for cdoc in case_docs {
            c = cdoc.to_dict();
            if c.get("actor") == handle {
                actor_cases.append(c);
            }
        }

        pol_docs = db.collection("policies").stream();
        pol_list = [];
        for pdoc in pol_docs {
            pd = pdoc.to_dict();
            if not pd.get("id") {
                pd["id"] = pdoc.id;
            }
            pol_list.append(pd);
        }

        result = llm_agent.assess_actor(actor_data, trends_data, actor_cases, pol_list);
        report {"assessment": result};
    }
}

# ---------------------------------------------------------------------------
# Generic Firestore get/set (kept for flexibility)
# ---------------------------------------------------------------------------

walker:pub firestore_get {
    has collection: str;
    has document_id: str;

    can fetch with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        doc = db.collection(self.collection).document(self.document_id).get();
        if doc.exists {
            report {"exists": True, "data": doc.to_dict()};
        } else {
            report {"exists": False};
        }
    }
}

walker:pub firestore_set {
    has collection: str;
    has document_id: str;
    has data: dict;

    can create with entry {
        if not ensure_firebase() {
            report {"error": "Firebase not initialized"};
            return;
        }
        db = firebase_app.get_firestore();
        db.collection(self.collection).document(self.document_id).set(self.data);
        report {"success": True};
    }
}

# ---------------------------------------------------------------------------
# Root node
# ---------------------------------------------------------------------------

node Root {
    has name: str = "dashboard-backend";
}

with entry {
    here = Root();
}
