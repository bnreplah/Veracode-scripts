#!/bin/bash

#Usage: DAST-rescan.sh [Analysis Name <String>] [Duration <INT>] [Start Now <Bool>] [Start Date String <UTC Date>]
analysis_name="$1"
duration="$2"

now=false
today=$(date +"%Y-%m-%dT23:00+00:00") # always at 11:00
#iso_date=$(date -I)
date=""

#Comment this out to have it use the date parameter for the start time instead only
if [[ "$3" -eq "true" ]]; then
   now=true
fi

if [[ -z "$4" ]]; then
  date="$today"
  echo $date
else
  date="$4"
fi

http --auth-type veracode_hmac "https://api.veracode.com/was/configservice/v1/analyses?name=$1" -o analysis.json
# if there are multiple names matching the criteria will select the first one
name=$(cat analysis.json | jq -r '._embedded.analyses[0].name')
analysis_id=$(cat analysis.json | jq -r '._embedded.analyses[0].analysis_id')
lt_occurrence_id=$(cat analysis.json | jq -r '._embedded.analyses[0].latest_occurrence_id')
lt_occurrence_status=$(cat analysis.json | jq -r '._embedded.analyses[0].latest_occurrence_status.status_type')
# TODO: Error handling
if [ -z "$name" ]; then
  echo "Analysis Name not found"
  exit
else
  echo "Name found" 
fi

echo """
{
  \"name\": \"$name\",
  \"schedule\": {
   \"now\": \"$now\",
    \"start_date\": \"$date\",
    \"duration\": {
      \"length\": $duration,
      \"unit\": \"DAY\"
        }
    }
}""" > input.json

# Use this echo statement to make the script trigger scans immidiately
#echo """
#{
#  \"name\": \"$name\",
#  \"schedule\": {
#   \"now\": \"true\",
#    
#    \"duration\": {
#      \"length\": $duration,
#      \"unit\": \"DAY\"
#        }
#    }
#}""" > input.json

echo "Sending the following payload: "
cat input.json
echo "" # blank line
echo "Scan scheduled for $duration Days"
echo "Analysis ID: $analysis_id"
http --auth-type veracode_hmac PUT "https://api.veracode.com/was/configservice/v1/analyses/$analysis_id?method=PATCH" @input.json  
