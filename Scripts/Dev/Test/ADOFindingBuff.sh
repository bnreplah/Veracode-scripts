#!/bin/bash
# Description: This script is intended to pull down all the finding details and list out the details in a format that can be parsed if this script is modified
# get the app ids


http --auth-type veracode_hmac "https://api.veracode.com/appsec/v1/applications" -o applications.json

ApplicationGUIDs=($( cat applications.json | jq -r '._embedded.applications[].guid' ))

for element in "${ApplicationGUIDs[@]}"; do
    http --auth-type veracode_hmac "https://api.veracode.com/appsec/v2/applications/$element/summary_report" -o summary_report-$element.json
    http --auth-type veracode_hmac "https://api.veracode.com/appsec/v2/applications/$element/findings" -o findings-$element.json
    echo "Sleeping 1 second..."
    sleep 1
    #running nested array
    issue_ids=($(cat findings-$element.json | jq -r '._embedded.findings[].issue_id'))
    for issue in "${issue_ids[@]}"; do
        http --auth-type veracode_hmac "https://api.veracode.com/appsec/v2/applications/$element/findings/$issue/static_flaw_info" -o $element-static-flaw-$issue_id.json
        cat $element-static-flaw-$issue_id.json | jq -r '{ function: .data_paths[] | .function_name , line_number: .data_paths[] | .line_number , local_path: .data_paths[] | .local_path , steps: .data_paths[] | .steps , module: .data_paths[] | .module_name 
,  function_name: .data_paths[] | .function_name }'
        cat findings-$element.json | jq --arg issue -r '._embedded.findings[] | select(.issue_id == $issue ) | .description ' # process this information and the information in this findings object
        echo "--------------------------------------------------------------------------------------------------------------------------------------------------"
    done
done
