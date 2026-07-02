"""Model registry loader.

The registry is pure data (models.json). Adding or enabling a model —
including Claude Mythos 5 or a future frontier model — is a config edit,
never a code change. Each entry carries the request-shaping knobs that
differ between model families (thinking mode, effort, refusal fallback).
"""

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

DEFAULT_CONFIG_PATH = Path(__file__).parent.parent / "models.json"

VALID_ROLES = {
    "triage",          # initial severity/priority assessment
    "validate",        # standard FP validation vote
    "deep-validate",   # frontier-model validation (higher-confidence vote)
    "correlate",       # cross-scan correlation assistance
    "chain",           # risk/attack-path chaining
    "second-opinion",  # full-set review for missed findings
}

# "adaptive" -> send thinking={"type": "adaptive"} (Opus/Sonnet 4.6+)
# "omit"     -> send no thinking param at all (Fable 5 / Mythos 5: always on)
VALID_THINKING = {"adaptive", "omit"}


@dataclass
class ModelConfig:
    key: str
    id: str
    enabled: bool = True
    thinking: str = "adaptive"
    effort: str = "high"
    max_tokens: int = 8000
    fallback_model: Optional[str] = None
    roles: list = field(default_factory=list)

    def __post_init__(self):
        if self.thinking not in VALID_THINKING:
            raise ValueError(
                f"model '{self.key}': thinking must be one of {sorted(VALID_THINKING)}"
            )
        unknown = set(self.roles) - VALID_ROLES
        if unknown:
            raise ValueError(f"model '{self.key}': unknown roles {sorted(unknown)}")

    def has_role(self, role: str) -> bool:
        return role in self.roles


@dataclass
class Registry:
    models: dict
    strategies: dict

    def enabled_models(self) -> list:
        return [m for m in self.models.values() if m.enabled]

    def models_for_role(self, role: str) -> list:
        """All enabled models that can serve a role."""
        return [m for m in self.enabled_models() if m.has_role(role)]

    def models_for_roles(self, roles) -> list:
        """Enabled models matching any of the given roles, deduplicated."""
        seen, out = set(), []
        for role in roles:
            for m in self.models_for_role(role):
                if m.key not in seen:
                    seen.add(m.key)
                    out.append(m)
        return out

    def strategy(self, name: str) -> dict:
        return self.strategies.get(name, {})


def load_registry(path=None) -> Registry:
    """Load models.json into a validated Registry."""
    config_path = Path(path) if path else DEFAULT_CONFIG_PATH
    with open(config_path) as f:
        raw = json.load(f)

    models = {}
    for key, entry in raw.get("models", {}).items():
        entry = {k: v for k, v in entry.items() if not k.startswith("_")}
        models[key] = ModelConfig(key=key, **entry)

    return Registry(models=models, strategies=raw.get("strategies", {}))
