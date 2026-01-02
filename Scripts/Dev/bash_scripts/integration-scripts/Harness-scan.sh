#!bash

#####################################################################################
## HARNESS PIPELINE #################################################################
## How to use #######################################################################
#####################################################################################
## 1) Replacing the variables at the top with arguments, removing export, and saving# 
##      this as a .sh script would allow for it to run with script parameters       #
## 2) Otherwise, paste the script into harness or refer to it in your harness       #
##      pipelines and it will run a pipeline scan if PIPELINE_SCAN=0 is changed to 1#
#####################################################################################


######################################################################################
## Development Feature Flags  ########################################################
######################################################################################
export DEBUG=0               ## Set this to 1 to run more verbose output
export PIPELINE_SCAN=0       ## Set this to 1 to run a pipeline scan. Comment out this variable and export to the optional env variables in the Harness interface in order to control externally

#export UPLOAD_APP_LIST=("SNAP", "VERADEMO", "VERADEMO-js") ## Fixed app list, 
## otherwise will use the built in/ search_name to look for app profile in the 
## platform then if the matching app profiles are matching an element, then it runs 
## the pipeline scan otherwise this is set in a simple enviornment variable above, 
## PIPELINE_SCAN set PIPELINE_SCAN to 1 or Comment out PIPELINE_SCAN and create a 
## variable in the optional arguments in Harness, and then it can also be controlled
## from there that allows the switch to potentially be controlled externally if needed
######################################################################################
## Veracode Variables ################################################################
######################################################################################
# adding alias expansions if needed
shopt -s expand_aliases

alias 'veracode-http'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-signing:cmd'
#alias 'veracode-api'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-wrapper-java:cmd'
#alias 'veracode-http'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-signing:cmd'


export VERACODE_API_KEY_ID=<+secrets.getValue("VERACODE_API_ID")>
export VERACODE_API_KEY_SECRET=<+secrets.getValue("VERACODE_API_KEY")>
export SRCCLR_API_TOKEN=<+secrets.getValue("SRCCLR_API_TOKEN")>
export BUILD_DIR="app/"         # place this in a variable in harness

######################################################################################
## UploadAndScan Argument Parameters: https://docs.veracode.com/r/r_uploadandscan ####
######################################################################################
## Optionally these can also be controlled from the advanced settings within harness,

export sandboxname="sandbox-$DRONE_REPO_NAME-<+codebase.branch>-<+pipeline.name>"    ## Sandbox name to match the sandbox name in the platform
export appname="$DRONE_REPO_NAME"                                                    ## Corresponding name in the Veracode App Profile to be used
export scanname="<+codebase.branch>-<+codebase.commitRef>-<+pipeline.executionId>"   ## The Scan name for the upload and scan that is then submitted
export fileLocation="./target/veracode.zip"                                          ## change this to either match the location based on language or accordingly for each pipeline, depending on the language and root folder name
export folderLocation="/harness/target/"                                             ## The location used in the upload and scan, this allows for uploading of mulitple artifacts if needed in the same analysis
export uploadFolder="/harness/veracode_target"
export app_names=()                                                                  ## Dynamically pulled app list
export CREATE_PROFILE=false                                                          ## The Upload and Scan Constant whether App Profiles should be created a new when they don't match
export CREATE_SANDBOX=true                                                           ## The Upload and Scan Constant whether Sandboxes should be created if the name doesn't match
export scan_types="STATIC"
export violate_policy="True"
#export search_name="snap" ## the name of the app profile or convention to find in the app profile names, all that match will run a pipeline scan instead

## if the sandbox scan name is not set:
##   Sandbox Scanning Naming Modes:
##      - 0 <=> revert to pipeline scan <=> PIPELINE_SCAN=1
##      - 1 <=> use the other details to specify the sandbox and scan name <=> PIPELINE_SCAN=0
##          Default Behavior: => PIPELINE_SCAN=0
##

######################################################################
## Function Block ####################################################
######################################################################

## Unused, uncomment to make use of the SCA Agent as well
# ### Function: SCA
# ### passes any arguments to the SRCCLR agent so the SCA function can act as an alias
# SCA(){
#     #export SRCCLR_API_TOKEN=<+secrets.getValue("SRCCLR_API_TOKEN")>
#     pwd
#     cd app/
#     curl -sSL https://download.sourceclear.com/ci.sh | sh "$@" 
# }


make_http_call(){
    API_ID=$VERACODE_API_KEY_ID
    API_KEY=$VERACODE_API_KEY_SECRET
    # Todo change out the openssl library to use something
    NONCE="$(cat /dev/random | xxd -p | head -c 32)"

    TS="$(($(date +%s%N)/1000))"
    URLBASE="http://"
    METHOD=$1
    URLPATH=$2
    

    # Usage: $1: url/endpoint/path $2: method
    # ./API-http-REST.sh $API_API_ID $API_API_KEY GET /healthcheck

    encryptedNonce=$(echo "$NONCE" | xxd -r -p | openssl dgst -sha256 -mac HMAC -macopt hexkey:$API_KEY | cut -d ' ' -f 2)


    encryptedTimestamp=$(echo -n "$TS" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$encryptedNonce | cut -d ' ' -f 2)


    signingKey=$(echo -n "vcode_request_version_1" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$encryptedTimestamp | cut -d ' ' -f 2)


    DATA="id=$API_ID&host=api.veracode.com&url=$URLPATH&method=$METHOD"
    signature=$(echo -n "$DATA" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$signingKey | cut -d ' ' -f 2)
    API_AUTH_HEADER="VERACODE-HMAC-SHA-256 id=$API_ID,ts=$TS,nonce=$NONCE,sig=$signature"



   return $( curl -X $METHOD -H "Authorization: $API_AUTH_HEADER" "$URLBASE$URLPATH" )
}


### Function: downloadWrapper
### Pre:
### Post:
### Function to download the latest version of the Java API Wrapper to be used in the upload and scan
downloadWrapper(){
    echo 'Get Jar'
    echo "Downloading the latest version of the Veracode Java API Wrapper"
    echo " | Grabbing the Latest Version of the Wrapper from Maven" 
    WRAPPER_VERSION=`curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/maven-metadata.xml | grep latest |  cut -d '>' -f 2 | cut -d '<' -f 1`
    if `wget https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/$WRAPPER_VERSION/vosp-api-wrappers-java-$WRAPPER_VERSION.jar -O VeracodeJavaAPI.jar`; then
        chmod 777 VeracodeJavaAPI.jar
        mkdir -p /harness/api-wrapper/
        mv VeracodeJavaAPI.jar -t ./api-wrapper/
        echo " [INFO] Listing out the Current Directory"
        echo "[INFO] " $(ls -la)
        echo "[INFO] "$(ls -la ./api-wrapper/ )
        #java -jar /harness/api-wrapper/VeracodeJavaAPI.jar 2> /dev/null
        echo "[INFO] SUCCESSFULLY DOWNLOADED WRAPPER"
    else
        echo '[ERROR] DOWNLOAD FAILED'
        
    fi
} 

### Function: downloadPipelineScanner
### Pre:
### Post:
### Downloads the Pipeline Scanner Jar
downloadPipelineScanner(){
    echo "Downloading the latest version of the Veracode Pipeline Scanner"
    curl -o ./pipeline-scan-LATEST.zip https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip
    #curl -sSO https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip
    pwd    
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed retrieving latest Pipeline Scanner jar from Veracode."
    else
        echo "[INFO] Unzipping Jar file"
        unzip -o pipeline-scan-LATEST.zip -d ./pipeline-scan/
        #unzip -o pipeline-scan-LATEST.zip
    fi
    ls -la


}

### Function: downloadVeracodeCLI
### Pre:
### Post:
### Uncomment for the future for the case of packaging in the script if needed
### TODO: In the case you uncomment, change the location set in fileLocation to the artifact
downloadVeracodeCLI(){
    curl -fsS https://tools.veracode.com/veracode-cli/install | sh
}

### Function: get_app_list
### Pre: run the download wrapper in the case this is needed since it uses the wrapper to grab the app list
### post: a populated array with app profiles to be able to compare and see if matches criteria to run pipeline scan
get_app_list(){
    ## should grab it from the enviornment
    mapfile app_names < <( $( java -jar VeracodeAPI.jar -action getapplist -rest | jq -r '.[].profile.name' ) )
    ## verify the files have been pulled succesfully
    echo "App Profiles found: ${#app_names[@]}" # echos out the number of app profiles or the number in the array ( array len )
    for n in "${app_names[@]}"; do # prints out the array
        echo "- $n"
    done
    ## can add logic here to process and determine which to run the pipeline scans
    ## place a conditional block either inside or outside of this function to achieve those capabilities
    
    ## An example of how you can quickly query through the array to look for the mapping profile
    # ## Flag to track if found
    # found=false

    # for item in "${app_names[@]}"; do
    #     if [[ "$item" == *"$search_word"*]]; then
    #         #if [[  ]] ## this is where you can put the logic to then switch to pipeline scan if desired
    #         found=true
    #         echo "Found Matching App Profile"
    #         break ## breaks on the first found one, can change the variable to an array instead if needed
    #     fi
    # done


    # java -jar VeracodeAPI.jar -action getapplist -vid  -vkey

}




grab_results_platform(){
  
  ###################################################################################################################################
  ## Converting the results into a format that can then be taken in by Harness
  ###################################################################################################################################
  # Converting into both results.json, and sarif format 

  ## TODO: Add the conversion of the results.json from the api call or from the results.json from the pipeline scan into the SARIF and the format that is supported by harness 
  ##
  ##

    #   guid=$(http --auth-type veracode_hmac GET "https://api.veracode.com/appsec/v1/applications?name=${appname}" | jq -r '._embedded.applications[0].guid') 
    #   echo GUID: ${guid}
    #   total_flaws=$(http --auth-type veracode_hmac GET "https://api.veracode.com/appsec/v2/applications/${guid}/findings?scan_type=STATIC&violates_policy=True&context=" | jq -r '.page.total_elements') # todo make sure it fully adjusts page and content side add pagenating script 
    #   echo TOTAL_FLAWS: ${total_flaws}
    #   http --auth-type veracode_hmac GET "https://api.veracode.com/appsec/v2/applications/${guid}/findings?scan_type=STATIC&violates_policy=True&size=${total_flaws}" > policy_flaws.json

    # Policy_flaws or sandbox_flaws.json to the proper format

  #############################################################################################################################
  # This conversion should be done in it's own step to be launched in a custom docker image with httpie isntalled

  output_file=flaws_all.json

  # grabs the first in the list matching the application profile name
  guid=$(make_http_call GET "api.veracode.com/appsec/v1/applications?name=${appname}" | jq -r '._embedded.applications[0].guid') 
  echo GUID: ${guid}


  # TODO: Look for sandboxes here


  # TODO: Add Sandbox context here

  total_pages=$(make_http_call GET "api.veracode.com/appsec/v2/applications/${guid}/findings?scan_type=STATIC&violates_policy=True" | tee flaws_p0.json | jq -r '.page.total_pages')
  echo Pages: ${total_pages}

  if [ ${total_pages} == 1 ]
  then
    mv flaws_p0.json ${output_file}
  else
    echo Already have flaws, page 0

    # get the rest of the pages and merge flaws
    for (( page=1; page<${total_pages}; page++ ))
    do
      echo Getting flaws, page ${page}
      make_http_call GET "api.veracode.com/appsec/v2/applications/${guid}/findings?scan_type=${scan_types}&violates_policy=${violate_policy}&page=${page}" > flaws_tmp.json
      
      echo Merging flaws, page `expr ${page} - 1` into page ${page}
      jq -s '.[0] as $f1 | .[1] as $f2 | ($f1 + $f2) | ._embedded.findings = ($f1._embedded.findings + $f2._embedded.findings)' flaws_p`expr ${page} - 1`.json flaws_tmp.json > flaws_p${page}.json
    done
    
    # rename final output file
    mv flaws_p`expr ${page} - 1`.json ${output_file}
  fi

  echo Done.  All flaws are in ${output_file}

  # Ensure jq is installed
  if ! command -v jq &> /dev/null; then
      echo "jq is required but not installed. Please install jq and rerun the script."
      exit 1
  fi

  echo "Produced ${output_file}"

}

grab_results_sandbox(){

  
  ###################################################################################################################################
  ## Converting the results into a format that can then be taken in by Harness
  ###################################################################################################################################
  # Converting into both results.json, and sarif format 

  ## TODO: Add the conversion of the results.json from the api call or from the results.json from the pipeline scan into the SARIF and the format that is supported by harness 
  ##
  ##

    #   guid=$(http --auth-type veracode_hmac GET "https://api.veracode.com/appsec/v1/applications?name=${appname}" | jq -r '._embedded.applications[0].guid') 
    #   echo GUID: ${guid}
    #   total_flaws=$(http --auth-type veracode_hmac GET "https://api.veracode.com/appsec/v2/applications/${guid}/findings?scan_type=STATIC&violates_policy=True&context=" | jq -r '.page.total_elements') # todo make sure it fully adjusts page and content side add pagenating script 
    #   echo TOTAL_FLAWS: ${total_flaws}
    #   http --auth-type veracode_hmac GET "https://api.veracode.com/appsec/v2/applications/${guid}/findings?scan_type=STATIC&violates_policy=True&size=${total_flaws}" > policy_flaws.json

    # Policy_flaws or sandbox_flaws.json to the proper format

  #############################################################################################################################
  # This conversion should be done in it's own step to be launched in a custom docker image with httpie isntalled

  output_file=flaws_all.json

  # grabs the first in the list matching the application profile name
  guid=$(make_http_call GET "api.veracode.com/appsec/v1/applications?name=${appname}" | jq -r '._embedded.applications[0].guid') 
  echo GUID: ${guid}


  # TODO: Look for sandboxes here


  # TODO: Add Sandbox context here
  sandbox_guid=$(make_http_call GET "api.veracode.com/appsec/v1/applications/${guid}/sandboxes?name=${sandboxname}" | jq -r '._embedded.applications[0].guid')
  echo "Sandbox GUIDL=: ${sandbox_guid}"

  total_pages=$(make_http_call GET "api.veracode.com/appsec/v2/applications/${guid}/findings?scan_type=STATIC&context=${sandbox_guid}" | tee flaws_p0.json | jq -r '.page.total_pages')
  echo Pages: ${total_pages}

  if [ ${total_pages} == 1 ]
  then
    mv flaws_p0.json ${output_file}
  else
    echo Already have flaws, page 0

    # get the rest of the pages and merge flaws
    for (( page=1; page<${total_pages}; page++ ))
    do
      echo Getting flaws, page ${page}
      make_http_call GET "api.veracode.com/appsec/v2/applications/${guid}/findings?context=${sandbox_guid}&scan_type=${scan_types}&violates_policy=${violate_policy}&page=${page}" > flaws_tmp.json
      
      echo Merging flaws, page `expr ${page} - 1` into page ${page}
      jq -s '.[0] as $f1 | .[1] as $f2 | ($f1 + $f2) | ._embedded.findings = ($f1._embedded.findings + $f2._embedded.findings)' flaws_p`expr ${page} - 1`.json flaws_tmp.json > flaws_p${page}.json
    done
    
    # rename final output file
    mv flaws_p`expr ${page} - 1`.json ${output_file}
  fi

  echo Done.  All flaws are in ${output_file}

  
  # Ensure jq is installed
  if ! command -v jq &> /dev/null; then
      echo "jq is required but not installed. Please install jq and rerun the script."
      exit 1
  fi

  return "${output_file}"


}


convert_results_to_json(){

  INPUT_FILE="$1"


  jq '{
    scan_id: "generated-scan-id",
    scan_status: "SUCCESS",
    message: ("Processed " + (._embedded.findings | length | tostring) + " findings"),
    modules: (._embedded.findings | map(.finding_details.module) | unique),
    modules_count: (._embedded.findings | map(.finding_details.module) | unique | length),
    findings: (._embedded.findings | map({
      title: .finding_details.attack_vector,
      issue_id: .issue_id,
      severity: .finding_de{tails.severity,
      cwe_id: .finding_details.cwe.id,
      cwe_name: .finding_details.cwe.name,
      cwe_href: .finding_details.cwe.href,
      file_path: .finding_details.file_path,
      file_name: .finding_details.file_name,
      module: .finding_details.module,
      relative_location: .finding_details.relative_location,
      finding_category_name: .finding_details.finding_category.name,
      finding_category_href: .finding_details.finding_category.href,
      procedure: .finding_details.procedure,
      exploitability: .finding_details.exploitability,
      attack_vector: .finding_details.attack_vector,
      file_line_number: .finding_details.file_line_number,
      description: .description,
      status: .finding_status.status,
      resolution: .finding_status.resolution,
      resolution_status: .finding_status.resolution_status,
      mitigation_review_status: .finding_status.mitigation_review_status,
      first_found_date: .finding_status.first_found_date,
      last_seen_date: .finding_status.last_seen_date,
      violates_policy: .violates_policy,
      build_id: .build_id
    }))
  }' "$INPUT_FILE" > "results.json"

cat results.json


}

convert_results_to_sarif(){
  
  INPUT_FILE="$1"

  jq '{
    version: "2.1.0",
    "$schema": "https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0.json",
    runs: [
      {
        tool: {
          driver: {
            name: "Veracode Static Analysis",
            informationUri: "https://www.veracode.com",
            rules: (
              ._embedded.findings
              | map({
                  id: (.finding_details.cwe.id | tostring),
                  name: .finding_details.cwe.name,
                  helpUri: .finding_details.cwe.href,
                  properties: {
                    tags: [ .finding_details.finding_category.name ]
                  }
                })
              | unique
            )
          }
        },
        results: (
          ._embedded.findings
          | map({
              ruleId: (.finding_details.cwe.id | tostring),
              message: { text: .description },
              level: (if .finding_details.severity >= 4 then "error"
                      elif .finding_details.severity == 3 then "warning"
                      else "note" end),
              locations: [
                {
                  physicalLocation: {
                    artifactLocation: { uri: .finding_details.file_path },
                    region: { startLine: .finding_details.file_line_number }
                  }
                }
              ]
            })
        )
      }
    ]
  }' "$INPUT_FILE" > "results.sarif.json"

  cat results.sarif.json

}




######################################################################
## Main Execution Block ##############################################
######################################################################
## Testing out the repo name display to conrol when or not to run the pipeline scan
echo $DRONE_REPO_NAME
## Optionally, you can also easily switch to a pipeline scan when needed by changing the PIPELINE_SCAN variable to 1
## Logic for check whether to run the pipeline scan can go here

# for item in "${app_names[@]}"; do
#         if [[ "$item" == *"$search_word"*]]; then
#             #if [[  ]] ## this is where you can put the logic to then switch to pipeline scan if desired
#             found=true
#             echo "Found Matching App Profile"
#             break ## breaks on the first found one, can change the variable to an array instead if needed
#         fi
#     done





## Downloads the Java API Wrapper and the pipeline scan
downloadWrapper
downloadPipelineScanner                                 ## This version of the pipeline scanner is the jar file, we have a Go Variation inside the Veracode CLI
downloadVeracodeCLI                                    ## The veracode CLI contains the pipeline scanner as well
./veracode help
## Makes a directory in the path of the Harness/Target directory
mkdir -p "$folderLocation"
## Copies the zipped artifact into the veracode.zip in the target
## Note: ( In the case of a Java project a Jar, War, or Ear would be required )
## Documentation for compilation: https://docs.veracode.com/r/compilation_packaging

## Veracode auto-packaging command to be able to package the app folder, and then place it in the scanning location
## if this is used, then need to change fileLocation to match to the corresponding name: https://docs.veracode.com/r/About_auto_packaging
ls
./veracode package -s "$BUILD_DIR" -o "$folderLocation" -a -v
#cp ./app.zip "$fileLocation"

## echos out the file size
#echo $( stat --format=%s $fileLocation )

######################################################################
## Conditional Block #################################################
######################################################################
## PIPELINE_SCAN 
##   false <==> 0
##   True  <==> 1


if [[ !($PIPELINE_SCAN -eq 1) ]]; then # if pipeline scan is set to 0 proceed to try to scan in sandbox  ( Pipeline_scan !== 1) .: (Sandbox == 1)
    if [[ $DEBUG -eq 1 ]]; then echo "[DEBUG]: On \n[PIPELINE SCAN]: " + "$PIPELINE_SCAN" ; fi #ENDIF # if debug is on ( Debug = True)
    
    
    ################################################################################################################################################
    ## if using the Harness variables mapped at the top this part can be commented out or disabled #################################################
    ################################################################################################################################################
    ## This will .: be skipped in that particular case

    if [[ "$sandboxname" == "" ]] ; then ## if the sandboxname is blank => revert to run the pipeline scanner 
        #|| [[ $( echo "$DRONE_REPO_NAME" ) == "$search_name"]] ## this can be added above to cause it to run this step if the repo == snap or any 
        if [[ $DEBUG -eq 1 ]]; then echo "[DEBUG]: WARNING!! No Sandboxname was set. Reverting to using the pipeline scanner " + "$PIPELINE_SCAN" ; fi    
        
        ## Any additional pipeline areguments can be added such as the ones below
        #java -jar pipeline-scan.jar --file $fileLocation  # The API ID and Key should all be picked up in the enviornment
        #java -jar pipeline-scan.jar --file $fileLocation -vid <+secrets.getValue("VERACODE_API_ID")> -vkey <+secrets.getValue("VERACODE_API_KEY")>
        echo "Running scan for <+pipeline.name>"
        java -jar ./pipeline-scan/pipeline-scan.jar \
                --veracode_api_id '<+secrets.getValue("account.veracode_api_id")>' \
                --veracode_api_key '<+secrets.getValue("account.veracode_api_key")>' \
                --file $fileLocation \
                --fail_on_severity="Very High, High" \
                --summary_display true \
                --summary_output true \
                --json_output true \
                --json_output_file "results.json" \
                --filtered_json_output_file "filtered_results.json" \
                --issue_details true \
                --timeout 60 \
                --project_name "<+pipeline.name>"
      
    else ## Sandbox Scan Running here
        if [[ $DEBUG -eq 1 ]]; then echo "[DEBUG]: On \n[PIPELINE SCAN]: " + "$PIPELINE_SCAN" ; fi
        echo skipping for testing
        #java -jar ./api-wrapper/VeracodeJavaAPI.jar -action uploadandscan -filepath "$folderLocation" -appname "$appname" -createprofile $CREATE_PROFILE -createsandbox $CREATE_SANDBOX -sandboxname "$sandboxname" -version "$scanname" -deleteincompletescan 1 #-scanpollinginterval 120 ## This allows you to run an asynchronous scan, otherwise will proceed not waiting on the results
        ## use the following command later to check whether the app profile passed or failed ( policy or would fail policy ) ( works both for policy and sandbox )
        # java -jar ./api-wrapper/VeracodeJavaAPI.jar -action passfail -appname $appname -sandboxname $sandboxname
        # java -jar ./api-wrapper/VeracodeJavaAPI.jar -action SummaryReport -appname $appname -sandboxname $sandboxname ## in order to get a summary report
        java -jar ./api-wrapper/VeracodeJavaAPI.jar -vid <+secrets.getValue("VERACODE_API_ID")> -vkey <+secrets.getValue("VERACODE_API_KEY")> -action uploadandscan -appname $appname -createprofile $CREATE_PROFILE -sandboxname $sandboxname -createsandbox $CREATE_SANDBOX -version $scanname -filepath $folderLocation -deleteincompletescan 1 -scanallnonfataltoplevelmodules true 
    fi ## ENDIFELSE

else # If the pipeline scan is set to 1
    #if [[ "$sandboxname" == "" ]]; then # this should be the condition to trigger the pipeline scan
        if [[ $DEBUG -eq 1 ]]; then echo "[DEBUG]: Using the pipeline scanner " + "$PIPELINE_SCAN" ; fi    
        
        #java -jar pipeline-scan.jar --file $fileLocation
        echo "Running scan for <+pipeline.name>"
        java -jar ./pipeline-scan/pipeline-scan.jar \
                --veracode_api_id '<+secrets.getValue("account.veracode_api_id")>' \
                --veracode_api_key '<+secrets.getValue("account.veracode_api_key")>' \
                --file "$fileLocation" \
                --fail_on_severity="Very High, High" \
                --summary_display true \
                --summary_output true \
                --json_output true \
                --json_output_file "results.json" \
                --filtered_json_output_file "filtered_results.json" \
                --issue_details true \
                --timeout 60 \
                --project_name "<+pipeline.name>"
        ## ? If harness STO is taking in the results.json file, are they taking it in a SARIF or are they importing it as it
        ## and does the Harness STO support taking in the detailedxml export or summary report as well, from the Upload
                

fi #ENDIFELSE

# grabs the results either from the platform to grab the results
#grab_results_platform
if [$PIPELINE_SCAN -eq 0]; then
  outputf=$(grab_results_sandbox)
  convert_results_to_json $outputf
  convert_results_to_sarif $outputf
fi

echo "results.json, results.sarif.json have been produced from $outputf"