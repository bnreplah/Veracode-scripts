# reconscope

HTTP surface discovery, fingerprinting, and error/information-disclosure
detection — single Python file, one required dependency, menu-driven.

**Authorized use only.** This sends live HTTP requests (and optionally raw
TCP probes and headless-browser page loads) to hosts you provide. Use it only
against systems you own or are explicitly authorized to test.

## Install

```bash
pip install -r requirements.txt
```

That's it for the core tool (`requests` is the only hard dependency — no
rich/colorama/bs4; colors and parsing are hand-rolled to keep this a true
single-file, no-build-step script).

The screenshot feature is optional and lazy-imported — the rest of the tool
runs fine without it:

```bash
pip install playwright
playwright install chromium
```

## Quick start

```bash
python3 reconscope.py                       # interactive menu
python3 reconscope.py -f urls.txt            # preload from file, then menu
python3 reconscope.py -u https://example.com # preload one URL, then menu
python3 reconscope.py -f urls.csv --batch -o results.json   # non-interactive, for CI/pipelines
```

`urls.txt`: one URL per line, `#` comments and blank lines ignored, scheme
optional (defaults to `https://`).
`urls.csv`: a column named `url`/`link`/`website`/`target`/`host` (any case)
if present, otherwise the first column.

## What each menu option does

1. **Load URLs** — manual entry (one per line) or from a `.txt`/`.csv` file.
2. **Initial discovery** — concurrent GET to every queued URL: response code,
   response headers, the `Server` header (the HTTP-level "banner"), cookies,
   and a fingerprint pass against ~40 header/cookie/body signatures (Apache,
   nginx, IIS, PHP, WordPress, Drupal, Next.js, Cloudflare, etc. — see
   `FINGERPRINT_RULES` near the top of the file to extend it). The response
   body is also scanned for ~16 error/information-disclosure signatures
   (PHP fatals, Django/Flask debug pages, ASP.NET YSOD, stack traces, raw SQL
   errors, etc. — see `ERROR_SIGNATURES`) so a soft error hiding behind a 200
   status still gets flagged.
3. **View / filter / investigate** — filter the running result set by status
   code, status class, response-header substring, request-header substring,
   fingerprint, "has errors only", URL substring, or phase; drill into any
   single result for the full request/response header dump.
4. **Secondary iteration** — select a subset of already-discovered URLs
   (`all`, `1,3,5-8`, `status:4xx`, `status:2xx`, `status:err`, or any comma
   mix), choose an HTTP method, set headers/payload that apply to *all*
   selected URLs, then optionally override headers/payload per individual
   URL. Re-sends and records new color-coded response codes as a fresh
   result set (`phase: secondary`) without overwriting the originals.
5. **Screenshot + parse** — headless Chromium loads each selected URL,
   saves a full-page PNG, and re-runs the error-signature scan against the
   **JS-rendered** DOM — this catches client-rendered error states (e.g. a
   React error boundary) that the raw HTTP body in step 2 can't see.
6. **Export / import** — dump all results or the current filter to JSON
   (full fidelity) or CSV (flattened, spreadsheet-friendly); reload a prior
   JSON export to keep investigating later.
7. **Settings** — timeout, concurrency, TLS verification on/off, optional
   raw TCP banner grab, User-Agent.

Response codes are ANSI color-coded throughout: green 2xx, cyan 3xx, yellow
4xx, red 5xx, magenta for a request that errored out (timeout/DNS/connection
refused) before a status was ever returned.

## Design notes

- **Raw banner grab** (socket connect + read before sending anything) is
  off by default — most HTTP(S) services are request-first and return
  nothing, so it mainly adds a per-host timeout tax at scale. It's there
  (settings menu / `--raw-banner`) for the services that do volunteer a
  banner, and for completeness.
- **Bodies are never stored in full** — only a 300-char snippet plus
  whatever signature matches were found — so bulk runs stay memory-light.
- **`--batch` mode** runs discovery once and exits (JSON/CSV export), so
  this slots into a CI pipeline as a DAST-adjacent step if useful.
- Screenshot capture is deliberately **serial**, not concurrent — Chromium
  automation across threads adds real failure modes for comparatively
  little benefit here, since this step is normally run against a short,
  already-filtered list rather than the full bulk set.

## Files

- `reconscope.py` — the tool.
- `requirements.txt` — dependencies.
- `test_server.py` / `smoke_test.py` — local dummy-target smoke test (no
  internet required) covering discovery, fingerprinting, error detection,
  secondary requests, selection parsing, and export/import. Useful as a
  regression check after any edit:

  ```bash
  python3 test_server.py 8765 &
  python3 smoke_test.py
  kill %1
  ```
