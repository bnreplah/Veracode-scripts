#!/bin/bash
# This is a helper script for the Reprting API to create an input.json for a report on all the Medium and Above Findings
echo '{
"scan_type": ["Static Analysis"],
"policy_sandbox": "Policy",
"status": "open",
"severity" : [ 3, 4, 5],
"report_type": "findings",
"last_updated_start_date": "2023-11-20 00:00:00"
}' > input.json
echo "The report payload has been written out to input.json"
ls input.json
