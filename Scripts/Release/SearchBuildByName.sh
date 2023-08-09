#!/bin/bash
# Author: Ben Halpern | Veracode
# Version: v.0.0.1
# Pass the app id that you want to search in, and the build name you want to find. If one is not provided then it will provide the details around the latest scan.
# If the build name is not found and one is provided, will return with Build match not found and the exit code 1

#provide the location of the veracode java api location
VeracodeJavaWrapper=../src/bin/VeracodeJavaAPI.jar


found=1
debug=1
app_id=$1
searchname=$2
buildinfo=""

if [ -z $1 ]; then
        echo "No parameter provided, please provide an app id and a scan name to search for, exiting"
        exit 0

fi

if [[ -z $searchname ]]; then

        echo "No Build name provided to search for, pulling latest build"
        buildinfo=$( java -jar $VeracodeJavaWrapper -action getbuildinfo -appid $app_id | grep "<build " )
        buildid=$( echo $buildinfo | cut -d '"' -f2 )
        launchdate=$( echo $buildinfo  | cut -d '"' -f6 )
        policyComplianceStatus=$( echo $buildinfo | cut -d '"' -f14 )
        resultsReady=$( echo $buildinfo | cut -d '"' -f22 )
        scanName=$( echo $buildinfo | cut -d '"' -f32 )

        echo "Scan Name:" $scanName
        echo "BuildID: " $buildid
        echo "Launch Date: " $launchdate
        echo "Policy Compliance Status: " $policyComplianceStatus
        echo "Results Ready: "$resultsReady

        echo "{" > output.json
        echo "'scan_name': '"$scanName"'," >> output.json
        echo "'build_id': '"$buildid"'," >> output.json
        echo "'launch_date': '"$launchdate"'," >> output.json
        echo "'policy_compliance_status': '"$policyComplianceStatus"'," >> output.json
        echo "'results_ready': "$resultsReady"," >> output.json
        echo "}" >> output.json
fi

#searchname=$2
#app_id=$1
buildlist=$( java -jar $VeracodeJavaWrapper -action getbuildlist -appid $app_id | grep '<build ' )

#echo $buildlist



readarray -t buildnames < <( java -jar $VeracodeJavaWrapper -action getbuildlist -appid $app_id | grep version | sed '1 d' | grep "version=" | grep -v dynamic_scan_type | cut -d '"' -f6 )
readarray -t buildLine < <( java -jar $VeracodeJavaWrapper -action getbuildlist -appid $app_id | grep build_id | sed '1 d' | grep "version=" | grep -v dynamic_scan_type  )




build_id_found=""
count=0

if [ "$debug" -eq "0"  ]; then 
        echo "[DEBUG] Starting loop"
fi

for i in ${!buildnames[@]};
do
        buildName=$( echo ${buildLine[$count]} | cut -d '"' -f6 )
        #option 1

        if [[ $buildName == $searchname ]]; then
                echo "Build Name: $( echo ${buildLine[$count]} | cut -d '"' -f6 )"
                echo "Build ID: $( echo ${buildLine[$count]} | cut -d '"' -f2 )"
                
                ############################## DEBUG block ###################################
                if [ "$debug" -eq "0"  ]; then
                        echo "[DEBUG] Count: $i : $count"
                fi
                ###############################################################################

                build_id_found=$( echo ${buildLine[$count]} | cut -d '"' -f2 )
                found=0
        fi

        ((count++))
        if [ "$debug" -eq "0"  ]; then
                echo $count
        fi
done

############################## DEBUG block ###################################
if [ "$debug" -eq "0"  ]; then
        echo "[DEBUG] Build ID outside the Loop: $build_id_found"
fi
###############################################################################

if [ "$found" -eq "0" ]; then
        echo "Build Match Found!"
        echo "$build_id_found"

        buildinfo=$( java -jar $VeracodeJavaWrapper -action getbuildinfo -appid $app_id -buildid $build_id_found | grep "<build " )
        buildid=$( echo $buildinfo | cut -d '"' -f2 )
        graceperiodexpired=$( echo $buildinfo | cut -d '"' -f4 )
        lifecyclestage=$( echo $buildinfo | cut -d '"' -f10 )
        policyname=$( echo $buildinfo | cut -d '"' -f16 )
        submitter=$( echo $buildinfo | cut -d '"' -f30 )
        scanoverdue=$( echo $buildinfo | cut -d '"' -f28 )
        scaresultsready=$( echo $buildinfo | cut -d '"' -f26 )
        rulesstatus=$( echo $buildinfo | cut -d '"' -f24 )
        launchdate=$( echo $buildinfo  | cut -d '"' -f6 )
        policyComplianceStatus=$( echo $buildinfo | cut -d '"' -f14 )
        resultsReady=$( echo $buildinfo | cut -d '"' -f22 )
        scanName=$( echo $buildinfo | cut -d '"' -f32 )

        ############################## DEBUG block ###################################
        if [ "$debug" -eq "0"  ]; then
                echo "[DEBUG] $buildinfo"
        fi
        ###############################################################################

        echo "Scan Name:" $scanName
        echo "Submitter:" $submitter
        echo "BuildID: " $buildid
        #echo "Launch Date: " $launchdate
        echo "Policy Name:" $policyname
        echo "Policy Compliance Status: " $policyComplianceStatus
        echo "Results Ready: "$resultsReady
        echo "SCA Results Ready:" $scaresultsready
        echo "Rules Status:" $rulesstatus
        echo "Grace Period Expires:" $graceperiodexpired
        echo "Lifecycle Stage:" $lifecyclestage

        echo "{" > output.json
        echo "'scan_name': '"$scanName"'," >> output.json
        echo "'build_id': '"$buildid"'," >> output.json
        echo "'launch_date': '"$launchdate"'," >> output.json
        echo "'policy_compliance_status': '"$policyComplianceStatus"'," >> output.json
        echo "'results_ready': "$resultsReady"," >> output.json
        echo "}" >> output.json
        
        exit 0
else
        echo "Build Match Not Found"
        exit 1
fi
