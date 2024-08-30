#!/bin/bash
# Simple script to get a list of all the DAST scans and Results
# this script utilizes the python httpie module and the veracode authentication library
# DAST - List script
# Install HTTPie: https://docs.veracode.com/r/c_httpie_tool
# Install Python Authentication Library: https://docs.veracode.com/r/t_install_api_authen
# Version 2.0.0
# Variable configuration and initailization
################################################################################
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Dast-LS"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Install HTTPie: https://docs.veracode.com/r/c_httpie_tool"
echo "Install Python Authentication Library: https://docs.veracode.com/r/t_install_api_authen"
echo "Version 2.0.0"
echo "------------------------------------------------------------------------------------------"

out_dir=".veracode-out"
analyses_names=()
analyses_status=()
analyses_last_occurrence_date_time=()
analyses_ids=()
analyses_last_occurrence_ids=()
analyses_occurrence_ids=()
scan_ids=()
scan_occurance_ids=()
has_verification_failures=()
ISM_in_use=() # check during scan occurance check
ISM_endpoints=() # check during scan occurance check
ISM_gateways=()  # check during scan occurance check
verbose=false
silent=false
size=100
# Verbose fields
verb_count_of_failed_verifications=()
verb_count_of_high_sev_flaws=()
verb_count_of_low_sev_flaws=()
verb_count_of_medium_sev_flaws=()
verb_count_of_very_high_sev_flaws=()
verb_duration=()
verb_expected_publish_date=()
verb_internal_scan_configuration=()
verb_scan_type=()
verb_results_import_status=()
verb_requests=()
verb_responses=()
verb_links_crawled=()
verb_links_audited=()
verb_network_errors=()
verb_port_shutdowns=()
verb_login_successes=()
verb_login_failures=()
verb_has_coverage_report=()
verb_dropped_events=()
DEBUG=false
# check if needs to pagenate
BASE_URL="https://api.veracode.com/was/configservice/v1"
# Initial page number
page_number=0
count=0 # itterator var
app_name=()
total_flaw_count=()
#################################################################################

help(){
  
    echo "DAST-ls.sh ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "- The purpose of this script is to list out the Analsyis occurrence timestamps and ID to better navigate DAST Scans"
    echo "  The script should produce output to the screen as it parses through, this can be disabled with the silent flag. "
    echo "  The script should create a .veracode-out folder and within it is the analyses.csv which contains the pulled     "
    echo "  results."
    echo "- Usage $0"
    echo "  -h       show this help menu "
    echo "  -s       silent, turn off output"
    echo "  -v       verbose, makes additional API calls to pull the analysis occurrence status"
    echo "  -a       List out analysis details [Default]"
}


# Function to make the API call and process the response
make_list_analyses_call() { # make a list of all the analyses
  local page=$1
  http --auth-type veracode_hmac "$BASE_URL/analyses?size=$size&page=$page" -o "analyses-$page.json"
  response=$(cat analyses-$page.json )

  # Extract total_pages, total_elements, and number from the response
  total_pages=$(cat analyses-$page.json | jq -r '.page.total_pages' )
  total_elements=$(cat analyses-$page.json | jq -r '.page.total_elements' )
  current_page=$(cat analyses-$page.json | jq -r '.page.number' )

  # Return total_pages for further use
  echo $total_pages

}

make_list_occurrences_call(){ # make a list of the analyses occurrences
  local page=$1
  #http --auth-type veracode_hmac "$BASE_URL/analysis_occurrences?size=$size&page=$page" 
  http --auth-type veracode_hmac "$BASE_URL/analysis_occurrences?size=$size&page=$page" -o "analyses-occurrences-$page.json"
  response=$(cat analyses-occurrences-$page.json )
  #cat analyses-occurrences-$page.json

  # Extract total_pages, total_elements, and number from the response
  total_pages=$(cat analyses-occurrences-$page.json | jq -r '.page.total_pages' )
  total_elements=$(cat analyses-occurrences-$page.json | jq -r '.page.total_elements' )
  current_page=$(cat analyses-occurrences-$page.json | jq -r '.page.number' )

  # Return total_pages for further use
  return $total_pages


}

verb_occurrence_call(){  # look at the configuration of the last scan run
    local page=$1
    local occurrence_id=$2
    #http --auth-type veracode_hmac "${BASE_URL}/analysis_occurrences/${occurrence_id}/scan_occurrences?size=$size" 
    http --auth-type veracode_hmac "${BASE_URL}/analysis_occurrences/${occurrence_id}/scan_occurrences?size=${size}&page=${page}" -o "analysis-occurrence-$occurrence_id-$page.json"
    response=$(cat analysis-occurrence-$occurrence_id-$page.json )
    #cat analysis-occurrence-$occurrence_id-$page.json

    # Extract total_pages, total_elements, and number from the response
    total_pages=$(cat analysis-occurrence-$occurrence_id-$page.json | jq -r '.page.total_pages' )
    total_elements=$(cat analysis-occurrence-$occurrence_id-$page.json | jq -r '.page.total_elements' )
    current_page=$(cat analysis-occurrence-$occurrence_id-$page.json | jq -r '.page.number' )
    # comment out and opt out of recursion, was just quicker
    # if [[ $((current_page + 1)) -lt $total_pages ]]; then
    #     page=$(( page + 1 ))
    #     verb_occurrence_call $page $occurrence_id
    # else
    #     echo $total_pages
    #     return
    # fi # end if
    return $total_pages
    
}
verb_analysis_call(){ # looks at the scan configurations of the scans not yet run
    local page=$1
    local analysis_id=$2
    http --auth-type veracode_hmac "$BASE_URL/analyses/$analysis_id/scans?size=$size&page=$page" -o "analysis-scans-$analysis_id-$page.json"
    response=$(cat analysis-scans-$analysis_id-$page.json )

    # Extract total_pages, total_elements, and number from the response
    total_pages=$(cat analysis-scans-$analysis_id-$page.json | jq -r '.page.total_pages' )
    total_elements=$(cat analysis-scans-$analysis_id-$page.json | jq -r '.page.total_elements' )
    current_page=$(cat analysis-scans-$analysis_id-$page.json | jq -r '.page.number' )
    # comment out and opt out of recursion, was just quicker
    if [[ $((current_page + 1)) -lt $total_pages ]]; then
        page=$(( page + 1 ))
        verb_occurrence_call $page $occurrence_id
    else
        echo $total_pages
        return
    fi # end if
}
get_all(){ # experimental
    local -n occurrence_array=$1  # Create a reference to the passed array variable
    local -n analyses_array=$2
    option=$3
    if [[ "$option" == "1" ]]; then
        for (( i=0; i<${#occurrence_array[@]}; i++ )); do
            
            verb_occurrence_call "${occurrence_array[$i]}"
        
        done
    else
        for (( i=0; i<${#analyses_array[@]}; i++ )); do
            
            verb_analyses_call "${analyses_array[$i]}"
        
        done
    fi
}
if [[ "${1}" ]]; then
    while [[ $# -gt 0 ]]; do
            case "$1" in
            
                # Display the Help Menu 
                -h)
                    help
                    shift 1
                    ;;
                -v)
                    echo "Verbose Mode"
                    verbose=true
                    shift 1
                    ;;
                -s)
                    echo "Silent Mode"
                    silent=true
                    shift 1
                    ;;
                -a) 
                    echo "Running Default"
                    shift 1
                    ;;
                -d)
                    echo "Turning on Debug Mode"
                    DEBUG=true
                    shift 1
                    ;;
                *)
                    help
                    shift 1
                    ;;
                #TODO: add Clean parameter
            esac
    done
fi

# if the out_dir already exists move in to it
# otherwise create it and then move in to it
if [ -d "$out_dir" ]; then
    echo ".veracode-out/ directory exists"
    cd "$out_dir/"
    pwd
else
    echo "Making directory .veracode-out/"
    mkdir $out_dir
    cd "$out_dir/"
    pwd
fi

echo "Current working directory: "
pwd


#initialize the headers of the CSV file
##################################################################################################################################
if $verbose; then # slightly different headers if verbose to give more clarification
    if $silent; then
        echo .
    else
        echo "Index     |  Analysis name  |  Last Analysis occurrence Status  |  Has Verification Failures |Last occurrence Date and Time | Analysis ID               | Last Analysis occurrence ID   | Count of Failed Verifications | Count of High Severity Flaws | Count of low Severity Flaws | Count of Medium Severity Flaws | Count of Very High Severity Flaws | Total Flaw Count | Duration | Expected Publish Date | Internal Scan Configuration | Scan Type | Results Import Status | Requests | Responses | Links Crawled | Links Audited | Network Errors | Port Shutdowns | Login Successes | Login Failures | Has Coverage Report | Dropped Events "
    fi
        echo "Analysis name , Last Analysis Occurrence Status , Has Verification Failures , Last occurrence Date and Time , Analysis ID , Last Analysis occurrence ID , Count of Failed Verifications , Count of High Severity Flaws , Count of low Severity Flaws , Count of Medium Severity Flaws , Count of Very High Severity Flaws , Total Flaw Count , Duration , Expected Publish Date , Internal Scan Configuration , Scan Type , Results Import Status , Requests , Responses , Links Crawled , Links Audited , Network Errors , Port Shutdowns , Login Successes , Login Failures , Has Coverage Report , Dropped Events " > "analyses.csv"
else
    if $silent; then
        echo .
    else
        echo "Index     |  Analysis name  |  Analysis Status  |  Last occurrence Date and Time  | Analysis ID               | Last Analysis occurrence ID "
    fi
    echo " Analysis Name , Analysis Status , Last occurrence Date and Time , Analysis ID , Last Analysis occurrence ID " > "analyses.csv"
fi

# Main loop to handle pagination
break_condition=true
while $break_condition; do

    if $verbose; then
        total_pages=$( make_list_analyses_call $page_number)
        # if $silent; then
        #     echo .
        # else
        #     echo "--------------------------"
        #     echo "Page number: $page_number"
        #     echo "--------------------------"
        # fi    

        

        total_pages=$( make_list_occurrences_call 0 )
        while IFS= read -r line; do
            analyses_occurrence_ids+=("$line")
            #echo "$line"
        done < <(jq -r '._embedded.analysis_occurrences[].analysis_occurrence_id' "analyses-occurrences-0.json")
        
        for id in "${analyses_occurrence_ids[@]}"; do
            #echo "$id"
            verb_occurrence_call 0 "$id"
        done

        # if $silent; then
        #     echo .
        # else
        #     echo "--------------------------"
        #     echo "Page number: $page_number"
        #     echo "--------------------------"
        # fi
        echo "Parsing Analyses occurrences ..."
        for lineo in "${analyses_occurrence_ids[@]}"; do

            if $DEBUG; then 
                echo "---------------------------------------------------------------------------------------------------------------"
                echo "Analysis occurrence ID : $lineo" 
            fi
            
            while IFS= read -r line; do
                if $DEBUG; then echo "Count of Failed Verifications: $line" ; fi
                verb_count_of_failed_verifications+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].count_of_failed_verifications' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Count of High Severity Flaws: $line" ; fi
                verb_count_of_high_sev_flaws+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].count_of_high_sev_flaws' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Count of Low Severity Flaws: $line"; fi
                verb_count_of_low_sev_flaws+=()
            done < <(jq -r '._embedded.scan_occurrences[0].count_of_low_sev_flaws' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Count of Medium Severity Flaws: $line"; fi
                verb_count_of_medium_sev_flaws+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].count_of_medium_sev_flaws' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Count of Very High Severity Flaws: $line"; fi
                verb_count_of_very_high_sev_flaws+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].count_of_very_high_sev_flaws' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Duration: $line"; fi
                verb_duration+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].duration' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Expected Publish Date: $line"; fi
                verb_expected_publish_date+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].expected_publish_date' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Internal Scan Configuration: $line"; fi
                verb_internal_scan_configuration+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].internal_scan_configuration.enabled' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                #echo "ISM in Use"
                ISM_in_use+=("$line")    
            done < <((jq -r '._embedded.scan_occurrences[0].internal_scan_configuration.enabled' "analysis-occurrence-$lineo-0.json" ))
            if [ "$(jq -r '._embedded.scan_occurrences[0].internal_scan_configuration.enabled' "analysis-occurrence-$lineo-0.json")" ]; then
                if $DEBUG; then echo "DEBUG: ISM detected"; fi
                while IFS= read -r line; do
                    if $DEBUG; then echo "ISM endpoint ID: $line"; fi
                    ISM_endpoints+=("$line")
                done < <( jq -r '._embedded.scan_occurrences[0].internal_scan_configuration.endpoint_id' "analysis-occurrence-$lineo-0.json")
                while IFS= read -r line; do
                    if $DEBUG; then echo "ISM gateway ID: $line"; fi
                    ISM_gateways+=("$line")
                done < <( jq -r '._embedded.scan_occurrences[0].internal_scan_configuration.gateway_id' "analysis-occurrence-$lineo-0.json") 
            fi
            while IFS= read -r line; do
                if $DEBUG; then echo "Scan Type: $line"; fi
                verb_scan_type+=("$line")
            done < <( jq -r '._embedded.scan_occurrences[0].scan_type' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Import Status: $line"; fi
                verb_results_import_status+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].result_import_status' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Requests: $line"; fi
                verb_requests+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].summary.requests' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Response: $line"; fi
                verb_responses+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].summary.responses' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Links Crawled: $line"; fi
                verb_links_crawled+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].summary.links_crawled' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Links Audited: $line"; fi
                verb_links_audited+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].summary.links_audited' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Network Errors: $line"; fi
                verb_network_errors+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].summary.network_errors' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Port Shutdowns: $line"; fi
                verb_port_shutdowns+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].summary.port_shutdowns' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Login Successes: $line"; fi
                verb_login_successes+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].summary.login_successes' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Login Failures: $line"; fi
                verb_login_failures+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].summary.login_failures' "analysis-occurrence-$lineo-0.json")
            while IFS= read -r line; do
                if $DEBUG; then echo "Coverage report available: $line"; fi
                verb_has_coverage_report+=($line)
            done < <(jq -r '._embedded.scan_occurrences[0].summary.has_coverage_report' "analysis-occurrence-$lineo-$page_number.json")
            while IFS= read -r line; do
                if $DEBUG; then  echo "Dropped Events: $line"; fi
                verb_dropped_events+=($line)
            done < <(jq -r '._embedded.scan_occurrences[0].summary.dropped_events' "analysis-occurrence-$lineo-$page_number.json")
            while IFS= read -r line; do
                analyses_names+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].analysis_name' "analysis-occurrence-$lineo-$page_number.json")
            while IFS= read -r line; do
                analyses_status+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].analysis_occurrence_status' "analysis-occurrence-$lineo-$page_number.json")
            while IFS= read -r line; do # no display currently
                app_name+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].linked_platform_app_name' "analysis-occurrence-$lineo-$page_number.json")
            while IFS= read -r line; do # no display currently
                total_flaw_count+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].total_flaw_count' "analysis-occurrence-$lineo-$page_number.json")
            while IFS= read -r line; do
                analyses_ids+=("$line")
            done < <(jq -r '._embedded.scan_occurrences[0].analysis_id' "analysis-occurrence-$lineo-$page_number.json")
        done 

    else
        total_pages=$( make_list_analyses_call $page_number)
        if $silent; then
            echo .
        else
            echo "--------------------------"
            echo "Page number: $page_number"
            echo "--------------------------"
        fi    

        #analyses_names+=( $(jq -r '._embedded.analyses[].name' "analyses-$page_number.json") )
        while IFS= read -r line; do
            analyses_names+=("$line")
        done < <(jq -r '._embedded.analyses[].name' "analyses-$page_number.json")
        #analyses_satus+=( $(jq -r '._embedded.analyses[].latest_occurrence_status.status_type' "analyses-$page_number.json") )
        while IFS= read -r line; do
            analyses_status+=("$line")
        done < <(jq -r '._embedded.analyses[].latest_occurrence_status.status_type' "analyses-$page_number.json")
        # analyses_last_occurrence_date_time+=($(jq -r '._embedded.analyses[].latest_occurrence_date_time' "analyses-$page_number.json"))
        while IFS= read -r line; do
            analyses_last_occurrence_date_time+=("$line")
        done < <(jq -r '._embedded.analyses[].latest_occurrence_date_time' "analyses-$page_number.json")
        # analyses_ids+=($(jq -r '._embedded.analyses[].analysis_id' "analyses-$page_number.json"))
        while IFS= read -r line; do
            analyses_ids+=("$line")
        done < <(jq -r '._embedded.analyses[].analysis_id' "analyses-$page_number.json")
        #analyses_last_occurrence_ids+=($(jq -r '._embedded.analyses[].latest_occurrence_id' "analyses-$page_number.json"))
        while IFS= read -r line; do
            analyses_last_occurrence_ids+=("$line")
        done < <(jq -r '._embedded.analyses[].latest_occurrence_id' "analyses-$page_number.json")
        #has_verification_failures+=($(jq -r '._embedded.analyses[].has_verification_failures' "analyses-$page_number.json"))
        while IFS= read -r line; do
            has_verification_failures+=("$line")
        done < <(jq -r '._embedded.analyses[].has_verification_failures' "analyses-$page_number.json")
        

    fi

    # Check if we have more pages to fetch
    if [[ $((page_number + 1)) -lt $total_pages ]] ;
    then
        page_number=$((page_number + 1))
    else
        break_condition=false
    fi 
done; # end while loop

echo "All pages fetched."

# now that all the results fetched itterate over the results
for name in "${analyses_names[@]}"; do
    if [ $silent == false ]; then
        if $verbose; then
            #echo "$count     : $name : ${analyses_status[$count]} : ${analyses_last_occurrence_date_time[$count]} : ${analyses_ids[$count]} : ${analyses_last_occurrence_ids[$count]}"
            echo "$count     : $name : ${analyses_status[$count]} : ${analyses_last_occurrence_date_time[$count]} : ${analyses_ids[$count]} : ${analyses_occurrence_ids[$count]} : ${verb_count_of_failed_verifications[$count]} : ${verb_count_of_failed_verifications[$count]} : ${verb_count_of_high_sev_flaws[$count]} : ${verb_count_of_low_sev_flaws[$count]} : ${verb_count_of_medium_sev_flaws[$count]} : ${verb_count_of_very_high_sev_flaws[$count]} : ${total_flaw_count[$count]} : ${verb_duration[$count]} : ${verb_expected_publish_date[$count]} : ${verb_internal_scan_configuration[$count]} : ${verb_scan_type[$count]} : ${verb_results_import_status[$count]} : ${verb_requests[$count]} : ${verb_responses[$count]} : ${verb_links_crawled[$count]} : ${verb_links_audited[$count]} : ${verb_network_errors[$count]} : ${verb_port_shutdowns[$count]} : ${verb_login_successes[$count]} : ${verb_login_failures[$count]} : ${verb_has_coverage_report[$count]} : ${verb_dropped_events[$count]}"
            
        else
            echo "$count     : $name : ${analyses_status[$count]} : ${analyses_last_occurrence_date_time[$count]} : ${analyses_ids[$count]} : ${analyses_last_occurrence_ids[$count]}"
        fi
    fi
    # http --auth-type veracode_hmac "https://api.veracode.com/was/configservice/v1/analysis_occurrences/${analyses_last_occurrence_ids[$count]}" -o "${analyses_last_occurrence_ids[$count]}-scan.json"
    if $verbose; then
        echo " $name : ${analyses_status[$count]} : ${analyses_last_occurrence_date_time[$count]} : ${analyses_ids[$count]} : ${analyses_occurrence_ids[$count]} : ${verb_count_of_failed_verifications[$count]} : ${verb_count_of_failed_verifications[$count]} : ${verb_count_of_high_sev_flaws[$count]} : ${verb_count_of_low_sev_flaws[$count]} : ${verb_count_of_medium_sev_flaws[$count]} : ${verb_count_of_very_high_sev_flaws[$count]} : ${verb_duration[$count]} : ${verb_expected_publish_date[$count]} : ${verb_internal_scan_configuration[$count]} : ${verb_scan_type[$count]} : ${verb_results_import_status[$count]} : ${verb_requests[$count]} : ${verb_responses[$count]} : ${verb_links_crawled[$count]} : ${verb_links_audited[$count]} : ${verb_network_errors[$count]} : ${verb_port_shutdowns[$count]} : ${verb_login_successes[$count]} : ${verb_login_failures[$count]} : ${verb_has_coverage_report[$count]} : ${verb_dropped_events[$count]}" >> analyses.csv
    else
        echo "$name , ${analyses_status[$count]} , ${analyses_last_occurrence_date_time[$count]} , ${analyses_ids[$count]} , ${analyses_last_occurrence_ids[$count]}" >> analyses.csv
        
    fi
    count=$((count+1))
done




echo ""
if [ $silent == false ]; then
    echo "Output written to $out_dir/analyses.csv"
fi
#cat analyses.csv
cd -

