#!/bin/bash
http --auth-type veracode_hmac "https://api.veracode.com/appsec/v1/applications?name=$1" -o veracode-tmp.txt 
jq -r '._embedded.applications[0].guid' veracode-tmp.txt
app_guid=$(jq -r '._embedded.applications[0].guid' veracode-tmp.txt)
sandbox_name="$2"
http --auth-type veracode_hmac "https://api.veracode.com/appsec/v1/applications/$app_guid/sandboxes" -o veracode-tmp.txt
# Use jq to extract the GUID for the given sandbox name
guid=$(cat veracode-tmp.txt | jq -r --arg name "$sandbox_name" '.["_embedded"]["sandboxes"][] | select(.name == $name) | .guid')

# Check if jq found a GUID
if [ -n "$guid" ]; then
  echo "GUID for sandbox '$sandbox_name': $guid"
  http --auth-type veracode_hmac POST "https://api.veracode.com/appsec/v1/applications/$app_guid/sandboxes/$sandbox_guid/promote" #"delete_on_promote==true" #Add additional options like build id here or delete_on_promote
else
  echo "Sandbox '$sandbox_name' not found."
fi
