#!/bin/bash
# the purpose of this script is to merge sboms


# Starting with Script starter creating from MS365 copilot

#!/usr/bin/env bash

# sbom_merge.sh
# Merge two SBOMs (CycloneDX/SPDX, JSON/XML) and export in CycloneDX, SPDX, or custom format.

set -euo pipefail

SBOM1="$1"
SBOM2="$2"
FORMAT="${3:-merged}" # Options: cyclonedx, spdx, merged
OUTPUT="${4:-merged_sbom.json}"

declare -A merged_components

# Detect SBOM type
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
    jq -r '.components[] | "\(.name)|\(.version)|\(.licenses[0].license.id // "N/A")|\(.hashes[0].value // "N/A")"' "$1"
}

# Parse CycloneDX XML
parse_cyclonedx_xml() {
    xmlstarlet sel -t -m "//component" \
        -v "concat(name,'|',version,'|',licenses/license/id,'|',hashes/hash)" -n "$1"
}

# Parse SPDX JSON
parse_spdx_json() {
    jq -r '.packages[] | "\(.name)|\(.versionInfo)|\(.licenseConcluded // "N/A")|\(.checksums[0].checksumValue // "N/A")"' "$1"
}

# Parse SPDX XML
parse_spdx_xml() {
    xmlstarlet sel -t -m "//Package" \
        -v "concat(name,'|',versionInfo,'|',licenseConcluded,'|',Checksum/checksumValue)" -n "$1"
}

# Load components into merged array
load_components() {
    local file="$1"
    local source="$2"
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

    while IFS='|' read -r name version license hash; do
        key="${name}:${version}"
        if [[ -n "${merged_components[$key]+x}" ]]; then
            # Merge metadata if conflict
            existing="${merged_components[$key]}"
            merged_components["$key"]="$(jq -n \
                --argjson old "$existing" \
                --arg name "$name" \
                --arg version "$version" \
                --arg license "$license" \
                --arg hash "$hash" \
                --arg source "$source" \
                '{
                    name: $name,
                    version: $version,
                    license: ($old.license + [$license] | unique),
                    hash: ($old.hash + [$hash] | unique),
                    sources: ($old.sources + [$source] | unique)
                }')"
        else
            merged_components["$key"]="$(jq -n \
                --arg name "$name" \
                --arg version "$version" \
                --arg license "$license" \
                --arg hash "$hash" \
                --arg source "$source" \
                '{
                    name: $name,
                    version: $version,
                    license: [$license],
                    hash: [$hash],
                    sources: [$source]
                }')"
        fi
    done <<< "$data"
}

# Export merged BOM
export_merged() {
    case "$FORMAT" in
        merged)
            echo "[" > "$OUTPUT"
            local first=true
            for comp in "${merged_components[@]}"; do
                if $first; then first=false; else echo "," >> "$OUTPUT"; fi
                echo "$comp" >> "$OUTPUT"
            done
            echo "]" >> "$OUTPUT"
            ;;
        cyclonedx)
            jq -n \
                --argjson components "[${merged_components[*]}]" \
                '{
                    bomFormat: "CycloneDX",
                    specVersion: "1.5",
                    version: 1,
                    components: $components
                }' > "$OUTPUT"
            ;;
        spdx)
            jq -n \
                --argjson packages "[${merged_components[*]}]" \
                '{
                    spdxVersion: "SPDX-2.3",
                    dataLicense: "CC0-1.0",
                    packages: $packages
                }' > "$OUTPUT"
            ;;
        *)
            echo "Invalid format: $FORMAT"; exit 1 ;;
    esac
    echo "Merged SBOM written to $OUTPUT in $FORMAT format"
}

# Load both SBOMs
load_components "$SBOM1" "SBOM1"
load_components "$SBOM2" "SBOMload_components "$SBOM2" "SBOM2"

# Export
