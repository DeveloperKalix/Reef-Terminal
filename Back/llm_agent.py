"""
LLM Agent module for Trust & Safety Dashboard.

Uses Google Gemini 2.0 Flash via Vertex AI, authenticated with the same
Firebase service account credentials. No extra API keys required.

Functions:
  - triage_case(case, actor, policies) -> dict
  - summarize_actor(actor, trends, cases) -> dict
  - assess_actor(actor, trends, cases, policies) -> dict
"""

import json
import os
from typing import Optional

_client = None

GCP_PROJECT = "reef-media-trust-panel"
GCP_LOCATION = "us-central1"
MODEL_ID = os.environ.get("GEMINI_MODEL_ID", "gemini-2.5-flash")


def _get_client():
    global _client
    if _client is not None:
        return _client

    from google import genai

    creds_path = os.environ.get("FIREBASE_CREDENTIALS_PATH") or os.environ.get(
        "GOOGLE_APPLICATION_CREDENTIALS"
    )
    if creds_path:
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = creds_path

    _client = genai.Client(
        vertexai=True, project=GCP_PROJECT, location=GCP_LOCATION
    )
    return _client


def _call_gemini(system_instruction: str, user_message: str) -> str:
    client = _get_client()
    response = client.models.generate_content(
        model=MODEL_ID,
        contents=user_message,
        config={
            "system_instruction": system_instruction,
            "temperature": 0.3,
            "max_output_tokens": 4096,
        },
    )
    return response.text.strip()


def _parse_json_response(text: str) -> Optional[dict]:
    cleaned = text
    if cleaned.startswith("```"):
        lines = cleaned.split("\n")
        lines = [l for l in lines if not l.strip().startswith("```")]
        cleaned = "\n".join(lines)
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        return None


# ── Feature A: Case Triage ────────────────────────────────────────────────

TRIAGE_SYSTEM = """You are a senior Trust & Safety analyst at Reef Media with deep expertise in misinformation research, platform governance, and information integrity.

You will receive a case with analysis metrics (factuality, rhetoric, logic, argumentation, overall — each 0-100, where higher = MORE problematic), the actor profile, and the list of available enforcement policies.

Your response must be ONLY a JSON object (no markdown fences) with these fields:

- "action": one of "Confirmed", "Escalated", "Dismissed", or "Policy: <exact policy name>" (use the exact name from the available policies list)
- "rationale": A thorough 4-6 sentence explanation that:
    1. Identifies specifically WHY this content is problematic (or not), referencing the case title, media type, and the specific factuality/rhetoric/logic scores
    2. Explains the real-world harm potential — reference established research from verifiable institutions such as Pew Research Center, Reuters Institute for the Study of Journalism, Stanford Internet Observatory, MIT Media Lab, Oxford Internet Institute, the Harvard Shorenstein Center, or EU DisinfoLab. Cite the institution by name and describe the relevant finding (e.g. "According to Pew Research Center's 2024 study on news trust, fabricated content mimicking official sources is believed by 48% of respondents on first exposure")
    3. If recommending a policy, justify WHY that specific policy is the correct enforcement mechanism for this content category — connect the case characteristics to the policy's stated purpose
    4. Assess the actor's pattern of behaviour and risk profile to contextualize the recommendation
- "confidence": a number 0-100 representing confidence in this recommendation

IMPORTANT: Your rationale must demonstrate analytical depth. Do not give superficial reasoning. Connect the metrics to real-world disinformation dynamics and cite specific ontological sources to support your assessment. When referencing research institutions, describe their actual finding relevant to the case type rather than making generic statements."""


def triage_case(case: dict, actor: dict, policies: list) -> dict:
    metrics = case.get("metrics", {})
    metric_details = case.get("metric_details", {})

    detail_context = ""
    for key in ["factuality", "rhetoric", "logic", "argumentation", "overall"]:
        md = metric_details.get(key, {})
        if md.get("detail"):
            detail_context += f"  {key.title()}: {md['detail'][:200]}\n"

    user_msg = f"""CASE: {case.get('id', 'Unknown')}
Title: {case.get('title', 'N/A')}
Media Type: {case.get('media_type', 'N/A')}
Date: {case.get('date', 'N/A')}
Current Outcome: {case.get('outcome', 'N/A')}

ANALYSIS METRICS (0-100, higher = more problematic):
- Factuality: {metrics.get('factuality', 'N/A')}
- Rhetoric: {metrics.get('rhetoric', 'N/A')}
- Logic: {metrics.get('logic', 'N/A')}
- Argumentation: {metrics.get('argumentation', 'N/A')}
- Overall: {metrics.get('overall', 'N/A')}

METRIC ANALYSIS DETAILS:
{detail_context if detail_context else '  No detailed analysis available.'}

ENGAGEMENT METRICS:
- Views: {case.get('views', 0):,}
- Shares: {case.get('shares', 0):,}
- Comments: {case.get('comments', 0):,}
- Ratings: {case.get('ratings', 0):,}

ACTOR PROFILE:
- Handle: {actor.get('handle', 'Unknown')}
- Type: {actor.get('type', 'Unknown')}
- Risk Score: {actor.get('risk', 'N/A')}/100
- Total Posts: {actor.get('posts', 'N/A')}

AVAILABLE POLICIES:
{chr(10).join(f'- {p["name"]} (rank: {p.get("rank", "Operator")}, restriction: {p.get("restriction", "N/A")}): {p.get("description", "")}' for p in policies)}

Based on the metrics, actor profile, engagement data, and available policies, provide a thorough recommendation with detailed justification referencing established disinformation research."""

    try:
        raw = _call_gemini(TRIAGE_SYSTEM, user_msg)
        result = _parse_json_response(raw)
        if result and "action" in result:
            return {
                "action": str(result.get("action", "")),
                "rationale": str(result.get("rationale", "")),
                "confidence": int(result.get("confidence", 50)),
            }
        return {
            "action": "Escalated",
            "rationale": raw[:800],
            "confidence": 30,
        }
    except Exception as e:
        return {
            "action": "Escalated",
            "rationale": f"AI analysis unavailable: {str(e)[:200]}",
            "confidence": 0,
        }


# ── Feature B: Actor Intelligence Summary ─────────────────────────────────

ACTOR_SYSTEM = """You are a senior intelligence analyst at Reef Media specialising in disinformation threat assessment, information operations, and platform integrity research.

You will receive comprehensive data about a bad actor including their handle, classification, risk score, audience growth trajectory, monthly trend data, existing intelligence insights, and their associated misinformation cases.

Generate a thorough intelligence brief. Respond with ONLY a JSON object (no markdown fences) with these fields:

- "brief": A 5-7 sentence executive summary of the actor's threat profile that:
    1. Opens with a clear threat classification and operational characterisation of the actor
    2. References specific data points — risk score, audience growth rate, post volume, and reach trajectory
    3. Contextualises the threat using established disinformation research from institutions such as the Stanford Internet Observatory, Oxford Internet Institute, Atlantic Council's Digital Forensic Research Lab (DFRLab), Pew Research Center, EU DisinfoLab, MIT Media Lab, Reuters Institute for the Study of Journalism, or the Harvard Shorenstein Center. Cite the institution by name and describe the relevant finding (e.g. "Research from the Oxford Internet Institute's Computational Propaganda Project has documented how state-linked actors use coordinated amplification networks to inflate content reach by 300-500% within 24 hours")
    4. Identifies the specific disinformation tactics and techniques observed, connecting them to established frameworks such as the AMITT (Adversarial Misinformation and Influence Tactics and Techniques) framework or the ABC framework (Actors, Behaviour, Content)
    5. Assesses real-world harm potential based on the actor's thematic focus, audience reach, and case outcomes

- "key_findings": A list of 4-5 strings (1-2 sentences each), each an actionable intelligence finding or recommendation that:
    - References a specific data point or pattern from the actor's profile
    - Connects to broader disinformation research or documented threat patterns
    - Provides a concrete recommendation for Trust & Safety response

IMPORTANT: Your analysis must demonstrate genuine analytical depth. Reference real research institutions and their documented findings relevant to the actor's disinformation type. Do not fabricate study names — reference institutions and their known research areas accurately."""


def summarize_actor(actor: dict, trends: dict, cases: list) -> dict:
    case_summary = []
    for c in cases[:15]:
        case_summary.append(
            f"  - {c.get('id', '?')}: {c.get('title', '?')} "
            f"(outcome: {c.get('outcome', '?')}, score: {c.get('score', '?')}, "
            f"media: {c.get('media_type', '?')}, views: {c.get('views', 0)}, "
            f"shares: {c.get('shares', 0)})"
        )

    trend_data_str = ""
    if trends and trends.get("trend_data"):
        for t in trends["trend_data"]:
            trend_data_str += (
                f"  - {t.get('name', '?')}: {t.get('posts', 0):,} posts, "
                f"reach {t.get('reach', 0):,}, risk score {t.get('risk', 0)}\n"
            )

    insights_str = ""
    if trends and trends.get("insights"):
        for ins in trends["insights"]:
            insights_str += (
                f"  - [{ins.get('severity', 'info').upper()}] "
                f"{ins.get('title', '')}: {ins.get('detail', '')}\n"
            )

    user_msg = f"""ACTOR PROFILE:
- Handle: {actor.get('handle', 'Unknown')}
- Classification: {actor.get('type', 'Unknown')}
- Risk Score: {actor.get('risk', 'N/A')}/100
- Total Posts: {actor.get('posts', 'N/A'):,}

THREAT ASSESSMENT:
- Threat Level: {trends.get('threat_level', 'N/A')}
- Audience Growth: {trends.get('audience_growth', 'N/A')}
- Summary: {trends.get('summary', 'N/A')}

MONTHLY TREND DATA:
{trend_data_str if trend_data_str else '  No trend data available.'}

EXISTING INTELLIGENCE INSIGHTS:
{insights_str if insights_str else '  No insights available.'}

ASSOCIATED CASES ({len(cases)} total):
{chr(10).join(case_summary) if case_summary else '  No cases found.'}

Generate a comprehensive intelligence brief synthesising all available data. Ground your analysis in established disinformation research and provide actionable recommendations."""

    try:
        raw = _call_gemini(ACTOR_SYSTEM, user_msg)
        result = _parse_json_response(raw)
        if result and "brief" in result:
            return {
                "brief": str(result.get("brief", "")),
                "key_findings": list(result.get("key_findings", [])),
            }
        return {
            "brief": raw[:1200],
            "key_findings": [],
        }
    except Exception as e:
        return {
            "brief": f"Intelligence brief unavailable: {str(e)[:200]}",
            "key_findings": [],
        }


# ── Feature C: Actor Enforcement Assessment ───────────────────────────────

ACTOR_ASSESS_SYSTEM = """You are a senior Trust & Safety enforcement specialist at Reef Media with deep expertise in platform governance, content moderation policy, proportional enforcement design, and disinformation countermeasures.

You will receive comprehensive data about a bad actor including their handle, classification, risk score, case history (with outcomes and severity scores), audience metrics, trend data, and the list of available platform policies.

Your task is to recommend the most proportional and effective enforcement action for this actor. Your approach must follow a graduated escalation philosophy:

ENFORCEMENT PHILOSOPHY — GRADUATED RESPONSE:
1. **Educational / Informational (risk ≤ 25 or first-time low-severity offenders)**: Soft approaches that inform the user WHY their content is problematic. Content advisory notices, fact-check labels, community guidelines reminders. Research from the Pew Research Center (2023) shows that contextual warning labels reduce resharing of misinformation by 10-25%. The MIT Media Lab's work on "accuracy nudges" demonstrates that prompting users to consider accuracy before sharing reduces misinformation spread by up to 30%.

2. **Restrictions (risk 25-50 or repeat low-to-moderate offenders)**: Reduce algorithmic reach, disable monetisation, disable sharing. The Stanford Internet Observatory has documented how de-amplification reduces viral spread by 40-70% without triggering the "censorship backlash" effect. The Oxford Internet Institute's research on platform interventions shows monetisation removal is particularly effective against financially-motivated disinformation actors.

3. **Temporary Suspensions (risk 50-75 or persistent moderate offenders)**: 7-day or 30-day bans for repeated Terms of Service violations. Research from the Atlantic Council's Digital Forensic Research Lab shows temporary bans are most effective when paired with clear reinstatement criteria. EU DisinfoLab studies indicate 30-day suspensions reduce recidivism rates by ~45% compared to shorter bans.

4. **Permanent Actions (risk ≥ 75 or coordinated/state-linked operations)**: Permanent bans for actors identified as part of coordinated influence operations, psy-ops, or systematic ToS violators. The Stanford Internet Observatory's takedown reports demonstrate that swift permanent removal of coordinated inauthentic behaviour nodes prevents network reconstitution. The Harvard Shorenstein Center research shows delayed action on coordinated campaigns allows message amplification to reach irreversible saturation.

Your response must be ONLY a JSON object (no markdown fences) with these fields:

- "recommended_action": The specific enforcement action string. Must be one of:
  "Warning: Content Advisory", "Warning: Fact-Check Notice", "Warning: Community Guidelines",
  "Restrict: Reduce Reach", "Restrict: Disable Monetisation", "Restrict: Disable Sharing",
  "Suspend: 7-Day Temp Ban", "Suspend: 30-Day Temp Ban", "Suspend: Indefinite",
  "Permanent Ban: ToS Violation", "Permanent Ban: Coordinated Psy-Op",
  OR "Policy: <exact policy name>" (use the exact name from the available policies list)

- "rationale": A thorough 5-7 sentence explanation that:
    1. Classifies the actor's threat type (financially motivated, ideological, state-linked, unwitting amplifier, coordinated network node, etc.)
    2. Justifies the proportionality of the recommended action by referencing the actor's risk score, case history pattern, and content severity — explain WHY this level of enforcement is appropriate and why lighter/heavier approaches would be insufficient/excessive
    3. References established research from verifiable institutions (Pew Research Center, Stanford Internet Observatory, Oxford Internet Institute, MIT Media Lab, Atlantic Council DFRLab, EU DisinfoLab, Harvard Shorenstein Center, Reuters Institute) — cite the institution by name and describe the relevant finding
    4. If the actor appears to be an unwitting sharer vs. a deliberate disinformation agent, explains how the approach addresses the root cause (education vs. enforcement)
    5. Assesses whether the actor's content patterns suggest coordination with other actors or isolated behaviour

- "escalation_path": A list of 3-4 strings describing the graduated enforcement steps if the actor continues problematic behaviour after this action. Each step should name the specific next action and the trigger condition.

- "confidence": A number 0-100 representing confidence in this recommendation

IMPORTANT: Your rationale must demonstrate nuanced judgment. Not every bad actor deserves a ban — many are better served by educational interventions that explain why their content is flawed. Reserve severe actions for actors whose content is unapologetically problematic, shows patterns of deliberate manipulation, or appears to be part of coordinated influence operations. Always connect your recommendation to the specific evidence in the actor's profile."""


def assess_actor(actor: dict, trends: dict, cases: list, policies: list) -> dict:
    case_summary = []
    for c in cases[:15]:
        case_summary.append(
            f"  - {c.get('id', '?')}: {c.get('title', '?')} "
            f"(outcome: {c.get('outcome', '?')}, score: {c.get('score', '?')}, "
            f"media: {c.get('media_type', '?')}, views: {c.get('views', 0):,}, "
            f"shares: {c.get('shares', 0):,})"
        )

    confirmed_count = sum(
        1
        for c in cases
        if c.get("outcome") == "Confirmed"
        or str(c.get("outcome", "")).startswith("Policy:")
    )
    escalated_count = sum(1 for c in cases if c.get("outcome") == "Escalated")
    avg_score = (
        sum(c.get("score", 0) for c in cases) / len(cases) if cases else 0
    )

    trend_data_str = ""
    if trends and trends.get("trend_data"):
        for t in trends["trend_data"]:
            trend_data_str += (
                f"  - {t.get('name', '?')}: {t.get('posts', 0):,} posts, "
                f"reach {t.get('reach', 0):,}, risk score {t.get('risk', 0)}\n"
            )

    insights_str = ""
    if trends and trends.get("insights"):
        for ins in trends["insights"]:
            insights_str += (
                f"  - [{ins.get('severity', 'info').upper()}] "
                f"{ins.get('title', '')}: {ins.get('detail', '')}\n"
            )

    user_msg = f"""ACTOR PROFILE:
- Handle: {actor.get('handle', 'Unknown')}
- Classification: {actor.get('type', 'Unknown')}
- Risk Score: {actor.get('risk', 'N/A')}/100
- Total Posts: {actor.get('posts', 'N/A'):,}

CASE HISTORY SUMMARY:
- Total Cases: {len(cases)}
- Confirmed / Policy Applied: {confirmed_count}
- Escalated: {escalated_count}
- Average Case Severity Score: {avg_score:.1f}/100

THREAT ASSESSMENT:
- Threat Level: {trends.get('threat_level', 'N/A')}
- Audience Growth: {trends.get('audience_growth', 'N/A')}
- Summary: {trends.get('summary', 'N/A')}

MONTHLY TREND DATA:
{trend_data_str if trend_data_str else '  No trend data available.'}

EXISTING INTELLIGENCE INSIGHTS:
{insights_str if insights_str else '  No insights available.'}

ASSOCIATED CASES ({len(cases)} total):
{chr(10).join(case_summary) if case_summary else '  No cases found.'}

AVAILABLE POLICIES:
{chr(10).join(f'- {p["name"]} (rank: {p.get("rank", "Operator")}, restriction: {p.get("restriction", "N/A")}): {p.get("description", "")}' for p in policies)}

Based on this actor's risk profile, case history, and available enforcement options, recommend the most proportional enforcement action. Consider whether the actor would benefit more from educational intervention or whether their behaviour warrants punitive action. Justify your recommendation with specific evidence and research citations."""

    try:
        raw = _call_gemini(ACTOR_ASSESS_SYSTEM, user_msg)
        result = _parse_json_response(raw)
        if result and "recommended_action" in result:
            return {
                "recommended_action": str(result.get("recommended_action", "")),
                "rationale": str(result.get("rationale", "")),
                "escalation_path": list(result.get("escalation_path", [])),
                "confidence": int(result.get("confidence", 50)),
            }
        return {
            "recommended_action": "Warning: Content Advisory",
            "rationale": raw[:800],
            "escalation_path": [],
            "confidence": 30,
        }
    except Exception as e:
        return {
            "recommended_action": "Warning: Content Advisory",
            "rationale": f"AI assessment unavailable: {str(e)[:200]}",
            "escalation_path": [],
            "confidence": 0,
        }
