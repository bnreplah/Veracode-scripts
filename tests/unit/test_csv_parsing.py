"""
Unit tests for CSV-to-JSON parsing logic.

Tests the allowlist and blacklist CSV parsing behavior that feeds into
DASTWebAppRequest-std.py and BlackList-std.py, verified against fixture files
and controlled temporary CSVs.
"""

import csv
import json
import pytest
from pathlib import Path

FIXTURES_DIR = Path(__file__).parent.parent / "fixtures"

VALID_RESTRICTION_TYPES = {
    "NONE",
    "FILE",
    "FOLDER_ONLY",
    "DIRECTORY_AND_SUBDIRECTORY",
}


# --- Helpers mirroring script CSV parsing logic ---

def parse_allowlist_csv(csv_path: str) -> dict:
    """
    Mirror of allowlistConfigCSVtoJSON() from DASTWebAppRequest-std.py.
    Returns {"allowed_hosts": [...]} or raises on error.
    """
    allowed_hosts = []
    with open(csv_path, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            allowed_hosts.append({
                "directory_restriction_type": row["directory_restriction_type"],
                "http_and_https": str(row["http_and_https"]).strip().lower(),
                "url": row["url"].strip(),
            })
    return {"allowed_hosts": allowed_hosts}


def parse_blacklist_csv(csv_path: str) -> list:
    """
    Mirror of blacklistConfigCSVtoJSON() from BlackList-std.py.
    Returns a list of blacklist entry dicts.
    """
    entries = []
    with open(csv_path, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            entries.append({
                "directory_restriction_type": row["directory_restriction_type"],
                "http_and_https": str(row["http_and_https"]).strip().lower(),
                "url": row["url"].strip(),
            })
    return entries


# --- Allowlist fixture tests ---

class TestAllowlistCSVFixture:
    def test_fixture_loads_without_error(self):
        result = parse_allowlist_csv(FIXTURES_DIR / "allowlist.csv")
        assert result is not None

    def test_result_has_allowed_hosts_key(self):
        result = parse_allowlist_csv(FIXTURES_DIR / "allowlist.csv")
        assert "allowed_hosts" in result

    def test_fixture_has_multiple_entries(self):
        result = parse_allowlist_csv(FIXTURES_DIR / "allowlist.csv")
        assert len(result["allowed_hosts"]) >= 2

    def test_each_entry_has_required_fields(self):
        result = parse_allowlist_csv(FIXTURES_DIR / "allowlist.csv")
        for host in result["allowed_hosts"]:
            assert "directory_restriction_type" in host
            assert "http_and_https" in host
            assert "url" in host

    def test_urls_are_nonempty(self):
        result = parse_allowlist_csv(FIXTURES_DIR / "allowlist.csv")
        for host in result["allowed_hosts"]:
            assert host["url"] != ""

    def test_http_and_https_is_boolean_string(self):
        result = parse_allowlist_csv(FIXTURES_DIR / "allowlist.csv")
        for host in result["allowed_hosts"]:
            assert host["http_and_https"].lower() in ("true", "false")

    def test_restriction_types_are_valid(self):
        result = parse_allowlist_csv(FIXTURES_DIR / "allowlist.csv")
        for host in result["allowed_hosts"]:
            assert host["directory_restriction_type"] in VALID_RESTRICTION_TYPES


# --- Blacklist fixture tests ---

class TestBlacklistCSVFixture:
    def test_fixture_loads_without_error(self):
        result = parse_blacklist_csv(FIXTURES_DIR / "blacklist.csv")
        assert result is not None

    def test_fixture_has_entries(self):
        result = parse_blacklist_csv(FIXTURES_DIR / "blacklist.csv")
        assert len(result) >= 1

    def test_each_entry_has_required_fields(self):
        result = parse_blacklist_csv(FIXTURES_DIR / "blacklist.csv")
        for entry in result:
            assert "directory_restriction_type" in entry
            assert "http_and_https" in entry
            assert "url" in entry

    def test_restriction_types_are_valid(self):
        result = parse_blacklist_csv(FIXTURES_DIR / "blacklist.csv")
        for entry in result:
            assert entry["directory_restriction_type"] in VALID_RESTRICTION_TYPES

    def test_http_and_https_is_boolean_string(self):
        result = parse_blacklist_csv(FIXTURES_DIR / "blacklist.csv")
        for entry in result:
            assert entry["http_and_https"].lower() in ("true", "false")


# --- Edge case tests with tmp files ---

class TestCSVEdgeCases:
    def test_empty_allowlist_returns_empty_list(self, tmp_path):
        csv_file = tmp_path / "allowlist.csv"
        csv_file.write_text("directory_restriction_type,http_and_https,url\n")
        result = parse_allowlist_csv(csv_file)
        assert result["allowed_hosts"] == []

    def test_empty_blacklist_returns_empty_list(self, tmp_path):
        csv_file = tmp_path / "blacklist.csv"
        csv_file.write_text("directory_restriction_type,http_and_https,url\n")
        result = parse_blacklist_csv(csv_file)
        assert result == []

    def test_single_allowlist_entry(self, tmp_path):
        csv_file = tmp_path / "allowlist.csv"
        csv_file.write_text(
            "directory_restriction_type,http_and_https,url\n"
            "NONE,TRUE,https://single.example.com\n"
        )
        result = parse_allowlist_csv(csv_file)
        assert len(result["allowed_hosts"]) == 1
        assert result["allowed_hosts"][0]["url"] == "https://single.example.com"

    def test_multiple_blacklist_entries(self, tmp_path):
        csv_file = tmp_path / "blacklist.csv"
        csv_file.write_text(
            "directory_restriction_type,http_and_https,url\n"
            "NONE,TRUE,https://blocked1.example.com\n"
            "FILE,FALSE,https://blocked2.example.com\n"
            "DIRECTORY_AND_SUBDIRECTORY,TRUE,https://blocked3.example.com\n"
        )
        result = parse_blacklist_csv(csv_file)
        assert len(result) == 3

    def test_missing_file_raises_error(self, tmp_path):
        with pytest.raises((FileNotFoundError, OSError)):
            parse_allowlist_csv(tmp_path / "nonexistent.csv")

    def test_result_serializes_to_json(self):
        result = parse_allowlist_csv(FIXTURES_DIR / "allowlist.csv")
        serialized = json.dumps(result)
        assert isinstance(serialized, str)
        reparsed = json.loads(serialized)
        assert reparsed["allowed_hosts"] == result["allowed_hosts"]

    def test_glblacklist_fixture_loads(self):
        result = parse_blacklist_csv(FIXTURES_DIR / "glblacklist.csv")
        assert isinstance(result, list)
        assert len(result) >= 1
