"""
Seed Firestore with initial dashboard data.
Collections: personnel, actors, cases, policies, analytics

Run:  python seed_firestore.py
Requires FIREBASE_CREDENTIALS_PATH or GOOGLE_APPLICATION_CREDENTIALS env var,
or defaults to the service account JSON in this directory.
"""

import os
import math

CREDENTIALS_PATH = os.environ.get(
    "FIREBASE_CREDENTIALS_PATH",
    os.environ.get(
        "GOOGLE_APPLICATION_CREDENTIALS",
        os.path.join(os.path.dirname(__file__),
                     "reef-media-trust-panel-firebase-adminsdk-fbsvc-39a64f5023.json"),
    ),
)

import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate(CREDENTIALS_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()

# ──────────────────────────────────────────────────────────────────────────────
# Personnel
# ──────────────────────────────────────────────────────────────────────────────

team_roster = [
    {"id": "u01", "first_name": "James",   "last_name": "Kowalski",  "email": "j.kowalski@reefmedia.ai",  "username": "jkowalski",  "rank": "Executive",     "initials": "JK", "avatar": "/static/assets/avatars/avatar1.svg"},
    {"id": "u02", "first_name": "Rachel",  "last_name": "Moreno",    "email": "r.moreno@reefmedia.ai",    "username": "rmoreno",    "rank": "Executive",     "initials": "RM", "avatar": "/static/assets/avatars/avatar2.svg"},
    {"id": "u03", "first_name": "Aisha",   "last_name": "Larsen",    "email": "a.larsen@reefmedia.ai",    "username": "alarsen",    "rank": "Administrator", "initials": "AL", "avatar": "/static/assets/avatars/avatar3.svg"},
    {"id": "u04", "first_name": "Samuel",  "last_name": "Park",      "email": "s.park@reefmedia.ai",      "username": "spark",      "rank": "Administrator", "initials": "SP", "avatar": "/static/assets/avatars/avatar4.svg"},
    {"id": "u05", "first_name": "Diana",   "last_name": "Novak",     "email": "d.novak@reefmedia.ai",     "username": "dnovak",     "rank": "Operator",      "initials": "DN", "avatar": "/static/assets/avatars/avatar1.svg"},
    {"id": "u06", "first_name": "Thomas",  "last_name": "Chen",      "email": "t.chen@reefmedia.ai",      "username": "tchen",      "rank": "Operator",      "initials": "TC", "avatar": "/static/assets/avatars/avatar2.svg"},
    {"id": "u07", "first_name": "Elena",   "last_name": "Vogt",      "email": "e.vogt@reefmedia.ai",      "username": "evogt",      "rank": "Operator",      "initials": "EV", "avatar": "/static/assets/avatars/avatar3.svg"},
    {"id": "u08", "first_name": "Marcus",  "last_name": "Obi",       "email": "m.obi@reefmedia.ai",       "username": "mobi",       "rank": "Administrator", "initials": "MO", "avatar": "/static/assets/avatars/avatar4.svg"},
    {"id": "u09", "first_name": "Fatima",  "last_name": "Al-Rashid", "email": "f.alrashid@reefmedia.ai",  "username": "falrashid",  "rank": "Operator",      "initials": "FA", "avatar": "/static/assets/avatars/avatar1.svg"},
    {"id": "u10", "first_name": "Liam",    "last_name": "Brennan",   "email": "l.brennan@reefmedia.ai",   "username": "lbrennan",   "rank": "Operator",      "initials": "LB", "avatar": "/static/assets/avatars/avatar2.svg"},
]

# ──────────────────────────────────────────────────────────────────────────────
# Bad Actors
# ──────────────────────────────────────────────────────────────────────────────

actors = [
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
    {"id": "a12", "handle": "@PharmaLeaks_Insider", "type": "Health Misinfo",        "risk": 70, "posts": 7200,  "avatar": "/static/assets/avatars/avatar4.svg"},
]

# ──────────────────────────────────────────────────────────────────────────────
# Policies
# ──────────────────────────────────────────────────────────────────────────────

policies = [
    {"id": "p1", "name": "Deepfake Takedown", "description": "Automatically flag and remove AI-generated synthetic media impersonating public figures.", "restriction": "Immediate removal", "rank": "Operator"},
    {"id": "p2", "name": "Coordinated Inauthentic Behaviour", "description": "Detect and dismantle networks of accounts engaged in coordinated manipulation campaigns.", "restriction": "Account suspension", "rank": "Administrator"},
    {"id": "p3", "name": "Health Misinformation", "description": "Restrict reach of content making unsubstantiated medical claims that endanger public health.", "restriction": "Reduced distribution", "rank": "Operator"},
    {"id": "p4", "name": "Financial Fraud Prevention", "description": "Identify and remove content promoting pump-and-dump schemes, fake regulatory filings, or scam tokens.", "restriction": "Content removal + referral", "rank": "Administrator"},
    {"id": "p5", "name": "Election Integrity", "description": "Enforce zero-tolerance policy on fabricated election content including fake ballots, false results, and voter suppression.", "restriction": "Immediate removal + escalation", "rank": "Executive"},
    {"id": "p6", "name": "Violent Extremism", "description": "Remove content that recruits for, glorifies, or incites real-world violence by extremist groups.", "restriction": "Permanent ban", "rank": "Executive"},
    {"id": "p7", "name": "Hate Speech \u2014 Protected Groups", "description": "Remove dehumanising or threatening content targeting individuals based on race, ethnicity, religion, or gender identity.", "restriction": "Strike + removal", "rank": "Operator"},
]

# ──────────────────────────────────────────────────────────────────────────────
# Cases (55 records — mirrors the frontend generation logic exactly)
# ──────────────────────────────────────────────────────────────────────────────

case_titles = [
    "Zelensky Orders Troops to Surrender",
    "Federal Reserve Announces Emergency Rate Cut to 0%",
    "New Study Links mRNA Boosters to Rising Infertility",
    "FEMA Insider Exposes Shadow Budget for Detention Sites",
    "Exclusive Footage: Airstrike Levels Hospital in Gaza",
    "SEC Greenlights New Bitcoin ETF \u2014 Token Surges 400%",
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
    "Cloned Embassy Website Issues Fake Travel Advisory",
]

case_types = ["Video", "Image", "Text", "Network"]
case_outcomes_pool = ["Confirmed", "Escalated", "Dismissed", "Under Review", "Open"]

thumb_pool = [
    "/static/assets/misinfo/zelensky.webp", "/static/assets/misinfo/fed.webp",
    "/static/assets/misinfo/vaccine.webp",  "/static/assets/misinfo/fema.webp",
    "/static/assets/misinfo/gaza.webp",     "/static/assets/misinfo/btc.webp",
    "/static/assets/misinfo/ballots.webp",  "/static/assets/misinfo/covid.webp",
]

metric_details = {
    "factuality": {
        "video": "At timestamp 01:23, the narrator claims the statement was made at a press conference on Jan 12, but no press conference occurred on that date. Cross-referencing with official White House schedules and AP wire feeds reveals no matching event. The quoted statistics at 02:45 cite a study that was retracted in November 2025.",
        "image": "The infographic claims the data originates from the Bureau of Labor Statistics Q4 2025 report. However, the actual BLS release for that quarter contains materially different figures. The bar chart exaggerates the delta by using a truncated y-axis starting at 80% rather than 0%.",
        "text": "Paragraph 3 attributes a direct quote to the WHO Director-General that does not appear in any WHO press briefing, transcript, or social media post. The cited report number (WHO/2026/114) does not exist in the WHO document registry.",
        "network": "The coordinated posting pattern cites a non-existent Reuters wire dispatch (ref: RTR-2026-0312). Reverse-image searches of the embedded media return results from unrelated 2024 events in different geographic regions.",
        "sources": ["Reuters Fact Check Archive \u2014 reuters.com/fact-check", "WHO Document Registry \u2014 apps.who.int/iris", "AP News Wire Archive \u2014 apnews.com/hub/ap-fact-check", "Bureau of Labor Statistics \u2014 bls.gov/data"],
    },
    "rhetoric": {
        "video": "The piece employs loaded language and emotional appeals throughout. At 00:42, the narrator uses the phrase 'silent genocide' without defining criteria. At 03:10, a dramatic musical sting accompanies an unsubstantiated claim, a classic appeal-to-fear technique.",
        "image": "The visual framing uses high-contrast red overlays and bold all-caps text ('EXPOSED', 'THEY DON\u2019T WANT YOU TO KNOW') to trigger alarm. The image pairs unrelated photos side-by-side to imply a causal connection that the text never establishes.",
        "text": "The article uses ad hominem attacks against named researchers (para 5: 'bought-and-paid-for academics') without addressing their published findings. Paragraphs 7-9 employ whataboutism to deflect from the central claim.",
        "network": "Accounts in the network amplify messaging using identical phrasing templates with minor word substitutions. The language patterns show coordinated use of dog-whistle terminology and emotionally charged hashtags designed to bypass moderation filters.",
        "sources": ["Harvard Shorenstein Center \u2014 Misinformation Rhetoric Taxonomy", "First Draft News \u2014 Rhetorical Manipulation Indicators", "Oxford Internet Institute \u2014 Computational Propaganda Project"],
    },
    "logic": {
        "video": "The argument at 01:50 commits a post hoc ergo propter hoc fallacy, claiming temporal proximity proves causation. At 04:02, a false dichotomy is presented \u2014 'either you believe this or you support the cover-up' \u2014 eliminating all nuanced positions.",
        "image": "The infographic draws a correlation between two unrelated datasets (5G tower installations and regional illness rates) using cherry-picked time windows. The implied causation ignores confounding variables documented in peer-reviewed epidemiological studies.",
        "text": "The article's central thesis rests on a hasty generalisation from a single anecdotal case (para 2) extrapolated to a population-level claim. The cited sample size (n=12) is insufficient for the statistical confidence implied.",
        "network": "The information cascade relies on circular sourcing \u2014 Account A cites Account B, which cites Account C, which cites Account A's original post. No independent primary source exists in the chain.",
        "sources": ["Stanford Encyclopedia of Philosophy \u2014 Logical Fallacies", "Purdue OWL \u2014 Logical Fallacies Guide", "Carl Sagan's Baloney Detection Kit \u2014 Criteria for Valid Argument"],
    },
    "argumentation": {
        "video": "The piece presents only one side of a multi-stakeholder issue, interviewing 4 critics and 0 supporters of the policy at 02:30-04:00. Key counter-evidence published in The Lancet (Dec 2025) is entirely omitted.",
        "image": "The graphic selectively quotes a 400-page government report, pulling 2 sentences from page 312 out of context. The full paragraph (not shown) contains qualifications that reverse the meaning of the excerpt.",
        "text": "The article acknowledges no limitations of its sources (para 1-4) and dismisses all opposing evidence as 'propaganda' (para 6) without engagement. The conclusion in para 10 does not follow from the premises established in paras 1-5.",
        "network": "The network employs a Gish Gallop strategy, flooding the discourse with numerous low-quality claims faster than they can be individually debunked. Each account introduces 3-4 new unverified claims per hour during peak engagement windows.",
        "sources": ["Argumentation Theory \u2014 van Eemeren & Grootendorst (2004)", "The Debunking Handbook 2020 \u2014 Lewandowsky et al.", "Media Bias/Fact Check \u2014 Methodology Notes"],
    },
    "overall": {
        "video": "Composite analysis indicates high probability of intentional manipulation. The combination of fabricated citations, emotional manipulation techniques, logical fallacies, and one-sided argumentation places this content in the 'high-risk' category for potential real-world harm.",
        "image": "The content exhibits hallmarks of coordinated disinformation: professionally produced visuals paired with verifiably false data, designed for maximum shareability. The lack of attribution and use of manipulative framing techniques suggest deliberate deception rather than honest error.",
        "text": "Overall assessment indicates systematic misrepresentation of source material combined with rhetorical strategies designed to undermine trust in institutional sources. The article functions as a 'gateway narrative' that funnels readers toward more extreme content.",
        "network": "Network-level analysis reveals a coordinated inauthentic behaviour campaign operating across multiple platforms with synchronized posting schedules, shared infrastructure, and consistent narrative framing. The operation likely involves both automated and human-operated accounts.",
        "sources": ["EU DisinfoLab \u2014 Methodology for Network Analysis", "Graphika \u2014 Coordinated Inauthentic Behaviour Reports", "DFRLab \u2014 Digital Forensic Research Lab Standards"],
    },
}

# Analytics theme slices
theme_slices = [
    {"name": "War & Conflict",    "value": 34, "color": "#E8C840", "insight": "The ongoing Ukraine-Russia war and the Gaza crisis continue to generate the highest volume of misinformation. State-linked information operations exploit fog-of-war uncertainty to push fabricated battlefield narratives and doctored casualty figures.", "trend": "+18% MoM", "trendUp": True},
    {"name": "Public Health",     "value": 22, "color": "#78C8E0", "insight": "Post-pandemic health misinformation remains persistent, driven by vaccine skepticism and distrust in pharmaceutical institutions. New mRNA therapeutics in clinical trials have reignited debunked narratives about gene modification and fertility.", "trend": "+7% MoM", "trendUp": True},
    {"name": "Climate Change",    "value": 16, "color": "#6DC87A", "insight": "Climate denial content surges around COP summits and extreme weather events. Recent record-breaking wildfires and floods triggered a wave of 'weather manipulation' conspiracy theories. Overall share has slightly declined as platform enforcement improves.", "trend": "-3% MoM", "trendUp": False},
    {"name": "Financial Markets", "value": 12, "color": "#E08A3A", "insight": "Pump-and-dump schemes and fabricated SEC filings targeting retail investors remain a steady threat. Crypto scam tokens leveraging deepfake celebrity endorsements saw a sharp increase following the latest Bitcoin rally.", "trend": "+24% MoM", "trendUp": True},
    {"name": "Elections",         "value": 9,  "color": "#E05C8C", "insight": "Election-related disinformation is cyclical, peaking in the months before major votes. Current activity centers on fabricated polling data and voter suppression messaging targeting minority communities ahead of upcoming midterms.", "trend": "+41% MoM", "trendUp": True},
    {"name": "Science & Tech",    "value": 4,  "color": "#A078D8", "insight": "Anti-5G and AI fearmongering represent a smaller but vocal slice. Claims about AI sentience and surveillance through consumer devices maintain a dedicated follower base but have limited mainstream reach.", "trend": "-8% MoM", "trendUp": False},
    {"name": "Immigration",       "value": 3,  "color": "#D87878", "insight": "Fabricated crime statistics attributed to immigrant populations and doctored images of border crossings circulate in niche political channels. Volume is low but engagement rates are disproportionately high.", "trend": "+5% MoM", "trendUp": True},
]

# Analytics chart time-series
chart_data = {
    "misinfo_monthly": [
        {"name": "Jan", "value": 120}, {"name": "Feb", "value": 180},
        {"name": "Mar", "value": 150}, {"name": "Apr", "value": 310},
        {"name": "May", "value": 280}, {"name": "Jun", "value": 200},
        {"name": "Jul", "value": 240},
    ],
    "engagement_monthly": [
        {"name": "Jan", "value": 45}, {"name": "Feb", "value": 62},
        {"name": "Mar", "value": 78}, {"name": "Apr", "value": 55},
        {"name": "May", "value": 130}, {"name": "Jun", "value": 95},
        {"name": "Jul", "value": 88},
    ],
    "toxicity_monthly": [
        {"name": "Jan", "value": 320}, {"name": "Feb", "value": 290},
        {"name": "Mar", "value": 350}, {"name": "Apr", "value": 410},
        {"name": "May", "value": 380}, {"name": "Jun", "value": 300},
        {"name": "Jul", "value": 270},
    ],
    "misinfo_weekly": [
        {"name": "Jan 2", "value": 34}, {"name": "Jan 9", "value": 52},
        {"name": "Jan 16", "value": 41}, {"name": "Jan 23", "value": 68},
        {"name": "Jan 30", "value": 73}, {"name": "Feb 6", "value": 55},
        {"name": "Feb 13", "value": 48}, {"name": "Feb 20", "value": 62},
    ],
    "engagement_weekly": [
        {"name": "Jan 2", "value": 12}, {"name": "Jan 9", "value": 18},
        {"name": "Jan 16", "value": 25}, {"name": "Jan 23", "value": 9},
        {"name": "Jan 30", "value": 38}, {"name": "Feb 6", "value": 31},
        {"name": "Feb 13", "value": 22}, {"name": "Feb 20", "value": 27},
    ],
    "toxicity_weekly": [
        {"name": "Jan 2", "value": 85}, {"name": "Jan 9", "value": 72},
        {"name": "Jan 16", "value": 94}, {"name": "Jan 23", "value": 110},
        {"name": "Jan 30", "value": 98}, {"name": "Feb 6", "value": 76},
        {"name": "Feb 13", "value": 65}, {"name": "Feb 20", "value": 88},
    ],
    "misinfo_daily": [
        {"name": "Feb 14", "value": 8}, {"name": "Feb 15", "value": 12},
        {"name": "Feb 16", "value": 5}, {"name": "Feb 17", "value": 14},
        {"name": "Feb 18", "value": 19}, {"name": "Feb 19", "value": 11},
        {"name": "Feb 20", "value": 7}, {"name": "Feb 21", "value": 16},
        {"name": "Feb 22", "value": 22}, {"name": "Feb 23", "value": 9},
        {"name": "Feb 24", "value": 13}, {"name": "Feb 25", "value": 18},
        {"name": "Feb 26", "value": 25}, {"name": "Feb 27", "value": 20},
    ],
    "engagement_daily": [
        {"name": "Feb 14", "value": 3}, {"name": "Feb 15", "value": 5},
        {"name": "Feb 16", "value": 2}, {"name": "Feb 17", "value": 7},
        {"name": "Feb 18", "value": 9}, {"name": "Feb 19", "value": 4},
        {"name": "Feb 20", "value": 6}, {"name": "Feb 21", "value": 11},
        {"name": "Feb 22", "value": 8}, {"name": "Feb 23", "value": 3},
        {"name": "Feb 24", "value": 10}, {"name": "Feb 25", "value": 14},
        {"name": "Feb 26", "value": 6}, {"name": "Feb 27", "value": 9},
    ],
    "toxicity_daily": [
        {"name": "Feb 14", "value": 42}, {"name": "Feb 15", "value": 38},
        {"name": "Feb 16", "value": 51}, {"name": "Feb 17", "value": 29},
        {"name": "Feb 18", "value": 63}, {"name": "Feb 19", "value": 47},
        {"name": "Feb 20", "value": 35}, {"name": "Feb 21", "value": 55},
        {"name": "Feb 22", "value": 44}, {"name": "Feb 23", "value": 31},
        {"name": "Feb 24", "value": 58}, {"name": "Feb 25", "value": 40},
        {"name": "Feb 26", "value": 67}, {"name": "Feb 27", "value": 49},
    ],
}


def generate_cases():
    """Mirror the exact frontend case generation algorithm."""
    seeds = [37,82,15,64,91,23,48,76,5,58,42,19,88,33,71,10,56,97,27,63,8,45,79,14,52,86,31,69,3,41,94,22,67,12,55,84,29,73,7,50,38,81,16,61,93,25,47,78,11,59,44,66,18,75,90]
    actor_count = len(actors)
    roster_count = len(team_roster)
    cases = []

    for i in range(55):
        s = seeds[i]
        mt = case_types[s % 4]
        mt_low = mt.lower()

        actor_idx = (s + i) % actor_count
        actor = actors[actor_idx]

        pers_count = (s % 3) + 1
        pers = []
        for pi in range(pers_count):
            member = team_roster[(s + pi) % roster_count]
            pers.append({
                "initials": member["initials"],
                "avatar": member["avatar"],
                "name": member["first_name"] + " " + member["last_name"],
            })

        f = 10 + (s * 89) % 91
        r = 5 + (s * 53) % 91
        l = 10 + (s * 71) % 91
        a = 8 + (s * 43) % 91
        o = (f + r + l + a) / 4

        day = 1 + (s % 28)
        mon_idx = (s + i) % 4
        if mon_idx == 0:
            mon = "Nov"
        elif mon_idx == 1:
            mon = "Dec"
        elif mon_idx == 2:
            mon = "Jan"
        else:
            mon = "Feb"
        yr = "2025" if mon_idx <= 1 else "2026"
        dstr = f"{mon} {day}, {yr}"

        if i >= 53:
            outcome = "Open"
        elif i >= 43:
            outcome = "Needs Review"
        else:
            outcome = case_outcomes_pool[(s + i * 3) % 4]

        score = round(o)

        if mt == "Video":
            length_str = f"{1 + s % 12}:{10 + s % 50} min"
        elif mt == "Text":
            length_str = f"{800 + (s * 31) % 4200} words"
        elif mt == "Image":
            length_str = f"{1 + s % 6} panels"
        else:
            length_str = f"{3 + s % 18} nodes"

        rec = {
            "id": f"RM-2026-{1001 + i}",
            "title": case_titles[i],
            "actor": actor["handle"],
            "actor_id": actor["id"],
            "media_type": mt,
            "personnel": pers,
            "outcome": outcome,
            "date": dstr,
            "score": score,
            "analyses": 200 + (s * 41) % 6000,
            "thumb": thumb_pool[(s + i) % 8],
            "uri": f"https://evidence.reefmedia.ai/case/{1001 + i}",
            "length": length_str,
            "ratings": 120 + (s * 17) % 4800,
            "comments": 30 + (s * 13) % 1200,
            "shares": 50 + (s * 23) % 9500,
            "views": 1200 + (s * 41) % 98000,
            "metrics": {
                "factuality": f,
                "rhetoric": r,
                "logic": l,
                "argumentation": a,
                "overall": round(o),
            },
            "metric_details": {
                "factuality": {"detail": metric_details["factuality"][mt_low], "sources": metric_details["factuality"]["sources"]},
                "rhetoric":   {"detail": metric_details["rhetoric"][mt_low],   "sources": metric_details["rhetoric"]["sources"]},
                "logic":      {"detail": metric_details["logic"][mt_low],      "sources": metric_details["logic"]["sources"]},
                "argumentation": {"detail": metric_details["argumentation"][mt_low], "sources": metric_details["argumentation"]["sources"]},
                "overall":    {"detail": metric_details["overall"][mt_low],    "sources": metric_details["overall"]["sources"]},
            },
        }
        cases.append(rec)

    return cases


# ──────────────────────────────────────────────────────────────────────────────
# Seed
# ──────────────────────────────────────────────────────────────────────────────

# ──────────────────────────────────────────────────────────────────────────────
# Actor Trends (per-actor intelligence data)
# ──────────────────────────────────────────────────────────────────────────────

actor_trends = {
    "a1": {
        "actor_id": "a1",
        "threat_level": "HIGH",
        "audience_growth": "+42% YoY",
        "summary": "State-linked operation with 42% audience growth fueled by fabricated battlefield narratives during the Ukraine-Russia conflict.",
        "insights": [
            {"title": "Coordinated Amplification Network", "detail": "Linked to a cluster of 240+ sock-puppet accounts that synchronize posting within 90-second windows. Network analysis shows shared hosting infrastructure traced to a known IO farm.", "severity": "critical"},
            {"title": "Narrative Seeding", "detail": "Consistently publishes fabricated 'leaked documents' 12-48 hours before they appear on state media outlets, suggesting upstream coordination with editorial teams.", "severity": "critical"},
            {"title": "Audience Weaponisation", "detail": "Follower base grew 42% YoY; 68% of new followers are accounts less than 6 months old with bot-like engagement patterns.", "severity": "warning"},
            {"title": "Platform Evasion", "detail": "Rotates through backup accounts at a rate of 2.3 per month, re-establishing reach within 72 hours of each suspension.", "severity": "warning"},
        ],
        "trend_data": [
            {"name": "Sep", "posts": 1420, "reach": 890000, "risk": 88},
            {"name": "Oct", "posts": 1680, "reach": 1050000, "risk": 90},
            {"name": "Nov", "posts": 1850, "reach": 1180000, "risk": 91},
            {"name": "Dec", "posts": 2100, "reach": 1340000, "risk": 92},
            {"name": "Jan", "posts": 2350, "reach": 1520000, "risk": 93},
            {"name": "Feb", "posts": 2500, "reach": 1680000, "risk": 94},
        ],
    },
    "a2": {
        "actor_id": "a2",
        "threat_level": "HIGH",
        "audience_growth": "+58% YoY",
        "summary": "Financial disinfo account driving pump-and-dump schemes with fabricated SEC filings; audience surged 58% during the latest crypto rally.",
        "insights": [
            {"title": "Pump-and-Dump Timing", "detail": "Posts peak 4-6 hours before coordinated token purchases. Wallet analysis links the account to $2.3M in illicit profits across 14 separate schemes since Q3 2025.", "severity": "critical"},
            {"title": "Fabricated Regulatory Documents", "detail": "Published 8 fake SEC approval letters in the last quarter, each generating 500K+ impressions before takedown.", "severity": "critical"},
            {"title": "Retail Investor Targeting", "detail": "Content specifically targets users who follow legitimate financial news accounts, exploiting trust signals from adjacent content.", "severity": "warning"},
        ],
        "trend_data": [
            {"name": "Sep", "posts": 280, "reach": 120000, "risk": 72},
            {"name": "Oct", "posts": 410, "reach": 210000, "risk": 76},
            {"name": "Nov", "posts": 520, "reach": 310000, "risk": 78},
            {"name": "Dec", "posts": 680, "reach": 450000, "risk": 80},
            {"name": "Jan", "posts": 750, "reach": 520000, "risk": 81},
            {"name": "Feb", "posts": 810, "reach": 580000, "risk": 81},
        ],
    },
    "a3": {
        "actor_id": "a3",
        "threat_level": "HIGH",
        "audience_growth": "+22% YoY",
        "summary": "Health misinformation account promoting unproven 'natural cures' as alternatives to evidence-based medicine, with 22% audience growth.",
        "insights": [
            {"title": "Medical Harm Potential", "detail": "Promoted 6 unregulated supplements linked to adverse health outcomes reported to the FDA. Content consistently undermines vaccination uptake.", "severity": "critical"},
            {"title": "Influencer Amplification", "detail": "Content shared by 12 mid-tier wellness influencers (50K-200K followers each), extending reach by an estimated 4.2x beyond direct followers.", "severity": "warning"},
            {"title": "Seasonal Surge Pattern", "detail": "Posting volume spikes 180% during flu season and vaccine rollout periods, exploiting heightened public health anxiety.", "severity": "warning"},
        ],
        "trend_data": [
            {"name": "Sep", "posts": 680, "reach": 340000, "risk": 68},
            {"name": "Oct", "posts": 820, "reach": 420000, "risk": 70},
            {"name": "Nov", "posts": 950, "reach": 510000, "risk": 71},
            {"name": "Dec", "posts": 1100, "reach": 580000, "risk": 72},
            {"name": "Jan", "posts": 1050, "reach": 560000, "risk": 73},
            {"name": "Feb", "posts": 1150, "reach": 620000, "risk": 73},
        ],
    },
    "a4": {
        "actor_id": "a4",
        "threat_level": "MID",
        "audience_growth": "+15% YoY",
        "summary": "Conspiracy network operator weaving anti-government narratives with real news events; moderate but steady growth of 15% YoY.",
        "insights": [
            {"title": "Gateway Radicalisation", "detail": "Content analysis shows a deliberate pipeline: benign political commentary progresses to conspiracy theories within 3-5 interactions, converting 8% of casual followers into active sharers.", "severity": "warning"},
            {"title": "Cross-Platform Presence", "detail": "Maintains mirrored accounts on 6 platforms. When content is removed on one, followers are redirected within hours via link shorteners to alternatives.", "severity": "warning"},
            {"title": "Real-Event Exploitation", "detail": "Latches onto breaking news within 30 minutes, injecting conspiratorial framing before fact-checkers can respond.", "severity": "info"},
        ],
        "trend_data": [
            {"name": "Sep", "posts": 980, "reach": 480000, "risk": 62},
            {"name": "Oct", "posts": 1050, "reach": 510000, "risk": 64},
            {"name": "Nov", "posts": 1120, "reach": 540000, "risk": 65},
            {"name": "Dec", "posts": 1200, "reach": 580000, "risk": 66},
            {"name": "Jan", "posts": 1280, "reach": 620000, "risk": 67},
            {"name": "Feb", "posts": 1350, "reach": 660000, "risk": 68},
        ],
    },
    "a5": {
        "actor_id": "a5",
        "threat_level": "MID",
        "audience_growth": "+35% YoY",
        "summary": "Conflict disinformation account exploiting fog-of-war conditions; audience grew 35% during escalation of the Gaza crisis.",
        "insights": [
            {"title": "Doctored Visual Media", "detail": "41% of images posted were verified as manipulated or misattributed. Uses AI upscaling and re-dating to make old conflict footage appear current.", "severity": "critical"},
            {"title": "Emotional Engagement", "detail": "Posts containing graphic imagery receive 5.8x more shares than text-only content, deliberately maximising emotional contagion.", "severity": "warning"},
            {"title": "Declining Accuracy", "detail": "Fact-check debunking rate increased from 28% to 51% over the past 6 months, indicating increasingly careless fabrication.", "severity": "info"},
        ],
        "trend_data": [
            {"name": "Sep", "posts": 420, "reach": 180000, "risk": 50},
            {"name": "Oct", "posts": 580, "reach": 260000, "risk": 53},
            {"name": "Nov", "posts": 720, "reach": 380000, "risk": 55},
            {"name": "Dec", "posts": 810, "reach": 440000, "risk": 57},
            {"name": "Jan", "posts": 890, "reach": 510000, "risk": 58},
            {"name": "Feb", "posts": 950, "reach": 560000, "risk": 59},
        ],
    },
    "a6": {
        "actor_id": "a6",
        "threat_level": "LOW",
        "audience_growth": "+12% YoY",
        "summary": "Low-volume pump-and-dump operator with limited reach; growing slowly at 12% YoY but lacks the infrastructure for large-scale impact.",
        "insights": [
            {"title": "Small-Scale Schemes", "detail": "Promotes micro-cap tokens averaging $50K daily volume. Financial impact is limited but patterns match known pump-and-dump playbooks.", "severity": "info"},
            {"title": "Celebrity Deepfakes", "detail": "Uses AI-generated celebrity endorsements (detected in 3 of last 10 campaigns) but production quality is low and easily debunked.", "severity": "warning"},
            {"title": "Growing Sophistication", "detail": "Quality of fabricated materials has improved quarter-over-quarter, suggesting investment in better tools or collaboration with more capable actors.", "severity": "info"},
        ],
        "trend_data": [
            {"name": "Sep", "posts": 140, "reach": 32000, "risk": 40},
            {"name": "Oct", "posts": 160, "reach": 38000, "risk": 42},
            {"name": "Nov", "posts": 185, "reach": 44000, "risk": 43},
            {"name": "Dec", "posts": 210, "reach": 51000, "risk": 45},
            {"name": "Jan", "posts": 230, "reach": 58000, "risk": 46},
            {"name": "Feb", "posts": 250, "reach": 64000, "risk": 47},
        ],
    },
    "a7": {
        "actor_id": "a7",
        "threat_level": "HIGH",
        "audience_growth": "+27% YoY",
        "summary": "Prolific conspiracy network with 27% audience growth; specialises in 'deep state' narratives that erode institutional trust.",
        "insights": [
            {"title": "Institutional Erosion", "detail": "Content targets trust in judiciary, intelligence agencies, and electoral systems. Sentiment analysis shows measurable trust decline in communities with high exposure.", "severity": "critical"},
            {"title": "Merchandise & Monetisation", "detail": "Operates a parallel merchandise store generating estimated $180K/year, creating financial incentive to maintain and grow disinformation output.", "severity": "warning"},
            {"title": "Community Building", "detail": "Runs private discussion groups with 14K+ members where radicalisation occurs in semi-private spaces harder to monitor.", "severity": "warning"},
        ],
        "trend_data": [
            {"name": "Sep", "posts": 1100, "reach": 620000, "risk": 80},
            {"name": "Oct", "posts": 1250, "reach": 720000, "risk": 82},
            {"name": "Nov", "posts": 1380, "reach": 810000, "risk": 83},
            {"name": "Dec", "posts": 1500, "reach": 900000, "risk": 84},
            {"name": "Jan", "posts": 1620, "reach": 980000, "risk": 85},
            {"name": "Feb", "posts": 1750, "reach": 1060000, "risk": 86},
        ],
    },
    "a8": {
        "actor_id": "a8",
        "threat_level": "HIGH",
        "audience_growth": "+30% YoY",
        "summary": "Audience grew 30% this year from sensationalist content about vaccine conspiracies, directly undermining public health campaigns.",
        "insights": [
            {"title": "Audience Surge", "detail": "Follower count increased 30% YoY driven by anti-mRNA content during clinical trial announcements. Peak growth coincided with WHO vaccine recommendations.", "severity": "critical"},
            {"title": "Cross-Platform Amplification", "detail": "Content reposted on 4+ platforms within 2 hours of original post, indicating coordinated distribution network with at least 80 relay accounts.", "severity": "warning"},
            {"title": "Engagement Spike", "detail": "Average engagement rate 3.2x higher than baseline during health policy announcements. Comments show evidence of scripted talking points.", "severity": "warning"},
            {"title": "Scientific Mimicry", "detail": "Adopts academic formatting, fake DOIs, and fabricated peer-review citations to appear credible. 23% of followers believed content was from a medical institution.", "severity": "critical"},
        ],
        "trend_data": [
            {"name": "Sep", "posts": 580, "reach": 280000, "risk": 68},
            {"name": "Oct", "posts": 720, "reach": 380000, "risk": 72},
            {"name": "Nov", "posts": 840, "reach": 460000, "risk": 74},
            {"name": "Dec", "posts": 920, "reach": 520000, "risk": 75},
            {"name": "Jan", "posts": 1010, "reach": 590000, "risk": 76},
            {"name": "Feb", "posts": 1100, "reach": 650000, "risk": 77},
        ],
    },
    "a9": {
        "actor_id": "a9",
        "threat_level": "HIGH",
        "audience_growth": "+48% YoY",
        "summary": "High-volume state-linked IO operation with 48% audience growth; the most prolific actor in the network with 22K+ posts.",
        "insights": [
            {"title": "Industrial-Scale Output", "detail": "Averages 60+ posts per day across time zones inconsistent with a single operator, confirming team-based operation. Content follows shift patterns matching a known IO farm's working hours.", "severity": "critical"},
            {"title": "Geopolitical Trigger Response", "detail": "Response time to geopolitical events averages 18 minutes, faster than most legitimate news outlets, suggesting pre-prepared narrative templates.", "severity": "critical"},
            {"title": "Language Sophistication", "detail": "Posts in 4 languages (English, Serbian, Russian, Turkish) with native-level fluency, indicating a multilingual team or advanced AI translation pipeline.", "severity": "warning"},
        ],
        "trend_data": [
            {"name": "Sep", "posts": 1800, "reach": 1100000, "risk": 85},
            {"name": "Oct", "posts": 2100, "reach": 1350000, "risk": 87},
            {"name": "Nov", "posts": 2400, "reach": 1580000, "risk": 88},
            {"name": "Dec", "posts": 2650, "reach": 1780000, "risk": 89},
            {"name": "Jan", "posts": 2900, "reach": 1950000, "risk": 90},
            {"name": "Feb", "posts": 3100, "reach": 2100000, "risk": 91},
        ],
    },
    "a10": {
        "actor_id": "a10",
        "threat_level": "MID",
        "audience_growth": "+18% YoY",
        "summary": "Anti-government sovereign citizen content with 18% growth; audience is niche but highly engaged and prone to real-world action.",
        "insights": [
            {"title": "Real-World Mobilisation Risk", "detail": "Content has been cited in 3 documented incidents of confrontation with law enforcement in the past 6 months. Followers show higher propensity for offline action.", "severity": "critical"},
            {"title": "Legal Misinformation", "detail": "Promotes fraudulent legal theories ('strawman' arguments, UCC filings) that have led to followers incurring legal penalties. 14 documented court cases reference this account's content.", "severity": "warning"},
            {"title": "Stable Niche Audience", "detail": "Low churn rate (2.1%) suggests a deeply committed follower base resistant to deplatforming effects.", "severity": "info"},
        ],
        "trend_data": [
            {"name": "Sep", "posts": 380, "reach": 145000, "risk": 56},
            {"name": "Oct", "posts": 420, "reach": 160000, "risk": 58},
            {"name": "Nov", "posts": 460, "reach": 178000, "risk": 59},
            {"name": "Dec", "posts": 500, "reach": 195000, "risk": 60},
            {"name": "Jan", "posts": 540, "reach": 215000, "risk": 61},
            {"name": "Feb", "posts": 580, "reach": 235000, "risk": 62},
        ],
    },
    "a11": {
        "actor_id": "a11",
        "threat_level": "MID",
        "audience_growth": "-3% YoY",
        "summary": "Climate denial account losing audience (-3% YoY) as platform enforcement improves, but maintains a vocal core following.",
        "insights": [
            {"title": "Declining Reach", "detail": "Algorithmic demotion reduced average post reach by 38% since Q3 2025. Organic engagement is dropping as content fails to penetrate mainstream feeds.", "severity": "info"},
            {"title": "Event-Driven Spikes", "detail": "Despite overall decline, posts during extreme weather events see 6x normal engagement as users search for alternative explanations.", "severity": "warning"},
            {"title": "Pivot to Adjacent Topics", "detail": "Gradually shifting from pure climate denial to anti-regulation and 'green energy scam' narratives, attempting to capture a broader audience.", "severity": "info"},
        ],
        "trend_data": [
            {"name": "Sep", "posts": 320, "reach": 110000, "risk": 58},
            {"name": "Oct", "posts": 310, "reach": 105000, "risk": 57},
            {"name": "Nov", "posts": 290, "reach": 98000, "risk": 56},
            {"name": "Dec", "posts": 280, "reach": 92000, "risk": 55},
            {"name": "Jan", "posts": 270, "reach": 88000, "risk": 55},
            {"name": "Feb", "posts": 260, "reach": 85000, "risk": 55},
        ],
    },
    "a12": {
        "actor_id": "a12",
        "threat_level": "HIGH",
        "audience_growth": "+25% YoY",
        "summary": "Poses as pharmaceutical industry 'insider' leaking fabricated documents; 25% audience growth driven by distrust in Big Pharma.",
        "insights": [
            {"title": "Fabricated Insider Leaks", "detail": "Published 18 fake 'internal memos' in the last quarter, each formatted to mimic authentic pharmaceutical company communications. Average detection time by fact-checkers: 4.2 days.", "severity": "critical"},
            {"title": "Trust Exploitation", "detail": "Account bio and content style deliberately mimic legitimate whistleblower accounts, making differentiation difficult for average users. 31% of respondents in a survey could not distinguish from a real insider.", "severity": "warning"},
            {"title": "Stock Price Impact", "detail": "3 posts in the past 90 days correlated with measurable dips in pharmaceutical stock prices (0.8-2.1%), suggesting potential market manipulation motive.", "severity": "critical"},
        ],
        "trend_data": [
            {"name": "Sep", "posts": 480, "reach": 220000, "risk": 62},
            {"name": "Oct", "posts": 560, "reach": 280000, "risk": 65},
            {"name": "Nov", "posts": 640, "reach": 340000, "risk": 67},
            {"name": "Dec", "posts": 710, "reach": 400000, "risk": 68},
            {"name": "Jan", "posts": 780, "reach": 460000, "risk": 69},
            {"name": "Feb", "posts": 850, "reach": 520000, "risk": 70},
        ],
    },
}


def clear_collection(name):
    docs = db.collection(name).stream()
    batch = db.batch()
    count = 0
    for doc in docs:
        batch.delete(doc.reference)
        count += 1
        if count % 400 == 0:
            batch.commit()
            batch = db.batch()
    if count % 400 != 0:
        batch.commit()
    print(f"  Cleared {count} docs from '{name}'")


def seed():
    print("=== Seeding Firestore ===\n")

    # 1. Personnel
    print("[1/6] Personnel")
    clear_collection("personnel")
    for u in team_roster:
        db.collection("personnel").document(u["id"]).set(u)
    print(f"  Wrote {len(team_roster)} personnel docs\n")

    # 2. Actors
    print("[2/6] Actors")
    clear_collection("actors")
    for a in actors:
        db.collection("actors").document(a["id"]).set(a)
    print(f"  Wrote {len(actors)} actor docs\n")

    # 3. Policies
    print("[3/6] Policies")
    clear_collection("policies")
    for p in policies:
        db.collection("policies").document(p["id"]).set(p)
    print(f"  Wrote {len(policies)} policy docs\n")

    # 4. Cases
    print("[4/6] Cases")
    clear_collection("cases")
    cases = generate_cases()
    for c in cases:
        db.collection("cases").document(c["id"]).set(c)
    print(f"  Wrote {len(cases)} case docs\n")

    # 5. Analytics
    print("[5/6] Analytics")
    clear_collection("analytics")
    db.collection("analytics").document("theme_slices").set({"slices": theme_slices})
    db.collection("analytics").document("chart_data").set(chart_data)
    print("  Wrote 2 analytics docs\n")

    # 6. Actor Trends
    print("[6/6] Actor Trends")
    clear_collection("actor_trends")
    for aid, trend in actor_trends.items():
        db.collection("actor_trends").document(aid).set(trend)
    print(f"  Wrote {len(actor_trends)} actor_trends docs\n")

    print("=== Seeding complete ===")


if __name__ == "__main__":
    seed()
