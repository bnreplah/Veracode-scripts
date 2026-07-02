"""
Unit tests for email validation logic used in DASTWebAppRequest-std.py.

The is_valid_email() function uses the pattern r'^[\\w\\.-]+@[\\w\\.-]+\\.\\w+$'.
These tests verify that behavior without importing the script (which has
module-level side effects including stdin prompts and file I/O).
"""

import re
import pytest

# Pattern mirrored from Scripts/Release/DASTWebAppRequest-std.py
EMAIL_PATTERN = r'^[\w\.-]+@[\w\.-]+\.\w+$'


def is_valid_email(email: str) -> bool:
    """Mirror of is_valid_email() from DASTWebAppRequest-std.py."""
    return bool(re.match(EMAIL_PATTERN, email))


class TestValidEmails:
    def test_simple_email(self):
        assert is_valid_email("user@example.com")

    def test_subdomain_email(self):
        assert is_valid_email("user@mail.example.com")

    def test_dot_in_local_part(self):
        assert is_valid_email("first.last@example.com")

    def test_hyphen_in_domain(self):
        assert is_valid_email("user@my-company.com")

    def test_numeric_local_part(self):
        assert is_valid_email("user123@example.com")

    def test_underscore_in_local(self):
        assert is_valid_email("user_name@example.com")

    def test_multi_level_tld(self):
        assert is_valid_email("user@example.co.uk")


class TestInvalidEmails:
    def test_no_at_sign(self):
        assert not is_valid_email("userexample.com")

    def test_no_domain_after_at(self):
        assert not is_valid_email("user@")

    def test_no_tld(self):
        assert not is_valid_email("user@example")

    def test_empty_string(self):
        assert not is_valid_email("")

    def test_only_at_sign(self):
        assert not is_valid_email("@")

    def test_plus_sign_not_supported(self):
        # The script's pattern uses [\w\.-] which does NOT include +
        # This documents that the pattern rejects plus-addressed emails
        assert not is_valid_email("user+tag@example.com")

    def test_spaces_rejected(self):
        assert not is_valid_email("user @example.com")

    def test_double_at(self):
        assert not is_valid_email("user@@example.com")
