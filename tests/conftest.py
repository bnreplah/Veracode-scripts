"""
Shared pytest fixtures and configuration for the Veracode SDK test suite.
"""

import shutil
import pytest
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
SCRIPTS_DIR = REPO_ROOT / "Scripts"
RELEASE_DIR = SCRIPTS_DIR / "Release"
DEV_DIR = SCRIPTS_DIR / "Dev"
FIXTURES_DIR = Path(__file__).parent / "fixtures"


@pytest.fixture(scope="session")
def repo_root():
    """Return the repository root path."""
    return REPO_ROOT


@pytest.fixture(scope="session")
def release_dir():
    """Return the path to the Release scripts directory."""
    return RELEASE_DIR


@pytest.fixture(scope="session")
def dev_dir():
    """Return the path to the Dev scripts directory."""
    return DEV_DIR


@pytest.fixture(scope="session")
def fixtures_dir():
    """Return the path to the test fixtures directory."""
    return FIXTURES_DIR


@pytest.fixture
def tmp_work_dir(tmp_path):
    """
    Create a temp working directory pre-populated with all test CSV fixtures.
    Use this for running scripts that need allowlist.csv, blacklist.csv, glblacklist.csv
    in the current working directory.
    """
    for csv_file in FIXTURES_DIR.glob("*.csv"):
        shutil.copy(csv_file, tmp_path / csv_file.name)
    return tmp_path
