"""Operational hooks.

Hook points let external tooling — including future frontier models running
alongside the pipeline — observe or modify data at each stage without
touching pipeline code. Register with a decorator:

    from veracode_ai.hooks import hooks

    @hooks.register("post_validate")
    def my_hook(payload):
        # payload is the stage's data; return it (possibly modified)
        return payload

Hook points fired by the pipeline, in order:

    pre_ingest        raw scan payloads, before normalization
    post_normalize    list[UnifiedFinding]
    pre_correlate     list[UnifiedFinding]
    post_correlate    {"findings": [...], "correlations": [...]}
    pre_validate      findings selected for validation
    post_validate     {"finding": ..., "votes": [...], "verdict": ...} per finding
    pre_chain         confirmed findings heading into risk chaining
    post_chain        {"chains": [...]}
    report            the final report dict, before it is written
"""

HOOK_POINTS = (
    "pre_ingest",
    "post_normalize",
    "pre_correlate",
    "post_correlate",
    "pre_validate",
    "post_validate",
    "pre_chain",
    "post_chain",
    "report",
)


class HookRegistry:
    def __init__(self):
        self._hooks = {point: [] for point in HOOK_POINTS}

    def register(self, point: str):
        """Decorator: attach a callable to a hook point."""
        if point not in self._hooks:
            raise ValueError(f"unknown hook point '{point}'; valid: {HOOK_POINTS}")

        def decorator(fn):
            self._hooks[point].append(fn)
            return fn

        return decorator

    def emit(self, point: str, payload):
        """Run every hook registered at `point`, threading the payload through.

        A hook that returns None leaves the payload unchanged; any other
        return value replaces it for the next hook.
        """
        for fn in self._hooks.get(point, []):
            result = fn(payload)
            if result is not None:
                payload = result
        return payload

    def clear(self, point=None):
        if point is None:
            for p in self._hooks:
                self._hooks[p] = []
        else:
            self._hooks[point] = []

    def count(self, point: str) -> int:
        return len(self._hooks.get(point, []))


# Module-level default registry used by the pipeline
hooks = HookRegistry()
