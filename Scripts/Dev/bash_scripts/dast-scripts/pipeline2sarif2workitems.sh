#!/bin/bash

# Azure DevOps Organization and Project information
org_name="YourOrganizationName"
project_name="YourProjectName"

# Personal Access Token (PAT) with Work Item Read & Write scope
pat="YourPersonalAccessToken"

# Azure DevOps REST API endpoint URLs
base_url="https://dev.azure.com/$org_name/$project_name/_apis"
work_items_url="$base_url/wit/workitems"

# Read input JSON file
input_json=$(cat input.json)

# Convert JSON to SARIF format using jq
sarif_output=$(echo "$input_json" | jq -c '
{
  version: "2.1.0",
  "$schema": "https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0-rtm.5.json",
  runs: [
    {
      tool: {
        driver: {
          name: "Veracode",
          version: .pipeline_scan,
          informationUri: ._links.help.href,
          rules: [
            .findings[] | {
              id: (.issue_id | tostring),
              name: .title,
              shortDescription: {
                text: .issue_type
              },
              fullDescription: {
                text: .display_text
              },
              helpUri: .flaw_details_link,
              properties: {
                tags: ["security", "injection", "OSCommandInjection"],
                precision: "high",
                severity: (.severity | tostring)
              }
            }
          ]
        }
      },
      results: [
        .findings[] | {
          ruleId: (.issue_id | tostring),
          ruleIndex: 0,  # Static index as jq does not have a built-in counter
          level: (if .severity == 5 then "error" else "warning" end),
          message: {
            text: .display_text
          },
          locations: [
            {
              physicalLocation: {
                artifactLocation: {
                  uri: .image_path
                },
                region: {
                  startLine: .files.source_file.line
                }
              },
              logicalLocation: {
                name: .files.source_file.qualified_function_name,
                fullyQualifiedName: .files.source_file.qualified_function_name,
                kind: "function"
              }
            }
          ],
          properties: {
            issueType: .issue_type_id,
            cweId: ("CWE-" + (.cwe_id | tostring))
          }
        }
      ],
      invocations: [
        {
          executionSuccessful: true,
          toolExecutionNotifications: [
            {
              descriptor: {
                id: .scan_id,
                name: .message,
                level: "warning"
              }
            }
          ]
        }
      ]
    }
  ]
}')

# Write SARIF output to file
echo "$sarif_output" > output.sarif

echo "Conversion complete. SARIF output written to output.sarif"

# Extract findings from input JSON
findings=$(echo "$input_json" | jq -c '.findings[]')

# Loop through each finding and create a work item in Azure DevOps
while IFS= read -r finding; do
  # Extract fields from JSON
  title=$(echo "$finding" | jq -r '.title')
  severity=$(echo "$finding" | jq -r '.severity')
  display_text=$(echo "$finding" | jq -r '.display_text')
  image_path=$(echo "$finding" | jq -r '.image_path')
  source_file=$(echo "$finding" | jq -r '.files.source_file.file')
  line=$(echo "$finding" | jq -r '.files.source_file.line')

  # Work item JSON payload
  work_item_payload=$(cat <<EOF
{
  "op": "add",
  "path": "/fields/System.Title",
  "value": "$title"
}
EOF
)

  # Create work item in Azure DevOps
  response=$(curl -s -H "Content-Type: application/json" -u ":$pat" -d "$work_item_payload" "$work_items_url?api-version=6.0-preview.3")

  # Print response for debugging (optional)
  echo "Created work item:"
  echo "$response"

done <<< "$findings"

echo "All findings imported as work items in Azure DevOps."
