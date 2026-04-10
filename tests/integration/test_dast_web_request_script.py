"""
Integration tests for Scripts/Release/DASTWebAppRequest-std.py.

Tests the script end-to-end via subprocess, verifying:
  - stdout mode with CLI args produces valid JSON
  - Request structure matches Veracode Dynamic Analysis API schema
  - Input file (input.json) is written correctly
  - Org info, scan config, and schedule are included

These tests do NOT require Veracode API credentials.
The script is invoked with pre-set CLI args so it runs non-interactively.
"""

import json
import sys
import shutil
import subprocess
import pytest
from pathlib import Path

RELEASE_DIR = Path(__file__).parent.parent.parent / "Scripts" / "Release"
FIXTURES_DIR = Path(__file__).parent.parent / "fixtures"
SCRIPT = RELEASE_DIR / "DASTWebAppRequest-std.py"

TEST_ARGS = [
    "integration-test-analysis",
    "https://target.example.com/",
    "owner@example.com",
    "Test Owner",
]


@pytest.fixture
def work_dir(tmp_path):
    """Temp dir with CSV fixtures so the script can find allowlist/blocklist files."""
    for f in FIXTURES_DIR.glob("*.csv"):
        shutil.copy(f, tmp_path / f.name)
    return tmp_path


def run_script(work_dir, args=None):
    """Run DASTWebAppRequest-std.py from work_dir with the given args."""
    cmd = [sys.executable, str(SCRIPT)] + (args or TEST_ARGS)
    return subprocess.run(cmd, capture_output=True, text=True, cwd=str(work_dir))


def extract_json(result) -> dict:
    """Extract the last JSON object from the script's stdout."""
    non_empty = [l for l in result.stdout.strip().splitlines() if l.strip()]
    assert non_empty, f"No output from script. stderr: {result.stderr}"
    return json.loads(non_empty[-1])


# --- Basic execution ---

class TestScriptExecution:
    def test_exits_zero(self, work_dir):
        result = run_script(work_dir)
        assert result.returncode == 0, f"Non-zero exit: {result.stderr}"

    def test_produces_stdout(self, work_dir):
        result = run_script(work_dir)
        assert result.stdout.strip() != ""

    def test_stdout_ends_with_valid_json(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        assert isinstance(parsed, dict)

    def test_writes_input_json_file(self, work_dir):
        run_script(work_dir)
        assert (work_dir / "input.json").exists()

    def test_input_json_matches_stdout_json(self, work_dir):
        result = run_script(work_dir)
        stdout_parsed = extract_json(result)
        with open(work_dir / "input.json") as f:
            file_parsed = json.load(f)
        assert stdout_parsed == file_parsed


# --- Request structure ---

class TestRequestStructure:
    def test_name_field_present(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        assert "name" in parsed

    def test_name_matches_arg(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        assert parsed["name"] == TEST_ARGS[0]

    def test_scans_field_present(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        assert "scans" in parsed

    def test_scans_is_nonempty_list(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        assert isinstance(parsed["scans"], list)
        assert len(parsed["scans"]) >= 1

    def test_schedule_field_present(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        assert "schedule" in parsed

    def test_schedule_has_duration(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        assert "duration" in parsed["schedule"]

    def test_org_info_present(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        assert "org_info" in parsed

    def test_org_info_has_email(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        assert "email" in parsed["org_info"]

    def test_org_email_matches_arg(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        assert parsed["org_info"]["email"] == TEST_ARGS[2]


# --- Scan configuration ---

class TestScanConfiguration:
    def test_scan_has_scan_config_request(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        scan = parsed["scans"][0]
        assert "scan_config_request" in scan

    def test_scan_config_has_target_url(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        scan_config = parsed["scans"][0]["scan_config_request"]
        assert "target_url" in scan_config

    def test_target_url_matches_arg(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        target = parsed["scans"][0]["scan_config_request"]["target_url"]
        assert target["url"] == TEST_ARGS[1]

    def test_target_url_has_http_and_https(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        target = parsed["scans"][0]["scan_config_request"]["target_url"]
        assert "http_and_https" in target

    def test_http_and_https_is_true(self, work_dir):
        result = run_script(work_dir)
        parsed = extract_json(result)
        target = parsed["scans"][0]["scan_config_request"]["target_url"]
        # The script sets this to "true" (string) or boolean true
        assert str(target["http_and_https"]).lower() == "true"


# --- Different analysis names ---

class TestAnalysisNameVariants:
    @pytest.mark.parametrize("name", [
        "my-app-dast-scan",
        "prod-api-scan-v2",
        "veracode-weekly-analysis",
    ])
    def test_custom_analysis_name(self, work_dir, name):
        args = [name, "https://example.com/", "scan@company.com", "Owner"]
        result = run_script(work_dir, args)
        parsed = extract_json(result)
        assert parsed["name"] == name

    @pytest.mark.parametrize("url", [
        "https://app.example.com/",
        "https://api.example.com/v1/",
        "https://staging.example.com/",
    ])
    def test_various_target_urls(self, work_dir, url):
        args = ["test-scan", url, "test@example.com", "Owner"]
        result = run_script(work_dir, args)
        parsed = extract_json(result)
        assert parsed["scans"][0]["scan_config_request"]["target_url"]["url"] == url
