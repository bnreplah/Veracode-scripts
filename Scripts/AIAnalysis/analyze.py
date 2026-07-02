#!/usr/bin/env python3
"""Veracode AI Analysis — CLI entry point.

Correlate and validate findings across Veracode scan types with one or more
Claude models. Model selection is driven entirely by models.json.

Examples:
    # Offline correlation only (no API key needed) — CI-safe
    python analyze.py --rest findings.json --offline -o report.json

    # Full pipeline: correlate + FP-reduce + risk-chain
    export ANTHROPIC_API_KEY=...
    python analyze.py --rest findings.json --container image.json -o report.json

Onboarding a new frontier model (e.g. Claude Mythos 5): set its
"enabled": true in models.json. No code change, no CLI flag.
"""

import argparse
import json
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0])

from veracode_ai.config import load_registry
from veracode_ai.pipeline import Pipeline


def main():
    parser = argparse.ArgumentParser(description="Veracode AI cross-scan analysis")
    parser.add_argument("--rest", help="Veracode REST Findings API JSON (any scan type)")
    parser.add_argument("--container", help="Container scan JSON (Veracode CLI)")
    parser.add_argument("--config", help="Path to models.json (default: bundled)")
    parser.add_argument("-o", "--output", default="ai-analysis-report.json")
    parser.add_argument("--offline", action="store_true",
                        help="Correlation only; no model calls (no API key needed)")
    parser.add_argument("--print-models", action="store_true",
                        help="Print the enabled model roster and exit")
    args = parser.parse_args()

    registry = load_registry(args.config)

    if args.print_models:
        for m in registry.enabled_models():
            print(f"{m.key:8} {m.id:20} roles={','.join(m.roles)}")
        return 0

    scan_payloads = {}
    if args.rest:
        scan_payloads["rest"] = args.rest
    if args.container:
        scan_payloads["container"] = args.container
    if not scan_payloads:
        parser.error("provide at least one of --rest / --container")

    provider = None
    if not args.offline:
        try:
            from veracode_ai.providers import Provider
            provider = Provider()
        except RuntimeError as exc:
            print(f"[WARN] {exc}\n[WARN] Falling back to --offline mode.", file=sys.stderr)

    pipeline = Pipeline(registry=registry, provider=provider)
    report = pipeline.analyze(scan_payloads, offline=args.offline or provider is None)

    with open(args.output, "w") as f:
        json.dump(report, f, indent=2)

    print(f"[INFO] mode={report['mode']} findings={report['total_findings']} "
          f"correlations={len(report['correlations'])} "
          f"chains={len(report.get('risk_chains', []))}")
    print(f"[INFO] wrote {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
