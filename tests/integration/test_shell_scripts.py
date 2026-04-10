"""
Integration tests for shell scripts under Scripts/Release/ and Scripts/Dev/bash_scripts/.

Tests:
  - bash -n syntax validation for all .sh files
  - shellcheck linting (skipped if shellcheck not installed)
  - Functional smoke tests: help output, basic invocation

These tests do NOT require Veracode API credentials.
"""

import shutil
import subprocess
import pytest
from pathlib import Path

RELEASE_DIR = Path(__file__).parent.parent.parent / "Scripts" / "Release"
DEV_BASH_DIR = Path(__file__).parent.parent.parent / "Scripts" / "Dev" / "bash_scripts"
XML_API_DIR = Path(__file__).parent.parent.parent / "xml_api_calls"

_RELEASE_SCRIPTS_CANDIDATES = [
    RELEASE_DIR / "veracode-installer.sh",
    RELEASE_DIR / "DAST-ls-v2.sh",
    RELEASE_DIR / "DAST-ls.sh",
    RELEASE_DIR / "DAST-rescan.sh",
    RELEASE_DIR / "SearchBuildByName.sh",
    RELEASE_DIR / "vdb-purl-lte.sh",
]

_DEV_BASH_SCRIPTS_CANDIDATES = [
    DEV_BASH_DIR / "veracode-installer.sh",
    DEV_BASH_DIR / "UploadExtended.sh",
    DEV_BASH_DIR / "SAST-promoteSandbox.sh",
    DEV_BASH_DIR / "SCA-Library-ProjectSearch.sh",
    DEV_BASH_DIR / "pipelinescan-sandboxscan-filesizecheck.sh",
]

# Only include scripts that actually exist on disk so ids always match values
RELEASE_SCRIPTS = [s for s in _RELEASE_SCRIPTS_CANDIDATES if s.exists()]
DEV_BASH_SCRIPTS = [s for s in _DEV_BASH_SCRIPTS_CANDIDATES if s.exists()]
ALL_SCRIPTS = RELEASE_SCRIPTS + DEV_BASH_SCRIPTS


# --- Bash syntax validation ---

class TestBashSyntax:
    @pytest.mark.parametrize(
        "script",
        [s for s in RELEASE_SCRIPTS if s.exists()],
        ids=[s.name for s in RELEASE_SCRIPTS],
    )
    def test_release_script_syntax(self, script):
        """All Release scripts should pass bash -n syntax check."""
        result = subprocess.run(
            ["bash", "-n", str(script)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, (
            f"Syntax error in {script.name}:\n{result.stderr}"
        )

    @pytest.mark.parametrize(
        "script",
        [s for s in DEV_BASH_SCRIPTS if s.exists()],
        ids=[s.name for s in DEV_BASH_SCRIPTS],
    )
    def test_dev_bash_script_syntax(self, script):
        """All Dev bash scripts should pass bash -n syntax check."""
        result = subprocess.run(
            ["bash", "-n", str(script)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, (
            f"Syntax error in {script.name}:\n{result.stderr}"
        )


# --- ShellCheck linting ---

@pytest.mark.skipif(
    not shutil.which("shellcheck"),
    reason="shellcheck not installed — install with: sudo apt-get install shellcheck",
)
class TestShellCheck:
    @pytest.mark.parametrize(
        "script",
        [s for s in RELEASE_SCRIPTS if s.exists()],
        ids=[s.name for s in RELEASE_SCRIPTS],
    )
    def test_shellcheck_release_script(self, script):
        """Release scripts should pass shellcheck at warning severity."""
        result = subprocess.run(
            ["shellcheck", "--severity=warning", str(script)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, (
            f"shellcheck issues in {script.name}:\n{result.stdout}"
        )

    @pytest.mark.parametrize(
        "script",
        [s for s in DEV_BASH_SCRIPTS if s.exists()],
        ids=[s.name for s in DEV_BASH_SCRIPTS],
    )
    def test_shellcheck_dev_script(self, script):
        """Dev bash scripts should pass shellcheck at warning severity."""
        result = subprocess.run(
            ["shellcheck", "--severity=warning", str(script)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, (
            f"shellcheck issues in {script.name}:\n{result.stdout}"
        )


# --- Functional smoke tests ---

class TestInstallerScript:
    def test_installer_help_prints_usage(self):
        """Installer script should print help text when invoked with unknown args."""
        script = RELEASE_DIR / "veracode-installer.sh"
        if not script.exists():
            pytest.skip("veracode-installer.sh not found in Release")
        result = subprocess.run(
            ["bash", str(script), "--help"],
            capture_output=True,
            text=True,
        )
        # --help hits the *) case which calls help() and exits 1
        combined = result.stdout + result.stderr
        assert "Veracode" in combined or "install" in combined.lower(), (
            f"Expected help output, got:\n{combined}"
        )

    def test_installer_help_lists_options(self):
        """Help output should list known installer flags."""
        script = RELEASE_DIR / "veracode-installer.sh"
        if not script.exists():
            pytest.skip("veracode-installer.sh not found in Release")
        result = subprocess.run(
            ["bash", str(script), "--help"],
            capture_output=True,
            text=True,
        )
        combined = result.stdout + result.stderr
        assert "--install-sca-ci" in combined or "--install-sca-cli" in combined


class TestSearchBuildByName:
    def test_script_has_valid_syntax(self):
        script = RELEASE_DIR / "SearchBuildByName.sh"
        if not script.exists():
            pytest.skip("SearchBuildByName.sh not found")
        result = subprocess.run(
            ["bash", "-n", str(script)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"Syntax error:\n{result.stderr}"

    def test_script_exists_and_is_readable(self):
        script = RELEASE_DIR / "SearchBuildByName.sh"
        if not script.exists():
            pytest.skip("SearchBuildByName.sh not found")
        assert script.stat().st_size > 0


class TestDASTRescan:
    def test_script_has_valid_syntax(self):
        script = RELEASE_DIR / "DAST-rescan.sh"
        if not script.exists():
            pytest.skip("DAST-rescan.sh not found")
        result = subprocess.run(
            ["bash", "-n", str(script)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"Syntax error:\n{result.stderr}"


class TestDASTLsV2:
    def test_script_has_valid_syntax(self):
        script = RELEASE_DIR / "DAST-ls-v2.sh"
        if not script.exists():
            pytest.skip("DAST-ls-v2.sh not found")
        result = subprocess.run(
            ["bash", "-n", str(script)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"Syntax error:\n{result.stderr}"

    def test_script_is_nonempty(self):
        script = RELEASE_DIR / "DAST-ls-v2.sh"
        if not script.exists():
            pytest.skip("DAST-ls-v2.sh not found")
        assert script.stat().st_size > 100


# --- XML API scripts ---

class TestXMLAPIScripts:
    XML_SCRIPTS = list(XML_API_DIR.glob("*.sh")) if XML_API_DIR.exists() else []

    @pytest.mark.parametrize(
        "script",
        XML_SCRIPTS,
        ids=[s.name for s in XML_SCRIPTS],
    )
    def test_xml_api_script_syntax(self, script):
        """XML API helper scripts should have valid bash syntax."""
        result = subprocess.run(
            ["bash", "-n", str(script)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, (
            f"Syntax error in {script.name}:\n{result.stderr}"
        )
