"""Unit tests for finding normalization across scan types."""

import sys
from pathlib import Path

import pytest

AI_DIR = Path(__file__).parent.parent.parent / "Scripts" / "AIAnalysis"
sys.path.insert(0, str(AI_DIR))

from veracode_ai.findings import UnifiedFinding, normalize_findings  # noqa: E402

FIXTURES = Path(__file__).parent.parent / "fixtures"


class TestUnifiedFinding:
    def test_summary_line_includes_cwe(self):
        f = UnifiedFinding(id="S-1", source="STATIC", severity=4,
                           title="SQL Injection", cwe=89, location="A.java:10")
        line = f.summary_line()
        assert "CWE-89" in line
        assert "S-1" in line

    def test_to_dict_excludes_raw_by_default(self):
        f = UnifiedFinding(id="S-1", source="STATIC", severity=4,
                           title="x", raw={"big": "payload"})
        assert "raw" not in f.to_dict()
        assert "raw" in f.to_dict(include_raw=True)


class TestRestNormalization:
    @pytest.fixture
    def findings(self):
        return normalize_findings(str(FIXTURES / "veracode_findings.json"))

    def test_normalizes_all_findings(self, findings):
        assert len(findings) == 4

    def test_static_finding_shape(self, findings):
        static = [f for f in findings if f.source == "STATIC"]
        assert len(static) == 2
        f = static[0]
        assert f.cwe == 89
        assert ":142" in f.location or ":88" in f.location
        assert f.attack_vector

    def test_dynamic_finding_shape(self, findings):
        dyn = [f for f in findings if f.source == "DYNAMIC"][0]
        assert dyn.cwe == 89
        assert dyn.location.startswith("https://")

    def test_sca_finding_has_cve(self, findings):
        sca = [f for f in findings if f.source == "SCA"][0]
        assert sca.cve == "CVE-2021-44228"
        assert sca.cvss == 10.0

    def test_ids_are_unique(self, findings):
        ids = [f.id for f in findings]
        assert len(ids) == len(set(ids))


class TestContainerNormalization:
    @pytest.fixture
    def findings(self):
        return normalize_findings(str(FIXTURES / "container_scan.json"),
                                  source_hint="container")

    def test_normalizes_container(self, findings):
        assert len(findings) == 2
        assert all(f.source == "CONTAINER" for f in findings)

    def test_critical_maps_to_severity_5(self, findings):
        log4shell = [f for f in findings if f.cve == "CVE-2021-44228"][0]
        assert log4shell.severity == 5

    def test_auto_detects_container_payload(self):
        # No hint given — presence of "vulnerabilities" triggers container path
        findings = normalize_findings(str(FIXTURES / "container_scan.json"))
        assert all(f.source == "CONTAINER" for f in findings)
