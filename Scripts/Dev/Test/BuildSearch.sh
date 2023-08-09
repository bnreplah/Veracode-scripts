#!/bin/bash
# Use this script to search and see the buildlist scan names 
# The script can be modified to parse out the data from the buildinfo 
# PoC outputting details to output.json
#
#provide the location of the veracode java api location
VeracodeJavaWrapper=../../src/bin/VeracodeJavaAPI.jar
found=1
debug=1



if [ -z $1 ]; then
        echo "No parameter provided, please provide an app id and a scan name to search for, exiting"
        exit 0

fi

app_id=$1
searchname=$2
buildinfo=""
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
        echo "'scanname': '"$scanName"'," >> output.json
        echo "'buildid': '"$buildid"'," >> output.json
        echo "'launchdate': '"$launchdate"'," >> output.json
        echo "'policycompliancestatus': '"$policyComplianceStatus"'," >> output.json
        echo "'resultsready': "$resultsReady"," >> output.json
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

                build_id_found=$( echo ${buildLine[$count]} | cut -d '"' -f2 )
                found=0
        fi

        ((count++))
        if [ "$debug" -eq "0"  ]; then
                echo $count
        fi
done

if [ "$debug" -eq "0"  ]; then
        echo "[DEBUG] Build ID outside the Loop: $build_id_found"
fi

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
        
        if [ "$debug" -eq "0"  ]; then
                echo "[DEBUG] $buildinfo"
        fi
        
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
        echo "'scanname': '"$scanName"'," >> output.json
        echo "'buildid': '"$buildid"'," >> output.json
        echo "'launchdate': '"$launchdate"'," >> output.json
        echo "'policycompliancestatus': '"$policyComplianceStatus"'," >> output.json
        echo "'resultsready': "$resultsReady"," >> output.json
        echo "}" >> output.json
        exit 0
else
        echo "Build Match Not Found"
        exit 0
fi
#TODO: pull the build id and see if it passed policy and pull the last date