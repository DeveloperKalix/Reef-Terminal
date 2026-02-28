# Dashboard Backend - Jaclang + Firebase
#
# Backend entry: walkers and functions become HTTP endpoints.
# Firebase is used via the firebase_app Python module (Firestore).
#
# Setup:
#   1. Set FIREBASE_CREDENTIALS_PATH or GOOGLE_APPLICATION_CREDENTIALS.
#   2. cd Back && jac install && jac start main.jac

import firebase_app;

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
