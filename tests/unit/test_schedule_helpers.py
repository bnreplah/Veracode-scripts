"""
Unit tests for scan scheduling helper functions.

These mirror the schedule logic from Scripts/Release/DASTWebAppRequest-std.py,
tested in isolation to avoid module-level side effects.
"""

import pytest


# --- Mirrors of schedule helpers from DASTWebAppRequest-std.py ---

def _is_true(value, var_true: bool = False):
    if str(value).casefold() == "true":
        return True if var_true else "true"
    return False if var_true else "false"


def schedule_now(now_b: str = _is_true(False), days: int = 1) -> dict:
    """Mirror of scheduleNow() from DASTWebAppRequest-std.py."""
    schedule = {"schedule": {
        "now": now_b,
        "duration": {
            "length": str(days),
            "unit": "DAY"
        }
    }}
    if now_b == _is_true(True):
        schedule["schedule"]["scheduled"] = True
    return schedule


def schedule_scan(start_now: bool = False, length: int = 1, unit: str = "DAY",
                  recurring: bool = False, recurrence_type: str = "WEEKLY",
                  schedule_end_after: int = 2, recurrence_interval: int = 1,
                  day_of_week: str = "FRIDAY") -> dict:
    """Mirror of scheduleScan() from DASTWebAppRequest-std.py."""
    schedule = {"schedule": {
        "duration": {"length": length, "unit": unit}
    }}
    if recurring:
        schedule["schedule"]["scan_recurrence_schedule"] = {
            "recurrence_type": recurrence_type,
            "schedule_end_after": schedule_end_after,
            "recurrence_interval": recurrence_interval,
            "day_of_week": day_of_week
        }
    if start_now:
        schedule["schedule"].update({"scheduled": True, "now": True})
    return schedule


# --- Tests ---

class TestIsTrue:
    def test_true_string_returns_true_string(self):
        assert _is_true("true") == "true"

    def test_false_string_returns_false_string(self):
        assert _is_true("false") == "false"

    def test_true_bool_with_var_true_returns_python_true(self):
        assert _is_true(True, var_true=True) is True

    def test_false_bool_with_var_true_returns_python_false(self):
        assert _is_true(False, var_true=True) is False

    def test_case_insensitive_TRUE(self):
        assert _is_true("TRUE") == "true"

    def test_case_insensitive_True(self):
        assert _is_true("True") == "true"


class TestScheduleNow:
    def test_returns_dict(self):
        result = schedule_now()
        assert isinstance(result, dict)

    def test_has_schedule_key(self):
        result = schedule_now()
        assert "schedule" in result

    def test_default_now_is_false_string(self):
        result = schedule_now()
        assert result["schedule"]["now"] == "false"

    def test_now_true_sets_scheduled_flag(self):
        result = schedule_now(now_b="true")
        assert result["schedule"].get("scheduled") is True

    def test_duration_unit_is_day(self):
        result = schedule_now()
        assert result["schedule"]["duration"]["unit"] == "DAY"

    def test_custom_days_reflected_as_string(self):
        result = schedule_now(days=5)
        assert result["schedule"]["duration"]["length"] == "5"

    def test_one_day_default(self):
        result = schedule_now()
        assert result["schedule"]["duration"]["length"] == "1"


class TestScheduleScan:
    def test_returns_dict(self):
        result = schedule_scan()
        assert isinstance(result, dict)

    def test_has_schedule_key(self):
        result = schedule_scan()
        assert "schedule" in result

    def test_default_unit_is_day(self):
        result = schedule_scan()
        assert result["schedule"]["duration"]["unit"] == "DAY"

    def test_start_now_sets_flags(self):
        result = schedule_scan(start_now=True)
        assert result["schedule"]["now"] is True
        assert result["schedule"]["scheduled"] is True

    def test_recurring_adds_recurrence_block(self):
        result = schedule_scan(recurring=True)
        assert "scan_recurrence_schedule" in result["schedule"]

    def test_recurring_day_of_week(self):
        result = schedule_scan(recurring=True, day_of_week="MONDAY")
        assert result["schedule"]["scan_recurrence_schedule"]["day_of_week"] == "MONDAY"

    def test_non_recurring_has_no_recurrence_block(self):
        result = schedule_scan(recurring=False)
        assert "scan_recurrence_schedule" not in result["schedule"]

    def test_custom_length(self):
        result = schedule_scan(length=7)
        assert result["schedule"]["duration"]["length"] == 7
