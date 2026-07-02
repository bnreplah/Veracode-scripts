"""Unit tests for the operational hook registry."""

import sys
from pathlib import Path

import pytest

AI_DIR = Path(__file__).parent.parent.parent / "Scripts" / "AIAnalysis"
sys.path.insert(0, str(AI_DIR))

from veracode_ai.hooks import HookRegistry  # noqa: E402


class TestHookRegistry:
    def test_register_and_emit(self):
        reg = HookRegistry()
        seen = []

        @reg.register("post_normalize")
        def _hook(payload):
            seen.append(payload)

        reg.emit("post_normalize", ["finding"])
        assert seen == [["finding"]]

    def test_hook_can_transform_payload(self):
        reg = HookRegistry()

        @reg.register("pre_validate")
        def _drop_info(findings):
            return [f for f in findings if f != "info"]

        result = reg.emit("pre_validate", ["bug", "info", "flaw"])
        assert result == ["bug", "flaw"]

    def test_returning_none_preserves_payload(self):
        reg = HookRegistry()

        @reg.register("report")
        def _observe(payload):
            pass  # returns None

        original = {"k": "v"}
        assert reg.emit("report", original) is original

    def test_multiple_hooks_chain_in_order(self):
        reg = HookRegistry()

        @reg.register("report")
        def _first(p):
            return p + ["a"]

        @reg.register("report")
        def _second(p):
            return p + ["b"]

        assert reg.emit("report", []) == ["a", "b"]

    def test_unknown_hook_point_rejected(self):
        reg = HookRegistry()
        with pytest.raises(ValueError):
            reg.register("not_a_point")

    def test_count_and_clear(self):
        reg = HookRegistry()
        reg.register("report")(lambda p: p)
        assert reg.count("report") == 1
        reg.clear("report")
        assert reg.count("report") == 0
