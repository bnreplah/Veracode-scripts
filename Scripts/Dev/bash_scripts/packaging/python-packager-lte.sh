#!/bin/bash
# GPT Created script
# Define the frameworks/packages to check for
declare -A supported_frameworks=(
    ["boto3"]="1.x"
    ["azure-functions"]="3.x"
    ["cryptography"]="0.6-1.x"
    ["django"]="1.x 3.x 4.x"
    ["flask"]="0.x-2.x"
    ["httplib2"]="0.9.2"
    ["jinja2"]="2.x"
    ["requests"]="2.x"
    ["sqlalchemy"]=".9.x-1.x"
)

# Function to check if a directory contains a supported framework/package
contains_supported_framework() {
    local dir="$1"
    local framework="$2"
    local version="$3"
    if [ -f "$dir/Pipfile.lock" ]; then
        if grep -q "$framework" "$dir/Pipfile.lock" && grep -q "$version" "$dir/Pipfile.lock"; then
            return 0
        fi
    fi
    return 1
}

# Function to zip up the code and HTML files
zip_project() {
    local project_dir="$1"
    local zip_name="$2"
    local python_files=$(find "$project_dir" -type f -name "*.py" -o -name "*.html" | xargs)
    if [ -n "$python_files" ]; then
        zip -r "$zip_name" $python_files
        echo "Zip created: $zip_name"
    else
        echo "No Python or HTML files found in $project_dir"
    fi
}

# Main script
for framework in "${!supported_frameworks[@]}"; do
    versions=${supported_frameworks[$framework]}
    for version in $versions; do
        if contains_supported_framework "$PWD" "$framework" "$version"; then
            zip_name="${PWD##*/}_${framework}_project.zip"
            zip_project "$PWD" "$zip_name"
            exit 0
        fi
    done
done

echo "No supported frameworks found in $PWD"
exit 1
