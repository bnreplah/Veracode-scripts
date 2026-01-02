#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install jq to use this script."
    exit 1
fi

# Check if the input file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_sbom.json> <args>"
    echo "Outputs a list of vulnerable components"
    exit 1
fi

input_file="$1"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
    echo "Input file not found: $input_file"
    exit 1
fi

# Create an associative array to store component names by bom-ref
#declare -A component_names
declare -A components
componentRef=()
declare -A componentMap
# Populate the associative array with component names
while read -r name bom_ref type; do
    echo "--------------------"
    echo "Name: "$name
    components["$bom_ref"]="$name"
    echo "Type:"$type
    echo "bom-ref:"$bom_ref
    componentRef=("$bom_ref")
    componentMap["$bom_ref"]=""
done < <( jq -r '.components[] |" \(."name") \(."bom-ref") \(."type")"' "$input_file")

echo "---------------------------"
echo "Vulnerabilities"

declare -A vulnerabilityMap
while read -r id affects; do
#    vulnerabilityMap["$id"]=($(affects[@]))
    echo "ID: "$id
    echo "Affects:"
    for element in "${affects[@]}"; do
        echo "         $element"
        componentMap["$element"]+="$id ,"
    done
done < <(jq -r '.vulnerabilities[] |" \(.id) \(.affects[].ref)"' "$input_file")
# Export the component_names array as an environment variable
#export component_name
echo "Vulnerable components"
echo "" > VulnerableComponents.txt
for component in "${!componentMap[@]}"; do
    if [ -n "${componentMap[$component]}" ]; then
          echo "  ComponentName: ${components["$component"]}"
          echo "                       Bom-Ref: $component"
          echo "                       Vulnerabilities: ${componentMap[$component]}"
          echo "  ComponentName: ${components["$component"]}" >> VulnerableComponents.txt
          echo "                       Bom-Ref: $component" >> VulnerableComponents.txt
          echo "                       Vulnerabilities: ${componentMap[$component]}" >> VulnerableComponents.txt
    fi
done