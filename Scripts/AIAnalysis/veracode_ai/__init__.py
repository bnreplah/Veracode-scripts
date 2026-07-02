"""Veracode AI analysis layer.

Model-agnostic pipeline that correlates findings across Veracode scan types
(SAST, DAST, SCA, container), validates them with one or more Claude models
to reduce false positives, and chains related findings into risk paths.

New frontier models (Claude Mythos 5, future releases) are onboarded by
editing models.json — no code changes required.
"""

from .config import ModelConfig, Registry, load_registry
from .findings import UnifiedFinding, normalize_findings
from .hooks import HookRegistry, hooks

__all__ = [
    "ModelConfig",
    "Registry",
    "load_registry",
    "UnifiedFinding",
    "normalize_findings",
    "HookRegistry",
    "hooks",
]
