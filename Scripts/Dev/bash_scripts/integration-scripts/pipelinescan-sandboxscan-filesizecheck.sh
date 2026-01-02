#!/bin/bash

echo "Downloading the latest version of the Veracode Java API Wrapper"
WRAPPER_VERSION=`curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/maven-metadata.xml | grep latest |  cut -d '>' -f 2 | cut -d '<' -f 1`
if `wget https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/$WRAPPER_VERSION/vosp-api-wrappers-java-$WRAPPER_VERSION.jar -O VeracodeJavaAPI.jar`; then
      chmod 755 VeracodeJavaAPI.jar
      echo '[INFO] SUCCESSFULLY DOWNLOADED WRAPPER'
else
      echo '[ERROR] DOWNLOAD FAILED'
      exit 1
fi

echo "Downloading the latest version of the Veracode Pipeline Scanner"
curl https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip --output pipeline-scan-LATEST.zip --silent
unzip pipeline-scan-LATEST.zip pipeline-scan.jar

#echo "file to scan:"
#read fileLocation
fileLocation="$1"
appname="$2"
scanname="$3"
if [[ -z "$fileLocation" ]];then
    echo "No File has been passed"
    exit 1
fi
echo $(stat --format=%s $fileLocation)

if [[ $(stat --format=%s $fileLocation) -le 20000 ]]; then
    java -jar pipeline-scan.jar --file $fileLocation
else
    java -jar VeracodeAPI.jar -action uploadandscan -filepath $fileLocation -appname $appname -createprofile false -version $scanname -deleteincompletescan 1
fi