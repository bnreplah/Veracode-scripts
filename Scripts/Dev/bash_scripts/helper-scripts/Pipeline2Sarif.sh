#!/bin/bash

# Read input JSON file
convert_results_json_to_sarif(){
  input_json=$1

  # Convert JSON to SARIF format using jq
  sarif_output=$(echo "$input_json" | jq '
  {
    "version": "2.1.0",
    "$schema": "https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0-rtm.5.json",
    "runs": [
      {
        "tool": {
          "driver": {
            "name": "Veracode",
            "version": .pipeline_scan,
            "informationUri": ._links.help.href,
            "rules": [
              {
                "id": (.findings[].issue_id | tostring),
                "name": .findings[].title,
                "shortDescription": {
                  "text": .findings[].issue_type
                },
                "fullDescription": {
                  "text": .findings[].display_text
                },
                "helpUri": .findings[].flaw_details_link,
                "properties": {
                  "tags": ["security", "injection", "OSCommandInjection"],
                  "precision": "high",
                  "severity": (.findings[].severity | tostring)
                }
              }
            ]
          }
        },
        "results": [
          {
            "ruleId": (.findings[].issue_id | tostring),
            "ruleIndex": (0),
            "level": if .findings[].severity == 5 then "error" else "warning" end,
            "message": {
              "text": .findings[].display_text
            },
            "locations": [
              {
                "physicalLocation": {
                  "artifactLocation": {
                    "uri": .findings[].image_path
                  },
                  "region": {
                    "startLine": .findings[].files.source_file.line
                  }
                },
                "logicalLocation": {
                  "name": .findings[].files.source_file.qualified_function_name,
                  "fullyQualifiedName": .findings[].files.source_file.qualified_function_name,
                  "kind": "function"
                }
              }
            ],
            "properties": {
              "issueType": .findings[].issue_type_id,
              "cweId": ("CWE-" + (.findings[].cwe_id | tostring))
            }
          }
        ],
        "invocations": [
          {
            "executionSuccessful": true,
            "toolExecutionNotifications": [
              {
                "descriptor": {
                  "id": .scan_id,
                  "name": .message,
                  "level": "warning"
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

  echo "Conversion complete. Output written to output.sarif"


}
# # This does it with JQ from the policy files from the platform
# jq '{
#   version: "2.1.0",
#   "$schema": "https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0.json",
#   runs: [
#     {
#       tool: {
#         driver: {
#           name: "Veracode Static Analysis",
#           informationUri: "https://www.veracode.com",
#           rules: (
#             ._embedded.findings
#             | map({
#                 id: (.finding_details.cwe.id | tostring),
#                 name: .finding_details.cwe.name,
#                 helpUri: .finding_details.cwe.href,
#                 properties: {
#                   tags: [ .finding_details.finding_category.name ]
#                 }
#               })
#             | unique
#           )
#         }
#       },
#       results: (
#         ._embedded.findings
#         | map({
#             ruleId: (.finding_details.cwe.id | tostring),
#             message: { text: .description },
#             level: (if .finding_details.severity >= 4 then "error"
#                     elif .finding_details.severity == 3 then "warning"
#                     else "note" end),
#             locations: [
#               {
#                 physicalLocation: {
#                   artifactLocation: { uri: .finding_details.file_path },
#                   region: { startLine: .finding_details.file_line_number }
#                 }
#               }
#             ]
#           })
#       )
#     }
#   ]
# }' "$INPUT_FILE" > "results.sarif.json"
