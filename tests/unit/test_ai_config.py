"""Unit tests for the AI analysis model registry (models.json driven)."""

import sys
from pathlib import Path

import pytest

AI_DIR = Path(__file__).parent.parent.parent / "Scripts" / "AIAnalysis"
sys.path.insert(0, str(AI_DIR))

from veracode_ai.config import ModelConfig, load_registry  # noqa: E402


class TestModelConfig:
    def test_valid_model(self):
        m = ModelConfig(key="opus", id="claude-opus-4-8", roles=["validate", "chain"])
        assert m.has_role("validate")
        assert not m.has_role("triage")

    def test_invalid_thinking_rejected(self):
        with pytest.raises(ValueError):
            ModelConfig(key="x", id="y", thinking="enabled")

    def test_unknown_role_rejected(self):
        with pytest.raises(ValueError):
            ModelConfig(key="x", id="y", roles=["not-a-role"])


class TestRegistry:
    @pytest.fixture
    def registry(self):
        return load_registry()

    def test_bundled_config_loads(self, registry):
        assert "opus" in registry.models

    def test_opus_enabled_by_default(self, registry):
        assert registry.models["opus"].enabled

    def test_frontier_models_disabled_by_default(self, registry):
        # Fable and Mythos ship disabled — enabled only when the org opts in
        assert not registry.models["fable"].enabled
        assert not registry.models["mythos"].enabled

    def test_enabled_models_excludes_disabled(self, registry):
        ids = {m.id for m in registry.enabled_models()}
        assert "claude-opus-4-8" in ids
        assert "claude-mythos-5" not in ids

    def test_models_for_role(self, registry):
        validators = registry.models_for_role("validate")
        assert any(m.key == "opus" for m in validators)

    def test_models_for_roles_dedupes(self, registry):
        models = registry.models_for_roles(["validate", "chain"])
        keys = [m.key for m in models]
        assert len(keys) == len(set(keys))

    def test_enabling_frontier_model_adds_it(self, tmp_path):
        # Simulate onboarding Mythos by flipping the flag in a copied config
        import json
        cfg = json.loads((AI_DIR / "models.json").read_text())
        cfg["models"]["mythos"]["enabled"] = True
        p = tmp_path / "models.json"
        p.write_text(json.dumps(cfg))

        registry = load_registry(p)
        deep = registry.models_for_role("deep-validate")
        assert any(m.id == "claude-mythos-5" for m in deep)

    def test_fable_has_fallback_and_omits_thinking(self, registry):
        fable = registry.models["fable"]
        assert fable.fallback_model == "claude-opus-4-8"
        assert fable.thinking == "omit"

    def test_strategy_lookup(self, registry):
        strat = registry.strategy("fp_reduction")
        assert strat["mode"] == "consensus"
