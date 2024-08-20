#!/bin/bash
# Simple script to get a list of all the DAST scans and Results 
# this script utilizes the python httpie module and the veracode authentication library
# 
# echo "DAST list "
# 
# Install HTTPie:
# Install Python:
#
# help(){ 
    


# }
out_dir=".veracode-out"
analyses_names=()
analyses_status=()
analyses_last_occurance_date_time=()
analyses_last_occurance_ids=()
ISM_in_use=()
ISM_endpoints=()
ISM_gateways=()
analyses_ids=()
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

echo "Current working directory: "
pwd


# check if needs to pagenate
BASE_URL="https://api.veracode.com/was/configservice/v1/analyses"
# Initial page number
page_number=0

# Function to make the API call and process the response
make_api_call() {
  local page=$1
  http --auth-type veracode_hmac "$BASE_URL?size=10&page=$page" -o analyses-$page.json
  response=$(cat analyses-$page.json )

  # Extract total_pages, total_elements, and number from the response
  total_pages=$(cat analyses-$page.json | jq -r '.page.total_pages' )
  total_elements=$(cat analyses-$page.json | jq -r '.page.total_elements' )
  current_page=$(cat analyses-$page.json | jq -r '.page.number' )
  
  # Return total_pages for further use
  echo $total_pages

}


count=0
echo "Index     |  Analysis name  |  Analysis Status  |  Last Occurance Date and Time  | Analysis ID               | Last Analysis Occurance ID "
echo " Analysis Name , Analysis Status , Last Occurance Date and Time , Analysis ID , Last Analysis Occurance ID " > "analyses.csv"

# Main loop to handle pagination
while true; do
  total_pages=$( make_api_call $page_number)
  echo "--------------------------"
  echo "Page number: $page_number"
  echo "--------------------------"

    while IFS= read -r line; do
        analyses_names+=("$line")
    done < <(jq -r '._embedded.analyses[].name' "analyses-$page_number.json")
    
    while IFS= read -r line; do
        analyses_status+=("$line")
    done < <(jq -r '._embedded.analyses[].latest_occurrence_status.status_type' "analyses-$page_number.json")
    
    while IFS= read -r line; do
        analyses_last_occurance_date_time+=("$line")
    done < <(jq -r '._embedded.analyses[].latest_occurrence_date_time' "analyses-$page_number.json")
    
    while IFS= read -r line; do
        analyses_ids+=("$line")
    done < <(jq -r '._embedded.analyses[].analysis_id' "analyses-$page_number.json")
    
    while IFS= read -r line; do
        analyses_last_occurance_ids+=("$line")
    done < <(jq -r '._embedded.analyses[].latest_occurrence_id' "analyses-$page_number.json")
    
    while IFS= read -r line; do
        ISM_in_use+=("$line")
    done < <(jq -r '._embedded.analyses[].latest_occurrence_id' "analyses-$page_number.json")
    
    while IFS= read -r line; do
        ISM_gateways+=("$line")
    done < <(jq -r '._embedded.analyses[].latest_occurrence_id' "analyses-$page_number.json")
    
    while IFS= read -r line; do
        ISM_endpoints+=("$line")
    done < <(jq -r '._embedded.analyses[].latest_occurrence_id' "analyses-$page_number.json")

    
  # Check if we have more pages to fetch
  if [[ $((page_number + 1)) -lt $total_pages ]]; then
    page_number=$(( page_number + 1 ))
  else
    break
  fi
done

echo "All pages fetched."


for name in "${analyses_names[@]}"; do
    echo "$count     : $name : ${analyses_status[$count]} : ${analyses_last_occurance_date_time[$count]} : ${analyses_ids[$count]} : ${analyses_last_occurance_ids[$count]}"
    http --auth-type veracode_hmac "https://api.veracode.com/was/configservice/v1/analysis_occurrences/${analyses_last_occurance_ids[$count]}" -o "${analyses_last_occurance_ids[$count]}-scan.json"
    echo "$name , ${analyses_status[$count]} , ${analyses_last_occurance_date_time[$count]} , ${analyses_ids[$count]} , ${analyses_last_occurance_ids[$count]}" >> analyses.csv
    count=$(($count+1))
    
done




echo ""
echo "Output written to $out_dir/analyses.csv"
#cat analyses.csv
cd -




