#!/bin/bash
echo "[Usage]: ./$0 <Analysis Name>"
echo "Retrieve blockList from a Dynamic Analysis"

http --auth-type veracode_hmac "https://api.veracode.com/was/configservice/v1/analyses?name=$1" -o analyses.json
analysis_id=$( cat analyses.json | jq -r '._embedded.analyses[0].analysis_id' )
http --auth-type veracode_hmac "https://api.veracode.com/was/configservice/v1/analyses/$analysis_id" | jq -r '.scan_setting.blacklist_configuration.blackList[]'