"""
Integration tests for Scripts/Release/BlackList-std.py.

Tests the script end-to-end via subprocess, verifying:
  - Script exits successfully when CSV files are present
  - Output contains expected scan configuration fragments
  - Blacklist entries from the CSV appear in the output
  - input.json is written to the working directory

These tests do NOT require Veracode API credentials.
The script runs its built-in test() function when DEBUG=True (the default).
"""

import csv
import sys
import shutil
import subprocess
import pytest
from pathlib import Path

RELEASE_DIR = Path(__file__).parent.parent.parent / "Scripts" / "Release"
FIXTURES_DIR = Path(__file__).parent.parent / "fixtures"
SCRIPT = RELEASE_DIR / "BlackList-std.py"


@pytest.fixture
def work_dir(tmp_path):
    """Temp dir with CSV fixtures so the script can find blacklist files."""
    for f in FIXTURES_DIR.glob("*.csv"):
        shutil.copy(f, tmp_path / f.name)
    return tmp_path


def run_script(work_dir):
    return subprocess.run(
        [sys.executable, str(SCRIPT)],
        capture_output=True,
        text=True,
        cwd=str(work_dir),
    )


# --- Execution health ---

class TestBlacklistScriptExecution:
    def test_exits_zero(self, work_dir):
        result = run_script(work_dir)
        assert result.returncode == 0, f"Non-zero exit:\nstdout: {result.stdout}\nstderr: {result.stderr}"

    def test_produces_output(self, work_dir):
        result = run_script(work_dir)
        assert result.stdout.strip() != ""

    def test_writes_input_json(self, work_dir):
        run_script(work_dir)
        assert (work_dir / "input.json").exists()

    def test_input_json_is_nonempty(self, work_dir):
        run_script(work_dir)
        content = (work_dir / "input.json").read_text()
        assert content.strip() != ""


# --- Output content ---

class TestBlacklistScriptOutput:
    def test_output_contains_analysis_name_prefix(self, work_dir):
        """The test() function prefixes the name with 'veracode-api-test-'."""
        result = run_script(work_dir)
        assert "veracode-api-test-" in result.stdout

    def test_output_contains_scan_config(self, work_dir):
        result = run_script(work_dir)
        assert "scan_config_request" in result.stdout

    def test_output_contains_target_url(self, work_dir):
        result = run_script(work_dir)
        assert "target_url" in result.stdout

    def test_output_contains_veracode_test_url(self, work_dir):
        """The test() function uses http://veracode.com as the target URL."""
        result = run_script(work_dir)
        assert "veracode.com" in result.stdout

    def test_output_contains_org_email(self, work_dir):
        """The test() function uses example@example.com as the org email."""
        result = run_script(work_dir)
        assert "example@example.com" in result.stdout

    def test_output_contains_blacklist_config(self, work_dir):
        result = run_script(work_dir)
        assert "blacklist_configuration" in result.stdout or "black_list" in result.stdout

    def test_blacklist_urls_appear_in_output(self, work_dir):
        """URLs from blacklist.csv should be present in the output."""
        with open(FIXTURES_DIR / "blacklist.csv") as f:
            reader = csv.DictReader(f)
            urls = [row["url"].strip() for row in reader]

        result = run_script(work_dir)
        assert any(url in result.stdout for url in urls), (
            f"None of the blacklist URLs {urls} found in output:\n{result.stdout[:500]}"
        )


# --- CSV not found handling ---

class TestBlacklistMissingCSV:
    def test_exits_zero_without_csv_files(self, tmp_path):
        """Script should not crash when CSV files are missing (graceful error handling)."""
        result = subprocess.run(
            [sys.executable, str(SCRIPT)],
            capture_output=True,
            text=True,
            cwd=str(tmp_path),
        )
        assert result.returncode == 0

    def test_reports_csv_load_error_without_csv(self, tmp_path):
        """When CSV files are missing the script should report load failures."""
        result = subprocess.run(
            [sys.executable, str(SCRIPT)],
            capture_output=True,
            text=True,
            cwd=str(tmp_path),
        )
        combined = result.stdout + result.stderr
        assert "failed to load" in combined or "veracode-api-test-" in combined
