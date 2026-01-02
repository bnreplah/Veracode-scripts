#!/bin/bash
# ChatGPT generated
# Experimental
# Function to convert SPDX to CycloneDX
convert_spdx_to_cyclonedx() {
    local spdx_file="$1"
    local output_file="$2"

    # Parse SPDX XML and generate CycloneDX JSON manually
    awk '
        BEGIN {
            print "{\"bomFormat\": \"CycloneDX\", \"components\": ["
        }
        /<package/ {
            sub(/^[[:space:]]*/, "", $0)
            gsub(/"/, "\\\"", $0)
            print "    {\"name\": \"" $2 "\", \"version\": \"" $4 "\", \"type\": \"" $6 "\"},"
        }
        END {
            print "  ]}"
        }
    ' "$spdx_file" > "$output_file"
}

# Function to convert SWID to CycloneDX
convert_swid_to_cyclonedx() {
    local swid_file="$1"
    local output_file="$2"

    # Parse SWID XML and generate CycloneDX JSON manually
    awk '
        BEGIN {
            print "{\"bomFormat\": \"CycloneDX\", \"components\": ["
        }
        /<SoftwareIdentity/ {
            sub(/^[[:space:]]*/, "", $0)
            gsub(/"/, "\\\"", $0)
            name = version = ""
        }
        /<Name/ {
            sub(/^[[:space:]]*/, "", $0)
            gsub(/"/, "\\\"", $0)
            name = $2
        }
        /<Version/ {
            sub(/^[[:space:]]*/, "", $0)
            gsub(/"/, "\\\"", $0)
            version = $2
        }
        /<\/SoftwareIdentity>/ {
            if (name != "" && version != "") {
                print "    {\"name\": \"" name "\", \"version\": \"" version "\", \"type\": \"Application\"},"
            }
        }
        END {
            print "  ]}"
        }
    ' "$swid_file" > "$output_file"
}

# Function to convert List to CycloneDX
convert_list_to_cyclonedx() {
    local list_file="$1"
    local output_file="$2"

    # Parse List and generate CycloneDX JSON manually
    awk '
        BEGIN {
            print "{\"bomFormat\": \"CycloneDX\", \"components\": ["
        }
        NF > 0 {
            sub(/^[[:space:]]*/, "", $0)
            gsub(/"/, "\\\"", $0)
            print "    {\"name\": \"" $1 "\", \"version\": \"" $2 "\", \"type\": \"" $3 "\"},"
        }
        END {
            print "  ]}"
        }
    ' "$list_file" > "$output_file"
}

# Function to convert CSV to CycloneDX
convert_csv_to_cyclonedx() {
    local csv_file="$1"
    local output_file="$2"

    # Parse CSV and generate CycloneDX JSON manually
    awk -F ',' '
        BEGIN {
            print "{\"bomFormat\": \"CycloneDX\", \"components\": ["
        }
        NF > 2 {
            sub(/^[[:space:]]*/, "", $0)
            gsub(/"/, "\\\"", $0)
            print "    {\"name\": \"" $1 "\", \"version\": \"" $2 "\", \"type\": \"" $3 "\"},"
        }
        END {
            print "  ]}"
        }
    ' "$csv_file" > "$output_file"
}

# Function to convert SBOM to CycloneDX JSON
convert_to_cyclonedx() {
    local sbom_file="$1"
    local sbom_type="$2"
    local cyclonedx_output=""

    case "$sbom_type" in
        SPDX)
            # Convert SPDX to CycloneDX
            cyclonedx_output="${sbom_file%.spdx.xml}.cyclonedx.json"
            convert_spdx_to_cyclonedx "$sbom_file" "$cyclonedx_output"
            echo "Conversion successful. CycloneDX output: $cyclonedx_output"
            ;;
        SWID)
            # Convert SWID to CycloneDX
            cyclonedx_output="${sbom_file%.swid.xml}.cyclonedx.json"
            convert_swid_to_cyclonedx "$sbom_file" "$cyclonedx_output"
            echo "Conversion successful. CycloneDX output: $cyclonedx_output"
            ;;
        CycloneDX)
            # Placeholder: No conversion needed for CycloneDX
            echo "CycloneDX format is already detected for file: $sbom_file"
            ;;
        CSV)
            # Convert CSV to CycloneDX
            cyclonedx_output="${sbom_file%.csv}.cyclonedx.json"
            convert_csv_to_cyclonedx "$sbom_file" "$cyclonedx_output"
            echo "Conversion successful. CycloneDX output: $cyclonedx_output"
            ;;
        List)
            # Convert List to CycloneDX
            cyclonedx_output="${sbom_file%.txt}.cyclonedx.json"
            convert_list_to_cyclonedx "$sbom_file" "$cyclonedx_output"
            echo "Conversion successful. CycloneDX output: $cyclonedx_output"
            ;;
        *)
            echo "Conversion not supported for SBOM type: $sbom_type"
            ;;
    esac
}

# Example usage
# Assuming 'detect_sbom_format' is the function from the previous responses
sbom_file="examples/example.spdx.xml"
sbom_type=$(detect_sbom_format "$sbom_file" | cut -d ' ' -f 4)
convert_to_cyclonedx "$sbom_file" "$sbom_type"

swid_file="examples/example_swid.xml"
swid_type=$(detect_sbom_format "$swid_file" | cut -d ' ' -f 4)
convert_to_cyclonedx "$swid_file" "$swid_type"

csv_file="examples/example.csv"
csv_type=$(detect_sbom_format "$csv_file" | cut -d ' ' -f 4)
convert_to_cyclonedx "$csv_file" "$csv_type"

list_file="examples/example_list.txt"
list_type=$(detect_sbom_format "$list_file" | cut -d ' ' -f 4)
convert_to_cyclonedx "$list_file" "$list_type"



