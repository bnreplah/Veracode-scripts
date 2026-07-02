"""End-to-end analysis pipeline.

Stages (each fires operational hooks so external tooling / future frontier
models can observe or transform the data):

    ingest -> normalize -> correlate -> validate (FP reduction) -> chain -> report

The pipeline is model-agnostic: which models run at each stage comes entirely
from the registry (models.json). Enabling Claude Mythos 5 there adds it to the
validator panel and chain stage with no code change.
"""

from . import findings as findings_mod
from .config import load_registry
from .correlate import correlate, chain_risks
from .hooks import hooks as default_hooks
from .validate import validate_findings


class Pipeline:
    def __init__(self, registry=None, provider=None, hooks=None):
        self.registry = registry or load_registry()
        self.provider = provider  # None => offline (correlation only)
        self.hooks = hooks or default_hooks

    def analyze(self, scan_payloads: dict, offline: bool = None) -> dict:
        """Run the full pipeline.

        scan_payloads: {source_hint: payload_or_path}, e.g.
            {"rest": findings_json, "container": container_json}
        offline: force correlation-only (no model calls). Defaults to True when
            no provider is configured.
        """
        offline = (self.provider is None) if offline is None else offline

        # --- ingest + normalize -------------------------------------------
        scan_payloads = self.hooks.emit("pre_ingest", scan_payloads)
        findings = []
        for hint, payload in scan_payloads.items():
            findings.extend(findings_mod.normalize_findings(payload, source_hint=hint))
        findings = self.hooks.emit("post_normalize", findings)

        # --- correlate (deterministic, always runs) -----------------------
        findings = self.hooks.emit("pre_correlate", findings)
        correlations = correlate(findings)
        self.hooks.emit("post_correlate",
                        {"findings": findings, "correlations": correlations})

        report = {
            "counts": _source_counts(findings),
            "total_findings": len(findings),
            "correlations": correlations,
        }

        if offline:
            report["mode"] = "offline"
            report["findings"] = [f.to_dict() for f in findings]
            return self.hooks.emit("report", report)

        # --- validate (FP reduction) --------------------------------------
        to_validate = self.hooks.emit("pre_validate", findings)
        report["validation"] = validate_findings(
            to_validate, self.registry, self.provider, self.hooks
        )

        # --- chain (confirmed findings only) ------------------------------
        confirmed = [
            f for f in findings
            if not f.validation or f.validation["verdict"] != "likely_false_positive"
        ]
        confirmed = self.hooks.emit("pre_chain", confirmed)
        chains = chain_risks(confirmed, correlations, self.registry, self.provider)
        self.hooks.emit("post_chain", {"chains": chains})

        report["mode"] = "full"
        report["risk_chains"] = chains
        report["findings"] = [f.to_dict() for f in findings]
        return self.hooks.emit("report", report)


def _source_counts(findings) -> dict:
    counts = {}
    for f in findings:
        counts[f.source] = counts.get(f.source, 0) + 1
    return counts
