#!/bin/bash
# the purpose of this script is to allow for the comparison of 2 types of scans
# input will be 2 of either formats
#   - output.json from SCA ABS scan
#   - sbom CycloneDX, SPDX formats
#   - CSV from the results from the platform
#   - a url to an app profile or project url 
#   - a project guid
#   - an app guid
#   - a detailedxml export from the app profile


# Starting with a baseline script written by MS365 copilot

#!/usr/bin/env bash

# sbom_compare.sh
# Compare two SBOM files (CycloneDX or SPDX) for differences, missing items, and duplicates.
# Supports JSON and XML formats. Exports normalized data to JSON or CSV.

set -euo pipefail

SBOM1="$1"
SBOM2="$2"
EXPORT_FORMAT="${3:-none}" # Options: json, csv, none

declare -A sbom1_components
declare -A sbom2_components

# Detect SBOM type and format
detect_sbom_type() {
    local file="$1"
    if grep -q '"bomFormat": "CycloneDX"' "$file"; then
        echo "CycloneDX-JSON"
    elif grep -q '<bom xmlns' "$file"; then
        echo "CycloneDX-XML"
    elif grep -q '"spdxVersion"' "$file"; then
        echo "SPDX-JSON"
    elif grep -q '<SpdxDocument' "$file"; then
        echo "SPDX-XML"
    else
        echo "Unknown"
    fi
}

# Parse CycloneDX JSON
parse_cyclonedx_json() {
    jq -r '.components[] | "\(.name):\(.version)"' "$1"
}

# Parse CycloneDX XML
parse_cyclonedx_xml() {
    xmlstarlet sel -t -m "//component" -v "concat(name,':',version)" -n "$1"
}

# Parse SPDX JSON
parse_spdx_json() {
    jq -r '.packages[] | "\(.name):\(.versionInfo)"' "$1"
}

# Parse SPDX XML
parse_spdx_xml() {
    xmlstarlet sel -t -m "//Package" -v "concat(name,':',versionInfo)" -n "$1"
}

# Load components into associative arrays
load_components() {
    local file="$1"
    local target_array="$2"
    local type
    type=$(detect_sbom_type "$file")

    local data
    case "$type" in
        CycloneDX-JSON) data=$(parse_cyclonedx_json "$file") ;;
        CycloneDX-XML)  data=$(parse_cyclonedx_xml "$file") ;;
        SPDX-JSON)      data=$(parse_spdx_json "$file") ;;
        SPDX-XML)       data=$(parse_spdx_xml "$file") ;;
        *) echo "Unsupported SBOM type for $file"; exit 1 ;;
    esac

    while read -r comp; do
        eval "$target_array[\"\$comp\"]=1"
    done <<< "$data"
}

# Compare SBOMs in git diff style
compare_sboms_git_diff() {
    echo "=== Git Diff Style Comparison ==="
    for comp in "${!sbom1_components[@]}"; do
        if [[ -z "${sbom2_components[$comp]+x}" ]]; then
            echo "- $comp"
        fi
    done
    for comp in "${!sbom2_components[@]}"; do
        if [[ -z "${sbom1_components[$comp]+x}" ]]; then
            echo "+ $comp"
        fi
    done
}

# Export normalized data
export_data() {
    local file="$1"
    local type="$2"
    local array_name="$3"

    case "$EXPORT_FORMAT" in
        json)
            echo "Exporting $file to JSON..."
            eval "printf '%s\n' \"\${!$array_name[@]}\" | jq -R -s -c 'split(\"\\n\")[:-1]' > ${file}.normalized.json"
            ;;
        csv)
            echo "Exporting $file to CSV..."
            eval "printf '%s\n' \"\${!$array_name[@]}\" | sed '/^$/d' | tr ':' ',' > ${file}.normalized.csv"
            ;;
        none) ;;
        *) echo "Invalid export format: $EXPORT_FORMAT"; exit 1 ;;
    esac
}

# Load both SBOMs
load_components "$SBOM1" sbom1_components
load_components "$SBOM2" sbom2_components

# Compare
compare_sboms_git_diff

# Export if requested
export_data "$SBOM1" "$(detect_sbom_type "$SBOM1")" sbom1_components
