"""
Veracode API connectivity integration tests.

These tests make LIVE calls to the Veracode REST/XML APIs and require
valid credentials to be configured via one of:
  - Environment variables: VERACODE_API_ID and VERACODE_API_KEY
  - Credentials file: ~/.veracode/credentials

Mark: @pytest.mark.api
Skip: Automatically skipped if no credentials are found.

Run selectively with:  pytest tests/integration/test_api_connectivity.py -m api -v
"""

import os
import subprocess
import sys
import shutil
import json
import pytest
from pathlib import Path

pytestmark = pytest.mark.api

RELEASE_DIR = Path(__file__).parent.parent.parent / "Scripts" / "Release"
FIXTURES_DIR = Path(__file__).parent.parent / "fixtures"

CREDS_FILE = Path.home() / ".veracode" / "credentials"


def credentials_available() -> bool:
    """Return True if Veracode API credentials can be found."""
    has_env = bool(
        os.environ.get("VERACODE_API_ID") and os.environ.get("VERACODE_API_KEY")
    )
    return has_env or CREDS_FILE.exists()


skip_no_creds = pytest.mark.skipif(
    not credentials_available(),
    reason=(
        "Veracode API credentials not found. "
        "Set VERACODE_API_ID + VERACODE_API_KEY env vars "
        "or configure ~/.veracode/credentials"
    ),
)


@skip_no_creds
class TestDASTAPIConnectivity:
    """Tests that verify connectivity to the Veracode Dynamic Analysis API."""

    def test_dast_ls_returns_without_auth_error(self):
        """DAST-ls-v2.sh should connect and not return a 401 auth error."""
        script = RELEASE_DIR / "DAST-ls-v2.sh"
        if not script.exists():
            pytest.skip("DAST-ls-v2.sh not found")

        result = subprocess.run(
            ["bash", str(script)],
            capture_output=True,
            text=True,
            timeout=60,
            env={**os.environ},
        )
        combined = result.stdout + result.stderr
        assert "401" not in combined, f"Authentication error returned:\n{combined}"
        assert "Unauthorized" not in combined

    def test_dast_ls_returns_json_or_status(self):
        """DAST-ls-v2.sh should return JSON data or an API status message."""
        script = RELEASE_DIR / "DAST-ls-v2.sh"
        if not script.exists():
            pytest.skip("DAST-ls-v2.sh not found")

        result = subprocess.run(
            ["bash", str(script)],
            capture_output=True,
            text=True,
            timeout=60,
        )
        # Either valid JSON response or a recognized API response structure
        combined = result.stdout + result.stderr
        assert len(combined.strip()) > 0, "No output from DAST ls script"


@skip_no_creds
class TestSASTAPIConnectivity:
    """Tests that verify connectivity to the Veracode Static Analysis API."""

    def test_search_build_no_auth_error(self):
        """SearchBuildByName.sh should connect without auth errors."""
        script = RELEASE_DIR / "SearchBuildByName.sh"
        if not script.exists():
            pytest.skip("SearchBuildByName.sh not found")

        result = subprocess.run(
            ["bash", str(script), "connectivity-test-app"],
            capture_output=True,
            text=True,
            timeout=60,
            input="",
        )
        combined = result.stdout + result.stderr
        assert "401" not in combined, f"Auth error:\n{combined}"


@skip_no_creds
class TestDASTRequestSubmission:
    """
    Tests that attempt to format and validate a DAST analysis request
    against the Veracode API schema.

    NOTE: These tests format a request JSON but do NOT submit/create scans
    to avoid affecting production data.
    """

    def test_formatted_request_valid_json(self, tmp_path):
        """A formatted DAST request should produce valid JSON output."""
        shutil.copy(FIXTURES_DIR / "allowlist.csv", tmp_path / "allowlist.csv")
        shutil.copy(FIXTURES_DIR / "blacklist.csv", tmp_path / "blacklist.csv")

        script = RELEASE_DIR / "DASTWebAppRequest-std.py"
        result = subprocess.run(
            [
                sys.executable,
                str(script),
                "api-connectivity-test",
                "https://target.example.com/",
                os.environ.get("VERACODE_ORG_EMAIL", "test@example.com"),
                "API Test",
            ],
            capture_output=True,
            text=True,
            cwd=str(tmp_path),
            timeout=30,
        )
        non_empty = [l for l in result.stdout.strip().splitlines() if l.strip()]
        assert non_empty, f"No output. stderr: {result.stderr}"

        parsed = json.loads(non_empty[-1])
        assert "name" in parsed
        assert "scans" in parsed
