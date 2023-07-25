# Based on previous code from Dgilmore
# Based on previous code writen by Unregistered436 - https://github.com/unregistered436/veracode-integrations/blob/master/shell-script/veracode-scan.sh
#Define AppName to pull build ID
# Takes appname from argument list
# Takes build name from argument list
# Requires Veracode Credentials file to operate, otherwise reconfigure API Wrapper command

#vid=""
#vkey=""
appname="$1"
buildname="$2"

#PRESCAN_SLEEP_TIME=60
SCAN_SLEEP_TIME=120

echo "Downloading the latest version of the Veracode Java API Wrapper"
WRAPPER_VERSION=`curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/maven-metadata.xml | grep latest |  cut -d '>' -f 2 | cut -d '<' -f 1`

echo '[INFO] ------------------------------------------------------------------------'
echo '[INFO] DOWNLOADING VERACODE JAVA WRAPPER'

if `wget https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/$WRAPPER_VERSION/vosp-api-wrappers-java-$WRAPPER_VERSION.jar -O VeracodeJavaAPI.jar`; then
      chmod 755 VeracodeJavaAPI.jar
      echo '[INFO] SUCCESSFULLY DOWNLOADED WRAPPER'
else
      echo '[ERROR] DOWNLOAD FAILED'
      exit 1
fi

#app_ID=$( java -verbose -jar VeracodeJavaAPI.jar -action GetAppList | grep -w "$appname" | sed -n 's/.* app_id=\"\([0-9]*\)\" .*/\1/p' )
app_ID=$(  java -verbose -jar VeracodeJavaAPI.jar -action GetAppList | grep $appname | sed -n 's/.* app_id=\"\([0-9]*\)\" .*/\1/p' | sed '2 d' )
build_ID=$( java -verbose -jar VeracodeJavaAPI.jar -appid $app_ID -action GetBuildList | grep "<build " | grep $buildname | cut -d '"' -f2 )
#build_ID=$( java -verbose -jar VeracodeJavaAPI.jar -appid $app_ID -action GetBuildList | grep -w "$buildname" | sed -n 's/.* build_id=\"\([0-9]*\)\" .*/\1/p' )
#policy_updated_date=$( java -verbose -jar VeracodeJavaAPI.jar -appid $app_ID -action GetBuildList | grep -w "$buildname" | sed -n 's/.* policy_updated_date=\"\([0-9]*\)\" .*/\1/p' )

echo "[INFO] Build-ID: $build_ID"
#echo "$policy_updated_date"


if [ -z "$app_ID" ];
then
      echo '[INFO] The Application Profile does not exist.'
      echo '[INFO] Please create the applicattion profile before running the Prescan-Check script.'
else
      echo "[INFO] App-ID:  $app_ID"
      echo ""
fi

# #Check scan status
# echo ""
# echo "[INFO] checking scan status"
# while true;
# do
#     java -jar ./VeracodeJavaAPI.jar -vid $vid -vkey $vkey -action getbuildinfo -appid $app_ID | tee appstatus.txt 2>&1
#     scan_status=$(cat appstatus.txt)
#     if [[ $scan_status = *"Scan In Process"* ]];
#     then
#             echo ""
#             echo '[INFO] A scan is in process, please wait for the previous scan to complete before submitting another job.'
#             sleep $SCAN_SLEEP_TIME
#     elif [[ $scan_status = *"Submitted to Engine"* ]];
#     then
#             echo ""
#             echo '[INFO] A scan has been already been submitted to the engine, please wait for the previous scan to complete before submitting another job.'
#     elif [[ $scan_status = *"Pre-Scan Submitted"* ]];
#     then
#             echo ""
#             echo '[INFO] A pre-scan is still running from a previous job, please wait for the previous scan to complete.'
#     elif [[ $scan_status = *"Pre-Scan Success"* ]];
#     then
#         java -jar ./VeracodeJavaAPI.jar -vid $vid -vkey $vkey -action GetPreScanResults -appid $app_ID > prescanerror.txt
#         echo ""
#         echo '[ERROR] Something went wrong with the prescan!'
#         cat prescanerror.txt
#         #Uncomment line below to remove deleting the prescanerror.txt to clean up 
#         #rm -rf prescanerror.txt
#         echo 'Double-Check the errors printed above in the prescan file.'
#         exit 1 && break
#     elif [[ $scan_status = *"Incomplete"* ]];
#     then
#     echo "[INFO] The results from the previous scan are incomplete."     
#     echo "[INFO] The scan is missing required information which includes uploading files, selecting modules or information for vendor acceptance of 3rd party scan requests."
#     echo "[INFO] Check https://docs.veracode.com/r/Troubleshooting_Veracode_APIs_and_Wrappers for more information."
#     #Uncomment the lines below to delete the scan from the platform
#     #echo "[INFO] The previous policy scan attempt will now be deleted."
#     #java -jar ./VeracodeJavaAPI.jar -vid $vid -vkey $vkey -action deletebuild -appid $app_ID | tee incompletebuild.txt
#     #deleteStatus=$(cat ./incompletebuild.txt)
#     #if [[ $deleteStatus = *"success"* ]];
#     #then
#         #echo "[INFO] The attempt to delete the last build for this application: success"
#     exit 1 && break
#     #else 
#     #echo "[ERROR] The attempt to delete the last build for this application: failed"
#     #fi
#     else
#         scan_finished=$(cat appstatus.txt)
#         if [[ $scan_finished = *"Results Ready"* ]];
#         then
#            echo ""
#            echo '[INFO] scan has finished'
#            rm -rf appstatus.txt
#            #sleep $SCAN_SLEEP_TIME
#            break;
#         fi
#     fi
