# Veracode AI Analysis Layer

A model-agnostic pipeline that sits on top of the Veracode scripts and adds
**cross-scan correlation**, **AI-assisted false-positive reduction**, and
**risk chaining** using one or more Claude models.

It is built so that **Claude Mythos 5 and future frontier models can be
switched on with a config edit** — no code changes — to validate and feed
into the results, reduce false positives, and surface a deeper breadth of
chained findings.

---

## What it does

```
 Veracode scans                    AI Analysis Layer                 Output
┌──────────────┐   normalize   ┌────────────────────────────┐   ┌──────────────┐
│ SAST (STATIC)│──────────────▶│ 1. Correlate (deterministic)│   │ risk chains  │
│ DAST         │               │ 2. Validate  (model panel)  │──▶│ FP verdicts  │
│ SCA          │               │ 3. Chain     (model)        │   │ correlations │
│ Container    │               └────────────────────────────┘   └──────────────┘
└──────────────┘                  driven entirely by models.json
```

1. **Normalize** every scan type into one `UnifiedFinding` shape.
2. **Correlate** (offline, rule-based — runs in CI with no API key):
   - **cross-layer confirmation** — same CWE found by SAST *and* DAST (present in code *and* reachable at runtime)
   - **common flaw source** — static findings sharing a data-path source (fix once, remediate many)
   - **shared CVE** — the same CVE in both SCA and container scans (confirmed in the deployed artifact)
   - **dependency usage** — a vulnerable SCA component referenced by first-party flawed code
3. **Validate** — every enabled validator model independently tries to *refute*
   each finding; a consensus quorum decides confirmed vs. likely-false-positive.
4. **Chain** — a chain-role model composes correlated findings into ordered
   attack paths with combined severity, remediation order, and a recommended
   security-training topic.

---

## Onboarding a new frontier model (Mythos / next model)

Edit [`models.json`](models.json) — set `"enabled": true`. That's the whole change.

```jsonc
"mythos": {
  "id": "claude-mythos-5",
  "enabled": true,            // ← flip this on
  "thinking": "omit",         // Fable/Mythos: thinking always on, send no config
  "effort": "xhigh",
  "max_tokens": 16000,
  "fallback_model": "claude-opus-4-8",   // refusal fallback via server-side beta
  "roles": ["deep-validate", "chain", "second-opinion"]
}
```

The new model immediately:
- joins the **validator panel** (a `deep-validate` vote runs alongside the existing votes),
- runs in the **chain stage** (its chains are tagged with its model id so you can compare),
- and requests are shaped correctly for its family (adaptive thinking vs. omit,
  effort level, server-side refusal fallback).

A model that isn't served yet (404) is disabled for that run and the pipeline
degrades gracefully — so you can enable a registry entry ahead of GA without
breaking CI.

**Roles**: `triage`, `validate`, `deep-validate`, `correlate`, `chain`, `second-opinion`.

---

## Operational hooks

Every stage fires a hook so external tooling — including a future frontier
model running *alongside* the pipeline — can observe or transform the data
without editing pipeline code:

```python
from veracode_ai.hooks import hooks

@hooks.register("post_validate")
def route_low_confidence(payload):
    # payload = {"finding": ..., "verdict": ..., "votes": [...]}
    # e.g. send split-vote findings to a frontier model for a second opinion
    return payload
```

Hook points, in order: `pre_ingest`, `post_normalize`, `pre_correlate`,
`post_correlate`, `pre_validate`, `post_validate`, `pre_chain`, `post_chain`,
`report`.

---

## Usage

```bash
# Offline correlation only — no API key, CI-safe
python analyze.py --rest findings.json --offline -o report.json

# Full pipeline: correlate + FP-reduce + risk-chain
export ANTHROPIC_API_KEY=...
python analyze.py \
  --rest findings.json \
  --container image-scan.json \
  -o report.json

# Show the enabled model roster
python analyze.py --print-models
```

`--rest` takes a Veracode REST Findings API response
(`GET /appsec/v2/applications/{guid}/findings`, any scan type). `--container`
takes Veracode CLI container scan JSON.

### As a library

```python
from veracode_ai import load_registry
from veracode_ai.pipeline import Pipeline
from veracode_ai.providers import Provider

pipeline = Pipeline(registry=load_registry(), provider=Provider())
report = pipeline.analyze({"rest": "findings.json", "container": "image.json"})
```

---

## Design notes

- **Model-agnostic**: no model id is hard-coded in the pipeline; everything
  comes from `models.json` via the registry.
- **Structured outputs**: every model call uses `output_config.format`
  (`json_schema`), so responses are guaranteed-parseable — no fragile text scraping.
- **Family-aware requests**: `providers.py` sends `thinking={"type":"adaptive"}`
  for Opus/Sonnet, omits `thinking` entirely for Fable/Mythos (where it's always
  on), and attaches server-side refusal fallbacks when a `fallback_model` is set.
- **Adversarial validation**: validators are prompted to *refute* findings, and
  a finding only becomes a likely-FP on a quorum — biased toward not silently
  dropping real bugs.
- **Offline-first**: correlation needs only the standard library, so it runs in
  every CI job; the model stages are additive.

Requirements: `pip install -r requirements.txt` (only needed for the
validate/chain stages; correlation is stdlib-only).
