# Veracode CI/CD Workflow Templates

Copy any template from this directory into your repo's `.github/workflows/` folder, then follow the `# CUSTOMIZE:` and `# TODO:` markers to tailor it.

## Templates

### By Scan Type

| File | Scan Type | When to Use |
|---|---|---|
| [`pipeline-scan.yml`](pipeline-scan.yml) | SAST (fast, inline) | Every PR and commit — fast feedback, no policy gate |
| [`policy-scan-sast.yml`](policy-scan-sast.yml) | SAST (full policy) | Main/release branches — authoritative policy result |
| [`sandbox-scan-promote.yml`](sandbox-scan-promote.yml) | SAST Sandbox | Feature branches — scan in sandbox, promote to policy on merge |
| [`sca-agent-scan.yml`](sca-agent-scan.yml) | SCA (dependencies) | Every PR — catch vulnerable OSS libraries |
| [`dast-web-scan.yml`](dast-web-scan.yml) | DAST (dynamic) | Scheduled or manual — test running web application |
| [`container-scan.yml`](container-scan.yml) | Container / IaC | On image build — scan Docker image layers |
| [`all-scans-devops.yml`](all-scans-devops.yml) | All scans | Full DevOps pipeline with build → all security gates |

### By Language (Build + Scan)

| File | Language | Package Manager |
|---|---|---|
| [`by-language/java-maven.yml`](by-language/java-maven.yml) | Java | Maven |
| [`by-language/java-gradle.yml`](by-language/java-gradle.yml) | Java | Gradle |
| [`by-language/nodejs.yml`](by-language/nodejs.yml) | JavaScript / TypeScript | npm / yarn |
| [`by-language/python.yml`](by-language/python.yml) | Python | pip |
| [`by-language/dotnet.yml`](by-language/dotnet.yml) | C# / .NET | dotnet CLI |
| [`by-language/go.yml`](by-language/go.yml) | Go | go build |

### Reusable / Callable

The two reusable workflows live in `.github/workflows/` so any repo can call them:

```yaml
jobs:
  security:
    uses: bnreplah/veracode-scripts/.github/workflows/reusable-pipeline-scan.yml@main
    secrets: inherit
    with:
      artifact_path: "target/app.jar"
      app_name: "My Application"
```

See `.github/workflows/reusable-pipeline-scan.yml` and `.github/workflows/reusable-policy-scan.yml`.

---

## Required GitHub Secrets

Set these in your repo under **Settings → Secrets and variables → Actions**:

| Secret | Required By | Description |
|---|---|---|
| `VERACODE_API_ID` | All scan types | Veracode API Key ID |
| `VERACODE_API_KEY` | All scan types | Veracode API Key Secret |
| `SRCCLR_API_TOKEN` | SCA scans | SourceClear / SCA agent token |

---

## Quick Onboarding Checklist

1. Copy the template(s) matching your stack to `.github/workflows/`
2. Add `VERACODE_API_ID`, `VERACODE_API_KEY` (and `SRCCLR_API_TOKEN` for SCA) to repo secrets
3. Search for `# CUSTOMIZE:` in the template and update every instance
4. Search for `# TODO:` and complete every action item
5. Push to trigger your first scan
