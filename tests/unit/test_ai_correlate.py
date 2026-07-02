"""Unit tests for deterministic cross-scan correlation and consensus logic."""

import sys
from pathlib import Path

import pytest

AI_DIR = Path(__file__).parent.parent.parent / "Scripts" / "AIAnalysis"
sys.path.insert(0, str(AI_DIR))

from veracode_ai.findings import normalize_findings  # noqa: E402
from veracode_ai.correlate import correlate  # noqa: E402
from veracode_ai.validate import consensus  # noqa: E402

FIXTURES = Path(__file__).parent.parent / "fixtures"


class TestCorrelation:
    @pytest.fixture
    def findings(self):
        rest = normalize_findings(str(FIXTURES / "veracode_findings.json"))
        container = normalize_findings(str(FIXTURES / "container_scan.json"),
                                       source_hint="container")
        return rest + container

    @pytest.fixture
    def correlations(self, findings):
        return correlate(findings)

    def test_cross_layer_cwe_detected(self, correlations):
        # CWE-89 appears in both STATIC and DYNAMIC -> cross-layer confirmation
        types = [c["type"] for c in correlations]
        assert "cross_layer_confirmation" in types

    def test_cross_layer_links_static_and_dynamic(self, correlations):
        cl = [c for c in correlations if c["type"] == "cross_layer_confirmation"][0]
        assert cl["cwe"] == 89
        assert len(cl["finding_ids"]) >= 3  # 2 static + 1 dynamic

    def test_common_flaw_source_detected(self, correlations):
        # Two static findings share the same attack_vector
        types = [c["type"] for c in correlations]
        assert "common_flaw_source" in types

    def test_shared_cve_across_sca_and_container(self, correlations):
        # CVE-2021-44228 in both SCA and CONTAINER
        shared = [c for c in correlations if c["type"] == "shared_cve"]
        assert any(c["cve"] == "CVE-2021-44228" for c in shared)

    def test_correlations_annotate_findings(self, findings, correlations):
        annotated = [f for f in findings if f.correlations]
        assert len(annotated) > 0

    def test_no_false_correlation_on_empty(self):
        assert correlate([]) == []


class TestConsensus:
    def test_no_votes_is_unvalidated(self):
        result = consensus([], quorum_fraction=0.5)
        assert result["verdict"] == "unvalidated"

    def test_majority_fp_marks_false_positive(self):
        votes = [
            {"is_likely_false_positive": True, "model": "a", "confidence": "high", "rationale": ""},
            {"is_likely_false_positive": True, "model": "b", "confidence": "medium", "rationale": ""},
        ]
        assert consensus(votes, 0.5)["verdict"] == "likely_false_positive"

    def test_split_below_quorum_confirms(self):
        votes = [
            {"is_likely_false_positive": True, "model": "a", "confidence": "low", "rationale": ""},
            {"is_likely_false_positive": False, "model": "b", "confidence": "high", "rationale": ""},
            {"is_likely_false_positive": False, "model": "c", "confidence": "high", "rationale": ""},
        ]
        # 1/3 refute, quorum 0.5 -> confirmed
        assert consensus(votes, 0.5)["verdict"] == "confirmed"

    def test_all_confirm(self):
        votes = [
            {"is_likely_false_positive": False, "model": "a", "confidence": "high", "rationale": ""},
        ]
        result = consensus(votes, 0.5)
        assert result["verdict"] == "confirmed"
        assert result["fp_votes"] == 0
