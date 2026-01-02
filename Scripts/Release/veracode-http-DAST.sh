#!/usr/bin/env bash
# Description: This script is the DAST essentials triggering script using HTTPie instead
# Prerequisites: Python, HTTPie installed, Veracode Authentication library installed, 



#### Setup variables ####
WEBHOOK=$(echo $1 )

# Set the Veracode API ID
if [ -n "$2" ]; then
VERACODE_API_ID=$(echo $2)
fi

# Set the Veracode API SECRET
if [ -n "$3" ]; then
VERACODE_API_KEY=$(echo $3 )
fi

# Set the API endpoint
API_ENDPOINT=api.veracode.com
API_PATH=/dae/api/core-api/webhook

#### Setup the build system ####

mkdir -p test-reports



#### Start Security Scan ####

# Start Scan and get scan ID
SCAN_ID=`http --auth-type veracode_hmac POST "https://$API_ENDPOINT$API_PATH/$WEBHOOK" | jq .data.scanId`
# Check if a positive integer was returned as SCAN_ID
if ! [ $SCAN_ID -ge 0 ] 2>/dev/null
then
   echo "Could not start Scan for Webhook $WEBHOOK."
   exit 1
fi

echo "Started Scan for Webhook $WEBHOOK. Scan ID is $SCAN_ID."

#### Check Security Scan Status ####

# Set status to Queued (100)
STATUS=100

# Run the scan until the status is not queued (100) or running (101) anymore
while [ $STATUS -le 101 ]
do
   echo "Scan Status currently is $STATUS (101 = Running)"

   # Only poll every minute
   sleep 60

   # Refresh status
    STATUS=`http --auth-type veracode_hmac "https://$API_ENDPOINT$API_PATH/$WEBHOOK/scans/$SCAN_ID/status" | jq .data.status.status_code`

done

echo "Scan finished with status $STATUS."

#### Download Scan Report ####


http --auth-type veracode_hmac "https://$API_ENDPOINT$API_PATH/$WEBHOOK/scans/$SCAN_ID/report/junit" -o test-reports/report.xml
echo "Downloaded Report to test-reports/report.xml"