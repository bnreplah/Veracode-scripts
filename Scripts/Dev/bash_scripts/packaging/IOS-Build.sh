#!/bin/bash
#  Author: Ben Halpern
#  Veracode
#  IOS Build Script Snippet
# Use this snippet inside a pipeline, integrate into a function, or utilize the snippets as needed
#::SCN001
##################################################################################
# Script Configuration Switches
##################################################################################
# DEBUG : true -> Uses Hardcoded Test Values

DEBUG=true
if [ "$DEBUG" == "true" ]; then
  echo "----------------------------------------------------------------------------"
  echo " Debug is turned on : $DEBUG"
  echo "----------------------------------------------------------------------------"
fi

###################################################################################
# XCODE Settings Variables
##################################################################################
# Put the location of Your Signing Identity to sign the code with
# This is needed for archiving the application. If you already have an archive file produced then this step is not needed and can be commented out.
# IF the code signing identity is already loaded from MS APP center you may be able to pass an enviornmental variable to call it
# https://learn.microsoft.com/en-us/appcenter/build/custom/variables/#pre-defined-variables

CODE_SIGN_IDENTITY_V="" 
CODE_SIGNING_REQUIRED_V=NO 
CODE_SIGNING_ALLOWED_V=NO
#AD_HOC_CODE_SIGNING_ALLOWED=YES
PROVISIONING_PROFILE=""
DEBUG_INFORMATION_FORMAT=dwarf-with-dsym
ENABLE_BITCODE=NO

# #::SCN002
# # Inspired by and utilized code written by gilmore867
# # https://github.com/gilmore867/VeracodePrescanCheck
# #################################################################################
# # Downloading Latest Version of the Wrapper 
# #################################################################################

# # Veracode's API Wrapper
# # Documentation:
# #   https://docs.veracode.com/r/c_about_wrappers
# #     
# # Description:
# #  Makes a curl request to pull down the latest wrapper version information and then uses that to pull down the latest version of the Veracode API Wrapper.

# WRAPPER_VERSION=`curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/maven-metadata.xml | grep latest |  cut -d '>' -f 2 | cut -d '<' -f 1`
# if `wget https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/$WRAPPER_VERSION/vosp-api-wrappers-java-$WRAPPER_VERSION.jar -O VeracodeJavaAPI.jar`; then
#                 chmod 755 VeracodeJavaAPI.jar
#                 echo '[INFO] SUCCESSFULLY DOWNLOADED WRAPPER'
#   else
#                 echo '[ERROR] DOWNLOAD FAILED'
#                 exit 1
# fi

#::SCN003
#################################################################################
# Local Script Variables
# Edit these to match your application
#################################################################################
# Set this manually or configure the appName to be utilized 
#Default
# Change this to your appname
appName="iGoat-Swift"

#projectWorkspaceLocation=$APPCENTER_XCODE_PROJECT
projectLocation="$appName.xcodeproj"
#schemeName=$APPCENTER_XCODE_SCHEME	
schemeName="$appName-Veracode"

#::SCN004
# https://docs.veracode.com/r/r_uploadandscan
###############################################################################
# Parameters for Veracode Upload and Scan
###############################################################################

#APPLICATIONNAME="$appName"       # Comment out to use enviornmental variable from within MS APP CENTER
#DELETEINCOMPLETE=2                # Default is [(0): don't delete a scan ,(1): delete any scan that is not in progress and doesn't have results ready,(2): delete any scan that doesn't have results ready]  
#SANDBOXNAME="MSAPPCENTER"         # If null then will skip
#CREATESANDBOX=true
#CREATEPROFILE=false
#OPTARGS=''

# echo "========================================================================================================================================================================"
# echo "Moving to build location"
# echo "========================================================================================================================================================================"

echo "Current Working Directory"
#cd iGoat-Swift 
pwd
#cd $appName
#ls -la

#::SCN005
echo "========================================================================================================================================================================"
echo "Clean build"
echo "========================================================================================================================================================================"

xcodebuild clean

#::SCN006
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "========================================================================================================================================================================"
echo "Install Gen-IR and Generate Dependencies"
echo "========================================================================================================================================================================"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
brew tap veracode/tap
brew install gen-ir

#::SCN007
# This section is specific to the example which the file is contained
# Make sure to change this to specifically point to the package managers in which your application utilizes

ls 

# TODO: Add Hueristic check to see which build files are located
#make dependencies
#bundle install
pod install

#::SCN008
if [ "$DEBUG" == "true" ]; then
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "========================================================================================================================================================================"
  echo "Reading out the configuration structure"
  echo "========================================================================================================================================================================"
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

  xcodebuild -list 
  xcodebuild -project "$appName.xcodeproj" -list
  xcodebuild -workspace "$appName.xcworkspace" -list

fi

#cd iGoat-Swift
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#::SCN010
# Creating XCODE Project Archive to be place within
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "========================================================================================================================================================================"
echo " Creating Archive"
echo "========================================================================================================================================================================"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
# Debug
if [ "$DEBUG" == "true" ]; then
      echo "[DEBUG]:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
      
      xcodebuild archive -workspace $appName.xcworkspace -configuration Debug -scheme $schemeName -destination generic/platform=iOS DEBUG_INFORMATION_FORMAT=dwarf-with-dsym -archivePath $appName.xcarchive CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO ENABLE_BITCODE=NO AD_HOC_CODE_SIGNING_ALLOWED=YES >> build_log.txt
      echo "[DEBUG]:========================================================================================================================================================================"
      echo "[DEBUG]:Output from Build_log.txt #############################################################################################################################################"
      echo "[DEBUG]:========================================================================================================================================================================"
      cat build_log.txt

elif [ "$DEBUG" == "false" ]; then
    xcodebuild archive -project $appName.xcodeproj -scheme $APPCENTER_XCODE_SCHEME -configuration Debug -destination generic/platform=iOS -archivePath $appName.xcarchive DEBUG_INFORMATION_FORMAT=dwarf-with-dsym CODE_SIGN_IDENTITY=$CODE_SIGN_IDENTITY_V CODE_SIGNING_REQUIRED=$CODE_SIGNING_REQUIRED_V CODE_SIGNING_ALLOWED=$CODE_SIGNING_ALLOWED_V ENABLE_BITCODE=NO >> build_log.txt
    cat build_log.txt
else
  # debug is neither true or false
  echo "[Error] There was an issue with the script"

fi

#::SCN011
################################################################################################################################################################################
######################################################### Veracode SCA AGENT BASED SCAN ######################################################################################## 
################################################################################################################################################################################
#if including the SRCCLR_API_TOKEN as an enviornmental variable to be able to conduct Veracode SCA Agent-based scan
# comment out the next line if the token is set in appcenter
# SRCCLR_API_TOKEN=$SRCCLR_API_TOKEN

#if [ -n $SRCCLR_API_TOKEN ]; then
#  
#  echo "========================================================================================================================================================================"
#  echo "RUNNING VERACODE SCA AGENT-BASED SCAN  #################################################################################################################################"
#  echo "========================================================================================================================================================================"
#
#  curl -sSL https://download.sourceclear.com/ci.sh | sh
#  ls -la 
#fi


#updated version
#::SCN012
if [ "$DEBUG" == "true" ]; then
  echo "[DEBUG]:========================================================================================================================================================================" 
  echo "[DEBUG]:Contents of archive before####################################################################################################################################################"
  echo "[DEBUG]:========================================================================================================================================================================"

  ls -la $appName.xcarchive
fi

echo "========================================================================================================================================================================"
echo "GEN-IR Running #########################################################################################################################################################"
echo "========================================================================================================================================================================"
# See Documentation and Source:
# https://github.com/veracode/gen-ir/

#::SCN013

if [ "$DEBUG" == "true" ]; then
  echo "[DEBUG]: Reading out the build log:"
  cat build_log.txt
fi

# uses new method
# https://docs.veracode.com/r/Generate_IR_to_Package_iOS_and_tvOS_Apps
#echo "Default"
gen-ir build_log.txt $appName.xcarchive --project-path $projectLocation



if [ "$DEBUG" == "true" ]; then
  echo "[DEBUG]:========================================================================================================================================================================" 
  echo "[DEBUG]:Contents of archive after####################################################################################################################################################"
  echo "[DEBUG]:========================================================================================================================================================================"

  echo "[DEBUG]:An IR folder should be present inside the archive, if not then there will be an issue with the scan and it won't be accepted for analysis"
  ls -la $appName.xcarchive/IR
fi

#::SCN013
echo "========================================================================================================================================================================"
echo "Zipping up artifact ####################################################################################################################################################"
echo "========================================================================================================================================================================"

#if [ "$LEGACY" = true ]; then
#  zip -r $appName.zip $appName.xcarchive
#else
#  zip -r $appName.zip $appName.xcarchive
#fi

zip -r $appName.zip $appName.xcarchive
# This section is also specific to your configuration. Make sure to include the necessary SCA component files such as the lock files from your enviornment
zip -r $appName-Podfile.zip Podfile.lock 
ls -la

#::SCN014

mkdir Veracode/
ls -la
cp $appName-Podfile.zip $appName.zip Veracode/
ls -la Veracode/

# #::SCN015
# echo "========================================================================================================================================================================"
# echo "#####  Veracode Upload and Scan  #######################################################################################################################################"
# echo "========================================================================================================================================================================"
# if [ "$DEBUG" == "true" ]; then
#   echo "[DEBUG]:         0000000000000000000000000          1111111    -----------------------------------------------------------"
#   echo "[DEBUG]:         000000              00000        11 111111    ------- Veracode Upload and Scan --------------------------"
#   echo "[DEBUG]:         111111              11111             1111    -----------------------------------------------------------"
#   echo "[DEBUG]:         010101              10101             1111    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#   echo "[DEBUG]:         110010              11011             1111    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#   echo "[DEBUG]:         111111              11111             1111    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#   echo "[DEBUG]:         1111111111111111111111111          111111111  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
# fi



# if [ -n $SANDBOXNAME ]; then
#   if [ "$DEBUG" == "true" ]; then
#     echo "[DEBUG]:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
#     java -jar VeracodeJavaAPI.jar -action UploadAndScan -vid $VID -vkey $VKEY  -deleteincompletescan 2 -createprofile false -createsandbox true -appname "$APPLICATIONNAME" -sandboxname "$SANDBOXNAME" -version "$APPCENTER_BUILD_ID-APPCENTER" -filepath Veracode/ $OPTARGS
#   else
#     # Default Sandbox
#     java -jar VeracodeJavaAPI.jar -action UploadAndScan -vid $VID -vkey $VKEY  -deleteincompletescan $DELETEINCOMPLETE -createprofile $CREATEPROFILE -createsandbox $CREATESANDBOX -appname "$APPLICATIONNAME" -sandboxname "$SANDBOXNAME" -version "$APPCENTER_BUILD_ID-APPCENTER" -filepath Veracode/ $OPTARGS
#   fi
# else
#    if [ "$DEBUG" == "true" ]; then
#     echo "[DEBUG]:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
#     java -jar VeracodeJavaAPI.jar -action UploadAndScan -vid $VID -vkey $VKEY  -deleteincompletescan 1 -createprofile false -appname "$APPLICATIONNAME"  -version "$APPCENTER_BUILD_ID-APPCENTER" -filepath Veracode/ $OPTARGS
#   else
#     # Default Policy
#     java -jar VeracodeJavaAPI.jar -action UploadAndScan -vid $VID -vkey $VKEY  -deleteincompletescan $DELETEINCOMPLETE -createprofile $CREATEPROFILE -appname "$APPLICATIONNAME" -version "$APPCENTER_BUILD_ID-APPCENTER" -filepath Veracode/ $OPTARGS
#   fi
# fi



#EOF