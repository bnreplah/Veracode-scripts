"""Cross-scan correlation and risk chaining.

Two layers:

1. Deterministic correlation (no API): rule-based links across scan types —
   cross-layer CWE confirmation (SAST+DAST), shared flaw sources, SCA/container
   CVE overlap, dependency-usage links. Runs offline and in CI.

2. Model-assisted risk chaining: a chain-role model composes correlated
   findings into ordered attack paths with a combined severity and rationale.
"""

from collections import defaultdict

from .providers import ModelUnavailable, ModelRefused

# ---------------------------------------------------------------------------
# Deterministic correlation rules
# ---------------------------------------------------------------------------


def correlate(findings) -> list:
    """Apply rule-based correlations. Mutates findings (appends to
    .correlations) and returns the list of correlation dicts."""
    correlations = []
    correlations += _cross_layer_cwe(findings)
    correlations += _common_flaw_source(findings)
    correlations += _shared_cve(findings)
    correlations += _dependency_usage(findings)

    by_id = {f.id: f for f in findings}
    for corr in correlations:
        for fid in corr["finding_ids"]:
            if fid in by_id:
                by_id[fid].correlations.append(corr["type"])
    return correlations


def _cross_layer_cwe(findings) -> list:
    """Same CWE observed by both static and dynamic analysis: the flaw is not
    just present in code — it is reachable in the running application."""
    by_cwe = defaultdict(lambda: defaultdict(list))
    for f in findings:
        if f.cwe and f.source in ("STATIC", "DYNAMIC"):
            by_cwe[f.cwe][f.source].append(f.id)

    out = []
    for cwe, sources in by_cwe.items():
        if "STATIC" in sources and "DYNAMIC" in sources:
            out.append({
                "type": "cross_layer_confirmation",
                "cwe": cwe,
                "finding_ids": sources["STATIC"] + sources["DYNAMIC"],
                "note": (
                    f"CWE-{cwe} found by both static and dynamic analysis — "
                    "the weakness is present in code AND reachable at runtime. "
                    "Treat as likely exploitable; prioritize remediation."
                ),
            })
    return out


def _common_flaw_source(findings) -> list:
    """Static findings sharing an attack vector (data-path source): fixing the
    shared source remediates the whole group at once."""
    by_vector = defaultdict(list)
    for f in findings:
        if f.source == "STATIC" and f.attack_vector:
            by_vector[f.attack_vector].append(f.id)

    return [
        {
            "type": "common_flaw_source",
            "attack_vector": vector,
            "finding_ids": ids,
            "note": (
                f"{len(ids)} static findings share the data-path source "
                f"'{vector}'. Sanitizing at this source remediates all of them."
            ),
        }
        for vector, ids in by_vector.items()
        if len(ids) >= 2
    ]


def _shared_cve(findings) -> list:
    """Same CVE reported by SCA and container scanning: the vulnerable library
    ships in both the dependency tree and the deployed image."""
    by_cve = defaultdict(lambda: defaultdict(list))
    for f in findings:
        if f.cve and f.source in ("SCA", "CONTAINER"):
            by_cve[f.cve][f.source].append(f.id)

    out = []
    for cve, sources in by_cve.items():
        if len(sources) >= 2:
            ids = [fid for group in sources.values() for fid in group]
            out.append({
                "type": "shared_cve",
                "cve": cve,
                "finding_ids": ids,
                "note": (
                    f"{cve} appears in both the dependency tree (SCA) and the "
                    "container image — confirmed in the deployed artifact."
                ),
            })
    return out


def _dependency_usage(findings) -> list:
    """SCA component name appearing in static finding module/file paths:
    the vulnerable dependency is referenced by first-party flawed code."""
    sca = [f for f in findings if f.source == "SCA" and f.module]
    static = [f for f in findings if f.source == "STATIC"]
    out = []
    for s in sca:
        # component base name without extension/version noise, e.g. "log4j"
        base = s.module.rsplit("/", 1)[-1].split("-")[0].split(".")[0].lower()
        if len(base) < 4:
            continue
        hits = [
            st.id for st in static
            if base in st.location.lower() or base in st.module.lower()
        ]
        if hits:
            out.append({
                "type": "dependency_usage",
                "component": s.module,
                "finding_ids": [s.id] + hits,
                "note": (
                    f"Vulnerable component '{s.module}' is referenced near "
                    "first-party static findings — elevated exposure."
                ),
            })
    return out


# ---------------------------------------------------------------------------
# Model-assisted risk chaining
# ---------------------------------------------------------------------------

CHAIN_SCHEMA = {
    "type": "object",
    "properties": {
        "chains": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "finding_ids": {"type": "array", "items": {"type": "string"}},
                    "combined_severity": {"type": "integer"},
                    "rationale": {"type": "string"},
                    "remediation_order": {"type": "array", "items": {"type": "string"}},
                    "recommended_training": {"type": "string"},
                },
                "required": [
                    "name", "finding_ids", "combined_severity",
                    "rationale", "remediation_order", "recommended_training",
                ],
                "additionalProperties": False,
            },
        }
    },
    "required": ["chains"],
    "additionalProperties": False,
}

CHAIN_SYSTEM = (
    "You are an application security analyst reviewing correlated findings from "
    "Veracode static, dynamic, software composition, and container scans of one "
    "application. Compose findings into risk chains: ordered sequences an attacker "
    "could combine (e.g. exposed endpoint -> injection -> vulnerable library -> "
    "container escape surface). Only chain findings with a plausible technical "
    "link; do not force unrelated findings together. combined_severity is 0-5. "
    "recommended_training names the security training topic that best addresses "
    "the chain's root cause (e.g. 'OWASP A03 Injection', 'Secure dependency "
    "management')."
)


def chain_risks(findings, correlations, registry, provider) -> list:
    """Ask each enabled chain-role model to build risk chains.

    Multiple chain models (e.g. Opus today, Mythos when enabled) each produce
    chains; results are tagged by model so downstream consumers can compare
    or merge. Degrades to [] when no chain model is available.
    """
    strategy = registry.strategy("risk_chaining")
    limit = strategy.get("max_findings_per_request", 60)
    chain_models = registry.models_for_roles(strategy.get("chain_roles", ["chain"]))

    ranked = sorted(findings, key=lambda f: f.severity, reverse=True)[:limit]
    finding_block = "\n".join(f.summary_line() for f in ranked)
    corr_block = "\n".join(
        f"- {c['type']}: {c['note']} (findings: {', '.join(c['finding_ids'])})"
        for c in correlations
    ) or "(no deterministic correlations found)"

    user = (
        f"FINDINGS ({len(ranked)} highest severity shown):\n{finding_block}\n\n"
        f"DETERMINISTIC CORRELATIONS:\n{corr_block}\n\n"
        "Build the risk chains."
    )

    chains = []
    for model_cfg in chain_models:
        try:
            result = provider.structured(model_cfg, CHAIN_SYSTEM, user, CHAIN_SCHEMA)
        except (ModelUnavailable, ModelRefused):
            continue
        for chain in result.get("chains", []):
            chain["model"] = model_cfg.id
            chains.append(chain)
    return chains
