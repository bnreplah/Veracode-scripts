"""Multi-model false-positive validation.

Every enabled model with a validator role independently tries to REFUTE each
finding (adversarial framing — a validator that can't refute it confirms it).
Verdicts are combined by consensus: a finding is confirmed unless a quorum of
validators refute it. Frontier models (deep-validate role) cast the same vote
shape, so enabling Mythos in models.json immediately adds an extra,
higher-confidence voice to the panel — no code changes.
"""

from .providers import ModelUnavailable, ModelRefused

VERDICT_SCHEMA = {
    "type": "object",
    "properties": {
        "verdicts": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "finding_id": {"type": "string"},
                    "is_likely_false_positive": {"type": "boolean"},
                    "confidence": {"type": "string", "enum": ["low", "medium", "high"]},
                    "rationale": {"type": "string"},
                },
                "required": [
                    "finding_id", "is_likely_false_positive",
                    "confidence", "rationale",
                ],
                "additionalProperties": False,
            },
        }
    },
    "required": ["verdicts"],
    "additionalProperties": False,
}

VALIDATE_SYSTEM = (
    "You are an application security reviewer performing false-positive triage "
    "on scanner findings. For each finding, actively try to REFUTE it: look for "
    "signs it is a false positive (framework-mitigated pattern, non-reachable "
    "code path, test fixture, informational-only, scanner heuristic misfire). "
    "Mark is_likely_false_positive=true ONLY when you can articulate a concrete "
    "refutation in the rationale. When in doubt, the finding stands "
    "(is_likely_false_positive=false). Return one verdict per finding, using "
    "the exact finding_id given."
)


def _batches(items, size):
    for i in range(0, len(items), size):
        yield items[i:i + size]


def consensus(votes, quorum_fraction: float) -> dict:
    """Combine per-model votes into a verdict.

    votes: list of {"model", "is_likely_false_positive", "confidence", "rationale"}
    A finding is marked a likely FP only when at least quorum_fraction of the
    votes refute it. Zero votes -> unvalidated (finding stands).
    """
    if not votes:
        return {"verdict": "unvalidated", "fp_votes": 0, "total_votes": 0, "votes": []}
    fp_votes = sum(1 for v in votes if v["is_likely_false_positive"])
    is_fp = (fp_votes / len(votes)) >= quorum_fraction and fp_votes > 0
    return {
        "verdict": "likely_false_positive" if is_fp else "confirmed",
        "fp_votes": fp_votes,
        "total_votes": len(votes),
        "votes": votes,
    }


def validate_findings(findings, registry, provider, hooks=None) -> dict:
    """Run the validator panel over findings. Mutates each finding's
    .validation and returns {"validated": n, "confirmed": n, "likely_fp": n,
    "unvalidated": n}."""
    strategy = registry.strategy("fp_reduction")
    quorum = strategy.get("quorum_fraction", 0.5)
    batch_size = strategy.get("batch_size", 10)
    validator_models = registry.models_for_roles(
        strategy.get("validator_roles", ["validate", "deep-validate"])
    )

    votes_by_finding = {f.id: [] for f in findings}

    for model_cfg in validator_models:
        for batch in _batches(findings, batch_size):
            block = "\n\n".join(
                f"{f.summary_line()}\n{f.description[:600]}" for f in batch
            )
            user = f"FINDINGS TO TRIAGE:\n\n{block}\n\nReturn one verdict per finding."
            try:
                result = provider.structured(
                    model_cfg, VALIDATE_SYSTEM, user, VERDICT_SCHEMA
                )
            except (ModelUnavailable, ModelRefused):
                break  # this model is out for the run / batch declined
            for v in result.get("verdicts", []):
                fid = v.get("finding_id")
                if fid in votes_by_finding:
                    votes_by_finding[fid].append({
                        "model": model_cfg.id,
                        "is_likely_false_positive": bool(v["is_likely_false_positive"]),
                        "confidence": v.get("confidence", "low"),
                        "rationale": v.get("rationale", ""),
                    })

    stats = {"validated": 0, "confirmed": 0, "likely_fp": 0, "unvalidated": 0}
    for f in findings:
        f.validation = consensus(votes_by_finding[f.id], quorum)
        if hooks is not None:
            hooks.emit("post_validate", {"finding": f, **f.validation})
        if f.validation["verdict"] == "unvalidated":
            stats["unvalidated"] += 1
        else:
            stats["validated"] += 1
            key = "likely_fp" if f.validation["verdict"] == "likely_false_positive" else "confirmed"
            stats[key] += 1
    return stats
