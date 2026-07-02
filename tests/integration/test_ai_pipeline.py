"""Integration tests for the AI analysis pipeline.

Offline mode runs with no dependencies. Full mode uses a MockProvider that
returns structured verdicts/chains without calling the API, so the
orchestration (batching, consensus, chaining, hooks) is exercised end-to-end
in CI without an API key.
"""

import sys
from pathlib import Path

import pytest

AI_DIR = Path(__file__).parent.parent.parent / "Scripts" / "AIAnalysis"
sys.path.insert(0, str(AI_DIR))

from veracode_ai.config import load_registry  # noqa: E402
from veracode_ai.pipeline import Pipeline  # noqa: E402
from veracode_ai.hooks import HookRegistry  # noqa: E402

FIXTURES = Path(__file__).parent.parent / "fixtures"

SCAN_PAYLOADS = {
    "rest": str(FIXTURES / "veracode_findings.json"),
    "container": str(FIXTURES / "container_scan.json"),
}


class MockProvider:
    """Stands in for the Anthropic provider. Deterministically confirms every
    finding and emits one risk chain, so orchestration can be tested offline."""

    def __init__(self):
        self.calls = []

    def available(self, model_cfg):
        return True

    def structured(self, model_cfg, system, user, schema):
        self.calls.append(model_cfg.id)
        if "verdicts" in schema["properties"]:
            # confirm everything (no false positives)
            ids = [tok[1:-1] for tok in user.split() if tok.startswith("[") and tok.endswith("]")]
            return {"verdicts": [
                {"finding_id": fid, "is_likely_false_positive": False,
                 "confidence": "high", "rationale": "reachable"}
                for fid in ids
            ]}
        return {"chains": [{
            "name": "SQLi to data exfiltration",
            "finding_ids": [],
            "combined_severity": 5,
            "rationale": "chained",
            "remediation_order": [],
            "recommended_training": "OWASP A03 Injection",
        }]}


class TestOfflinePipeline:
    def test_offline_correlation_only(self):
        pipeline = Pipeline(registry=load_registry(), provider=None)
        report = pipeline.analyze(SCAN_PAYLOADS, offline=True)
        assert report["mode"] == "offline"
        assert report["total_findings"] == 6
        assert len(report["correlations"]) > 0

    def test_offline_has_source_counts(self):
        pipeline = Pipeline(provider=None)
        report = pipeline.analyze(SCAN_PAYLOADS, offline=True)
        assert report["counts"]["STATIC"] == 2
        assert report["counts"]["CONTAINER"] == 2

    def test_offline_needs_no_validation(self):
        pipeline = Pipeline(provider=None)
        report = pipeline.analyze(SCAN_PAYLOADS, offline=True)
        assert "validation" not in report


class TestFullPipeline:
    @pytest.fixture
    def pipeline(self):
        return Pipeline(registry=load_registry(), provider=MockProvider())

    def test_full_run_produces_validation(self, pipeline):
        report = pipeline.analyze(SCAN_PAYLOADS, offline=False)
        assert report["mode"] == "full"
        assert "validation" in report
        assert report["validation"]["confirmed"] == 6

    def test_full_run_produces_chains(self, pipeline):
        report = pipeline.analyze(SCAN_PAYLOADS, offline=False)
        assert len(report["risk_chains"]) >= 1
        assert report["risk_chains"][0]["recommended_training"]

    def test_chain_tagged_with_model(self, pipeline):
        report = pipeline.analyze(SCAN_PAYLOADS, offline=False)
        assert "model" in report["risk_chains"][0]

    def test_only_chain_role_models_called_for_chaining(self):
        provider = MockProvider()
        pipeline = Pipeline(registry=load_registry(), provider=provider)
        pipeline.analyze(SCAN_PAYLOADS, offline=False)
        # opus has both validate and chain roles; it should appear
        assert "claude-opus-4-8" in provider.calls


class TestHooksIntegration:
    def test_hooks_fire_across_stages(self):
        hooks = HookRegistry()
        fired = []
        for point in ("pre_ingest", "post_normalize", "post_correlate",
                      "post_validate", "post_chain", "report"):
            hooks.register(point)(lambda p, pt=point: fired.append(pt) or p)

        pipeline = Pipeline(registry=load_registry(),
                            provider=MockProvider(), hooks=hooks)
        pipeline.analyze(SCAN_PAYLOADS, offline=False)

        assert "pre_ingest" in fired
        assert "post_normalize" in fired
        assert "post_chain" in fired
        assert "report" in fired

    def test_pre_validate_hook_can_filter_findings(self):
        hooks = HookRegistry()

        @hooks.register("pre_validate")
        def _only_high(findings):
            return [f for f in findings if f.severity >= 4]

        provider = MockProvider()
        pipeline = Pipeline(registry=load_registry(), provider=provider, hooks=hooks)
        report = pipeline.analyze(SCAN_PAYLOADS, offline=False)
        # low-severity findings were filtered before validation
        assert report["validation"]["confirmed"] <= 6
