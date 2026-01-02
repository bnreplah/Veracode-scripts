#!/bin/bash
# Define AppName to pull build ID
# Takes appname from argument list
# Takes build name from argument list
# Takes sandbox name from argument list
# Requires Veracode Credentials file to operate, otherwise reconfigure API Wrapper command

#vid=""
#vkey=""
appname="$1"
#buildname="$2"
sandboxname="$2"

#PRESCAN_SLEEP_TIME=60
SCAN_SLEEP_TIME=120

#!/bin/bash
# Base URL of the API endpoint
BASE_URL="https://api.veracode.com/appsec/v1/applications"
# Initial page number
page_number=0
out_dir=".veracode-out"

if [ -d "$out_dir" ]; then
    echo "directory exists"
    cd "$out_dir/"
    pwd
else
    echo "Making directory"
    mkdir $out_dir
    cd "$out_dir/"
    pwd
fi

# Function to make the API call and process the response
make_api_call() {
  local page=$1
  http --auth-type veracode_hmac "$BASE_URL?size=100&page=$page" -o applications-$page.json
  response=$(cat applications-$page.json )

  # Extract total_pages, total_elements, and number from the response
  total_pages=$(cat applications-$page.json | jq -r '.page.total_pages' )
  total_elements=$(cat applications-$page.json | jq -r '.page.total_elements' )
  current_page=$(cat applications-$page.json | jq -r '.page.number' )
  
  # Return total_pages for further use
  echo $total_pages


}

# Main loop to handle pagination
while true; do
  total_pages=$( make_api_call $page_number)
  echo "Page number: $page_number"
  # Check if we have more pages to fetch
  if [[ $((page_number + 1)) -lt $total_pages ]]; then
    page_number=$(( page_number + 1 ))
  else
    break
  fi
done

echo "All pages fetched."

#http --auth-type veracode_hmac https://api.veracode.com/appsec/v1/applications -o applications.json



