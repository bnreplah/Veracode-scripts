#!/usr/bin/env python3
"""
reconscope — HTTP surface discovery & fingerprinting toolkit
Veracode

Bulk header/banner grabbing, technology fingerprinting, error/information-
disclosure detection, an authenticated-payload re-test pass, and optional
headless screenshot capture, driven from a single interactive CLI.

AUTHORIZED USE ONLY. This tool sends live HTTP requests (and, optionally,
raw TCP probes and headless-browser page loads) to hosts you provide. Use it
only against systems you own or are explicitly authorized to test. You are
responsible for complying with applicable law and any engagement scope.

Dependencies: `requests` (required). `playwright` (optional, screenshot
feature only — the rest of the tool runs without it).

Usage:
    python3 reconscope.py                          # interactive menu
    python3 reconscope.py -f urls.txt               # preload from file, then menu
    python3 reconscope.py -u https://example.com     # preload one URL, then menu
    python3 reconscope.py -f urls.csv --batch -o out.json   # non-interactive discovery only
"""

from __future__ import annotations

import argparse
import concurrent.futures as cf
import csv
import ipaddress
import json
import re
import socket
import sys
import threading
import time
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, List, Dict, Any, Tuple
from urllib.parse import urlparse

import requests
from requests.adapters import HTTPAdapter

try:
    from urllib3.util.retry import Retry
except ImportError:  # pragma: no cover
    Retry = None

VERSION = "1.0.0"
TOOL_NAME = "reconscope"

# --------------------------------------------------------------------------
# ANSI color (zero extra dependencies — no colorama/rich required)
# --------------------------------------------------------------------------

class C:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    WHITE = "\033[37m"
    BR_RED = "\033[91m"
    BR_GREEN = "\033[92m"
    BR_YELLOW = "\033[93m"
    BR_CYAN = "\033[96m"
    GREY = "\033[90m"


def _supports_color() -> bool:
    return sys.stdout.isatty()


_COLOR_ENABLED = _supports_color()


def paint(text: str, *codes: str) -> str:
    """Wrap text in ANSI codes if the terminal supports it, else return plain."""
    if not _COLOR_ENABLED or not codes:
        return text
    return "".join(codes) + text + C.RESET


def status_color_codes(status: Optional[int]) -> Tuple[str, ...]:
    """Return the ANSI code(s) appropriate for an HTTP status code (or None = error)."""
    if status is None:
        return (C.BOLD, C.MAGENTA)
    if 200 <= status < 300:
        return (C.GREEN,)
    if 300 <= status < 400:
        return (C.CYAN,)
    if 400 <= status < 500:
        return (C.YELLOW,)
    if 500 <= status < 600:
        return (C.RED,)
    return (C.WHITE,)


def status_label(status: Optional[int], reason: Optional[str] = None) -> str:
    if status is None:
        return paint("ERR", C.BOLD, C.MAGENTA)
    text = f"{status}" + (f" {reason}" if reason else "")
    return paint(text, *status_color_codes(status))


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def banner() -> str:
    return paint(
        f"\n=== Veracode :: {TOOL_NAME} v{VERSION} ===\n"
        "Authorized use only — scan only what you own or are cleared to test.\n",
        C.BOLD, C.CYAN,
    )


# --------------------------------------------------------------------------
# Data model
# --------------------------------------------------------------------------

@dataclass
class ScanResult:
    index: int
    url: str
    phase: str                              # "initial" | "secondary"
    method: str = "GET"
    timestamp: str = field(default_factory=now_iso)
    status_code: Optional[int] = None
    reason: Optional[str] = None
    elapsed_ms: Optional[float] = None
    final_url: Optional[str] = None         # after redirects
    request_headers: Dict[str, str] = field(default_factory=dict)
    response_headers: Dict[str, str] = field(default_factory=dict)
    cookies: Dict[str, str] = field(default_factory=dict)
    banner_http: Optional[str] = None       # Server header, effectively the HTTP "banner"
    banner_raw: Optional[str] = None        # raw TCP banner, if requested
    fingerprints: List[str] = field(default_factory=list)
    payload_sent: Optional[str] = None
    body_snippet: Optional[str] = None      # small excerpt only — bodies are not stored in full
    error_signatures: List[Tuple[str, str]] = field(default_factory=list)
    network_error: Optional[str] = None     # set when the request itself failed
    screenshot_path: Optional[str] = None
    rendered_error_signatures: List[Tuple[str, str]] = field(default_factory=list)

    def status_display(self) -> str:
        return status_label(self.status_code, self.reason)

    def to_flat_dict(self) -> Dict[str, Any]:
        """Flattened representation safe for CSV export."""
        d = asdict(self)
        d["request_headers"] = json.dumps(self.request_headers)
        d["response_headers"] = json.dumps(self.response_headers)
        d["cookies"] = json.dumps(self.cookies)
        d["fingerprints"] = "; ".join(self.fingerprints)
        d["error_signatures"] = "; ".join(f"{lbl}:{snip}" for lbl, snip in self.error_signatures)
        d["rendered_error_signatures"] = "; ".join(
            f"{lbl}:{snip}" for lbl, snip in self.rendered_error_signatures
        )
        return d


# --------------------------------------------------------------------------
# Fingerprint signature database
# --------------------------------------------------------------------------
# Extend freely — each rule is (tech_label, kind, key_or_None, pattern_or_None).
# kind: "header" (presence only), "header_value" (key + regex on value),
#       "cookie" (presence only), "body" (regex over a capped slice of the body)

@dataclass
class FPRule:
    tech: str
    kind: str
    key: Optional[str] = None
    pattern: Optional[re.Pattern] = None


FINGERPRINT_RULES: List[FPRule] = [
    # --- Headers: presence-only ---
    FPRule("ASP.NET", "header", key="X-AspNet-Version"),
    FPRule("ASP.NET MVC", "header", key="X-AspNetMvc-Version"),
    FPRule("Cloudflare", "header", key="CF-RAY"),
    FPRule("Cloudflare", "header", key="CF-Cache-Status"),
    FPRule("AWS CloudFront", "header", key="X-Amz-Cf-Id"),
    FPRule("Varnish Cache", "header", key="X-Varnish"),
    FPRule("Drupal", "header", key="X-Drupal-Cache"),
    FPRule("Drupal", "header", key="X-Generator", pattern=re.compile(r"Drupal", re.I)),
    FPRule("Akamai", "header", key="X-Akamai-Transformed"),
    FPRule("Fastly", "header", key="X-Fastly-Request-ID"),
    FPRule("Vercel", "header", key="X-Vercel-Id"),
    FPRule("Symfony Debug", "header", key="X-Debug-Token"),
    # --- Headers: value pattern match ---
    FPRule("PHP", "header_value", key="X-Powered-By", pattern=re.compile(r"PHP", re.I)),
    FPRule("Express/Node.js", "header_value", key="X-Powered-By", pattern=re.compile(r"Express", re.I)),
    FPRule("Apache httpd", "header_value", key="Server", pattern=re.compile(r"Apache", re.I)),
    FPRule("Nginx", "header_value", key="Server", pattern=re.compile(r"nginx", re.I)),
    FPRule("Microsoft IIS", "header_value", key="Server", pattern=re.compile(r"IIS", re.I)),
    FPRule("LiteSpeed", "header_value", key="Server", pattern=re.compile(r"LiteSpeed", re.I)),
    FPRule("Cowboy (Erlang)", "header_value", key="Server", pattern=re.compile(r"Cowboy", re.I)),
    FPRule("Werkzeug (Flask dev)", "header_value", key="Server", pattern=re.compile(r"Werkzeug", re.I)),
    # --- Cookies: presence-only ---
    FPRule("PHP", "cookie", key="PHPSESSID"),
    FPRule("Java / JSP", "cookie", key="JSESSIONID"),
    FPRule("Laravel", "cookie", key="laravel_session"),
    FPRule("Django", "cookie", key="csrftoken"),
    FPRule("Django", "cookie", key="sessionid"),
    FPRule("CodeIgniter", "cookie", key="ci_session"),
    FPRule("Express/Node.js", "cookie", key="connect.sid"),
    FPRule("ASP.NET", "cookie", key="ASP.NET_SessionId"),
    # --- Body: regex over a capped slice ---
    FPRule("WordPress", "body", pattern=re.compile(r'wp-content/|wp-includes/|content="WordPress', re.I)),
    FPRule("Drupal", "body", pattern=re.compile(r"Drupal\.settings|/sites/default/files|/sites/all/", re.I)),
    FPRule("Joomla", "body", pattern=re.compile(r'Joomla!|content="Joomla|/media/jui/', re.I)),
    FPRule("Next.js", "body", pattern=re.compile(r"__NEXT_DATA__|/_next/static", re.I)),
    FPRule("React", "body", pattern=re.compile(r"data-reactroot|react-dom(\.min)?\.js", re.I)),
    FPRule("Angular", "body", pattern=re.compile(r"ng-version=|ng-app[= ]", re.I)),
    FPRule("Vue.js", "body", pattern=re.compile(r"data-v-[0-9a-f]{6,}|__vue__", re.I)),
    FPRule("Bootstrap", "body", pattern=re.compile(r"bootstrap(\.min)?\.css", re.I)),
    FPRule("jQuery", "body", pattern=re.compile(r"jquery(-[\d.]+)?(\.min)?\.js", re.I)),
    FPRule("Shopify", "body", pattern=re.compile(r"cdn\.shopify\.com|Shopify\.theme", re.I)),
    FPRule("Magento", "body", pattern=re.compile(r"Mage\.Cookies|/skin/frontend/", re.I)),
    FPRule("Spring Boot", "body", pattern=re.compile(r"Whitelabel Error Page", re.I)),
]

BODY_SNIFF_CAP = 200_000  # max characters of body inspected for fingerprint/error signatures


def fingerprint_response(resp: "requests.Response", body_text: str) -> List[str]:
    found: List[str] = []
    headers = resp.headers  # case-insensitive dict
    cookie_names = set(resp.cookies.keys())
    slice_ = body_text[:BODY_SNIFF_CAP]

    for rule in FINGERPRINT_RULES:
        hit = False
        if rule.kind == "header" and rule.key in headers:
            hit = True
        elif rule.kind == "header_value" and rule.key in headers:
            val = headers.get(rule.key, "")
            if rule.pattern and rule.pattern.search(val):
                hit = True
        elif rule.kind == "cookie" and rule.key in cookie_names:
            hit = True
        elif rule.kind == "body" and rule.pattern and rule.pattern.search(slice_):
            hit = True
        if hit and rule.tech not in found:
            found.append(rule.tech)
    return found


# --------------------------------------------------------------------------
# Error / information-disclosure signature database
# --------------------------------------------------------------------------

ERROR_SIGNATURES: List[Tuple[str, re.Pattern]] = [
    ("PHP Fatal Error", re.compile(r"Fatal error:.{0,120}?on line \d+", re.I | re.S)),
    ("PHP Warning", re.compile(r"Warning:\s+\w+\(\)", re.I)),
    ("PHP Notice", re.compile(r"Notice:\s+Undefined", re.I)),
    ("PHP Parse Error", re.compile(r"Parse error:.{0,120}?on line \d+", re.I | re.S)),
    ("Django Debug Page", re.compile(r"You're seeing this error because.{0,40}DEBUG.{0,10}True|DisallowedHost", re.I | re.S)),
    ("Flask/Werkzeug Debugger", re.compile(r"Werkzeug Debugger|The debugger caught an exception", re.I)),
    ("ASP.NET YSOD", re.compile(r"Server Error in '/' Application|Runtime Error.{0,80}ASP\.NET", re.I | re.S)),
    (".NET Unhandled Exception", re.compile(r"at System\.\w[\w.]*|Unhandled [Ee]xception:", re.I)),
    ("Java Stack Trace", re.compile(r"at [\w$]+(\.[\w$]+)+\([\w.]+\.java:\d+\)|java\.lang\.\w+Exception", re.I)),
    ("Spring Boot Whitelabel Error", re.compile(r"Whitelabel Error Page", re.I)),
    ("Ruby on Rails Error", re.compile(r"ActionController::RoutingError|We're sorry, but something went wrong", re.I)),
    ("Node.js Stack Trace", re.compile(r"at Object\.<anonymous>|UnhandledPromiseRejection", re.I)),
    ("SQL Syntax Error", re.compile(r"you have an error in your sql syntax|SQLSTATE\[\w+\]|unclosed quotation mark after the character string", re.I)),
    ("Oracle DB Error", re.compile(r"ORA-\d{5}", re.I)),
    ("Python Traceback", re.compile(r"Traceback \(most recent call last\)", re.I)),
    ("Generic 500 Text In Body", re.compile(r"\b500 Internal Server Error\b", re.I)),
]

ERROR_SNIPPET_MAX_MATCHES = 5
ERROR_SNIPPET_CONTEXT = 60


def detect_error_signatures(body_text: str) -> List[Tuple[str, str]]:
    """Scan page text for known error/information-disclosure patterns.
    Returns up to ERROR_SNIPPET_MAX_MATCHES (label, short snippet) pairs.
    """
    slice_ = body_text[:BODY_SNIFF_CAP]
    hits: List[Tuple[str, str]] = []
    for label, pattern in ERROR_SIGNATURES:
        m = pattern.search(slice_)
        if m:
            start = max(0, m.start() - ERROR_SNIPPET_CONTEXT)
            end = min(len(slice_), m.end() + ERROR_SNIPPET_CONTEXT)
            snippet = " ".join(slice_[start:end].split())  # collapse whitespace/newlines
            hits.append((label, snippet))
            if len(hits) >= ERROR_SNIPPET_MAX_MATCHES:
                break
    return hits


# --------------------------------------------------------------------------
# URL loading
# --------------------------------------------------------------------------

def normalize_url(raw: str) -> Optional[str]:
    raw = raw.strip()
    if not raw or raw.startswith("#"):
        return None
    if "://" not in raw:
        raw = "https://" + raw
    parsed = urlparse(raw)
    if not parsed.netloc:
        return None
    return raw


def load_urls_from_txt(path: Path) -> List[str]:
    urls = []
    for line in path.read_text(errors="ignore").splitlines():
        u = normalize_url(line)
        if u:
            urls.append(u)
    return urls


_CSV_HEADER_CANDIDATES = {"url", "urls", "link", "links", "website", "target", "host", "hostname", "address"}


def load_urls_from_csv(path: Path) -> List[str]:
    """Loads URLs from a CSV. If the first row contains a recognizable header
    (url/link/website/target/host/...), that column is used and the header row
    is skipped. Otherwise every row is treated as data, first column."""
    urls = []
    with path.open(newline="", errors="ignore") as fh:
        rows = [row for row in csv.reader(fh) if row]
    if not rows:
        return urls
    first_row_lower = [c.strip().lower() for c in rows[0]]
    col_idx, start = 0, 0
    matched = [name for name in first_row_lower if name in _CSV_HEADER_CANDIDATES]
    if matched:
        col_idx = first_row_lower.index(matched[0])
        start = 1
    for row in rows[start:]:
        if col_idx >= len(row):
            continue
        u = normalize_url(row[col_idx])
        if u:
            urls.append(u)
    return urls


def load_urls_from_file(path_str: str) -> List[str]:
    path = Path(path_str).expanduser()
    if not path.is_file():
        raise FileNotFoundError(f"No such file: {path}")
    if path.suffix.lower() == ".csv":
        return load_urls_from_csv(path)
    return load_urls_from_txt(path)


def dedupe_preserve_order(urls: List[str]) -> List[str]:
    seen = set()
    out = []
    for u in urls:
        if u not in seen:
            seen.add(u)
            out.append(u)
    return out


# --------------------------------------------------------------------------
# Networking helpers
# --------------------------------------------------------------------------

_thread_local = threading.local()

DEFAULT_UA = f"{TOOL_NAME}/{VERSION} (+authorized-security-testing)"


def get_session() -> requests.Session:
    """One requests.Session per worker thread (connection pooling, thread-safe)."""
    sess = getattr(_thread_local, "session", None)
    if sess is None:
        sess = requests.Session()
        if Retry is not None:
            retry = Retry(total=0, connect=0, read=0, redirect=0, raise_on_status=False)
            adapter = HTTPAdapter(max_retries=retry, pool_maxsize=32)
        else:
            adapter = HTTPAdapter(pool_maxsize=32)
        sess.mount("http://", adapter)
        sess.mount("https://", adapter)
        _thread_local.session = sess
    return sess


def grab_raw_banner(url: str, timeout: float = 1.5, read_bytes: int = 256) -> Optional[str]:
    """Best-effort raw TCP banner grab: open the socket and see if the service
    volunteers anything before we send a request. Most HTTP(S) servers are
    request-first and will return nothing here — that's expected and normal;
    this mainly adds value against non-HTTP or legacy services on the same
    host/port. Off by default because of the per-host timeout cost at scale.
    """
    try:
        parsed = urlparse(url)
        host = parsed.hostname
        if not host:
            return None
        port = parsed.port or (443 if parsed.scheme == "https" else 80)
        with socket.create_connection((host, port), timeout=timeout) as sock:
            sock.settimeout(timeout)
            try:
                data = sock.recv(read_bytes)
            except socket.timeout:
                return None
            if not data:
                return None
            try:
                return data.decode("utf-8", errors="replace").strip()
            except Exception:
                return repr(data)
    except (socket.timeout, socket.gaierror, ConnectionRefusedError, OSError):
        return None


def is_ip_literal(host: str) -> bool:
    try:
        ipaddress.ip_address(host)
        return True
    except ValueError:
        return False


# --------------------------------------------------------------------------
# Scanner — concurrent probing for both the initial and secondary phases
# --------------------------------------------------------------------------

class Scanner:
    def __init__(self, timeout: float = 8.0, verify: bool = True,
                 raw_banner: bool = False, user_agent: str = DEFAULT_UA,
                 max_workers: int = 10):
        self.timeout = timeout
        self.verify = verify
        self.raw_banner = raw_banner
        self.user_agent = user_agent
        self.max_workers = max_workers
        if not verify:
            try:
                import urllib3
                urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
            except Exception:
                pass

    # ---- single-request workers ----

    def probe_initial(self, index: int, url: str) -> ScanResult:
        result = ScanResult(index=index, url=url, phase="initial", method="GET")
        req_headers = {"User-Agent": self.user_agent}
        result.request_headers = req_headers
        session = get_session()
        try:
            start = time.time()
            resp = session.get(url, headers=req_headers, timeout=self.timeout,
                                verify=self.verify, allow_redirects=True)
            result.elapsed_ms = round((time.time() - start) * 1000, 1)
            self._fill_from_response(result, resp)
            if self.raw_banner:
                result.banner_raw = grab_raw_banner(url)
        except requests.exceptions.RequestException as e:
            result.network_error = f"{type(e).__name__}: {e}"
        return result

    def probe_secondary(self, index: int, url: str, method: str,
                         headers: Dict[str, str], payload: Optional[str]) -> ScanResult:
        result = ScanResult(index=index, url=url, phase="secondary", method=method.upper())
        result.request_headers = dict(headers)
        result.payload_sent = payload
        session = get_session()
        try:
            kwargs: Dict[str, Any] = dict(headers=headers, timeout=self.timeout,
                                           verify=self.verify, allow_redirects=True)
            if payload:
                kwargs["data"] = payload.encode("utf-8", errors="replace")
            start = time.time()
            resp = session.request(method.upper() or "GET", url, **kwargs)
            result.elapsed_ms = round((time.time() - start) * 1000, 1)
            self._fill_from_response(result, resp)
        except requests.exceptions.RequestException as e:
            result.network_error = f"{type(e).__name__}: {e}"
        return result

    @staticmethod
    def _fill_from_response(result: ScanResult, resp: "requests.Response") -> None:
        result.status_code = resp.status_code
        result.reason = resp.reason
        if resp.url and resp.url != result.url:
            result.final_url = resp.url
        result.response_headers = dict(resp.headers)
        result.cookies = dict(resp.cookies)
        result.banner_http = resp.headers.get("Server")
        body_text = resp.text or ""
        result.body_snippet = body_text[:300]
        result.fingerprints = fingerprint_response(resp, body_text)
        result.error_signatures = detect_error_signatures(body_text)

    # ---- bulk runner (phase-agnostic) ----

    def run_bulk(self, tasks: List[Any], on_result=None) -> List[ScanResult]:
        """`tasks` is a list of zero-arg callables, each returning a ScanResult."""
        results: List[ScanResult] = []
        with cf.ThreadPoolExecutor(max_workers=self.max_workers) as ex:
            futures = [ex.submit(t) for t in tasks]
            for fut in cf.as_completed(futures):
                r = fut.result()
                results.append(r)
                if on_result:
                    on_result(r)
        results.sort(key=lambda r: r.index)
        return results


# --------------------------------------------------------------------------
# Selection parser — pick a subset of results by index, range, or status
# --------------------------------------------------------------------------

def _matches_status_filter(r: ScanResult, val: str) -> bool:
    val = val.strip().lower()
    if val in ("err", "error"):
        return r.status_code is None
    if len(val) == 3 and val.endswith("xx") and val[0].isdigit():
        cls = int(val[0])
        return r.status_code is not None and cls * 100 <= r.status_code < (cls + 1) * 100
    if val.isdigit():
        return r.status_code == int(val)
    return False


def parse_selection(spec: str, results: List[ScanResult]) -> List[ScanResult]:
    """Accepts: "all" | "1,3,5-8" | "status:404" | "status:2xx" | "status:err",
    or any comma-separated mix of the above. Returns matches in index order."""
    spec = spec.strip()
    if not spec:
        return []
    if spec.lower() == "all":
        return list(results)
    by_index = {r.index: r for r in results}
    selected: Dict[int, ScanResult] = {}
    for token in spec.split(","):
        token = token.strip()
        if not token:
            continue
        if token.lower().startswith("status:"):
            val = token.split(":", 1)[1]
            for r in results:
                if _matches_status_filter(r, val):
                    selected[r.index] = r
            continue
        if re.fullmatch(r"\d+-\d+", token):
            a, b = token.split("-", 1)
            for i in range(int(a), int(b) + 1):
                if i in by_index:
                    selected[i] = by_index[i]
            continue
        if token.isdigit():
            i = int(token)
            if i in by_index:
                selected[i] = by_index[i]
    return [selected[i] for i in sorted(selected)]


# --------------------------------------------------------------------------
# ResultStore — holds every scan result, supports filtering, export, import
# --------------------------------------------------------------------------

class ResultStore:
    def __init__(self):
        self.results: List[ScanResult] = []
        self._next_index = 1

    def reserve_indices(self, n: int) -> List[int]:
        start = self._next_index
        self._next_index += n
        return list(range(start, start + n))

    def add_many(self, results: List[ScanResult]) -> None:
        self.results.extend(results)

    def all(self, phase: Optional[str] = None) -> List[ScanResult]:
        if phase:
            return [r for r in self.results if r.phase == phase]
        return list(self.results)

    def filter(self, *, status: Optional[int] = None, status_class: Optional[int] = None,
               phase: Optional[str] = None, url_contains: Optional[str] = None,
               header_contains: Optional[str] = None, request_header_contains: Optional[str] = None,
               fingerprint_contains: Optional[str] = None,
               has_errors: Optional[bool] = None) -> List[ScanResult]:
        out = []
        for r in self.results:
            if phase and r.phase != phase:
                continue
            if status is not None and r.status_code != status:
                continue
            if status_class is not None:
                if r.status_code is None or not (status_class * 100 <= r.status_code < (status_class + 1) * 100):
                    continue
            if url_contains and url_contains.lower() not in r.url.lower():
                continue
            if header_contains:
                k = header_contains.lower()
                if not any(k in f"{hk}:{hv}".lower() for hk, hv in r.response_headers.items()):
                    continue
            if request_header_contains:
                k = request_header_contains.lower()
                if not any(k in f"{hk}:{hv}".lower() for hk, hv in r.request_headers.items()):
                    continue
            if fingerprint_contains:
                k = fingerprint_contains.lower()
                if not any(k in fp.lower() for fp in r.fingerprints):
                    continue
            has_any_error = bool(r.error_signatures or r.rendered_error_signatures)
            if has_errors is True and not has_any_error:
                continue
            if has_errors is False and has_any_error:
                continue
            out.append(r)
        return out

    def export_json(self, path: Path, results: Optional[List[ScanResult]] = None) -> None:
        data = [asdict(r) for r in (results if results is not None else self.results)]
        path.write_text(json.dumps(data, indent=2))

    def export_csv(self, path: Path, results: Optional[List[ScanResult]] = None) -> None:
        rows = [r.to_flat_dict() for r in (results if results is not None else self.results)]
        if not rows:
            path.write_text("")
            return
        fieldnames = list(rows[0].keys())
        with path.open("w", newline="") as fh:
            writer = csv.DictWriter(fh, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)

    def load_json(self, path: Path) -> List[ScanResult]:
        data = json.loads(path.read_text())
        loaded = []
        for item in data:
            item = dict(item)
            item["error_signatures"] = [tuple(x) for x in item.get("error_signatures", [])]
            item["rendered_error_signatures"] = [tuple(x) for x in item.get("rendered_error_signatures", [])]
            loaded.append(ScanResult(**item))
        self.results.extend(loaded)
        if loaded:
            self._next_index = max(r.index for r in self.results) + 1
        return loaded


# --------------------------------------------------------------------------
# Screenshotter — optional headless-browser capture (lazy Playwright import)
# --------------------------------------------------------------------------

class Screenshotter:
    """Loads a page in headless Chromium, screenshots it, and re-runs the
    error/information-disclosure signatures against the JS-rendered DOM —
    this catches client-rendered error states (e.g. a React error boundary)
    that a raw HTTP fetch in the discovery phase would never see.

    Requires `pip install playwright` + `playwright install chromium`. The
    rest of the tool works fully without it; this is only imported when the
    screenshot menu is actually used.
    """

    def __init__(self, out_dir: Path, timeout_ms: int = 15000):
        self.out_dir = out_dir
        self.timeout_ms = timeout_ms
        self._pw_cm = None
        self._playwright = None
        self._browser = None

    @staticmethod
    def available() -> bool:
        try:
            import playwright.sync_api  # noqa: F401
            return True
        except ImportError:
            return False

    def __enter__(self) -> "Screenshotter":
        from playwright.sync_api import sync_playwright
        self._pw_cm = sync_playwright()
        self._playwright = self._pw_cm.__enter__()
        self._browser = self._playwright.chromium.launch(headless=True)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        try:
            if self._browser:
                self._browser.close()
        finally:
            if self._pw_cm:
                self._pw_cm.__exit__(exc_type, exc_val, exc_tb)

    def capture(self, result: ScanResult) -> None:
        parsed = urlparse(result.url)
        safe_name = re.sub(r"[^a-zA-Z0-9._-]", "_", (parsed.netloc + parsed.path))[:120] or "page"
        ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        out_path = self.out_dir / f"{result.index:03d}_{safe_name}_{ts}.png"
        page = self._browser.new_page()
        try:
            page.goto(result.url, timeout=self.timeout_ms, wait_until="load")
            page.screenshot(path=str(out_path), full_page=True)
            content = page.content()
            result.rendered_error_signatures = detect_error_signatures(content)
            result.screenshot_path = str(out_path)
        except Exception as e:
            note = f"[screenshot: {type(e).__name__}: {e}]"
            result.network_error = f"{result.network_error} {note}" if result.network_error else note
        finally:
            page.close()


# --------------------------------------------------------------------------
# CLI display helpers
# --------------------------------------------------------------------------

def status_cell(r: ScanResult, width: int = 14) -> str:
    plain = "ERR" if r.status_code is None else f"{r.status_code} {r.reason or ''}".strip()
    plain = plain[:width].ljust(width)
    return paint(plain, *status_color_codes(r.status_code))


def print_results_table(results: List[ScanResult], show_fp: bool = True, show_err: bool = True) -> None:
    if not results:
        print(paint("  (no results)", C.GREY))
        return
    for r in results:
        elapsed = f"{r.elapsed_ms:.0f}ms" if r.elapsed_ms is not None else "-"
        print(f"[{r.index:>3}] {status_cell(r)} {elapsed:>8}  {r.method:<6} {r.url}")
        if r.network_error:
            print(paint(f"        network error: {r.network_error}", C.MAGENTA))
        if show_fp and r.fingerprints:
            print(paint(f"        fingerprint: {', '.join(r.fingerprints)}", C.CYAN))
        if show_err and (r.error_signatures or r.rendered_error_signatures):
            labels = [lbl for lbl, _ in r.error_signatures]
            labels += [f"(rendered) {lbl}" for lbl, _ in r.rendered_error_signatures]
            print(paint(f"        possible error/info-disclosure: {', '.join(labels)}", C.YELLOW))
        if r.screenshot_path:
            print(paint(f"        screenshot: {r.screenshot_path}", C.GREY))


def print_detail(r: ScanResult) -> None:
    print(paint(f"\n[{r.index}] {r.url}  ({r.phase})", C.BOLD, C.CYAN))
    print(f"  status: {status_cell(r)}   method: {r.method}   "
          f"elapsed: {r.elapsed_ms if r.elapsed_ms is not None else '-'} ms   time: {r.timestamp}")
    if r.final_url:
        print(f"  redirected to: {r.final_url}")
    if r.network_error:
        print(paint(f"  network error: {r.network_error}", C.MAGENTA))
    if r.request_headers:
        print("  -- request headers --")
        for k, v in r.request_headers.items():
            print(f"    {k}: {v}")
    if r.payload_sent:
        print(f"  payload sent: {r.payload_sent}")
    if r.response_headers:
        print("  -- response headers --")
        for k, v in r.response_headers.items():
            print(f"    {k}: {v}")
    if r.cookies:
        print(f"  cookies: {r.cookies}")
    if r.banner_http:
        print(f"  HTTP banner (Server header): {r.banner_http}")
    if r.banner_raw:
        print(f"  raw TCP banner: {r.banner_raw}")
    if r.fingerprints:
        print(paint(f"  fingerprint: {', '.join(r.fingerprints)}", C.CYAN))
    if r.error_signatures:
        print(paint("  possible error/info-disclosure (raw HTML):", C.YELLOW))
        for lbl, snip in r.error_signatures:
            print(f"    - {lbl}: {snip}")
    if r.rendered_error_signatures:
        print(paint("  possible error/info-disclosure (rendered page):", C.YELLOW))
        for lbl, snip in r.rendered_error_signatures:
            print(f"    - {lbl}: {snip}")
    if r.screenshot_path:
        print(f"  screenshot: {r.screenshot_path}")


def prompt_headers(prompt_prefix: str = "  ") -> Dict[str, str]:
    """Reads 'Key: Value' lines until a blank line."""
    headers: Dict[str, str] = {}
    while True:
        line = input(prompt_prefix)
        if not line.strip():
            break
        if ":" in line:
            k, v = line.split(":", 1)
            headers[k.strip()] = v.strip()
        else:
            print(paint("    (expected 'Key: Value' — skipped)", C.YELLOW))
    return headers


# --------------------------------------------------------------------------
# App — interactive menu-driven controller
# --------------------------------------------------------------------------

class App:
    def __init__(self):
        self.store = ResultStore()
        self.urls: List[str] = []
        self.settings: Dict[str, Any] = {
            "timeout": 8.0,
            "verify": True,
            "raw_banner": False,
            "user_agent": DEFAULT_UA,
            "max_workers": 10,
        }
        self.scanner = Scanner(**self.settings)
        self.screenshot_dir = Path("screenshots")

    def rebuild_scanner(self) -> None:
        self.scanner = Scanner(**self.settings)

    # ---- main loop ----

    def run(self) -> None:
        while True:
            self.print_main_menu()
            choice = input("> ").strip()
            if choice == "0":
                print("Exiting.")
                return
            elif choice == "1":
                self.menu_load_urls()
            elif choice == "2":
                self.menu_run_discovery()
            elif choice == "3":
                self.menu_view_filter()
            elif choice == "4":
                self.menu_secondary_iteration()
            elif choice == "5":
                self.menu_screenshot()
            elif choice == "6":
                self.menu_export_import()
            elif choice == "7":
                self.menu_settings()
            else:
                print(paint("  unrecognized option.", C.YELLOW))

    def print_main_menu(self) -> None:
        n_init = len(self.store.all("initial"))
        n_sec = len(self.store.all("secondary"))
        print(paint("\n── Main Menu ──", C.BOLD))
        print(f"  queued URLs: {len(self.urls)}   |   results — initial: {n_init}  secondary: {n_sec}")
        print("  1) Load URLs (manual entry or .txt/.csv file)")
        print("  2) Run initial discovery (headers, banner, fingerprint)")
        print("  3) View / filter / investigate results")
        print("  4) Secondary iteration (custom headers & payload on selected URLs)")
        print("  5) Screenshot + parse selected URLs for page errors")
        print("  6) Export / import results (JSON, CSV)")
        print("  7) Settings (timeout, concurrency, TLS verify, raw banner, UA)")
        print("  0) Exit")

    # ---- 1) load ----

    def menu_load_urls(self) -> None:
        print("\n  1) Enter URLs manually   2) Load from .txt/.csv file   0) back")
        c = input("  > ").strip()
        if c == "1":
            print("  One URL per line. Blank line to finish.")
            entered = []
            while True:
                line = input("  ")
                if not line.strip():
                    break
                u = normalize_url(line)
                if u:
                    entered.append(u)
                else:
                    print(paint(f"    skipped (invalid): {line}", C.YELLOW))
            self._queue_urls(entered)
        elif c == "2":
            path = input("  file path (.txt or .csv): ").strip()
            try:
                self._queue_urls(load_urls_from_file(path))
            except Exception as e:
                print(paint(f"  error loading file: {e}", C.RED))

    def _queue_urls(self, new_urls: List[str]) -> None:
        before = len(self.urls)
        self.urls = dedupe_preserve_order(self.urls + new_urls)
        print(paint(f"  queued {len(self.urls) - before} new URL(s); {len(self.urls)} total pending discovery.", C.GREEN))

    # ---- 2) initial discovery ----

    def menu_run_discovery(self) -> None:
        if not self.urls:
            print(paint("  no URLs queued — load some first (option 1).", C.YELLOW))
            return
        total = len(self.urls)
        print(f"  running initial discovery against {total} URL(s)...")
        idxs = self.store.reserve_indices(total)
        tasks = [(lambda i=i, u=u: self.scanner.probe_initial(i, u)) for i, u in zip(idxs, self.urls)]
        counter = {"n": 0}

        def on_result(r: ScanResult) -> None:
            counter["n"] += 1
            print(f"  [{counter['n']}/{total}] {status_cell(r)}  {r.url}")

        results = self.scanner.run_bulk(tasks, on_result=on_result)
        self.store.add_many(results)
        print(paint(f"  done — {len(results)} probed.", C.GREEN))
        self.urls = []

    # ---- 3) view / filter / investigate ----

    def menu_view_filter(self) -> None:
        results = self.store.all()
        if not results:
            print(paint("  no results yet — run discovery first.", C.YELLOW))
            return
        current = results
        while True:
            print(f"\n  showing {len(current)} of {len(self.store.results)} result(s):")
            print_results_table(current)
            print(paint("\n  filter:", C.BOLD),
                  "1) status code  2) status class  3) response header contains  4) request header contains "
                  "\n           5) fingerprint contains  6) errors only  7) url contains  8) phase  "
                  "9) clear filter  d) drill into one  0) back")
            c = input("  > ").strip().lower()
            if c == "0":
                return
            if c == "9":
                current = results
                continue
            if c == "d":
                try:
                    idx = int(input("  index to inspect: ").strip())
                    match = next((r for r in current if r.index == idx), None)
                    if match:
                        print_detail(match)
                    else:
                        print(paint("  not found in current view.", C.YELLOW))
                except ValueError:
                    print(paint("  enter a numeric index.", C.YELLOW))
                continue
            kwargs: Dict[str, Any] = {}
            if c == "1":
                kwargs["status"] = int(input("  status code: ").strip())
            elif c == "2":
                kwargs["status_class"] = int(input("  status class (2/3/4/5): ").strip())
            elif c == "3":
                kwargs["header_contains"] = input("  response header/value substring: ").strip()
            elif c == "4":
                kwargs["request_header_contains"] = input("  request header/value substring: ").strip()
            elif c == "5":
                kwargs["fingerprint_contains"] = input("  fingerprint substring: ").strip()
            elif c == "6":
                kwargs["has_errors"] = True
            elif c == "7":
                kwargs["url_contains"] = input("  url substring: ").strip()
            elif c == "8":
                kwargs["phase"] = input("  phase (initial/secondary): ").strip()
            else:
                print(paint("  unrecognized option.", C.YELLOW))
                continue
            current = self.store.filter(**kwargs)

    # ---- 4) secondary iteration ----

    def menu_secondary_iteration(self) -> None:
        base = self.store.all()
        if not base:
            print(paint("  no results yet — run initial discovery first.", C.YELLOW))
            return
        print_results_table(base)
        spec = input("\n  select URLs to re-test (e.g. 'all', '1,3,5-8', 'status:4xx'): ").strip()
        selected = parse_selection(spec, base)
        if not selected:
            print(paint("  nothing selected.", C.YELLOW))
            return
        print(paint(f"  {len(selected)} URL(s) selected.", C.GREEN))

        method = input("  HTTP method [GET]: ").strip() or "GET"

        print("  global headers — applied to ALL selected URLs. 'Key: Value' per line, blank line to finish:")
        global_headers = prompt_headers()
        global_payload = input("  global payload/body (blank for none): ")

        per_url_headers: Dict[int, Dict[str, str]] = {}
        per_url_payload: Dict[int, str] = {}
        wants_overrides = input("  customize per-URL overrides for any of these? (y/N): ").strip().lower() == "y"
        if wants_overrides:
            for r in selected:
                if input(f"    override for [{r.index}] {r.url}? (y/N): ").strip().lower() == "y":
                    print("    per-URL headers ('Key: Value' per line, blank to finish):")
                    per_url_headers[r.index] = prompt_headers("    ")
                    p = input("    per-URL payload (blank = use global): ")
                    if p:
                        per_url_payload[r.index] = p

        new_idxs = self.store.reserve_indices(len(selected))
        tasks = []
        for new_idx, r in zip(new_idxs, selected):
            merged_headers = {**global_headers, **per_url_headers.get(r.index, {})}
            if not merged_headers:
                merged_headers = {"User-Agent": self.settings["user_agent"]}
            payload = per_url_payload.get(r.index) or (global_payload or None)
            tasks.append(
                lambda i=new_idx, u=r.url, m=method, h=merged_headers, p=payload:
                self.scanner.probe_secondary(i, u, m, h, p)
            )

        total = len(tasks)
        counter = {"n": 0}

        def on_result(res: ScanResult) -> None:
            counter["n"] += 1
            print(f"  [{counter['n']}/{total}] {status_cell(res)}  {res.url}")

        results = self.scanner.run_bulk(tasks, on_result=on_result)
        self.store.add_many(results)
        print(paint(f"  done — {len(results)} re-tested.", C.GREEN))

    # ---- 5) screenshot ----

    def menu_screenshot(self) -> None:
        if not Screenshotter.available():
            print(paint(
                "  Playwright isn't installed — this feature needs it.\n"
                "  Install with:\n    pip install playwright\n    playwright install chromium",
                C.YELLOW,
            ))
            return
        results = self.store.all()
        if not results:
            print(paint("  no results yet — run discovery first.", C.YELLOW))
            return
        print_results_table(results, show_fp=False, show_err=False)
        spec = input("\n  select URLs to screenshot (e.g. 'all', '1,3,5-8', 'status:2xx'): ").strip()
        selected = parse_selection(spec, results)
        if not selected:
            print(paint("  nothing selected.", C.YELLOW))
            return
        self.screenshot_dir.mkdir(parents=True, exist_ok=True)
        print(f"  capturing {len(selected)} screenshot(s) -> {self.screenshot_dir}/ ...")
        try:
            with Screenshotter(self.screenshot_dir) as shooter:
                for i, r in enumerate(selected, 1):
                    print(f"  [{i}/{len(selected)}] {r.url} ...", end=" ", flush=True)
                    shooter.capture(r)
                    if r.screenshot_path:
                        print(paint("saved", C.GREEN), r.screenshot_path)
                        if r.rendered_error_signatures:
                            labels = ", ".join(lbl for lbl, _ in r.rendered_error_signatures)
                            print(paint(f"        rendered-page findings: {labels}", C.YELLOW))
                    else:
                        print(paint("failed", C.RED))
        except Exception as e:
            print(paint(f"  screenshot session failed: {type(e).__name__}: {e}", C.RED))

    # ---- 6) export / import ----

    def menu_export_import(self) -> None:
        print("\n  1) Export ALL results   2) Export current filter (re-filter now)   "
              "3) Import results from JSON   0) back")
        c = input("  > ").strip()
        if c == "1":
            self._export(self.store.results)
        elif c == "2":
            kwargs = self._prompt_filter_kwargs()
            self._export(self.store.filter(**kwargs))
        elif c == "3":
            path = input("  JSON file path: ").strip()
            try:
                loaded = self.store.load_json(Path(path))
                print(paint(f"  imported {len(loaded)} result(s).", C.GREEN))
            except Exception as e:
                print(paint(f"  import failed: {e}", C.RED))

    def _prompt_filter_kwargs(self) -> Dict[str, Any]:
        print("    leave blank to skip a filter")
        kwargs: Dict[str, Any] = {}
        sc = input("    status class (2/3/4/5): ").strip()
        if sc:
            kwargs["status_class"] = int(sc)
        he = input("    has errors only? (y/N): ").strip().lower()
        if he == "y":
            kwargs["has_errors"] = True
        return kwargs

    def _export(self, results: List[ScanResult]) -> None:
        if not results:
            print(paint("  nothing to export.", C.YELLOW))
            return
        path = input(f"  export path for {len(results)} result(s) (.json or .csv): ").strip()
        if not path:
            print(paint("  no path given.", C.YELLOW))
            return
        out = Path(path)
        try:
            if out.suffix.lower() == ".csv":
                self.store.export_csv(out, results)
            else:
                self.store.export_json(out, results)
            print(paint(f"  exported {len(results)} result(s) -> {out}", C.GREEN))
        except Exception as e:
            print(paint(f"  export failed: {e}", C.RED))

    # ---- 7) settings ----

    def menu_settings(self) -> None:
        s = self.settings
        print(f"\n  current: timeout={s['timeout']}s  verify_tls={s['verify']}  "
              f"raw_banner={s['raw_banner']}  concurrency={s['max_workers']}\n  user_agent={s['user_agent']}")
        print("  1) timeout  2) TLS verify on/off  3) raw banner grab on/off  "
              "4) concurrency  5) user-agent  0) back")
        c = input("  > ").strip()
        if c == "1":
            s["timeout"] = float(input("  timeout seconds: ").strip())
        elif c == "2":
            s["verify"] = input("  verify TLS certs? (y/n): ").strip().lower() != "n"
        elif c == "3":
            s["raw_banner"] = input("  attempt raw TCP banner grab? (y/n): ").strip().lower() == "y"
        elif c == "4":
            s["max_workers"] = int(input("  concurrent workers: ").strip())
        elif c == "5":
            s["user_agent"] = input("  user-agent string: ").strip() or DEFAULT_UA
        else:
            return
        self.rebuild_scanner()
        print(paint("  settings updated.", C.GREEN))


# --------------------------------------------------------------------------
# Entry point
# --------------------------------------------------------------------------

def build_arg_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog=TOOL_NAME,
        description="HTTP surface discovery & fingerprinting toolkit. Authorized use only.",
    )
    p.add_argument("-u", "--url", action="append", default=[], help="URL to preload (repeatable)")
    p.add_argument("-f", "--file", help="Preload URLs from a .txt or .csv file")
    p.add_argument("-c", "--concurrency", type=int, default=10, help="Concurrent workers (default 10)")
    p.add_argument("-t", "--timeout", type=float, default=8.0, help="Per-request timeout in seconds (default 8)")
    p.add_argument("--insecure", action="store_true", help="Disable TLS certificate verification")
    p.add_argument("--raw-banner", action="store_true",
                    help="Also attempt a raw TCP banner grab per host (adds latency)")
    p.add_argument("--ua", default=DEFAULT_UA, help="User-Agent header to send")
    p.add_argument("--batch", action="store_true",
                    help="Run initial discovery once, non-interactively, then exit (for scripting/CI)")
    p.add_argument("-o", "--output", help="Export path for --batch mode (.json or .csv)")
    return p


def main() -> None:
    args = build_arg_parser().parse_args()

    app = App()
    app.settings.update({
        "timeout": args.timeout,
        "verify": not args.insecure,
        "raw_banner": args.raw_banner,
        "user_agent": args.ua,
        "max_workers": args.concurrency,
    })
    app.rebuild_scanner()

    seed: List[str] = []
    if args.file:
        try:
            seed.extend(load_urls_from_file(args.file))
        except Exception as e:
            print(paint(f"error loading {args.file}: {e}", C.RED))
            sys.exit(1)
    for u in args.url:
        nu = normalize_url(u)
        if nu:
            seed.append(nu)
    app.urls = dedupe_preserve_order(seed)

    if args.batch:
        if not app.urls:
            print(paint("--batch requires -u/--url or -f/--file", C.RED))
            sys.exit(1)
        print(banner())
        app.menu_run_discovery()
        if args.output:
            out = Path(args.output)
            if out.suffix.lower() == ".csv":
                app.store.export_csv(out)
            else:
                app.store.export_json(out)
            print(paint(f"exported {len(app.store.results)} result(s) -> {out}", C.GREEN))
        return

    print(banner())
    if app.urls:
        print(paint(f"  preloaded {len(app.urls)} URL(s) from the command line.", C.GREEN))
    app.run()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrupted.")
        sys.exit(130)
