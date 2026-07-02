"""Unified finding schema and normalizers.

Every scan type (SAST, DAST, SCA, container) is normalized into
UnifiedFinding so correlation, validation, and chaining operate on one
shape. Normalizers accept the Veracode REST Findings API response
(GET /appsec/v2/applications/{guid}/findings) and best-effort container
scan output from the Veracode CLI.
"""

import hashlib
import json
from dataclasses import dataclass, field, asdict
from typing import Optional


@dataclass
class UnifiedFinding:
    id: str                        # stable id derived from source content
    source: str                    # STATIC | DYNAMIC | SCA | CONTAINER | CONFIG
    severity: int                  # 0 (info) - 5 (very high), Veracode scale
    title: str
    description: str = ""
    cwe: Optional[int] = None
    cve: Optional[str] = None
    cvss: Optional[float] = None
    location: str = ""             # file:line, URL, component name, or image layer
    module: str = ""               # module/component grouping key
    attack_vector: str = ""        # SAST data-path entry point where available
    status: str = "OPEN"
    raw: dict = field(default_factory=dict)

    # Enriched by the pipeline
    correlations: list = field(default_factory=list)
    validation: Optional[dict] = None

    def to_dict(self, include_raw: bool = False) -> dict:
        d = asdict(self)
        if not include_raw:
            d.pop("raw", None)
        return d

    def summary_line(self) -> str:
        """Compact single-line form used in model prompts."""
        parts = [f"[{self.id}] {self.source} sev={self.severity}"]
        if self.cwe:
            parts.append(f"CWE-{self.cwe}")
        if self.cve:
            parts.append(self.cve)
        parts.append(self.title[:120])
        if self.location:
            parts.append(f"@ {self.location}")
        if self.attack_vector:
            parts.append(f"vector: {self.attack_vector[:80]}")
        return " | ".join(parts)


def _stable_id(*parts) -> str:
    digest = hashlib.sha256("|".join(str(p) for p in parts).encode()).hexdigest()
    return digest[:12]


def _normalize_rest_finding(f: dict) -> UnifiedFinding:
    """One finding from the Veracode REST Findings API (any scan_type)."""
    details = f.get("finding_details", {}) or {}
    scan_type = (f.get("scan_type") or "STATIC").upper()
    cwe = (details.get("cwe") or {}).get("id")
    severity = details.get("severity", 3)

    cve_info = details.get("cve") or {}
    cve = cve_info.get("name")
    cvss = cve_info.get("cvss") or cve_info.get("cvss3", {}).get("score") \
        if isinstance(cve_info.get("cvss3"), dict) else cve_info.get("cvss")

    if scan_type == "STATIC":
        file_name = details.get("file_name", "")
        line = details.get("file_line_number", "")
        location = f"{file_name}:{line}" if file_name else ""
        module = details.get("module", "") or (file_name.rsplit("/", 1)[-1] if file_name else "")
        title = ((details.get("finding_category") or {}).get("name")
                 or (details.get("cwe") or {}).get("name") or "Static finding")
    elif scan_type == "DYNAMIC":
        location = details.get("url", "") or details.get("path", "")
        module = details.get("hostname", "")
        title = ((details.get("cwe") or {}).get("name") or "Dynamic finding")
    elif scan_type == "SCA":
        component = details.get("component_filename", "") or details.get("component_path", "")
        location = component
        module = component
        title = cve or ((details.get("cwe") or {}).get("name") or "SCA finding")
    else:
        location = details.get("url", "") or details.get("file_name", "")
        module = ""
        title = (details.get("cwe") or {}).get("name") or f"{scan_type} finding"

    status = ((f.get("finding_status") or {}).get("status") or "OPEN").upper()
    issue_id = f.get("issue_id") or _stable_id(scan_type, cwe, location, title)

    return UnifiedFinding(
        id=f"{scan_type[:3]}-{issue_id}",
        source=scan_type,
        severity=int(severity) if severity is not None else 3,
        title=title,
        description=(f.get("description") or "")[:2000],
        cwe=cwe,
        cve=cve,
        cvss=float(cvss) if cvss else None,
        location=location,
        module=module,
        attack_vector=str(details.get("attack_vector", "") or ""),
        status=status,
        raw=f,
    )


def normalize_rest_findings(payload: dict) -> list:
    """Normalize a Veracode REST Findings API response (all scan types)."""
    findings = (payload.get("_embedded") or {}).get("findings", [])
    if not findings and isinstance(payload.get("findings"), list):
        findings = payload["findings"]
    return [_normalize_rest_finding(f) for f in findings]


def normalize_container_findings(payload: dict) -> list:
    """Best-effort normalization of Veracode CLI container scan JSON."""
    out = []
    vulns = payload.get("vulnerabilities") or payload.get("matches") or []
    for v in vulns:
        cve = v.get("cve") or v.get("id") or (v.get("vulnerability") or {}).get("id")
        sev_name = str(v.get("severity", "medium")).lower()
        severity = {"critical": 5, "very high": 5, "high": 4, "medium": 3,
                    "low": 2, "negligible": 1, "info": 0}.get(sev_name, 3)
        component = (v.get("artifact") or {}).get("name") or v.get("package", "") or ""
        out.append(UnifiedFinding(
            id=f"CON-{_stable_id(cve, component)}",
            source="CONTAINER",
            severity=severity,
            title=cve or "Container vulnerability",
            description=(v.get("description") or "")[:2000],
            cve=cve if cve and str(cve).upper().startswith("CVE") else None,
            location=component,
            module=component,
            raw=v,
        ))
    return out


def normalize_findings(payload, source_hint: str = "auto") -> list:
    """Normalize any supported payload into UnifiedFindings.

    payload may be a dict (parsed JSON) or a path to a JSON file.
    """
    if isinstance(payload, str):
        with open(payload) as f:
            payload = json.load(f)

    if source_hint == "container" or "vulnerabilities" in payload or "matches" in payload:
        return normalize_container_findings(payload)
    return normalize_rest_findings(payload)
