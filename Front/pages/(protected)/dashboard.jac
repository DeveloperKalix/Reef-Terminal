# /dashboard — Trust & Safety Dashboard (protected)
# Tabs: Dashboard, Policies, History, Analytics, Personnel, Settings

cl import from "@jac/runtime" { jacLogout, jacIsLoggedIn, jacSpawn, useNavigate, __getLocalStorage, __getApiBaseUrl, useEffect }
cl import from "@components/Charts" { MiniChart, FullScreenChart, ThemePieChart }

cl {
    import "@styles/dashboard.css";

    def:pub page() -> JsxElement {
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

        # Current user rank (hardcoded for now; in production derive from JWT)
        has my_rank:       str   = "Executive";

        # Logged-in user display
        has my_username:   str   = "";

        # Dashboard tab state
        has dash_pill:     str   = "cases";
        has dash_search:   str   = "";
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

        # History tab state
        has history_selected:    dict = {};
        has open_history_menu:   str  = "";
        has report_open_metrics: list = [];
        has report_action:       str  = "";
        has report_saving:       bool = False;

        navigate = useNavigate();

        can with entry {
            if not jacIsLoggedIn() {
                navigate("/");
            }
        }

        if not jacIsLoggedIn() {
            return <div className="login-page"><p>Redirecting...</p></div>;
        }

        async def fetch_user_info() -> None {
            token = __getLocalStorage("jac_token");
            if not token { return; }
            base_url = __getApiBaseUrl();
            resp = await fetch(base_url + "/user/info", {
                "method": "GET",
                "headers": {"Authorization": "Bearer " + token, "Accept": "application/json"}
            });
            if resp.ok {
                payload = await resp.json();
                if payload["data"] and payload["data"]["username"] {
                    my_username = payload["data"]["username"];
                }
            }
        }

        useEffect(lambda -> None {
            fetch_user_info();
        }, []);

        # ── data loaders ───────────────────────────────────────────────
        async def load_users() -> None {
            result = await jacSpawn("list_personnel", "", {});
            if result and result["reports"] and result["reports"].length > 0 {
                data = result["reports"][0];
                if data["users"] and data["users"].length > 0 {
                    existing_emails = {};
                    for bu in data["users"] {
                        existing_emails[bu["email"] or ""] = True;
                    }
                    merged = data["users"].slice();
                    for ru in users {
                        if not existing_emails[ru["email"] or ""] {
                            merged.append(ru);
                        }
                    }
                    users = merged;
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

        can with entry {
            load_users();
            load_roles();
        }

        # ── actions ────────────────────────────────────────────────────
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

        def rank_css(rank: str) -> str {
            low = rank.toLowerCase();
            if low == "administrator" { return "rank-tag rank-tag--administrator"; }
            if low == "executive" { return "rank-tag rank-tag--executive"; }
            return "rank-tag rank-tag--operator";
        }

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

        # ══════════════════════════════════════════════════════════════
        # UNIFIED DATA MODEL
        # ══════════════════════════════════════════════════════════════

        # ── Team roster (seeds Personnel tab) ────────────────────────
        team_roster = [
            {"id": "u01", "first_name": "James",    "last_name": "Kowalski",  "email": "j.kowalski@reefmedia.ai",  "username": "jkowalski",  "rank": "Executive",     "initials": "JK", "avatar": "/static/assets/avatars/avatar1.svg"},
            {"id": "u02", "first_name": "Rachel",   "last_name": "Moreno",    "email": "r.moreno@reefmedia.ai",    "username": "rmoreno",    "rank": "Executive",     "initials": "RM", "avatar": "/static/assets/avatars/avatar2.svg"},
            {"id": "u03", "first_name": "Aisha",    "last_name": "Larsen",    "email": "a.larsen@reefmedia.ai",    "username": "alarsen",    "rank": "Administrator", "initials": "AL", "avatar": "/static/assets/avatars/avatar3.svg"},
            {"id": "u04", "first_name": "Samuel",   "last_name": "Park",      "email": "s.park@reefmedia.ai",      "username": "spark",      "rank": "Administrator", "initials": "SP", "avatar": "/static/assets/avatars/avatar4.svg"},
            {"id": "u05", "first_name": "Diana",    "last_name": "Novak",     "email": "d.novak@reefmedia.ai",     "username": "dnovak",     "rank": "Operator",      "initials": "DN", "avatar": "/static/assets/avatars/avatar1.svg"},
            {"id": "u06", "first_name": "Thomas",   "last_name": "Chen",      "email": "t.chen@reefmedia.ai",      "username": "tchen",      "rank": "Operator",      "initials": "TC", "avatar": "/static/assets/avatars/avatar2.svg"},
            {"id": "u07", "first_name": "Elena",    "last_name": "Vogt",      "email": "e.vogt@reefmedia.ai",      "username": "evogt",      "rank": "Operator",      "initials": "EV", "avatar": "/static/assets/avatars/avatar3.svg"},
            {"id": "u08", "first_name": "Marcus",   "last_name": "Obi",       "email": "m.obi@reefmedia.ai",       "username": "mobi",       "rank": "Administrator", "initials": "MO", "avatar": "/static/assets/avatars/avatar4.svg"},
            {"id": "u09", "first_name": "Fatima",   "last_name": "Al-Rashid", "email": "f.alrashid@reefmedia.ai",  "username": "falrashid",  "rank": "Operator",      "initials": "FA", "avatar": "/static/assets/avatars/avatar1.svg"},
            {"id": "u10", "first_name": "Liam",     "last_name": "Brennan",   "email": "l.brennan@reefmedia.ai",   "username": "lbrennan",   "rank": "Operator",      "initials": "LB", "avatar": "/static/assets/avatars/avatar2.svg"}
        ];

        can with entry {
            if users.length == 0 and users_loaded == False {
                users = team_roster.map(lambda u: dict -> dict {
                    return {
                        "id": u["id"],
                        "first_name": u["first_name"],
                        "last_name": u["last_name"],
                        "email": u["email"],
                        "username": u["username"],
                        "rank": u["rank"]
                    };
                });
                users_loaded = True;
            }
        }

        # ── Actors ───────────────────────────────────────────────────
        fake_actors = [
            {"id": "a1",  "handle": "@TruthLegion_Intel",   "type": "State-Linked IO",      "risk": 94, "posts": 18700, "avatar": "/static/assets/avatars/avatar1.svg"},
            {"id": "a2",  "handle": "@MarketWhispers0",     "type": "Financial Disinfo",     "risk": 81, "posts": 4320,  "avatar": "/static/assets/avatars/avatar2.svg"},
            {"id": "a3",  "handle": "@NaturalCuresNow",     "type": "Health Misinfo",        "risk": 73, "posts": 9150,  "avatar": "/static/assets/avatars/avatar3.svg"},
            {"id": "a4",  "handle": "@PatriotWatchUS",      "type": "Conspiracy Network",    "risk": 68, "posts": 12400, "avatar": "/static/assets/avatars/avatar4.svg"},
            {"id": "a5",  "handle": "@GazaRealFootage",     "type": "Conflict Disinfo",      "risk": 59, "posts": 6800,  "avatar": "/static/assets/avatars/avatar1.svg"},
            {"id": "a6",  "handle": "@CryptoAlpha_Sig",     "type": "Pump & Dump",           "risk": 47, "posts": 2100,  "avatar": "/static/assets/avatars/avatar2.svg"},
            {"id": "a7",  "handle": "@DeepStateFiles",      "type": "Conspiracy Network",    "risk": 86, "posts": 14200, "avatar": "/static/assets/avatars/avatar3.svg"},
            {"id": "a8",  "handle": "@VaxTruthNetwork",     "type": "Health Misinfo",        "risk": 77, "posts": 8400,  "avatar": "/static/assets/avatars/avatar4.svg"},
            {"id": "a9",  "handle": "@BalkanInfoWars",      "type": "State-Linked IO",       "risk": 91, "posts": 22100, "avatar": "/static/assets/avatars/avatar1.svg"},
            {"id": "a10", "handle": "@SovereignCitizen_X",  "type": "Anti-Government",       "risk": 62, "posts": 5600,  "avatar": "/static/assets/avatars/avatar2.svg"},
            {"id": "a11", "handle": "@ClimateHoax_Daily",   "type": "Science Denial",        "risk": 55, "posts": 3100,  "avatar": "/static/assets/avatars/avatar3.svg"},
            {"id": "a12", "handle": "@PharmaLeaks_Insider", "type": "Health Misinfo",        "risk": 70, "posts": 7200,  "avatar": "/static/assets/avatars/avatar4.svg"}
        ];

        # ── Thumbnails ───────────────────────────────────────────────
        thumb_pool = [
            "/static/assets/misinfo/zelensky.webp", "/static/assets/misinfo/fed.webp",
            "/static/assets/misinfo/vaccine.webp", "/static/assets/misinfo/fema.webp",
            "/static/assets/misinfo/gaza.webp", "/static/assets/misinfo/btc.webp",
            "/static/assets/misinfo/ballots.webp", "/static/assets/misinfo/covid.webp"
        ];

        # Monthly data
        misinfo_monthly = [
            {"name": "Jan", "value": 120}, {"name": "Feb", "value": 180},
            {"name": "Mar", "value": 150}, {"name": "Apr", "value": 310},
            {"name": "May", "value": 280}, {"name": "Jun", "value": 200},
            {"name": "Jul", "value": 240}
        ];
        engagement_monthly = [
            {"name": "Jan", "value": 45}, {"name": "Feb", "value": 62},
            {"name": "Mar", "value": 78}, {"name": "Apr", "value": 55},
            {"name": "May", "value": 130}, {"name": "Jun", "value": 95},
            {"name": "Jul", "value": 88}
        ];
        toxicity_monthly = [
            {"name": "Jan", "value": 320}, {"name": "Feb", "value": 290},
            {"name": "Mar", "value": 350}, {"name": "Apr", "value": 410},
            {"name": "May", "value": 380}, {"name": "Jun", "value": 300},
            {"name": "Jul", "value": 270}
        ];

        # Weekly data (previous 8 weeks ending on Fridays)
        misinfo_weekly = [
            {"name": "Jan 2", "value": 34}, {"name": "Jan 9", "value": 52},
            {"name": "Jan 16", "value": 41}, {"name": "Jan 23", "value": 68},
            {"name": "Jan 30", "value": 73}, {"name": "Feb 6", "value": 55},
            {"name": "Feb 13", "value": 48}, {"name": "Feb 20", "value": 62}
        ];
        engagement_weekly = [
            {"name": "Jan 2", "value": 12}, {"name": "Jan 9", "value": 18},
            {"name": "Jan 16", "value": 25}, {"name": "Jan 23", "value": 9},
            {"name": "Jan 30", "value": 38}, {"name": "Feb 6", "value": 31},
            {"name": "Feb 13", "value": 22}, {"name": "Feb 20", "value": 27}
        ];
        toxicity_weekly = [
            {"name": "Jan 2", "value": 85}, {"name": "Jan 9", "value": 72},
            {"name": "Jan 16", "value": 94}, {"name": "Jan 23", "value": 110},
            {"name": "Jan 30", "value": 98}, {"name": "Feb 6", "value": 76},
            {"name": "Feb 13", "value": 65}, {"name": "Feb 20", "value": 88}
        ];

        # Daily data (last 14 days)
        misinfo_daily = [
            {"name": "Feb 14", "value": 8}, {"name": "Feb 15", "value": 12},
            {"name": "Feb 16", "value": 5}, {"name": "Feb 17", "value": 14},
            {"name": "Feb 18", "value": 19}, {"name": "Feb 19", "value": 11},
            {"name": "Feb 20", "value": 7}, {"name": "Feb 21", "value": 16},
            {"name": "Feb 22", "value": 22}, {"name": "Feb 23", "value": 9},
            {"name": "Feb 24", "value": 13}, {"name": "Feb 25", "value": 18},
            {"name": "Feb 26", "value": 25}, {"name": "Feb 27", "value": 20}
        ];
        engagement_daily = [
            {"name": "Feb 14", "value": 3}, {"name": "Feb 15", "value": 5},
            {"name": "Feb 16", "value": 2}, {"name": "Feb 17", "value": 7},
            {"name": "Feb 18", "value": 9}, {"name": "Feb 19", "value": 4},
            {"name": "Feb 20", "value": 6}, {"name": "Feb 21", "value": 11},
            {"name": "Feb 22", "value": 8}, {"name": "Feb 23", "value": 3},
            {"name": "Feb 24", "value": 10}, {"name": "Feb 25", "value": 14},
            {"name": "Feb 26", "value": 6}, {"name": "Feb 27", "value": 9}
        ];
        toxicity_daily = [
            {"name": "Feb 14", "value": 42}, {"name": "Feb 15", "value": 38},
            {"name": "Feb 16", "value": 51}, {"name": "Feb 17", "value": 29},
            {"name": "Feb 18", "value": 63}, {"name": "Feb 19", "value": 47},
            {"name": "Feb 20", "value": 35}, {"name": "Feb 21", "value": 55},
            {"name": "Feb 22", "value": 44}, {"name": "Feb 23", "value": 31},
            {"name": "Feb 24", "value": 58}, {"name": "Feb 25", "value": 40},
            {"name": "Feb 26", "value": 67}, {"name": "Feb 27", "value": 49}
        ];

        def get_viz_list() -> list {
            if viz_timescale == "daily" {
                return [
                    {"title": "Misinformation Monitor", "data": misinfo_daily, "color": "#5A3E9B", "type": "line"},
                    {"title": "Engagement Monitor", "data": engagement_daily, "color": "#E05C5C", "type": "area"},
                    {"title": "Toxicity Trends", "data": toxicity_daily, "color": "#C89A5A", "type": "line"}
                ];
            }
            if viz_timescale == "weekly" {
                return [
                    {"title": "Misinformation Monitor", "data": misinfo_weekly, "color": "#5A3E9B", "type": "line"},
                    {"title": "Engagement Monitor", "data": engagement_weekly, "color": "#E05C5C", "type": "area"},
                    {"title": "Toxicity Trends", "data": toxicity_weekly, "color": "#C89A5A", "type": "line"}
                ];
            }
            return [
                {"title": "Misinformation Monitor", "data": misinfo_monthly, "color": "#5A3E9B", "type": "line"},
                {"title": "Engagement Monitor", "data": engagement_monthly, "color": "#E05C5C", "type": "area"},
                {"title": "Toxicity Trends", "data": toxicity_monthly, "color": "#C89A5A", "type": "line"}
            ];
        }

        def score_color(score: int) -> str {
            if score >= 50 { return "red"; }
            if score >= 20 { return "amber"; }
            return "green";
        }

        def get_analytics_viz_list() -> list {
            if analytics_timescale == "daily" {
                return [
                    {"title": "Misinformation Monitor", "data": misinfo_daily, "color": "#5A3E9B", "type": "line"},
                    {"title": "Engagement Monitor", "data": engagement_daily, "color": "#E05C5C", "type": "area"},
                    {"title": "Toxicity Trends", "data": toxicity_daily, "color": "#C89A5A", "type": "line"}
                ];
            }
            if analytics_timescale == "weekly" {
                return [
                    {"title": "Misinformation Monitor", "data": misinfo_weekly, "color": "#5A3E9B", "type": "line"},
                    {"title": "Engagement Monitor", "data": engagement_weekly, "color": "#E05C5C", "type": "area"},
                    {"title": "Toxicity Trends", "data": toxicity_weekly, "color": "#C89A5A", "type": "line"}
                ];
            }
            return [
                {"title": "Misinformation Monitor", "data": misinfo_monthly, "color": "#5A3E9B", "type": "line"},
                {"title": "Engagement Monitor", "data": engagement_monthly, "color": "#E05C5C", "type": "area"},
                {"title": "Toxicity Trends", "data": toxicity_monthly, "color": "#C89A5A", "type": "line"}
            ];
        }

        # ── Theme pie chart data ──────────────────────────────────────
        theme_slices = [
            {"name": "War & Conflict",    "value": 34, "color": "#E8C840", "insight": "The ongoing Ukraine-Russia war and the Gaza crisis continue to generate the highest volume of misinformation. State-linked information operations exploit fog-of-war uncertainty to push fabricated battlefield narratives and doctored casualty figures.", "trend": "+18% MoM", "trendUp": True},
            {"name": "Public Health",     "value": 22, "color": "#78C8E0", "insight": "Post-pandemic health misinformation remains persistent, driven by vaccine skepticism and distrust in pharmaceutical institutions. New mRNA therapeutics in clinical trials have reignited debunked narratives about gene modification and fertility.", "trend": "+7% MoM", "trendUp": True},
            {"name": "Climate Change",    "value": 16, "color": "#6DC87A", "insight": "Climate denial content surges around COP summits and extreme weather events. Recent record-breaking wildfires and floods triggered a wave of 'weather manipulation' conspiracy theories. Overall share has slightly declined as platform enforcement improves.", "trend": "-3% MoM", "trendUp": False},
            {"name": "Financial Markets", "value": 12, "color": "#E08A3A", "insight": "Pump-and-dump schemes and fabricated SEC filings targeting retail investors remain a steady threat. Crypto scam tokens leveraging deepfake celebrity endorsements saw a sharp increase following the latest Bitcoin rally.", "trend": "+24% MoM", "trendUp": True},
            {"name": "Elections",         "value": 9,  "color": "#E05C8C", "insight": "Election-related disinformation is cyclical, peaking in the months before major votes. Current activity centers on fabricated polling data and voter suppression messaging targeting minority communities ahead of upcoming midterms.", "trend": "+41% MoM", "trendUp": True},
            {"name": "Science & Tech",    "value": 4,  "color": "#A078D8", "insight": "Anti-5G and AI fearmongering represent a smaller but vocal slice. Claims about AI sentience and surveillance through consumer devices maintain a dedicated follower base but have limited mainstream reach.", "trend": "-8% MoM", "trendUp": False},
            {"name": "Immigration",       "value": 3,  "color": "#D87878", "insight": "Fabricated crime statistics attributed to immigrant populations and doctored images of border crossings circulate in niche political channels. Volume is low but engagement rates are disproportionately high.", "trend": "+5% MoM", "trendUp": True}
        ];

        def outcome_css(outcome: str) -> str {
            low = outcome.toLowerCase();
            if low == "confirmed" { return "outcome-tag outcome-tag--confirmed"; }
            if low == "escalated" { return "outcome-tag outcome-tag--escalated"; }
            if low == "dismissed" { return "outcome-tag outcome-tag--dismissed"; }
            if low == "open" { return "outcome-tag outcome-tag--open"; }
            if low == "needs review" { return "outcome-tag outcome-tag--needs-review"; }
            if outcome.startsWith("Policy:") { return "outcome-tag outcome-tag--policy"; }
            return "outcome-tag outcome-tag--review";
        }

        def metric_bar_color(val: int) -> str {
            if val <= 20 { return "#3DA04D"; }
            if val <= 35 { return "#6DC87A"; }
            if val <= 50 { return "#E8C840"; }
            if val <= 70 { return "#E0A83A"; }
            return "#E05C5C";
        }

        # ── Case titles (55 total) ────────────────────────────────────
        case_titles = [
            "Zelensky Orders Troops to Surrender",
            "Federal Reserve Announces Emergency Rate Cut to 0%",
            "New Study Links mRNA Boosters to Rising Infertility",
            "FEMA Insider Exposes Shadow Budget for Detention Sites",
            "Exclusive Footage: Airstrike Levels Hospital in Gaza",
            "SEC Greenlights New Bitcoin ETF — Token Surges 400%",
            "Thousands of Ballots Found Pre-Filled in Swing County",
            "Exposed: 5G Towers Installed Near Schools Without Permits",
            "Pentagon Confirms UFO Wreckage Recovered in Nevada",
            "WHO Whistleblower Leaks Internal Pandemic Playbook",
            "AI Deepfake of World Leader Triggers Market Crash",
            "Leaked Documents Reveal Secret NATO Withdrawal Plan",
            "Viral Claim: Tap Water Contains Mind-Altering Chemicals",
            "Fake Red Cross Alert Causes Mass Evacuation Panic",
            "Doctored Satellite Images Show Hidden Military Base",
            "Fabricated CDC Memo Orders Mandatory Quarantine Zones",
            "Forged UN Resolution on Climate Refugee Camps Circulates",
            "Manipulated Audio of Central Bank Governor Goes Viral",
            "Staged Protest Footage Attributed to Wrong Country",
            "False Flag Chemical Attack Claims Flood Social Media",
            "Synthetic News Anchor Reads Entirely Fabricated Report",
            "Coordinated Bot Campaign Targets Midterm Candidates",
            "Falsified Earthquake Warning Triggers Nationwide Panic",
            "Deepfake Video Shows Senator Accepting Bribe",
            "Cloned News Website Publishes Fake Assassination Report",
            "Manipulated Polling Data Surfaces Before State Election",
            "Fraudulent Charity Campaign Exploits Disaster Victims",
            "Fake Pharmaceutical Trial Results Posted on ArXiv",
            "AI-Generated War Footage Shared as Breaking News",
            "Counterfeit Government ID Scheme Advertised on Telegram",
            "Fabricated Embargo Notice Crashes Commodity Markets",
            "Synthetic Voice Message Impersonates Emergency Services",
            "Viral Conspiracy Links Vaccine to Population Tracking",
            "Doctored Court Documents Accuse Opposition Leader",
            "Fake Arrest Warrant Circulated Against Journalist",
            "Manufactured Riot Footage Used to Justify Crackdown",
            "Cloned Banking App Steals Credentials of 50K Users",
            "Disinformation Campaign Targets Refugee Communities",
            "Fabricated Trade Agreement Text Causes Currency Swing",
            "AI-Written Op-Ed Attributed to Deceased Nobel Laureate",
            "Phishing Campaign Disguised as Government Tax Refund",
            "Manipulated Weather Radar Images Spark Panic Buying",
            "Forged Military Communique Announces Ceasefire",
            "Synthetic Celebrity Endorsement Promotes Scam Token",
            "Fake Academic Paper Claims to Disprove Climate Change",
            "Coordinated Hashtag Hijack Spreads During Live Event",
            "Doctored Passport Scans Used in Human Trafficking Ring",
            "Fabricated Pipeline Explosion Report Spikes Oil Prices",
            "AI-Cloned Newscast Broadcast on Compromised Station",
            "Falsified Autopsy Report Goes Viral on Reddit",
            "Deepfake Audio of UN Secretary-General Leaked Online",
            "Fabricated Interpol Red Notice Targets Activist",
            "Synthetic Drone Footage Claims to Show Border Incursion",
            "Manipulated FDA Approval Letter for Untested Drug",
            "Cloned Embassy Website Issues Fake Travel Advisory"
        ];

        case_types = ["Video", "Image", "Text", "Network"];
        case_outcomes = ["Confirmed", "Escalated", "Dismissed", "Under Review", "Open"];

        metric_details = {
            "factuality": {
                "video": "At timestamp 01:23, the narrator claims the statement was made at a press conference on Jan 12, but no press conference occurred on that date. Cross-referencing with official White House schedules and AP wire feeds reveals no matching event. The quoted statistics at 02:45 cite a study that was retracted in November 2025.",
                "image": "The infographic claims the data originates from the Bureau of Labor Statistics Q4 2025 report. However, the actual BLS release for that quarter contains materially different figures. The bar chart exaggerates the delta by using a truncated y-axis starting at 80% rather than 0%.",
                "text": "Paragraph 3 attributes a direct quote to the WHO Director-General that does not appear in any WHO press briefing, transcript, or social media post. The cited report number (WHO/2026/114) does not exist in the WHO document registry.",
                "network": "The coordinated posting pattern cites a non-existent Reuters wire dispatch (ref: RTR-2026-0312). Reverse-image searches of the embedded media return results from unrelated 2024 events in different geographic regions.",
                "sources": ["Reuters Fact Check Archive — reuters.com/fact-check", "WHO Document Registry — apps.who.int/iris", "AP News Wire Archive — apnews.com/hub/ap-fact-check", "Bureau of Labor Statistics — bls.gov/data"]
            },
            "rhetoric": {
                "video": "The piece employs loaded language and emotional appeals throughout. At 00:42, the narrator uses the phrase 'silent genocide' without defining criteria. At 03:10, a dramatic musical sting accompanies an unsubstantiated claim, a classic appeal-to-fear technique.",
                "image": "The visual framing uses high-contrast red overlays and bold all-caps text ('EXPOSED', 'THEY DON'T WANT YOU TO KNOW') to trigger alarm. The image pairs unrelated photos side-by-side to imply a causal connection that the text never establishes.",
                "text": "The article uses ad hominem attacks against named researchers (para 5: 'bought-and-paid-for academics') without addressing their published findings. Paragraphs 7-9 employ whataboutism to deflect from the central claim.",
                "network": "Accounts in the network amplify messaging using identical phrasing templates with minor word substitutions. The language patterns show coordinated use of dog-whistle terminology and emotionally charged hashtags designed to bypass moderation filters.",
                "sources": ["Harvard Shorenstein Center — Misinformation Rhetoric Taxonomy", "First Draft News — Rhetorical Manipulation Indicators", "Oxford Internet Institute — Computational Propaganda Project"]
            },
            "logic": {
                "video": "The argument at 01:50 commits a post hoc ergo propter hoc fallacy, claiming temporal proximity proves causation. At 04:02, a false dichotomy is presented — 'either you believe this or you support the cover-up' — eliminating all nuanced positions.",
                "image": "The infographic draws a correlation between two unrelated datasets (5G tower installations and regional illness rates) using cherry-picked time windows. The implied causation ignores confounding variables documented in peer-reviewed epidemiological studies.",
                "text": "The article's central thesis rests on a hasty generalisation from a single anecdotal case (para 2) extrapolated to a population-level claim. The cited sample size (n=12) is insufficient for the statistical confidence implied.",
                "network": "The information cascade relies on circular sourcing — Account A cites Account B, which cites Account C, which cites Account A's original post. No independent primary source exists in the chain.",
                "sources": ["Stanford Encyclopedia of Philosophy — Logical Fallacies", "Purdue OWL — Logical Fallacies Guide", "Carl Sagan's Baloney Detection Kit — Criteria for Valid Argument"]
            },
            "argumentation": {
                "video": "The piece presents only one side of a multi-stakeholder issue, interviewing 4 critics and 0 supporters of the policy at 02:30-04:00. Key counter-evidence published in The Lancet (Dec 2025) is entirely omitted.",
                "image": "The graphic selectively quotes a 400-page government report, pulling 2 sentences from page 312 out of context. The full paragraph (not shown) contains qualifications that reverse the meaning of the excerpt.",
                "text": "The article acknowledges no limitations of its sources (para 1-4) and dismisses all opposing evidence as 'propaganda' (para 6) without engagement. The conclusion in para 10 does not follow from the premises established in paras 1-5.",
                "network": "The network employs a Gish Gallop strategy, flooding the discourse with numerous low-quality claims faster than they can be individually debunked. Each account introduces 3-4 new unverified claims per hour during peak engagement windows.",
                "sources": ["Argumentation Theory — van Eemeren & Grootendorst (2004)", "The Debunking Handbook 2020 — Lewandowsky et al.", "Media Bias/Fact Check — Methodology Notes"]
            },
            "overall": {
                "video": "Composite analysis indicates high probability of intentional manipulation. The combination of fabricated citations, emotional manipulation techniques, logical fallacies, and one-sided argumentation places this content in the 'high-risk' category for potential real-world harm.",
                "image": "The content exhibits hallmarks of coordinated disinformation: professionally produced visuals paired with verifiably false data, designed for maximum shareability. The lack of attribution and use of manipulative framing techniques suggest deliberate deception rather than honest error.",
                "text": "Overall assessment indicates systematic misrepresentation of source material combined with rhetorical strategies designed to undermine trust in institutional sources. The article functions as a 'gateway narrative' that funnels readers toward more extreme content.",
                "network": "Network-level analysis reveals a coordinated inauthentic behaviour campaign operating across multiple platforms with synchronized posting schedules, shared infrastructure, and consistent narrative framing. The operation likely involves both automated and human-operated accounts.",
                "sources": ["EU DisinfoLab — Methodology for Network Analysis", "Graphika — Coordinated Inauthentic Behaviour Reports", "DFRLab — Digital Forensic Research Lab Standards"]
            }
        };

        # ── Generate all_cases (55 records) ──────────────────────────
        has all_cases:      list = [];
        has history_records:list = [];
        has fake_cases:     list = [];

        can with entry {
            if all_cases.length == 0 {
                _seeds = [37,82,15,64,91,23,48,76,5,58,42,19,88,33,71,10,56,97,27,63,8,45,79,14,52,86,31,69,3,41,94,22,67,12,55,84,29,73,7,50,38,81,16,61,93,25,47,78,11,59,44,66,18,75,90];
                _actor_count = fake_actors.length;
                _roster_count = team_roster.length;

                for i in range(55) {
                    s = _seeds[i];
                    _mt = case_types[s % 4];
                    _mt_low = _mt.toLowerCase();

                    # Assign actor
                    _actor_idx = (s + i) % _actor_count;
                    _actor = fake_actors[_actor_idx];

                    # Assign 1-3 personnel from team_roster
                    _pers_count = (s % 3) + 1;
                    _pers = [];
                    for pi in range(_pers_count) {
                        _member = team_roster[(s + pi) % _roster_count];
                        _pers.append({"initials": _member["initials"], "avatar": _member["avatar"], "name": _member["first_name"] + " " + _member["last_name"]});
                    }

                    # Metrics
                    _f = 10 + (s * 89) % 91;
                    _r = 5 + (s * 53) % 91;
                    _l = 10 + (s * 71) % 91;
                    _a = 8 + (s * 43) % 91;
                    _o = (_f + _r + _l + _a) / 4;

                    # Date
                    _day = 1 + (s % 28);
                    _mon_idx = (s + i) % 4;
                    _mon = _mon_idx == 0 and "Nov" or (_mon_idx == 1 and "Dec" or (_mon_idx == 2 and "Jan" or "Feb"));
                    _yr = _mon_idx <= 1 and "2025" or "2026";
                    _dstr = _mon + " " + String(_day) + ", " + _yr;

                    # Status: cases 43-52 = Needs Review (have analysis but unreviewed), 53-54 = Open
                    _outcome = i >= 53 and "Open" or (i >= 43 and "Needs Review" or case_outcomes[(s + i * 3) % 4]);

                    # Score derived from overall metric
                    _score = Math.round(_o);

                    rec = {
                        "id": "RM-2026-" + String(1001 + i),
                        "title": case_titles[i],
                        "actor": _actor["handle"],
                        "actor_id": _actor["id"],
                        "media_type": _mt,
                        "personnel": _pers,
                        "outcome": _outcome,
                        "date": _dstr,
                        "score": _score,
                        "analyses": 200 + (s * 41) % 6000,
                        "thumb": thumb_pool[(s + i) % 8],
                        "uri": "https://evidence.reefmedia.ai/case/" + String(1001 + i),
                        "length": _mt == "Video" and (String(1 + s % 12) + ":" + String(10 + s % 50) + " min") or (_mt == "Text" and (String(800 + s * 31 % 4200) + " words") or (_mt == "Image" and (String(1 + s % 6) + " panels") or (String(3 + s % 18) + " nodes"))),
                        "ratings": 120 + (s * 17) % 4800,
                        "comments": 30 + (s * 13) % 1200,
                        "shares": 50 + (s * 23) % 9500,
                        "views": 1200 + (s * 41) % 98000,
                        "metrics": {
                            "factuality": _f,
                            "rhetoric": _r,
                            "logic": _l,
                            "argumentation": _a,
                            "overall": Math.round(_o)
                        },
                        "metric_details": {
                            "factuality": {"detail": metric_details["factuality"][_mt_low], "sources": metric_details["factuality"]["sources"]},
                            "rhetoric": {"detail": metric_details["rhetoric"][_mt_low], "sources": metric_details["rhetoric"]["sources"]},
                            "logic": {"detail": metric_details["logic"][_mt_low], "sources": metric_details["logic"]["sources"]},
                            "argumentation": {"detail": metric_details["argumentation"][_mt_low], "sources": metric_details["argumentation"]["sources"]},
                            "overall": {"detail": metric_details["overall"][_mt_low], "sources": metric_details["overall"]["sources"]}
                        }
                    };
                    all_cases.append(rec);
                }

                sorted_cases = [];
                for c in all_cases { if c["outcome"] == "Needs Review" { sorted_cases.append(c); } }
                for c in all_cases { if c["outcome"] == "Open" { sorted_cases.append(c); } }
                for c in all_cases { if c["outcome"] != "Needs Review" and c["outcome"] != "Open" { sorted_cases.append(c); } }
                fake_cases = sorted_cases;
                history_records = [c for c in all_cases if c["outcome"] != "Open"];
            }
        }

        def get_applicable_policies() -> list {
            my_level = rank_order[my_rank] or 0;
            result = [];
            for p in policies {
                pol_level = rank_order[p["rank"] or "Operator"] or 0;
                if my_level >= pol_level {
                    result.append(p);
                }
            }
            return result;
        }

        def apply_case_action() -> None {
            if not report_action or not history_selected or not history_selected["id"] { return; }
            cid = history_selected["id"];
            new_outcome = report_action;
            updated_all = [];
            for c in all_cases {
                if c["id"] == cid {
                    c["outcome"] = new_outcome;
                }
                updated_all.append(c);
            }
            all_cases = updated_all;
            reordered = [];
            for c in all_cases { if c["outcome"] == "Needs Review" { reordered.append(c); } }
            for c in all_cases { if c["outcome"] == "Open" { reordered.append(c); } }
            for c in all_cases { if c["outcome"] != "Needs Review" and c["outcome"] != "Open" { reordered.append(c); } }
            fake_cases = reordered;
            history_records = [c for c in all_cases if c["outcome"] != "Open"];
            history_selected["outcome"] = new_outcome;
            report_action = "";
        }

        def toggle_report_metric(name: str) -> None {
            if report_open_metrics.indexOf(name) >= 0 {
                report_open_metrics = [m for m in report_open_metrics if m != name];
            } else {
                report_open_metrics = report_open_metrics + [name];
            }
        }

        # ── fake policies ────────────────────────────────────────────
        can with entry {
            if policies.length == 0 {
                policies = [
                    {"id": "p1", "name": "Deepfake Takedown", "description": "Automatically flag and remove AI-generated synthetic media impersonating public figures.", "restriction": "Immediate removal", "rank": "Operator"},
                    {"id": "p2", "name": "Coordinated Inauthentic Behaviour", "description": "Detect and dismantle networks of accounts engaged in coordinated manipulation campaigns.", "restriction": "Account suspension", "rank": "Administrator"},
                    {"id": "p3", "name": "Health Misinformation", "description": "Restrict reach of content making unsubstantiated medical claims that endanger public health.", "restriction": "Reduced distribution", "rank": "Operator"},
                    {"id": "p4", "name": "Financial Fraud Prevention", "description": "Identify and remove content promoting pump-and-dump schemes, fake regulatory filings, or scam tokens.", "restriction": "Content removal + referral", "rank": "Administrator"},
                    {"id": "p5", "name": "Election Integrity", "description": "Enforce zero-tolerance policy on fabricated election content including fake ballots, false results, and voter suppression.", "restriction": "Immediate removal + escalation", "rank": "Executive"},
                    {"id": "p6", "name": "Violent Extremism", "description": "Remove content that recruits for, glorifies, or incites real-world violence by extremist groups.", "restriction": "Permanent ban", "rank": "Executive"},
                    {"id": "p7", "name": "Hate Speech — Protected Groups", "description": "Remove dehumanising or threatening content targeting individuals based on race, ethnicity, religion, or gender identity.", "restriction": "Strike + removal", "rank": "Operator"}
                ];
            }
        }

        def rank_req_css(rank: str) -> str {
            low = rank.toLowerCase();
            if low == "administrator" { return "rank-tag rank-tag--administrator"; }
            if low == "executive" { return "rank-tag rank-tag--executive"; }
            return "rank-tag rank-tag--operator";
        }

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

        def submit_add_policy() -> None {
            if not pol_name.trim() or not pol_desc.trim() or not pol_restriction.trim() {
                pol_error = "All fields are required.";
                return;
            }
            new_id = "p" + String(Date.now());
            new_pol = {
                "id": new_id,
                "name": pol_name.trim(),
                "description": pol_desc.trim(),
                "restriction": pol_restriction.trim(),
                "rank": pol_rank
            };
            policies = [new_pol] + policies;
            close_policy_modals();
        }

        def submit_edit_policy() -> None {
            if not pol_name.trim() or not pol_desc.trim() or not pol_restriction.trim() {
                pol_error = "All fields are required.";
                return;
            }
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
        }

        def delete_policy(pid: str) -> None {
            policies = [p for p in policies if p["id"] != pid];
            open_policy_menu = "";
        }

        # ── sorting helpers ───────────────────────────────────────────
        rank_order = {"Executive": 3, "Administrator": 2, "Operator": 1};

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

        def user_sort_val(u: dict, k: str) -> str {
            if k == "name" {
                return ((u["first_name"] or "") + " " + (u["last_name"] or "")).toLowerCase();
            }
            if k == "rank" {
                return String(rank_order[u["rank"] or "Operator"] or 0);
            }
            return (u[k] or "").toLowerCase();
        }

        def policy_sort_val(p: dict, k: str) -> str {
            if k == "rank" {
                return String(rank_order[p["rank"] or "Operator"] or 0);
            }
            return (p[k] or "").toLowerCase();
        }

        def sorted_users() -> list {
            if not personnel_sort_key { return users; }
            k = personnel_sort_key;
            asc = personnel_sort_asc;
            copy = users.slice();
            is_numeric = k == "rank";
            copy.sort(lambda a: dict, b: dict -> int {
                va = user_sort_val(a, k);
                vb = user_sort_val(b, k);
                if is_numeric {
                    na = Number(va);
                    nb = Number(vb);
                    return asc and (na - nb) or (nb - na);
                }
                if va < vb { return asc and -1 or 1; }
                if va > vb { return asc and 1 or -1; }
                return 0;
            });
            return copy;
        }

        def sorted_policies() -> list {
            if not policies_sort_key { return policies; }
            k = policies_sort_key;
            asc = policies_sort_asc;
            copy = policies.slice();
            is_numeric = k == "rank";
            copy.sort(lambda a: dict, b: dict -> int {
                va = policy_sort_val(a, k);
                vb = policy_sort_val(b, k);
                if is_numeric {
                    na = Number(va);
                    nb = Number(vb);
                    return asc and (na - nb) or (nb - na);
                }
                if va < vb { return asc and -1 or 1; }
                if va > vb { return asc and 1 or -1; }
                return 0;
            });
            return copy;
        }

        def sort_indicator(active_key: str, current_key: str, is_asc: bool) -> str {
            if active_key != current_key { return ""; }
            if is_asc { return " \u2191"; }
            return " \u2193";
        }

        # ── render: tab content ────────────────────────────────────────
        def render_dashboard_tab() -> JsxElement {
            items = dash_pill == "cases" and fake_cases or fake_actors;
            filtered = items;
            if dash_search.trim() {
                q = dash_search.trim().toLowerCase();
                if dash_pill == "cases" {
                    filtered = [c for c in fake_cases if c["title"].toLowerCase().indexOf(q) >= 0];
                } else {
                    filtered = [a for a in fake_actors if a["handle"].toLowerCase().indexOf(q) >= 0];
                }
            }

            cur_viz = get_viz_list();
            viz_start = viz_page * 2;
            visible_viz = cur_viz.slice(viz_start, viz_start + 2);
            has_more_viz = (viz_start + 2) < cur_viz.length;

            return <div className="dashboard-content-card" style={{"display": "flex", "flexDirection": "column", "gap": "var(--space-5)", "padding": "var(--space-6)"}}>

                <div className="dash-header">
                    <h2>Trust & Safety Dashboard</h2>
                    <div className="dash-controls">
                        <div className="dash-search">
                            <img src="/static/assets/icons/search.svg" alt="" className="dash-search__icon" />
                            <input
                                type="text"
                                placeholder="Search"
                                value={dash_search}
                                onChange={lambda e: any -> None { dash_search = e.target.value; }}
                            />
                        </div>
                    </div>
                </div>

                <div className={viz_fullscreen >= 0 and "dash-grid dash-grid--fullscreen" or "dash-grid"}>
                    <div className="cases-list">
                        <div style={{"display": "flex", "justifyContent": "center"}}>
                            <div className="pill-toggle">
                                <button
                                    className={"pill-toggle__btn" + (dash_pill == "cases" and " pill-toggle__btn--active" or "")}
                                    onClick={lambda -> None { dash_pill = "cases"; }}
                                    type="button"
                                >Cases</button>
                                <button
                                    className={"pill-toggle__btn" + (dash_pill == "actors" and " pill-toggle__btn--active" or "")}
                                    onClick={lambda -> None { dash_pill = "actors"; }}
                                    type="button"
                                >Bad Actors</button>
                            </div>
                        </div>
                        {dash_pill == "cases" and (
                            filtered.map(lambda c: dict -> JsxElement {
                                sc = score_color(c["score"]);
                                return <div className="case-card" key={c["id"]}>
                                    <img className="case-card__thumb" src={c["thumb"]} alt={c["title"]} />
                                    <div className="case-card__info">
                                        <p className="case-card__title">{c["title"]}</p>
                                        <p className="case-card__meta">
                                            {c["media_type"]} | {c["analyses"]} analyses
                                            <span className={outcome_css(c["outcome"])} style={{"marginLeft": "var(--space-2)"}}>{c["outcome"]}</span>
                                        </p>
                                        <div className="case-card__bar">
                                            <div className={"case-card__bar-fill bar-" + sc} style={{"width": c["score"] + "%"}} />
                                        </div>
                                    </div>
                                    <span className={"case-card__score score-" + sc}>{c["score"]}%</span>
                                    <div className="dot-menu-wrap">
                                        <button
                                            className="case-card__menu-btn"
                                            type="button"
                                            onClick={lambda -> None { open_card_menu = (open_card_menu == c["id"] and "" or c["id"]); }}
                                        >
                                            <img src="/static/assets/menu.svg" alt="menu" />
                                        </button>
                                        {open_card_menu == c["id"] and (
                                            <div className="dot-menu-dropdown">
                                                <button onClick={lambda -> None { history_selected = c; report_open_metrics = []; open_card_menu = ""; }}>Investigate</button>
                                                <button onClick={lambda -> None { open_card_menu = ""; }}>Edit</button>
                                                <button className="danger" onClick={lambda -> None { open_card_menu = ""; }}>Close Case</button>
                                            </div>
                                        )}
                                    </div>
                                </div>;
                            })
                        )}
                        {dash_pill == "actors" and (
                            filtered.map(lambda a: dict -> JsxElement {
                                sc = score_color(a["risk"]);
                                return <div className="case-card" key={a["id"]}>
                                    <img className="case-card__thumb case-card__thumb--avatar" src={a["avatar"]} alt={a["handle"]} />
                                    <div className="case-card__info">
                                        <p className="case-card__title">{a["handle"]}</p>
                                        <p className="case-card__meta">{a["type"]} | {a["posts"]} posts</p>
                                        <div className="case-card__bar">
                                            <div className={"case-card__bar-fill bar-" + sc} style={{"width": a["risk"] + "%"}} />
                                        </div>
                                    </div>
                                    <span className={"case-card__score score-" + sc}>{a["risk"]}%</span>
                                    <div className="dot-menu-wrap">
                                        <button
                                            className="case-card__menu-btn"
                                            type="button"
                                            onClick={lambda -> None { open_card_menu = (open_card_menu == a["id"] and "" or a["id"]); }}
                                        >
                                            <img src="/static/assets/menu.svg" alt="menu" />
                                        </button>
                                        {open_card_menu == a["id"] and (
                                            <div className="dot-menu-dropdown">
                                                <button onClick={lambda -> None { open_card_menu = ""; }}>Investigate</button>
                                                <button onClick={lambda -> None { open_card_menu = ""; }}>Edit</button>
                                                <button className="danger" onClick={lambda -> None { open_card_menu = ""; }}>Close Case</button>
                                            </div>
                                        )}
                                    </div>
                                </div>;
                            })
                        )}
                    </div>

                    {viz_fullscreen < 0 and (
                        <div className="viz-sidebar">
                            <div style={{"display": "flex", "alignItems": "center", "justifyContent": "space-between", "marginBottom": "var(--space-2)"}}>
                                <h3 className="analytics-header" style={{"margin": "0", "textAlign": "left"}}>Analytics</h3>
                                <select
                                    className="viz-timescale-select"
                                    value={viz_timescale}
                                    onChange={lambda e: any -> None { viz_timescale = e.target.value; viz_page = 0; }}
                                >
                                    <option value="monthly">Monthly</option>
                                    <option value="weekly">Weekly</option>
                                    <option value="daily">Daily</option>
                                </select>
                            </div>
                            {visible_viz.map(lambda v: dict, i: int -> JsxElement {
                                idx = viz_start + i;
                                return <div className="viz-card" key={v["title"] + viz_timescale}>
                                    <MiniChart data={v["data"]} color={v["color"]} type={v["type"]} height={140} />
                                    <div className="viz-card__header">
                                        <span className="viz-card__title">{v["title"]}</span>
                                        <button
                                            className="viz-card__expand"
                                            type="button"
                                            onClick={lambda -> None { viz_fullscreen = idx; }}
                                        >&#x26F6;</button>
                                    </div>
                                </div>;
                            })}
                            {has_more_viz and (
                                <div className="viz-carousel-nav">
                                    <button className="viz-carousel-btn" type="button" onClick={lambda -> None { viz_page = viz_page + 1; }}>
                                        <img src="/static/assets/icons/chevron.svg" alt="next" style={{"width": "11px", "height": "7px"}} />
                                    </button>
                                </div>
                            )}
                            {viz_page > 0 and (
                                <div className="viz-carousel-nav">
                                    <button className="viz-carousel-btn" type="button" onClick={lambda -> None { viz_page = viz_page - 1; }}>
                                        <img src="/static/assets/icons/chevron.svg" alt="prev" style={{"width": "11px", "height": "7px", "transform": "rotate(180deg)"}} />
                                    </button>
                                </div>
                            )}
                        </div>
                    )}
                </div>

                {viz_fullscreen >= 0 and (
                    <div className="viz-fullscreen" onClick={lambda -> None { viz_fullscreen = -1; }}>
                        <div className="viz-fullscreen__card" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                            <button className="viz-fullscreen__close" type="button" onClick={lambda -> None { viz_fullscreen = -1; }}>
                                <img src="/static/assets/icons/close.svg" alt="close" className="close-icon" />
                            </button>
                            <FullScreenChart
                                data={cur_viz[viz_fullscreen]["data"]}
                                color={cur_viz[viz_fullscreen]["color"]}
                                type={cur_viz[viz_fullscreen]["type"]}
                                title={cur_viz[viz_fullscreen]["title"]}
                            />
                        </div>
                    </div>
                )}

            </div>;
        }

        # ── Actor helpers ────────────────────────────────────────────
        def get_actor_cases() -> list {
            if actor_profile_open and actor_profile_open["handle"] {
                return [c for c in all_cases if c["actor"] == actor_profile_open["handle"]];
            }
            return [];
        }

        def render_actor_trust_metrics() -> JsxElement {
            risk = actor_profile_open["risk"];
            metrics_list = [
                {"label": "Factuality",     "val": 10 + (risk * 37) % 80},
                {"label": "Rhetoric",       "val": 5  + (risk * 53) % 70},
                {"label": "Logic",          "val": 10 + (risk * 71) % 85},
                {"label": "Argumentation",  "val": 8  + (risk * 43) % 75},
                {"label": "Overall",        "val": risk}
            ];
            return <div className="actor-profile-metrics">
                {metrics_list.map(lambda m: dict -> JsxElement {
                    return <div key={m["label"]} className="actor-metric-row">
                        <span className="actor-metric-row__label">{m["label"]}</span>
                        <div className="actor-metric-row__track">
                            <div className="actor-metric-row__fill" style={{"width": String(m["val"]) + "%", "background": metric_bar_color(m["val"])}} />
                        </div>
                        <span className="actor-metric-row__score">{String(m["val"])}%</span>
                    </div>;
                })}
            </div>;
        }

        def render_actor_history_list() -> JsxElement {
            actor_cases = get_actor_cases();
            if actor_cases.length == 0 {
                return <p className="actor-profile-empty">No case history.</p>;
            }
            return <div className="actor-profile-history">
                <div className="actor-profile-history__list">
                    {actor_cases.map(lambda c: dict -> JsxElement {
                        return <div key={c["id"]} className="actor-history-item">
                            <span className="actor-history-item__id">{c["id"]}</span>
                            <span className="actor-history-item__title">{c["title"]}</span>
                            <span className={outcome_css(c["outcome"])}>{c["outcome"]}</span>
                        </div>;
                    })}
                </div>
            </div>;
        }

        # ── Analytics tab (redesigned with themes pie, trends carousel, actors sidebar) ──
        def render_analytics_tab() -> JsxElement {
            a_viz = get_analytics_viz_list();
            a_total = a_viz.length;
            current = a_viz[analytics_page];

            # Find the hovered theme slice for the tooltip modal
            hovered_theme = {};
            if pie_hover_label {
                for ts in theme_slices {
                    if ts["name"] == pie_hover_label { hovered_theme = ts; }
                }
            }

            return <div className={"analytics-layout" + (actors_collapsed and " analytics-layout--expanded" or "")}>

                <div className="analytics-main">
                    <div className="analytics-main__header">
                        <h2 className="analytics-main__title">Misinformation Dashboard</h2>
                        <div className="analytics-pill-toggle">
                            <button
                                className={"analytics-pill-btn" + (analytics_pill == "themes" and " analytics-pill-btn--active" or "")}
                                type="button"
                                onClick={lambda -> None { analytics_pill = "themes"; }}
                            >Themes</button>
                            <button
                                className={"analytics-pill-btn" + (analytics_pill == "trends" and " analytics-pill-btn--active" or "")}
                                type="button"
                                onClick={lambda -> None { analytics_pill = "trends"; }}
                            >Trends</button>
                            <button
                                className={"analytics-pill-btn" + (analytics_pill == "impact" and " analytics-pill-btn--active" or "")}
                                type="button"
                                onClick={lambda -> None { analytics_pill = "impact"; }}
                            >Impact</button>
                        </div>
                    </div>

                    {analytics_pill == "themes" and (
                        <div className="analytics-themes-wrap">
                            <div className="analytics-pie-container">
                                <ThemePieChart
                                    data={theme_slices}
                                    activeLabel={pie_hover_label}
                                    onHoverSlice={lambda label: str -> None { pie_hover_label = label; }}
                                />

                                {hovered_theme and hovered_theme["name"] and (
                                    <div className="pie-tooltip-modal">
                                        <div className="pie-tooltip-modal__header">
                                            <span className="pie-tooltip-modal__dot" style={{"background": hovered_theme["color"]}} />
                                            <span className="pie-tooltip-modal__name">{hovered_theme["name"]}</span>
                                            <span className={"pie-tooltip-modal__trend" + (hovered_theme["trendUp"] and " pie-tooltip-modal__trend--up" or " pie-tooltip-modal__trend--down")}>
                                                {hovered_theme["trend"]}
                                            </span>
                                        </div>
                                        <p className="pie-tooltip-modal__text">{hovered_theme["insight"]}</p>
                                        <div className="pie-tooltip-modal__stat">
                                            <span>{String(hovered_theme["value"])}% of total cases</span>
                                        </div>
                                    </div>
                                )}
                            </div>
                        </div>
                    )}

                    {analytics_pill == "trends" and (
                        <div className="analytics-trends-wrap">
                            <div className="analytics-trends-controls">
                                <select
                                    className="viz-timescale-select"
                                    value={analytics_timescale}
                                    onChange={lambda e: any -> None { analytics_timescale = e.target.value; analytics_page = 0; }}
                                >
                                    <option value="monthly">Monthly</option>
                                    <option value="weekly">Weekly</option>
                                    <option value="daily">Daily</option>
                                </select>
                            </div>

                            <div className="analytics-full__carousel">
                                <button
                                    className="analytics-full__arrow analytics-full__arrow--left"
                                    type="button"
                                    disabled={analytics_page == 0}
                                    onClick={lambda -> None { analytics_page = analytics_page - 1; }}
                                >
                                    <img src="/static/assets/icons/chevron.svg" alt="prev" style={{"width": "14px", "height": "10px", "transform": "rotate(90deg)"}} />
                                </button>

                                <div className="analytics-full__chart" key={current["title"] + analytics_timescale}>
                                    <FullScreenChart
                                        data={current["data"]}
                                        color={current["color"]}
                                        type={current["type"]}
                                        title={current["title"]}
                                    />
                                </div>

                                <button
                                    className="analytics-full__arrow analytics-full__arrow--right"
                                    type="button"
                                    disabled={analytics_page >= a_total - 1}
                                    onClick={lambda -> None { analytics_page = analytics_page + 1; }}
                                >
                                    <img src="/static/assets/icons/chevron.svg" alt="next" style={{"width": "14px", "height": "10px", "transform": "rotate(-90deg)"}} />
                                </button>
                            </div>

                            <div className="analytics-full__dots">
                                {a_viz.map(lambda v: dict, i: int -> JsxElement {
                                    return <button
                                        key={v["title"]}
                                        className={"analytics-full__dot" + (i == analytics_page and " analytics-full__dot--active" or "")}
                                        type="button"
                                        onClick={lambda -> None { analytics_page = i; }}
                                    />;
                                })}
                            </div>
                        </div>
                    )}

                    {analytics_pill == "impact" and (
                        <div className="analytics-impact-wrap">
                            <div className="analytics-impact-grid">
                                <div className="analytics-impact-card">
                                    <span className="analytics-impact-card__value">2.4M</span>
                                    <span className="analytics-impact-card__label">Total Reach</span>
                                </div>
                                <div className="analytics-impact-card">
                                    <span className="analytics-impact-card__value">487K</span>
                                    <span className="analytics-impact-card__label">Engagements</span>
                                </div>
                                <div className="analytics-impact-card">
                                    <span className="analytics-impact-card__value">55</span>
                                    <span className="analytics-impact-card__label">Active Cases</span>
                                </div>
                                <div className="analytics-impact-card">
                                    <span className="analytics-impact-card__value">78%</span>
                                    <span className="analytics-impact-card__label">Resolution Rate</span>
                                </div>
                            </div>
                        </div>
                    )}
                </div>

                <div className={"analytics-actors-sidebar" + (actors_collapsed and " analytics-actors-sidebar--collapsed" or "")}>
                    <button
                        className="analytics-actors-toggle"
                        type="button"
                        onClick={lambda -> None { actors_collapsed = not actors_collapsed; }}
                    >
                        <img
                            src="/static/assets/icons/chevron.svg" alt="toggle"
                            className={"analytics-actors-toggle__icon" + (actors_collapsed and " analytics-actors-toggle__icon--collapsed" or "")}
                        />
                    </button>

                    {not actors_collapsed and (
                        <div className="analytics-actors-content">
                            <h3 className="analytics-actors-title">Negative Actors</h3>
                            <div className="analytics-actors-list">
                                {fake_actors.map(lambda a: dict -> JsxElement {
                                    risk_cls = a["risk"] >= 70 and "actor-risk--high" or (a["risk"] >= 40 and "actor-risk--mid" or "actor-risk--low");
                                    return <button
                                        key={a["id"]}
                                        className="analytics-actor-card"
                                        type="button"
                                        onClick={lambda -> None { actor_profile_open = a; actor_profile_pill = "trust"; }}
                                    >
                                        <img src={a["avatar"]} alt="" className="analytics-actor-card__avatar" />
                                        <span className="analytics-actor-card__handle">{a["handle"]}</span>
                                        <span className={"analytics-actor-card__risk " + risk_cls}>
                                            {a["risk"] >= 70 and "HIGH" or (a["risk"] >= 40 and "MID" or "LOW")}
                                        </span>
                                        <img src="/static/assets/icons/chevron.svg" alt="" className="analytics-actor-card__chevron" />
                                    </button>;
                                })}
                            </div>
                        </div>
                    )}
                </div>

                {actor_profile_open and actor_profile_open["id"] and (
                    <div className="actor-profile-overlay" onClick={lambda -> None { actor_profile_open = {}; }}>
                        <div className="actor-profile-card" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                            <button
                                className="actor-profile-close"
                                type="button"
                                onClick={lambda -> None { actor_profile_open = {}; }}
                            ><img src="/static/assets/icons/close.svg" alt="close" className="close-icon" /></button>

                            <h2 className="actor-profile__heading">Negative Actor</h2>

                            <img src={actor_profile_open["avatar"]} alt="" className="actor-profile__avatar" />
                            <h3 className="actor-profile__handle">{actor_profile_open["handle"]}</h3>
                            <p className="actor-profile__type">{actor_profile_open["type"]}</p>

                            <div className="actor-profile-pills">
                                <button className={"actor-profile-pill" + (actor_profile_pill == "trust" and " actor-profile-pill--active" or "")} type="button" onClick={lambda -> None { actor_profile_pill = "trust"; }}>Trust Factor</button>
                                <button className={"actor-profile-pill" + (actor_profile_pill == "history" and " actor-profile-pill--active" or "")} type="button" onClick={lambda -> None { actor_profile_pill = "history"; }}>History</button>
                                <button className={"actor-profile-pill" + (actor_profile_pill == "trends" and " actor-profile-pill--active" or "")} type="button" onClick={lambda -> None { actor_profile_pill = "trends"; }}>Trends</button>
                                <button className={"actor-profile-pill" + (actor_profile_pill == "reports" and " actor-profile-pill--active" or "")} type="button" onClick={lambda -> None { actor_profile_pill = "reports"; }}>Reports</button>
                            </div>

                            {actor_profile_pill == "trust" and render_actor_trust_metrics()}

                            {actor_profile_pill == "history" and render_actor_history_list()}

                            {actor_profile_pill == "trends" and (
                                <div className="actor-profile-trends">
                                    <p className="actor-profile-trends__info">Posts: {String(actor_profile_open["posts"])}</p>
                                    <p className="actor-profile-trends__info">Risk Score: {String(actor_profile_open["risk"])}</p>
                                </div>
                            )}

                            {actor_profile_pill == "reports" and (
                                <div className="actor-profile-reports">
                                    <p className="actor-profile-empty">Detailed reports coming soon.</p>
                                </div>
                            )}
                        </div>

                        <div className="actor-content-sidebar" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                            <h3 className="actor-content-sidebar__title">Unsubstantiated Content</h3>
                            <div className="actor-content-sidebar__list">
                                {get_actor_cases().map(lambda c: dict -> JsxElement {
                                    return <div key={c["id"]} className="actor-content-item">
                                        <img src={c["thumb"]} alt="" className="actor-content-item__thumb" />
                                        <div className="actor-content-item__info">
                                            <span className="actor-content-item__title">{c["title"]}</span>
                                        </div>
                                        <button className="case-card__menu-btn" type="button">
                                            <img src="/static/assets/menu.svg" alt="menu" />
                                        </button>
                                    </div>;
                                })}
                            </div>
                        </div>
                    </div>
                )}

            </div>;
        }

        # ── History tab ──────────────────────────────────────────────
        def render_history_tab() -> JsxElement {
            return <div className="dashboard-content-card">
                <div className="content-header">
                    <h2>Case History</h2>
                </div>

                <div className="history-table-wrap">
                    <table className="data-table history-table">
                        <thead>
                            <tr>
                                <th>Case ID</th>
                                <th>Media Title</th>
                                <th>Actor</th>
                                <th>Personnel</th>
                                <th>Outcome</th>
                                <th className="col-actions"></th>
                            </tr>
                        </thead>
                        <tbody>
                            {history_records.map(lambda rec: dict -> JsxElement {
                                return <tr key={rec["id"]} className="history-row" onClick={lambda -> None { history_selected = rec; report_open_metrics = []; }}>
                                    <td className="history-cell--id">{rec["id"]}</td>
                                    <td className="history-cell--title">{rec["title"]}</td>
                                    <td className="history-cell--actor">{rec["actor"]}</td>
                                    <td className="history-cell--personnel">
                                        <div className="personnel-avatars">
                                            {rec["personnel"].map(lambda p: dict, pi: int -> JsxElement {
                                                return <span className="personnel-badge" key={p["initials"] + String(pi)} title={p["initials"]}>
                                                    {p["initials"]}
                                                </span>;
                                            })}
                                        </div>
                                    </td>
                                    <td><span className={outcome_css(rec["outcome"])}>{rec["outcome"]}</span></td>
                                    <td className="col-actions" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                                        <div className="dot-menu-wrap">
                                            <button
                                                className="dot-menu-btn"
                                                type="button"
                                                onClick={lambda -> None { open_history_menu = (open_history_menu == rec["id"] and "" or rec["id"]); }}
                                            >
                                                <img src="/static/assets/menu.svg" alt="menu" style={{"width": "4px", "height": "18px", "opacity": "0.6"}} />
                                            </button>
                                            {open_history_menu == rec["id"] and (
                                                <div className="dot-menu-dropdown">
                                                    <button onClick={lambda -> None { history_selected = rec; report_open_metrics = []; open_history_menu = ""; }}>Examine</button>
                                                    <button
                                                        disabled={not is_executive()}
                                                        onClick={lambda -> None { open_history_menu = ""; }}
                                                    >Re-evaluate</button>
                                                </div>
                                            )}
                                        </div>
                                    </td>
                                </tr>;
                            })}
                        </tbody>
                    </table>
                </div>
            </div>;
        }

        # ── Full report modal ────────────────────────────────────────
        def render_report_modal() -> JsxElement {
            if not history_selected or not history_selected["id"] { return <span />; }
            rec = history_selected;
            m = rec["metrics"];
            md = rec["metric_details"];
            metric_names = ["factuality", "rhetoric", "logic", "argumentation", "overall"];
            metric_labels = {"factuality": "Factuality", "rhetoric": "Rhetoric", "logic": "Logic", "argumentation": "Argumentation", "overall": "Overall"};

            return <div className="report-overlay" onClick={lambda -> None { history_selected = {}; }}>
                <div className="report-card" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                    <button className="report-close" type="button" onClick={lambda -> None { history_selected = {}; }}>
                        <img src="/static/assets/icons/close.svg" alt="close" className="close-icon" />
                    </button>

                    <div className="report-header">
                        <span className="report-header__id">{rec["id"]}</span>
                        <h2 className="report-header__title">{rec["title"]}</h2>
                        <span className={outcome_css(rec["outcome"])}>{rec["outcome"]}</span>
                    </div>

                    <div className="report-bento">
                        <div className="report-bento__card">
                            <h4>Media Metadata</h4>
                            <div className="report-meta-grid">
                                <span className="report-meta__label">Type</span>
                                <span className="report-meta__value">{rec["media_type"]}</span>
                                <span className="report-meta__label">Length</span>
                                <span className="report-meta__value">{rec["length"]}</span>
                                <span className="report-meta__label">URI</span>
                                <a className="report-meta__value report-meta__link" href={rec["uri"]} target="_blank" rel="noreferrer">{rec["uri"]}</a>
                                <span className="report-meta__label">Date</span>
                                <span className="report-meta__value">{rec["date"]}</span>
                            </div>
                        </div>

                        <div className="report-bento__card">
                            <h4>Creator Profile</h4>
                            <div className="report-meta-grid">
                                <span className="report-meta__label">Handle</span>
                                <span className="report-meta__value">{rec["actor"]}</span>
                                <span className="report-meta__label">Category</span>
                                <span className="report-meta__value">{fake_actors.find(lambda a: dict -> bool { return a["handle"] == rec["actor"]; }) and fake_actors.find(lambda a: dict -> bool { return a["handle"] == rec["actor"]; })["type"] or "Unknown"}</span>
                                <span className="report-meta__label">Total Posts</span>
                                <span className="report-meta__value">{fake_actors.find(lambda a: dict -> bool { return a["handle"] == rec["actor"]; }) and String(fake_actors.find(lambda a: dict -> bool { return a["handle"] == rec["actor"]; })["posts"]) or "N/A"}</span>
                                <span className="report-meta__label">Risk Score</span>
                                <span className="report-meta__value">{fake_actors.find(lambda a: dict -> bool { return a["handle"] == rec["actor"]; }) and String(fake_actors.find(lambda a: dict -> bool { return a["handle"] == rec["actor"]; })["risk"]) + "%" or "N/A"}</span>
                            </div>
                        </div>
                    </div>

                    <div className="report-stats-row">
                        <div className="report-stat">
                            <span className="report-stat__value">{String(rec["ratings"])}</span>
                            <span className="report-stat__label">Ratings</span>
                        </div>
                        <div className="report-stat">
                            <span className="report-stat__value">{String(rec["comments"])}</span>
                            <span className="report-stat__label">Comments</span>
                        </div>
                        <div className="report-stat">
                            <span className="report-stat__value">{String(rec["shares"])}</span>
                            <span className="report-stat__label">Shares</span>
                        </div>
                        <div className="report-stat">
                            <span className="report-stat__value">{String(rec["views"])}</span>
                            <span className="report-stat__label">Views</span>
                        </div>
                    </div>

                    <div className="report-section-title">Analysis Metrics</div>

                    <div className="report-metrics">
                        {metric_names.map(lambda mn: str -> JsxElement {
                            score = m[mn];
                            is_open = report_open_metrics.indexOf(mn) >= 0;
                            bar_color = metric_bar_color(score);
                            detail_data = md[mn];

                            return <div className={"report-metric" + (is_open and " report-metric--open" or "")} key={mn}>
                                <button className="report-metric__row" type="button" onClick={lambda -> None { toggle_report_metric(mn); }}>
                                    <span className="report-metric__label">{metric_labels[mn]}</span>
                                    <div className="report-metric__bar-track">
                                        <div className="report-metric__bar-fill" style={{"width": String(score) + "%", "background": bar_color}} />
                                    </div>
                                    <span className="report-metric__score">{String(score)}%</span>
                                    <img
                                        src="/static/assets/icons/chevron.svg"
                                        alt="toggle"
                                        className={"report-metric__chevron" + (is_open and " report-metric__chevron--open" or "")}
                                    />
                                </button>
                                {is_open and (
                                    <div className="report-metric__detail">
                                        <p className="report-metric__analysis">{detail_data["detail"]}</p>
                                        <div className="report-metric__footnotes">
                                            <span className="report-metric__fn-title">Sources</span>
                                            {detail_data["sources"].map(lambda src: str, si: int -> JsxElement {
                                                return <span className="report-metric__fn" key={String(si)}>[{String(si + 1)}] {src}</span>;
                                            })}
                                        </div>
                                    </div>
                                )}
                            </div>;
                        })}
                    </div>

                    <div className="report-personnel-section">
                        <span className="report-section-title">Assigned Personnel</span>
                        <div className="personnel-avatars personnel-avatars--lg">
                            {rec["personnel"].map(lambda p: dict, pi: int -> JsxElement {
                                return <span className="personnel-badge personnel-badge--lg" key={p["initials"] + String(pi)} title={p["initials"]}>
                                    {p["initials"]}
                                </span>;
                            })}
                        </div>
                    </div>

                    {(rec["outcome"] == "Needs Review" or rec["outcome"] == "Open" or rec["outcome"] == "Under Review") and (
                        <div className="report-action-section">
                            <div className="report-section-title">Investigation Action</div>
                            <div className="report-action-row">
                                <select
                                    className="report-action-select"
                                    value={report_action}
                                    onChange={lambda e: any -> None { report_action = e.target.value; }}
                                >
                                    <option value="">Select action...</option>
                                    <option value="Confirmed">Confirm - Misinformation Verified</option>
                                    <option value="Escalated">Escalate - Requires Senior Review</option>
                                    <option value="Dismissed">Dismiss - No Policy Violation</option>
                                    <option value="Under Review">Keep Under Review</option>
                                    {get_applicable_policies().map(lambda pol: dict -> JsxElement {
                                        return <option key={pol["id"]} value={"Policy: " + pol["name"]}>
                                            {"Apply Policy \u2014 " + pol["name"]}
                                        </option>;
                                    })}
                                </select>
                                <button
                                    className="btn-modal-submit report-action-save"
                                    type="button"
                                    disabled={not report_action}
                                    onClick={lambda -> None { apply_case_action(); }}
                                >Save Decision</button>
                            </div>
                        </div>
                    )}
                </div>
            </div>;
        }

        def render_placeholder_tab(label: str) -> JsxElement {
            return <div className="dashboard-content-card">
                <h2 style={{"fontWeight": "800", "fontSize": "1.5rem", "color": "var(--color-text-heading)", "marginBottom": "0.5rem"}}>
                    {label}
                </h2>
                <p className="empty-state">This section is under development.</p>
            </div>;
        }

        # ── Policies tab ────────────────────────────────────────────────
        def render_policies_tab() -> JsxElement {
            return <div className="dashboard-content-card">
                <div className="content-header">
                    <h2>Policies</h2>
                    {is_executive() and (
                        <button className="btn-add" onClick={lambda -> None { open_add_policy_modal(); }} type="button">
                            + Add Policy
                        </button>
                    )}
                </div>

                {policies.length == 0 and (
                    <p className="empty-state">No policies defined yet.</p>
                ) or (
                    <table className="data-table">
                        <thead>
                            <tr>
                                <th className="sortable-th" onClick={lambda -> None { toggle_policies_sort("name"); }}>Name<span className="sort-arrow">{sort_indicator(policies_sort_key, "name", policies_sort_asc)}</span></th>
                                <th className="sortable-th" onClick={lambda -> None { toggle_policies_sort("description"); }}>Description<span className="sort-arrow">{sort_indicator(policies_sort_key, "description", policies_sort_asc)}</span></th>
                                <th className="sortable-th" onClick={lambda -> None { toggle_policies_sort("restriction"); }}>Restriction<span className="sort-arrow">{sort_indicator(policies_sort_key, "restriction", policies_sort_asc)}</span></th>
                                <th className="sortable-th" onClick={lambda -> None { toggle_policies_sort("rank"); }}>Rank Req.<span className="sort-arrow">{sort_indicator(policies_sort_key, "rank", policies_sort_asc)}</span></th>
                                <th className="col-actions"></th>
                            </tr>
                        </thead>
                        <tbody>
                            {sorted_policies().map(lambda p: dict -> JsxElement {
                                return <tr key={p["id"]}>
                                    <td style={{"fontWeight": "var(--font-weight-semibold)", "color": "var(--color-text-heading)"}}>{p["name"]}</td>
                                    <td style={{"maxWidth": "320px", "lineHeight": "1.4"}}>{p["description"]}</td>
                                    <td>{p["restriction"]}</td>
                                    <td><span className={rank_req_css(p["rank"] or "Operator")}>{p["rank"] or "Operator"}</span></td>
                                    <td className="col-actions">
                                        <div className="dot-menu-wrap">
                                            <button
                                                className="dot-menu-btn"
                                                type="button"
                                                onClick={lambda -> None { open_policy_menu = (open_policy_menu == p["id"] and "" or p["id"]); }}
                                            >
                                                <img src="/static/assets/menu.svg" alt="menu" style={{"width": "4px", "height": "18px", "opacity": "0.6"}} />
                                            </button>
                                            {open_policy_menu == p["id"] and (
                                                <div className="dot-menu-dropdown">
                                                    <button
                                                        onClick={lambda -> None { open_edit_policy_modal(p); }}
                                                        disabled={not is_executive()}
                                                    >Edit</button>
                                                    <button
                                                        className="danger"
                                                        onClick={lambda -> None { delete_policy(p["id"]); }}
                                                        disabled={not is_executive()}
                                                    >Delete</button>
                                                </div>
                                            )}
                                        </div>
                                    </td>
                                </tr>;
                            })}
                        </tbody>
                    </table>
                )}

                {not is_executive() and (
                    <p className="perm-notice">Only Executive-rank users can add, edit, or delete policies.</p>
                )}
            </div>;
        }

        # ── Modal: Add Policy ───────────────────────────────────────────
        def render_add_policy_modal() -> JsxElement {
            if not show_add_policy { return <span />; }
            return <div className="modal-overlay" onClick={lambda -> None { close_policy_modals(); }}>
                <div className="modal-card" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                    <button className="modal-close-btn" type="button" onClick={lambda -> None { close_policy_modals(); }}>
                        <img src="/static/assets/icons/close.svg" alt="close" className="close-icon" />
                    </button>
                    <h3>Add Policy</h3>
                    {pol_error and <div className="login-error">{pol_error}</div>}
                    <div className="modal-field">
                        <label>Name</label>
                        <input type="text" value={pol_name} onChange={lambda e: any -> None { pol_name = e.target.value; }} />
                    </div>
                    <div className="modal-field">
                        <label>Description</label>
                        <input type="text" value={pol_desc} onChange={lambda e: any -> None { pol_desc = e.target.value; }} />
                    </div>
                    <div className="modal-field">
                        <label>Restriction</label>
                        <input type="text" value={pol_restriction} onChange={lambda e: any -> None { pol_restriction = e.target.value; }} />
                    </div>
                    <div className="modal-field">
                        <label>Rank Requirement</label>
                        <select value={pol_rank} onChange={lambda e: any -> None { pol_rank = e.target.value; }}>
                            <option value="Operator">Operator</option>
                            <option value="Administrator">Administrator</option>
                            <option value="Executive">Executive</option>
                        </select>
                    </div>
                    <div className="modal-actions">
                        <button className="btn-modal-cancel" type="button" onClick={lambda -> None { close_policy_modals(); }}>Cancel</button>
                        <button className="btn-modal-submit" type="button" onClick={lambda -> None { submit_add_policy(); }}>
                            Add Policy
                        </button>
                    </div>
                </div>
            </div>;
        }

        # ── Modal: Edit Policy ──────────────────────────────────────────
        def render_edit_policy_modal() -> JsxElement {
            if not show_edit_policy { return <span />; }
            return <div className="modal-overlay" onClick={lambda -> None { close_policy_modals(); }}>
                <div className="modal-card" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                    <button className="modal-close-btn" type="button" onClick={lambda -> None { close_policy_modals(); }}>
                        <img src="/static/assets/icons/close.svg" alt="close" className="close-icon" />
                    </button>
                    <h3>Edit Policy</h3>
                    {pol_error and <div className="login-error">{pol_error}</div>}
                    <div className="modal-field">
                        <label>Name</label>
                        <input type="text" value={pol_name} onChange={lambda e: any -> None { pol_name = e.target.value; }} />
                    </div>
                    <div className="modal-field">
                        <label>Description</label>
                        <input type="text" value={pol_desc} onChange={lambda e: any -> None { pol_desc = e.target.value; }} />
                    </div>
                    <div className="modal-field">
                        <label>Restriction</label>
                        <input type="text" value={pol_restriction} onChange={lambda e: any -> None { pol_restriction = e.target.value; }} />
                    </div>
                    <div className="modal-field">
                        <label>Rank Requirement</label>
                        <select value={pol_rank} onChange={lambda e: any -> None { pol_rank = e.target.value; }}>
                            <option value="Operator">Operator</option>
                            <option value="Administrator">Administrator</option>
                            <option value="Executive">Executive</option>
                        </select>
                    </div>
                    <div className="modal-actions">
                        <button className="btn-modal-cancel" type="button" onClick={lambda -> None { close_policy_modals(); }}>Cancel</button>
                        <button className="btn-modal-submit" type="button" onClick={lambda -> None { submit_edit_policy(); }}>
                            Save Changes
                        </button>
                    </div>
                </div>
            </div>;
        }

        # ── Personnel tab ──────────────────────────────────────────────
        def render_personnel_tab() -> JsxElement {
            return <div className="dashboard-content-card">
                <div className="content-header">
                    <h2>Personnel</h2>
                    {is_executive() and (
                        <button className="btn-add" onClick={lambda -> None { open_add_modal(); }} type="button">
                            + Add User
                        </button>
                    )}
                </div>

                {not users_loaded and (
                    <p className="empty-state">Loading personnel...</p>
                ) or users.length == 0 and (
                    <p className="empty-state">No personnel found. Add your first team member.</p>
                ) or (
                    <table className="data-table">
                        <thead>
                            <tr>
                                <th className="sortable-th" onClick={lambda -> None { toggle_personnel_sort("name"); }}><img src="/static/assets/icons/star.svg" alt="" className="th-icon" />Name<span className="sort-arrow">{sort_indicator(personnel_sort_key, "name", personnel_sort_asc)}</span></th>
                                <th className="sortable-th" onClick={lambda -> None { toggle_personnel_sort("email"); }}><img src="/static/assets/icons/mail.svg" alt="" className="th-icon" />Email<span className="sort-arrow">{sort_indicator(personnel_sort_key, "email", personnel_sort_asc)}</span></th>
                                <th className="sortable-th" onClick={lambda -> None { toggle_personnel_sort("rank"); }}><img src="/static/assets/icons/tag.svg" alt="" className="th-icon" />Rank<span className="sort-arrow">{sort_indicator(personnel_sort_key, "rank", personnel_sort_asc)}</span></th>
                                <th className="col-actions"></th>
                            </tr>
                        </thead>
                        <tbody>
                            {sorted_users().map(lambda u: dict -> JsxElement {
                                return <tr key={u["id"]}>
                                    <td>{(u["first_name"] or "") + " " + (u["last_name"] or "")}</td>
                                    <td>{u["email"] or ""}</td>
                                    <td><span className={rank_css(u["rank"] or "Operator")}>{u["rank"] or "Operator"}</span></td>
                                    <td className="col-actions">
                                        <div className="dot-menu-wrap">
                                            <button
                                                className="dot-menu-btn"
                                                type="button"
                                                onClick={lambda -> None { open_menu = (open_menu == u["id"] and "" or u["id"]); }}
                                            >
                                                <img src="/static/assets/menu.svg" alt="menu" style={{"width": "4px", "height": "18px", "opacity": "0.6"}} />
                                            </button>
                                            {open_menu == u["id"] and (
                                                <div className="dot-menu-dropdown">
                                                    <button
                                                        onClick={lambda -> None { open_edit_modal(u); }}
                                                        disabled={not is_executive()}
                                                    >
                                                        Edit
                                                    </button>
                                                    <button
                                                        className="danger"
                                                        onClick={lambda -> None { delete_user(u["id"]); }}
                                                        disabled={not is_executive()}
                                                    >
                                                        Delete
                                                    </button>
                                                </div>
                                            )}
                                        </div>
                                    </td>
                                </tr>;
                            })}
                        </tbody>
                    </table>
                )}

                {not is_executive() and (
                    <p className="perm-notice">Only Executive-rank users can add, edit, or delete personnel.</p>
                )}
            </div>;
        }

        # ── Settings tab ───────────────────────────────────────────────
        def render_settings_tab() -> JsxElement {
            all_permissions = [
                "View Dashboard",
                "View Cases",
                "View Analytics",
                "View History",
                "Investigate Cases",
                "Apply Case Actions",
                "View Personnel",
                "Add Personnel",
                "Edit Personnel",
                "Delete Personnel",
                "View Policies",
                "Add Policies",
                "Edit Policies",
                "Delete Policies",
                "Manage Roles",
                "Export Data",
                "System Configuration"
            ];

            operator_perms = [
                "View Dashboard",
                "View Cases",
                "View Analytics",
                "View History",
                "Investigate Cases",
                "Apply Case Actions",
                "View Personnel",
                "View Policies"
            ];

            admin_perms = [
                "View Dashboard",
                "View Cases",
                "View Analytics",
                "View History",
                "Investigate Cases",
                "Apply Case Actions",
                "View Personnel",
                "Add Personnel",
                "Edit Personnel",
                "View Policies",
                "Add Policies",
                "Edit Policies",
                "Export Data"
            ];

            role_configs = [
                {"name": "Operator",      "perms": operator_perms, "is_exec": False},
                {"name": "Administrator", "perms": admin_perms,    "is_exec": False},
                {"name": "Executive",     "perms": all_permissions, "is_exec": True}
            ];

            return <div className="dashboard-content-card">
                <div className="content-header">
                    <h2>Settings</h2>
                </div>

                <div className="settings-roles-grid">
                    {role_configs.map(lambda rc: dict -> JsxElement {
                        return <div key={rc["name"]} className="settings-role-card">
                            <h3 className={"settings-role-card__title " + rank_css(rc["name"])}>{rc["name"]}</h3>

                            {rc["is_exec"] and (
                                <div className="settings-exec-blurb">
                                    <p>The Executive role has unrestricted access to all current and future platform capabilities. This includes full administrative control, policy enforcement, personnel management, and system configuration.</p>
                                </div>
                            )}

                            <div className="settings-perms-list">
                                {all_permissions.map(lambda perm: str -> JsxElement {
                                    has_it = rc["perms"].indexOf(perm) >= 0;
                                    return <div key={perm} className={"settings-perm-row" + (has_it and " settings-perm-row--granted" or " settings-perm-row--denied")}>
                                        <span className="settings-perm-row__icon">{has_it and "\u2713" or "\u2717"}</span>
                                        <span className="settings-perm-row__label">{perm}</span>
                                    </div>;
                                })}
                            </div>
                        </div>;
                    })}
                </div>
            </div>;
        }

        # ── Modal: Add User ────────────────────────────────────────────
        def render_add_modal() -> JsxElement {
            if not show_add { return <span />; }
            return <div className="modal-overlay" onClick={lambda -> None { close_modals(); }}>
                <div className="modal-card" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                    <button className="modal-close-btn" type="button" onClick={lambda -> None { close_modals(); }}>
                        <img src="/static/assets/icons/close.svg" alt="close" className="close-icon" />
                    </button>
                    <h3>Add Team Member</h3>
                    {form_error and <div className="login-error">{form_error}</div>}
                    <div className="modal-field">
                        <label>First Name</label>
                        <input
                            type="text"
                            value={form_first}
                            onChange={lambda e: any -> None { form_first = e.target.value; }}
                        />
                    </div>
                    <div className="modal-field">
                        <label>Last Name</label>
                        <input
                            type="text"
                            value={form_last}
                            onChange={lambda e: any -> None { form_last = e.target.value; }}
                        />
                    </div>
                    <div className="modal-field">
                        <label>Email</label>
                        <input
                            type="email"
                            value={form_email}
                            onChange={lambda e: any -> None { form_email = e.target.value; }}
                        />
                    </div>
                    <div className="modal-field">
                        <label>Username</label>
                        <input
                            type="text"
                            value={form_username}
                            onChange={lambda e: any -> None { form_username = e.target.value; }}
                        />
                    </div>
                    <div className="modal-field">
                        <label>Rank</label>
                        <select
                            value={form_rank}
                            onChange={lambda e: any -> None { form_rank = e.target.value; }}
                        >
                            <option value="Operator">Operator</option>
                            <option value="Administrator">Administrator</option>
                            <option value="Executive">Executive</option>
                        </select>
                    </div>
                    <div className="modal-actions">
                        <button className="btn-modal-cancel" type="button" onClick={lambda -> None { close_modals(); }}>Cancel</button>
                        <button className="btn-modal-submit" type="button" onClick={lambda -> None { submit_add(); }} disabled={form_saving}>
                            {form_saving and "Saving..." or "Add User"}
                        </button>
                    </div>
                </div>
            </div>;
        }

        # ── Modal: Edit User ───────────────────────────────────────────
        def render_edit_modal() -> JsxElement {
            if not show_edit { return <span />; }
            return <div className="modal-overlay" onClick={lambda -> None { close_modals(); }}>
                <div className="modal-card" onClick={lambda e: any -> None { e.stopPropagation(); }}>
                    <button className="modal-close-btn" type="button" onClick={lambda -> None { close_modals(); }}>
                        <img src="/static/assets/icons/close.svg" alt="close" className="close-icon" />
                    </button>
                    <h3>Edit Team Member</h3>
                    {form_error and <div className="login-error">{form_error}</div>}
                    <div className="modal-field">
                        <label>First Name</label>
                        <input
                            type="text"
                            value={form_first}
                            onChange={lambda e: any -> None { form_first = e.target.value; }}
                        />
                    </div>
                    <div className="modal-field">
                        <label>Last Name</label>
                        <input
                            type="text"
                            value={form_last}
                            onChange={lambda e: any -> None { form_last = e.target.value; }}
                        />
                    </div>
                    <div className="modal-field">
                        <label>Email</label>
                        <input
                            type="email"
                            value={form_email}
                            onChange={lambda e: any -> None { form_email = e.target.value; }}
                        />
                    </div>
                    <div className="modal-field">
                        <label>Username</label>
                        <input
                            type="text"
                            value={form_username}
                            onChange={lambda e: any -> None { form_username = e.target.value; }}
                        />
                    </div>
                    <div className="modal-field">
                        <label>Rank</label>
                        <select
                            value={form_rank}
                            onChange={lambda e: any -> None { form_rank = e.target.value; }}
                        >
                            <option value="Operator">Operator</option>
                            <option value="Administrator">Administrator</option>
                            <option value="Executive">Executive</option>
                        </select>
                    </div>
                    <div className="modal-actions">
                        <button className="btn-modal-cancel" type="button" onClick={lambda -> None { close_modals(); }}>Cancel</button>
                        <button className="btn-modal-submit" type="button" onClick={lambda -> None { submit_edit(); }} disabled={form_saving}>
                            {form_saving and "Saving..." or "Save Changes"}
                        </button>
                    </div>
                </div>
            </div>;
        }

        # ── main render ────────────────────────────────────────────────
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
                {active_nav == "dashboard"  and render_dashboard_tab()}
                {active_nav == "policies"   and render_policies_tab()}
                {active_nav == "history"    and render_history_tab()}
                {active_nav == "analytics"  and render_analytics_tab()}
                {active_nav == "personnel"  and render_personnel_tab()}
                {active_nav == "settings"   and render_settings_tab()}
            </main>

            {render_add_modal()}
            {render_edit_modal()}
            {render_add_policy_modal()}
            {render_edit_policy_modal()}
            {render_report_modal()}

        </div>;
    }
}
