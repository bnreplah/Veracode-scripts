#!/bin/bash

#provide the location of the veracode java api location
VeracodeJavaWrapper=VeracodeJavaAPI.jar
found=1

if [ -z $1 ]; then
        echo "No parameter provided, exiting"
        exit 0

fi

app_id=$1
searchname=$2

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

fi

#searchname=$2
#app_id=$1
buildlist=$( java -jar $VeracodeJavaWrapper -action getbuildlist -appid $app_id | grep '<build ' )

#echo $buildlist



readarray -d '' -t buildnames < <( java -jar $VeracodeJavaWrapper -action getbuildlist -appid $app_id | grep version | sed '1 d' | grep "version=" | grep -v dynamic_scan_type | cut -d '"' -f6 )




for name in ${buildnames[@]};
do
        if [[ $searchname == $name ]]; then
                #echo "Found"
                #echo $2 ":" $name
                found=0
        #else
                #echo $2 ":" $name
                #echo "Not Found"
        fi
done
if [ "$found" -eq "0" ]; then
        echo "Build Match Found!"
        exit 0
else
        echo "Build Match Not Found"
        exit 0
fi