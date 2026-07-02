# Veracode Security Testing SDK Framework

[![Integration Tests](https://github.com/bnreplah/veracode-scripts/actions/workflows/integration-tests.yml/badge.svg)](https://github.com/bnreplah/veracode-scripts/actions/workflows/integration-tests.yml)
[![Security Scan](https://github.com/bnreplah/veracode-scripts/actions/workflows/security-scan.yml/badge.svg)](https://github.com/bnreplah/veracode-scripts/actions/workflows/security-scan.yml)
[![QAT](https://github.com/bnreplah/veracode-scripts/actions/workflows/qat.yml/badge.svg)](https://github.com/bnreplah/veracode-scripts/actions/workflows/qat.yml)

---

## Overview

A comprehensive SDK and tooling framework for Veracode application security testing.  
It wraps the Veracode REST and XML APIs with helper scripts, automated analysis utilities, and an installation framework — targeting SAST, DAST, SCA, container security, and misconfiguration detection from a single, unified toolset.

### Goals
- **Correlate findings** across DAST, SAST, SCA, container findings, and security misconfigurations
- **Directed analysis** — surface overlapping data paths, common flaw sources in static analysis, and cross-scan vulnerability patterns
- **Automated recommendations** — link findings to security training modules and remediation guidance
- **Cross-platform installation** — thin installer in Bash (`.sh`), PowerShell (`.ps1`), and Go (`.exe`) to bootstrap the full toolset

---

## Workflows & Badges

| Workflow | Description | Badge |
|---|---|---|
| **Integration Tests** | Unit tests + Python script integration tests + shell script syntax/shellcheck | [![Integration Tests](https://github.com/bnreplah/veracode-scripts/actions/workflows/integration-tests.yml/badge.svg)](https://github.com/bnreplah/veracode-scripts/actions/workflows/integration-tests.yml) |
| **Security Scan** | Bandit (Python), ShellCheck, Gitleaks secret scanning, pip-audit, Semgrep SAST | [![Security Scan](https://github.com/bnreplah/veracode-scripts/actions/workflows/security-scan.yml/badge.svg)](https://github.com/bnreplah/veracode-scripts/actions/workflows/security-scan.yml) |
| **QAT** | flake8 linting, ShellCheck lint, JSON/YAML validation, PSScriptAnalyzer, full test suite | [![QAT](https://github.com/bnreplah/veracode-scripts/actions/workflows/qat.yml/badge.svg)](https://github.com/bnreplah/veracode-scripts/actions/workflows/qat.yml) |

---

## What's Included

### Scripts/Release — Production-Ready

| Script | Type | Description |
|---|---|---|
| `DASTWebAppRequest-std.py` | Python | Format and submit Dynamic Web App scan requests from CLI or piped JSON |
| `BlackList-std.py` | Python | Build DAST blocklist/scan settings from CSV files |
| `DAST-ls-v2.sh` | Bash | List DAST scans and results with pagination and verbose reporting |
| `DAST-rescan.sh` | Bash | Trigger rescans for Dynamic Analysis |
| `SearchBuildByName.sh` | Bash | Search Veracode application builds by name across apps |
| `vdb-purl-lte.sh` | Bash | Veracode vulnerability DB PURL lookup (lite) |
| `veracode-installer.sh` | Bash | Install and configure Veracode CLI tooling |

### Scripts/AIAnalysis — AI Analysis Layer

Model-agnostic pipeline that correlates findings across scan types, uses Claude
models to reduce false positives, and chains related findings into risk paths.
New frontier models (Claude Mythos 5, future releases) are onboarded by editing
`models.json` — no code changes. See [Scripts/AIAnalysis/README.md](Scripts/AIAnalysis/README.md).

| File | Purpose |
|---|---|
| `analyze.py` | CLI entry point (offline correlation or full AI pipeline) |
| `models.json` | Model registry — enable/disable models and assign roles |
| `veracode_ai/` | Package: config, findings normalization, correlation, validation, chaining, hooks |

### Scripts/Dev — In Development

| Directory | Contents |
|---|---|
| `DASTFramework/` | Modular DAST configuration framework (request builder, status polling, hooks, API scan) |
| `DBlookup/` | CPE/PURL vulnerability database lookup utilities |
| `bash_scripts/` | SCA library search, pipeline scan, sandbox promotion, upload scripts |
| `ps_scripts/` | PowerShell scripts: Java API wrapper management, scan status monitoring |
| `Test/` | Test scripts, sample data, and debugging utilities |

### xml_api_calls — Legacy XML API

Sequential workflow scripts for the Veracode XML API:
`0_getapplist` → `1_getapplist` → `2_getbuildlist` → `3_getsandboxlist` → `4_detailedreport`

---

## Veracode APIs Used

| API | Purpose |
|---|---|
| **Dynamic Analysis REST API** | DAST scan creation, configuration, scheduling, status |
| **Upload/Results API (XML)** | SAST scan submission, build management, detailed reports |
| **SCA REST API** | Workspace/project scanning, library/dependency findings |
| **Identity API** | Team and user management (replacing deprecated XML Admin API) |
| **Pipeline Scan API** | CI/CD integrated scanning with pre-scan file size checks |
| **Veracode CLI** | Modern CLI wrapper for SAST, SCA, and SBOM generation |

---

## Authentication

Credentials can be supplied via:

1. **Credentials file** — `~/.veracode/credentials`:
   ```ini
   [default]
   veracode_api_key_id     = YOUR_API_ID
   veracode_api_key_secret = YOUR_API_KEY
   ```

2. **Environment variables**:
   ```bash
   export VERACODE_API_ID="your-api-id"
   export VERACODE_API_KEY="your-api-key"
   ```

3. **SCA Agent token** (for `srcclr`):
   ```bash
   export SRCCLR_API_TOKEN="your-token"
   ```

---

## Quick Start

### Install Veracode Tooling
```bash
# Install Veracode CLI
bash Scripts/Release/veracode-installer.sh --force-install-vccli

# Install SCA CLI agent
bash Scripts/Release/veracode-installer.sh --install-sca-cli

# Install Java API Wrapper
bash Scripts/Release/veracode-installer.sh --install-java-api-wrapper

# Install Pipeline Scanner
bash Scripts/Release/veracode-installer.sh --install-pipeline-scanner
```

### Create a DAST Analysis Request
```bash
# Interactive mode
python Scripts/Release/DASTWebAppRequest-std.py

# Non-interactive / pipe mode (stdout JSON for use with http or curl)
python Scripts/Release/DASTWebAppRequest-std.py \
  "My-App-Scan" \
  "https://target.example.com/" \
  "owner@company.com" \
  "Security Team" \
  | http POST "https://api.veracode.com/was/configservice/v1/analyses" \
      --auth-type=veracode_hmac
```

### List DAST Scans
```bash
bash Scripts/Release/DAST-ls-v2.sh
```

### SCA Library Search
```bash
bash Scripts/Dev/bash_scripts/SCA-Library-ProjectSearch.sh "log4j"
```

---

## Running Tests

```bash
# Install test dependencies
pip install -r requirements-test.txt

# Run all unit tests (no credentials needed)
pytest tests/unit/ -v

# Run all integration tests (no credentials needed)
pytest tests/integration/ --ignore=tests/integration/test_api_connectivity.py -v

# Run full suite
pytest tests/ --ignore=tests/integration/test_api_connectivity.py -v

# Run with coverage
pytest tests/ --ignore=tests/integration/test_api_connectivity.py \
  --cov=Scripts --cov-report=term-missing

# Run live API connectivity tests (requires credentials)
pytest tests/integration/test_api_connectivity.py -m api -v
```

### Test Structure

```
tests/
├── conftest.py                          # Shared fixtures (tmp_work_dir, paths)
├── fixtures/
│   ├── allowlist.csv                    # DAST allowlist test fixture
│   ├── blacklist.csv                    # DAST blocklist test fixture
│   └── glblacklist.csv                  # Global blocklist test fixture
├── unit/
│   ├── test_email_validation.py         # Email regex validation logic
│   ├── test_schedule_helpers.py         # Scan schedule helper functions
│   └── test_csv_parsing.py             # CSV → JSON parsing logic
└── integration/
    ├── test_dast_web_request_script.py  # DASTWebAppRequest-std.py end-to-end
    ├── test_blacklist_script.py         # BlackList-std.py end-to-end
    ├── test_shell_scripts.py            # Bash syntax + shellcheck for all .sh
    └── test_api_connectivity.py         # Live Veracode API calls (needs creds)
```

### GitHub Secrets Required (for API tests)

| Secret | Description |
|---|---|
| `VERACODE_API_ID` | Veracode API Key ID |
| `VERACODE_API_KEY` | Veracode API Key Secret |

---

## SRM (Scriptable Request Modification)

Supports Veracode SRM API specification configuration for authenticated dynamic scans.  
Reference: [Veracode SRM Documentation](https://docs.veracode.com/r/Example_Script_for_Scriptable_Request_Modification_Authentication?tocId=GxBzVtHR5GnF~kPAmh0MNw)

---

## License

See [LICENSE](LICENSE) for details.
