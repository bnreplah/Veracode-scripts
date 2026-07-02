"""Anthropic model provider.

Shapes each request per the model family described in models.json:

  - thinking="adaptive"  -> sends thinking={"type": "adaptive"} (Opus 4.8, Sonnet 5)
  - thinking="omit"      -> sends no thinking parameter at all (Fable 5 / Mythos 5,
                            where thinking is always on and any explicit config 400s)
  - fallback_model set   -> uses the beta messages endpoint with server-side
                            refusal fallbacks so a safety-classifier decline is
                            transparently re-served by the fallback model

Structured output uses output_config.format (json_schema), so responses are
guaranteed-parseable JSON. A model that is not yet served (404) is disabled
for the rest of the run instead of failing the pipeline — this is what lets
the registry carry entries for models that ship later.
"""

import json

try:
    import anthropic
except ImportError:  # pragma: no cover - exercised only without the SDK
    anthropic = None

SERVER_SIDE_FALLBACK_BETA = "server-side-fallback-2026-06-01"


class ModelUnavailable(Exception):
    """Model is not served (yet) or was disabled mid-run."""


class ModelRefused(Exception):
    """Safety classifiers declined and no fallback rescued the request."""


class Provider:
    """Wraps one Anthropic client; issues structured requests per model config."""

    def __init__(self, client=None):
        if client is None:
            if anthropic is None:
                raise RuntimeError(
                    "The 'anthropic' package is required for live analysis: pip install anthropic"
                )
            client = anthropic.Anthropic()
        self.client = client
        self._dead_models = set()

    def available(self, model_cfg) -> bool:
        return model_cfg.id not in self._dead_models

    def structured(self, model_cfg, system: str, user: str, schema: dict) -> dict:
        """Run one structured-output request; returns the parsed JSON object."""
        if not self.available(model_cfg):
            raise ModelUnavailable(model_cfg.id)

        kwargs = {
            "model": model_cfg.id,
            "max_tokens": model_cfg.max_tokens,
            "system": system,
            "messages": [{"role": "user", "content": user}],
            "output_config": {
                "effort": model_cfg.effort,
                "format": {"type": "json_schema", "schema": schema},
            },
        }
        if model_cfg.thinking == "adaptive":
            kwargs["thinking"] = {"type": "adaptive"}
        # thinking == "omit": send nothing — Fable/Mythos reject explicit config

        try:
            if model_cfg.fallback_model:
                response = self.client.beta.messages.create(
                    betas=[SERVER_SIDE_FALLBACK_BETA],
                    fallbacks=[{"model": model_cfg.fallback_model}],
                    **kwargs,
                )
            else:
                response = self.client.messages.create(**kwargs)
        except Exception as exc:
            if _is_model_not_found(exc):
                # Model not served yet (e.g. registry entry enabled early).
                # Disable for this run; callers degrade gracefully.
                self._dead_models.add(model_cfg.id)
                raise ModelUnavailable(model_cfg.id) from exc
            raise

        if getattr(response, "stop_reason", None) == "refusal":
            raise ModelRefused(model_cfg.id)

        text = next(
            (b.text for b in response.content if getattr(b, "type", "") == "text"),
            None,
        )
        if text is None:
            raise ModelRefused(model_cfg.id)
        return json.loads(text)


def _is_model_not_found(exc) -> bool:
    if anthropic is not None and isinstance(exc, anthropic.NotFoundError):
        return True
    return "not_found" in str(exc).lower() and "model" in str(exc).lower()
