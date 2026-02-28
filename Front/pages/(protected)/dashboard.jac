# /dashboard — Trust & Safety Dashboard (protected)
# Tabs: Dashboard, Policies, History, Analytics, Personnel, Settings

cl import from "@jac/runtime" { jacLogout, jacIsLoggedIn, jacSpawn, useNavigate, __getLocalStorage, __getApiBaseUrl, useEffect }
cl import from "@lib/helpers" { RANK_ORDER }
cl import from "@components/tabs" { DashboardTab, AnalyticsTab, HistoryTab, ReportModal, PoliciesTab, PolicyModal, PersonnelTab, UserModal, SettingsTab, ActorModal }

cl {
    import "@styles/dashboard.css";

    def:pub page() -> JsxElement {
        # ══════════════════════════════════════════════════════════════
        # STATE DECLARATIONS
        # ══════════════════════════════════════════════════════════════

        has active_nav:    str   = "dashboard";
        has signing_out:   bool  = False;

        # Personnel state
        has users:         list  = [];
        has users_loaded:  bool  = False;
        has show_add:      bool  = False;
        has show_edit:     bool  = False;
        has edit_user:     dict  = {};
        has open_menu:     str   = "";

        # Add/Edit form fields
        has form_first:    str   = "";
        has form_last:     str   = "";
        has form_email:    str   = "";
        has form_username: str   = "";
        has form_rank:     str   = "Operator";
        has form_saving:   bool  = False;
        has form_error:    str   = "";

        # Roles state
        has roles:         list  = [];
        has roles_loaded:  bool  = False;

        # Current user rank
        has my_rank:       str   = "Executive";
        has my_username:   str   = "";

        # Dashboard tab state
        has fake_actors:   list  = [];
        has dash_pill:     str   = "cases";
        has dash_search:   str   = "";
        has dash_page:     int   = 0;
        has viz_page:      int   = 0;
        has viz_fullscreen:int   = -1;
        has viz_timescale: str   = "monthly";
        has open_card_menu: str  = "";

        # Policies state
        has policies:      list  = [];
        has show_add_policy:  bool = False;
        has show_edit_policy: bool = False;
        has edit_policy:      dict = {};
        has open_policy_menu: str  = "";
        has pol_name:      str   = "";
        has pol_desc:      str   = "";
        has pol_restriction: str = "";
        has pol_rank:      str   = "Operator";
        has pol_saving:    bool  = False;
        has pol_error:     str   = "";

        # Sorting state
        has personnel_sort_key: str  = "";
        has personnel_sort_asc: bool = True;
        has policies_sort_key:  str  = "";
        has policies_sort_asc:  bool = True;

        # Analytics tab state
        has analytics_page:      int = 0;
        has analytics_timescale: str = "monthly";
        has analytics_pill:      str = "themes";
        has pie_hover_label:     str = "";
        has actors_collapsed:    bool = False;
        has actor_profile_open:  dict = {};
        has actor_profile_pill:  str = "trust";
        has actor_trends_data:   dict = {};
        has actor_trends_loading: bool = False;

        # History tab state
        has history_selected:    dict = {};
        has open_history_menu:   str  = "";
        has report_open_metrics: list = [];
        has report_action:       str  = "";
        has report_saving:       bool = False;

        # AI Triage state
        has triage_result:       dict = {};
        has triage_loading:      bool = False;

        # AI Actor Brief state
        has actor_brief:         dict = {};
        has actor_brief_loading: bool = False;

        # Actor investigation state
        has actor_selected:       dict = {};
        has actor_assessment:     dict = {};
        has actor_assessment_loading: bool = False;
        has actor_action:         str  = "";
        has actor_action_saving:  bool = False;

        # Analytics chart data
        has misinfo_monthly:    list = [];
        has engagement_monthly: list = [];
        has toxicity_monthly:   list = [];
        has misinfo_weekly:     list = [];
        has engagement_weekly:  list = [];
        has toxicity_weekly:    list = [];
        has misinfo_daily:      list = [];
        has engagement_daily:   list = [];
        has toxicity_daily:     list = [];
        has theme_slices:       list = [];

        # Case data
        has all_cases:      list = [];
        has history_records:list = [];
        has fake_cases:     list = [];
        has data_loaded:    bool = False;

        # ══════════════════════════════════════════════════════════════
        # AUTHENTICATION & INITIALISATION
        # ══════════════════════════════════════════════════════════════

        navigate = useNavigate();

        can with entry {
            if not jacIsLoggedIn() {
                navigate("/");
            }
        }

        if not jacIsLoggedIn() {
            return <div className="login-page"><p>Redirecting...</p></div>;
        }

        useEffect(lambda -> None {
            token = __getLocalStorage("jac_token");
            if token {
                base_url = __getApiBaseUrl();
                fetch(base_url + "/user/info", {
                    "method": "GET",
                    "headers": {"Authorization": "Bearer " + token, "Accept": "application/json"}
                }).then(lambda resp: any -> any {
                    if resp.ok { return resp.json(); }
                    return None;
                }).then(lambda payload: any -> None {
                    if payload and payload["data"] and payload["data"]["username"] {
                        my_username = payload["data"]["username"];
                    }
                }).catch(lambda _e: any -> None {});
            }
        }, []);

        # ══════════════════════════════════════════════════════════════
        # DATA LOADERS
        # ══════════════════════════════════════════════════════════════

        async def load_users() -> None {
            result = await jacSpawn("list_personnel", "", {});
            if result and result["reports"] and result["reports"].length > 0 {
                data = result["reports"][0];
                if data["users"] and data["users"].length > 0 {
                    users = data["users"];
                }
            }
            users_loaded = True;
        }

        async def load_roles() -> None {
            result = await jacSpawn("list_roles", "", {});
            if result and result["reports"] and result["reports"].length > 0 {
                data = result["reports"][0];
                if data["roles"] {
                    roles = data["roles"];
                }
            }
            roles_loaded = True;
        }

        async def load_cases() -> None {
            result = await jacSpawn("list_cases", "", {});
            if not result or not result["reports"] or result["reports"].length == 0 { return; }
            case_data = result["reports"][0];
            if not case_data["cases"] or case_data["cases"].length == 0 { return; }
            reorder_cases(case_data["cases"]);
        }

        async def load_actors() -> None {
            result = await jacSpawn("list_actors", "", {});
            if result and result["reports"] and result["reports"].length > 0 {
                data = result["reports"][0];
                if data["actors"] and data["actors"].length > 0 {
                    fake_actors = data["actors"];
                }
            }
        }

        async def load_policies() -> None {
            result = await jacSpawn("list_policies", "", {});
            if result and result["reports"] and result["reports"].length > 0 {
                data = result["reports"][0];
                if data["policies"] and data["policies"].length > 0 {
                    policies = data["policies"];
                }
            }
        }

        async def load_analytics() -> None {
            result = await jacSpawn("get_analytics", "", {});
            if not result or not result["reports"] or result["reports"].length == 0 { return; }
            rpt = result["reports"][0];
            theme_slices = rpt["theme_slices"] or [];
            cd = rpt["chart_data"] or {};
            misinfo_monthly = cd["misinfo_monthly"] or [];
            engagement_monthly = cd["engagement_monthly"] or [];
            toxicity_monthly = cd["toxicity_monthly"] or [];
            misinfo_weekly = cd["misinfo_weekly"] or [];
            engagement_weekly = cd["engagement_weekly"] or [];
            toxicity_weekly = cd["toxicity_weekly"] or [];
            misinfo_daily = cd["misinfo_daily"] or [];
            engagement_daily = cd["engagement_daily"] or [];
            toxicity_daily = cd["toxicity_daily"] or [];
        }

        async def load_actor_trends(aid: str) -> None {
            actor_trends_loading = True;
            result = await jacSpawn("get_actor_trends", "", {"actor_id": aid});
            actor_trends_loading = False;
            if result and result["reports"] and result["reports"].length > 0 {
                data = result["reports"][0];
                if data["trends"] {
                    actor_trends_data = data["trends"];
                    return;
                }
            }
            actor_trends_data = {};
        }

        # ── AI Agent calls ────────────────────────────────────────────

        async def run_triage(case_id: str) -> None {
            triage_loading = True;
            triage_result = {};
            result = await jacSpawn("triage_case", "", {"case_id": case_id});
            triage_loading = False;
            if result and result["reports"] and result["reports"].length > 0 {
                data = result["reports"][0];
                if data["triage"] {
                    triage_result = data["triage"];
                    return;
                }
            }
            triage_result = {"action": "Escalated", "rationale": "AI analysis could not be completed.", "confidence": 0};
        }

        async def run_actor_brief(aid: str) -> None {
            actor_brief_loading = True;
            actor_brief = {};
            result = await jacSpawn("summarize_actor", "", {"actor_id": aid});
            actor_brief_loading = False;
            if result and result["reports"] and result["reports"].length > 0 {
                data = result["reports"][0];
                if data["summary"] {
                    actor_brief = data["summary"];
                    return;
                }
            }
            actor_brief = {"brief": "Intelligence brief could not be generated.", "key_findings": []};
        }

        # ── Actor Investigation ───────────────────────────────────────

        def open_actor_modal(a: dict) -> None {
            actor_selected = a;
            actor_assessment = {};
            actor_action = "";
        }

        async def run_actor_assessment(aid: str) -> None {
            actor_assessment_loading = True;
            actor_assessment = {};
            result = await jacSpawn("assess_actor", "", {"actor_id": aid});
            actor_assessment_loading = False;
            if result and result["reports"] and result["reports"].length > 0 {
                data = result["reports"][0];
                if data["assessment"] {
                    actor_assessment = data["assessment"];
                    return;
                }
            }
            actor_assessment = {"recommended_action": "Warning: Content Advisory", "rationale": "AI assessment could not be completed.", "escalation_path": [], "confidence": 0};
        }

        async def apply_actor_action() -> None {
            if not actor_action or not actor_selected or not actor_selected["id"] { return; }
            aid = actor_selected["id"];
            actor_action_saving = True;
            # Store the enforcement action as a case note or actor status update
            await jacSpawn("firestore_set", "", {
                "collection": "actor_actions",
                "document_id": aid + "_" + String(Date.now()),
                "data": {
                    "actor_id": aid,
                    "handle": actor_selected["handle"] or "",
                    "action": actor_action,
                    "timestamp": Date.now(),
                    "applied_by": my_username
                }
            });
            actor_action_saving = False;
            actor_selected = {};
        }

        can with entry {
            if not data_loaded {
                data_loaded = True;
                load_actors();
                load_cases();
                load_users();
                load_roles();
                load_policies();
                load_analytics();
            }
        }

        # ══════════════════════════════════════════════════════════════
        # ACTIONS & HELPERS
        # ══════════════════════════════════════════════════════════════

        async def handle_logout() -> None {
            signing_out = True;
            jacLogout();
            navigate("/");
        }

        def nav_class(key: str) -> str {
            return "sidebar-nav-item" + (" active" if key == active_nav else "");
        }

        def is_executive() -> bool {
            return my_rank == "Executive";
        }

        # ── Case management ───────────────────────────────────────────

        def reorder_cases(case_list: list) -> None {
            nr = [];
            op = [];
            rest = [];
            for c in case_list {
                if c["outcome"] == "Needs Review" { nr.append(c); }
                elif c["outcome"] == "Open" { op.append(c); }
                else { rest.append(c); }
            }
            combined = [];
            for c in nr { combined.append(c); }
            for c in op { combined.append(c); }
            for c in rest { combined.append(c); }
            all_cases = case_list;
            fake_cases = combined;
            hist = [];
            for c in case_list { if c["outcome"] != "Open" { hist.append(c); } }
            history_records = hist;
        }

        async def apply_case_action() -> None {
            if not report_action or not history_selected or not history_selected["id"] { return; }
            cid = history_selected["id"];
            new_outcome = report_action;
            report_saving = True;
            result = await jacSpawn("update_case", "", {"id": cid, "outcome": new_outcome});
            report_saving = False;
            rpt = result and result["reports"] and result["reports"].length > 0 and result["reports"][0];
            if not rpt or not rpt["success"] { return; }
            updated_all = [];
            for c in all_cases {
                if c["id"] == cid {
                    c["outcome"] = new_outcome;
                }
                updated_all.append(c);
            }
            reorder_cases(updated_all);
            updated_sel = {};
            for k in Object.keys(history_selected) {
                updated_sel[k] = history_selected[k];
            }
            updated_sel["outcome"] = new_outcome;
            history_selected = updated_sel;
            report_action = "";
        }

        def toggle_report_metric(name: str) -> None {
            if report_open_metrics.indexOf(name) >= 0 {
                report_open_metrics = [m for m in report_open_metrics if m != name];
            } else {
                report_open_metrics = report_open_metrics + [name];
            }
        }

        def open_case_modal(c: dict) -> None {
            history_selected = c;
            report_open_metrics = [];
            triage_result = {};
            report_action = "";
        }

        # ── Personnel actions ─────────────────────────────────────────

        def open_add_modal() -> None {
            form_first    = "";
            form_last     = "";
            form_email    = "";
            form_username = "";
            form_rank     = "Operator";
            form_error    = "";
            show_add      = True;
        }

        def open_edit_modal(u: dict) -> None {
            edit_user     = u;
            form_first    = u["first_name"] or "";
            form_last     = u["last_name"] or "";
            form_email    = u["email"] or "";
            form_username = u["username"] or "";
            form_rank     = u["rank"] or "Operator";
            form_error    = "";
            open_menu     = "";
            show_edit     = True;
        }

        def close_modals() -> None {
            show_add  = False;
            show_edit = False;
        }

        async def submit_add() -> None {
            if not form_first.trim() or not form_last.trim() or not form_email.trim() or not form_username.trim() {
                form_error = "All fields are required.";
                return;
            }
            input_email = form_email.trim().toLowerCase();
            input_uname = form_username.trim().toLowerCase();
            for u in users {
                if (u["email"] or "").toLowerCase() == input_email {
                    form_error = "A user with that email already exists.";
                    return;
                }
                if (u["username"] or "").toLowerCase() == input_uname {
                    form_error = "A user with that username already exists.";
                    return;
                }
            }
            form_saving = True;
            form_error  = "";
            result = await jacSpawn("create_personnel", "", {
                "first_name": form_first.trim(),
                "last_name":  form_last.trim(),
                "email":      form_email.trim(),
                "username":   form_username.trim(),
                "rank":       form_rank
            });
            form_saving = False;
            rpt = result and result["reports"] and result["reports"].length > 0 and result["reports"][0];
            if rpt and rpt["success"] {
                new_user = rpt["user"];
                updated = [new_user];
                for eu in users { updated.append(eu); }
                users = updated;
                close_modals();
            } else {
                form_error = "Failed to create user.";
            }
        }

        async def submit_edit() -> None {
            if not form_first.trim() or not form_last.trim() or not form_email.trim() {
                form_error = "All fields are required.";
                return;
            }
            form_saving = True;
            form_error  = "";
            result = await jacSpawn("update_personnel", "", {
                "id":         edit_user["id"],
                "first_name": form_first.trim(),
                "last_name":  form_last.trim(),
                "email":      form_email.trim(),
                "username":   form_username.trim(),
                "rank":       form_rank
            });
            form_saving = False;
            rpt = result and result["reports"] and result["reports"].length > 0 and result["reports"][0];
            if rpt and rpt["success"] {
                updated = [];
                for u in users {
                    if u["id"] == edit_user["id"] {
                        u["first_name"] = form_first.trim();
                        u["last_name"]  = form_last.trim();
                        u["email"]      = form_email.trim();
                        u["username"]   = form_username.trim();
                        u["rank"]       = form_rank;
                    }
                    updated.append(u);
                }
                users = updated;
                close_modals();
            } else {
                form_error = "Failed to update user.";
            }
        }

        async def delete_user(uid: str) -> None {
            result = await jacSpawn("delete_personnel", "", {"id": uid});
            rpt = result and result["reports"] and result["reports"].length > 0 and result["reports"][0];
            if rpt and rpt["success"] {
                users = [u for u in users if u["id"] != uid];
            }
            open_menu = "";
        }

        # ── Policy actions ────────────────────────────────────────────

        def open_add_policy_modal() -> None {
            pol_name        = "";
            pol_desc        = "";
            pol_restriction = "";
            pol_rank        = "Operator";
            pol_error       = "";
            show_add_policy = True;
        }

        def open_edit_policy_modal(p: dict) -> None {
            edit_policy      = p;
            pol_name         = p["name"] or "";
            pol_desc         = p["description"] or "";
            pol_restriction  = p["restriction"] or "";
            pol_rank         = p["rank"] or "Operator";
            pol_error        = "";
            open_policy_menu = "";
            show_edit_policy = True;
        }

        def close_policy_modals() -> None {
            show_add_policy  = False;
            show_edit_policy = False;
        }

        async def submit_add_policy() -> None {
            if not pol_name.trim() or not pol_desc.trim() or not pol_restriction.trim() {
                pol_error = "All fields are required.";
                return;
            }
            pol_saving = True;
            pol_error  = "";
            result = await jacSpawn("create_policy", "", {
                "name":        pol_name.trim(),
                "description": pol_desc.trim(),
                "restriction": pol_restriction.trim(),
                "rank":        pol_rank
            });
            pol_saving = False;
            rpt = result and result["reports"] and result["reports"].length > 0 and result["reports"][0];
            if rpt and rpt["success"] {
                new_pol = rpt["policy"];
                updated = [new_pol];
                for ep in policies { updated.append(ep); }
                policies = updated;
                close_policy_modals();
            } else {
                pol_error = "Failed to create policy.";
            }
        }

        async def submit_edit_policy() -> None {
            if not pol_name.trim() or not pol_desc.trim() or not pol_restriction.trim() {
                pol_error = "All fields are required.";
                return;
            }
            pol_saving = True;
            pol_error  = "";
            result = await jacSpawn("update_policy", "", {
                "id":          edit_policy["id"],
                "name":        pol_name.trim(),
                "description": pol_desc.trim(),
                "restriction": pol_restriction.trim(),
                "rank":        pol_rank
            });
            pol_saving = False;
            rpt = result and result["reports"] and result["reports"].length > 0 and result["reports"][0];
            if rpt and rpt["success"] {
                updated = [];
                for p in policies {
                    if p["id"] == edit_policy["id"] {
                        p["name"]        = pol_name.trim();
                        p["description"] = pol_desc.trim();
                        p["restriction"] = pol_restriction.trim();
                        p["rank"]        = pol_rank;
                    }
                    updated.append(p);
                }
                policies = updated;
                close_policy_modals();
            } else {
                pol_error = "Failed to update policy.";
            }
        }

        async def delete_policy(pid: str) -> None {
            result = await jacSpawn("delete_policy", "", {"id": pid});
            rpt = result and result["reports"] and result["reports"].length > 0 and result["reports"][0];
            if rpt and rpt["success"] {
                policies = [p for p in policies if p["id"] != pid];
            }
            open_policy_menu = "";
        }

        # ── Sorting ───────────────────────────────────────────────────

        def toggle_personnel_sort(key: str) -> None {
            if personnel_sort_key == key {
                personnel_sort_asc = not personnel_sort_asc;
            } else {
                personnel_sort_key = key;
                personnel_sort_asc = True;
            }
        }

        def toggle_policies_sort(key: str) -> None {
            if policies_sort_key == key {
                policies_sort_asc = not policies_sort_asc;
            } else {
                policies_sort_key = key;
                policies_sort_asc = True;
            }
        }

        # ── Viz list helpers ──────────────────────────────────────────

        def get_viz_list() -> list {
            ts_label = viz_timescale == "daily" and "Day" or (viz_timescale == "weekly" and "Week" or "Month");
            if viz_timescale == "daily" {
                return [
                    {"title": "Misinformation Monitor", "data": misinfo_daily, "color": "#5A3E9B", "type": "line", "xLabel": ts_label, "yLabel": "Flow Rate (flags / day)"},
                    {"title": "Engagement Monitor", "data": engagement_daily, "color": "#E05C5C", "type": "area", "xLabel": ts_label, "yLabel": "Engagement Rate (%)"},
                    {"title": "Toxicity Trends", "data": toxicity_daily, "color": "#C89A5A", "type": "line", "xLabel": ts_label, "yLabel": "Toxicity Score"}
                ];
            }
            if viz_timescale == "weekly" {
                return [
                    {"title": "Misinformation Monitor", "data": misinfo_weekly, "color": "#5A3E9B", "type": "line", "xLabel": ts_label, "yLabel": "Flow Rate (flags / wk)"},
                    {"title": "Engagement Monitor", "data": engagement_weekly, "color": "#E05C5C", "type": "area", "xLabel": ts_label, "yLabel": "Engagement Rate (%)"},
                    {"title": "Toxicity Trends", "data": toxicity_weekly, "color": "#C89A5A", "type": "line", "xLabel": ts_label, "yLabel": "Toxicity Score"}
                ];
            }
            return [
                {"title": "Misinformation Monitor", "data": misinfo_monthly, "color": "#5A3E9B", "type": "line", "xLabel": ts_label, "yLabel": "Flow Rate (flags / mo)"},
                {"title": "Engagement Monitor", "data": engagement_monthly, "color": "#E05C5C", "type": "area", "xLabel": ts_label, "yLabel": "Engagement Rate (%)"},
                {"title": "Toxicity Trends", "data": toxicity_monthly, "color": "#C89A5A", "type": "line", "xLabel": ts_label, "yLabel": "Toxicity Score"}
            ];
        }

        def get_analytics_viz_list() -> list {
            ts_label = analytics_timescale == "daily" and "Day" or (analytics_timescale == "weekly" and "Week" or "Month");
            if analytics_timescale == "daily" {
                return [
                    {"title": "Misinformation Monitor", "data": misinfo_daily, "color": "#5A3E9B", "type": "line", "xLabel": ts_label, "yLabel": "Flow Rate (flags / day)"},
                    {"title": "Engagement Monitor", "data": engagement_daily, "color": "#E05C5C", "type": "area", "xLabel": ts_label, "yLabel": "Engagement Rate (%)"},
                    {"title": "Toxicity Trends", "data": toxicity_daily, "color": "#C89A5A", "type": "line", "xLabel": ts_label, "yLabel": "Toxicity Score"}
                ];
            }
            if analytics_timescale == "weekly" {
                return [
                    {"title": "Misinformation Monitor", "data": misinfo_weekly, "color": "#5A3E9B", "type": "line", "xLabel": ts_label, "yLabel": "Flow Rate (flags / wk)"},
                    {"title": "Engagement Monitor", "data": engagement_weekly, "color": "#E05C5C", "type": "area", "xLabel": ts_label, "yLabel": "Engagement Rate (%)"},
                    {"title": "Toxicity Trends", "data": toxicity_weekly, "color": "#C89A5A", "type": "line", "xLabel": ts_label, "yLabel": "Toxicity Score"}
                ];
            }
            return [
                {"title": "Misinformation Monitor", "data": misinfo_monthly, "color": "#5A3E9B", "type": "line", "xLabel": ts_label, "yLabel": "Flow Rate (flags / mo)"},
                {"title": "Engagement Monitor", "data": engagement_monthly, "color": "#E05C5C", "type": "area", "xLabel": ts_label, "yLabel": "Engagement Rate (%)"},
                {"title": "Toxicity Trends", "data": toxicity_monthly, "color": "#C89A5A", "type": "line", "xLabel": ts_label, "yLabel": "Toxicity Score"}
            ];
        }

        # ══════════════════════════════════════════════════════════════
        # MAIN RENDER
        # ══════════════════════════════════════════════════════════════

        rank_order = RANK_ORDER;

        return <div className="dashboard-shell">

            <aside className="sidebar">
                <div className="sidebar-user">
                    <div className="sidebar-avatar" style={{
                        "background": "var(--gradient-accent)",
                        "display": "flex",
                        "alignItems": "center",
                        "justifyContent": "center",
                        "color": "#fff",
                        "fontSize": "0.875rem",
                        "fontWeight": "700"
                    }}>
                        {my_username and my_username[0].toUpperCase() or "?"}
                    </div>
                    <div className="sidebar-user-info">
                        <span className="sidebar-user-name">{my_username or "Loading..."}</span>
                        <span className="sidebar-user-role">Trust & Safety Team</span>
                    </div>
                </div>

                <nav className="sidebar-nav">
                    <button className={nav_class("dashboard")} onClick={lambda -> None { active_nav = "dashboard"; }}>
                        <img src="/static/assets/icons/dashboard.svg" alt="" className="sidebar-nav-icon" />
                        Dashboard
                    </button>
                    <button className={nav_class("policies")} onClick={lambda -> None { active_nav = "policies"; }}>
                        <img src="/static/assets/icons/policy.svg" alt="" className="sidebar-nav-icon" />
                        Policies
                    </button>
                    <button className={nav_class("history")} onClick={lambda -> None { active_nav = "history"; }}>
                        <img src="/static/assets/icons/history.svg" alt="" className="sidebar-nav-icon" />
                        History
                    </button>
                    <button className={nav_class("analytics")} onClick={lambda -> None { active_nav = "analytics"; }}>
                        <img src="/static/assets/icons/analytics.svg" alt="" className="sidebar-nav-icon" />
                        Analytics
                    </button>
                    <button className={nav_class("personnel")} onClick={lambda -> None { active_nav = "personnel"; }}>
                        <img src="/static/assets/icons/personnel.svg" alt="" className="sidebar-nav-icon" />
                        Personnel
                    </button>
                    <button className={nav_class("settings")} onClick={lambda -> None { active_nav = "settings"; }}>
                        <img src="/static/assets/icons/clipboard.svg" alt="" className="sidebar-nav-icon" />
                        Settings
                    </button>
                </nav>

                <div className="sidebar-brand sidebar-brand--bottom">
                    <img src="/static/assets/reef_media_svg.png" alt="Reef Media" className="sidebar-brand-logo" />
                    <span className="sidebar-brand-name">Reef Media</span>
                </div>

                <button
                    className="sidebar-logout"
                    onClick={lambda -> None { handle_logout(); }}
                    disabled={signing_out}
                >
                    {signing_out and "Signing out..." or "Sign out"}
                </button>
            </aside>

            <main className="dashboard-main">

                {active_nav == "dashboard" and (
                    <DashboardTab
                        dashPill={dash_pill}
                        dashSearch={dash_search}
                        dashPage={dash_page}
                        vizPage={viz_page}
                        vizFullscreen={viz_fullscreen}
                        vizTimescale={viz_timescale}
                        openCardMenu={open_card_menu}
                        fakeCases={fake_cases}
                        fakeActors={fake_actors}
                        vizList={get_viz_list()}
                        onSetDashPill={lambda v: str -> None { dash_pill = v; }}
                        onSetDashSearch={lambda v: str -> None { dash_search = v; }}
                        onSetDashPage={lambda v: int -> None { dash_page = v; }}
                        onSetVizPage={lambda v: int -> None { viz_page = v; }}
                        onSetVizFullscreen={lambda v: int -> None { viz_fullscreen = v; }}
                        onSetVizTimescale={lambda v: str -> None { viz_timescale = v; }}
                        onSetOpenCardMenu={lambda v: str -> None { open_card_menu = v; }}
                        onInvestigateCase={lambda c: dict -> None { open_case_modal(c); }}
                        onInvestigateActor={lambda a: dict -> None { open_actor_modal(a); }}
                    />
                )}

                {active_nav == "policies" and (
                    <PoliciesTab
                        policies={policies}
                        isExecutive={is_executive()}
                        sortKey={policies_sort_key}
                        sortAsc={policies_sort_asc}
                        openPolicyMenu={open_policy_menu}
                        onToggleSort={lambda k: str -> None { toggle_policies_sort(k); }}
                        onSetOpenPolicyMenu={lambda v: str -> None { open_policy_menu = v; }}
                        onOpenAddModal={lambda -> None { open_add_policy_modal(); }}
                        onOpenEditModal={lambda p: dict -> None { open_edit_policy_modal(p); }}
                        onDeletePolicy={lambda id: str -> None { delete_policy(id); }}
                    />
                )}

                {active_nav == "history" and (
                    <HistoryTab
                        historyRecords={history_records}
                        openHistoryMenu={open_history_menu}
                        isExecutive={is_executive()}
                        onSetOpenHistoryMenu={lambda v: str -> None { open_history_menu = v; }}
                        onSelectCase={lambda c: dict -> None { open_case_modal(c); }}
                    />
                )}

                {active_nav == "analytics" and (
                    <AnalyticsTab
                        analyticsPage={analytics_page}
                        analyticsTimescale={analytics_timescale}
                        analyticsPill={analytics_pill}
                        pieHoverLabel={pie_hover_label}
                        actorsCollapsed={actors_collapsed}
                        actorProfileOpen={actor_profile_open}
                        actorProfilePill={actor_profile_pill}
                        actorTrendsData={actor_trends_data}
                        actorTrendsLoading={actor_trends_loading}
                        actorBrief={actor_brief}
                        actorBriefLoading={actor_brief_loading}
                        fakeActors={fake_actors}
                        allCases={all_cases}
                        themeSlices={theme_slices}
                        analyticsVizList={get_analytics_viz_list()}
                        onSetAnalyticsPage={lambda v: int -> None { analytics_page = v; }}
                        onSetAnalyticsTimescale={lambda v: str -> None { analytics_timescale = v; }}
                        onSetAnalyticsPill={lambda v: str -> None { analytics_pill = v; }}
                        onSetPieHoverLabel={lambda v: str -> None { pie_hover_label = v; }}
                        onSetActorsCollapsed={lambda v: bool -> None { actors_collapsed = v; }}
                        onSetActorProfileOpen={lambda v: dict -> None { actor_profile_open = v; actor_brief = {}; }}
                        onSetActorProfilePill={lambda v: str -> None { actor_profile_pill = v; }}
                        onLoadActorTrends={lambda id: str -> None { load_actor_trends(id); }}
                        onRunActorBrief={lambda id: str -> None { run_actor_brief(id); }}
                    />
                )}

                {active_nav == "personnel" and (
                    <PersonnelTab
                        users={users}
                        usersLoaded={users_loaded}
                        isExecutive={is_executive()}
                        sortKey={personnel_sort_key}
                        sortAsc={personnel_sort_asc}
                        openMenu={open_menu}
                        onToggleSort={lambda k: str -> None { toggle_personnel_sort(k); }}
                        onSetOpenMenu={lambda v: str -> None { open_menu = v; }}
                        onOpenAddModal={lambda -> None { open_add_modal(); }}
                        onOpenEditModal={lambda u: dict -> None { open_edit_modal(u); }}
                        onDeleteUser={lambda id: str -> None { delete_user(id); }}
                    />
                )}

                {active_nav == "settings" and (
                    <SettingsTab />
                )}
            </main>

            {show_add and (
                <UserModal
                    mode="add"
                    formFirst={form_first}
                    formLast={form_last}
                    formEmail={form_email}
                    formUsername={form_username}
                    formRank={form_rank}
                    formError={form_error}
                    formSaving={form_saving}
                    onSetFirst={lambda v: str -> None { form_first = v; }}
                    onSetLast={lambda v: str -> None { form_last = v; }}
                    onSetEmail={lambda v: str -> None { form_email = v; }}
                    onSetUsername={lambda v: str -> None { form_username = v; }}
                    onSetRank={lambda v: str -> None { form_rank = v; }}
                    onSubmit={lambda -> None { submit_add(); }}
                    onClose={lambda -> None { close_modals(); }}
                />
            )}

            {show_edit and (
                <UserModal
                    mode="edit"
                    formFirst={form_first}
                    formLast={form_last}
                    formEmail={form_email}
                    formUsername={form_username}
                    formRank={form_rank}
                    formError={form_error}
                    formSaving={form_saving}
                    onSetFirst={lambda v: str -> None { form_first = v; }}
                    onSetLast={lambda v: str -> None { form_last = v; }}
                    onSetEmail={lambda v: str -> None { form_email = v; }}
                    onSetUsername={lambda v: str -> None { form_username = v; }}
                    onSetRank={lambda v: str -> None { form_rank = v; }}
                    onSubmit={lambda -> None { submit_edit(); }}
                    onClose={lambda -> None { close_modals(); }}
                />
            )}

            {show_add_policy and (
                <PolicyModal
                    mode="add"
                    polName={pol_name}
                    polDesc={pol_desc}
                    polRestriction={pol_restriction}
                    polRank={pol_rank}
                    polError={pol_error}
                    polSaving={pol_saving}
                    onSetName={lambda v: str -> None { pol_name = v; }}
                    onSetDesc={lambda v: str -> None { pol_desc = v; }}
                    onSetRestriction={lambda v: str -> None { pol_restriction = v; }}
                    onSetRank={lambda v: str -> None { pol_rank = v; }}
                    onSubmit={lambda -> None { submit_add_policy(); }}
                    onClose={lambda -> None { close_policy_modals(); }}
                />
            )}

            {show_edit_policy and (
                <PolicyModal
                    mode="edit"
                    polName={pol_name}
                    polDesc={pol_desc}
                    polRestriction={pol_restriction}
                    polRank={pol_rank}
                    polError={pol_error}
                    polSaving={pol_saving}
                    onSetName={lambda v: str -> None { pol_name = v; }}
                    onSetDesc={lambda v: str -> None { pol_desc = v; }}
                    onSetRestriction={lambda v: str -> None { pol_restriction = v; }}
                    onSetRank={lambda v: str -> None { pol_rank = v; }}
                    onSubmit={lambda -> None { submit_edit_policy(); }}
                    onClose={lambda -> None { close_policy_modals(); }}
                />
            )}

            <ReportModal
                record={history_selected}
                fakeActors={fake_actors}
                policies={policies}
                reportOpenMetrics={report_open_metrics}
                reportAction={report_action}
                reportSaving={report_saving}
                triageLoading={triage_loading}
                triageResult={triage_result}
                myRank={my_rank}
                rankOrder={rank_order}
                onClose={lambda -> None { history_selected = {}; }}
                onToggleMetric={lambda name: str -> None { toggle_report_metric(name); }}
                onSetReportAction={lambda v: str -> None { report_action = v; }}
                onApplyAction={lambda -> None { apply_case_action(); }}
                onRunTriage={lambda id: str -> None { run_triage(id); }}
            />

            <ActorModal
                actor={actor_selected}
                allCases={all_cases}
                policies={policies}
                actorTrendsData={actor_trends_data}
                actorTrendsLoading={actor_trends_loading}
                actorAssessment={actor_assessment}
                actorAssessmentLoading={actor_assessment_loading}
                actorAction={actor_action}
                actorActionSaving={actor_action_saving}
                myRank={my_rank}
                rankOrder={rank_order}
                onClose={lambda -> None { actor_selected = {}; }}
                onSetActorAction={lambda v: str -> None { actor_action = v; }}
                onApplyActorAction={lambda -> None { apply_actor_action(); }}
                onRunActorAssessment={lambda id: str -> None { run_actor_assessment(id); }}
                onLoadActorTrends={lambda id: str -> None { load_actor_trends(id); }}
            />

        </div>;
    }
}
