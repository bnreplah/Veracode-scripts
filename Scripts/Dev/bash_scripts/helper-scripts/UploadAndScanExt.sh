#!/bin/bash
# The purpose of this script is to use the API wrapper and check if the app exists, if it doesn't exist create it with the specified parameters then upload and scan
#   if it does exist upload and scan into it





help_menu(){
    echo "Veracode Upload And Scan Expanded"
    echo "Usage: $0 --appname <application profile name> --createprofile true --filepath <path to upload> <additional args>"
    echo """
            --help 
                Displays this help menu
            --filepath 
                Path to the file path or folder to upload the contents of
            --update 
                Update the application profile with the provided fields
            --clean             
                Clean up and remove the API Wrapper
            --vid 
                Veracode API ID
            --vkey
                Veracode API Key
            --appname 
                The application profile name
            --createprofile 
                Boolean to create a profile if it doesn't exist
            --version 
                the scan name
            --createsandbox 
                Boolean to create a sandbox if it doesn't exist
            --deleteincompletescan 
                parameter to delete a scan in the way if needed
            --exclude 
                exclude parameter to specify what modules to exclude in selection
            --include 
                include parameter to specify what modules to select
            --includenewmodules
                include
            --lifecyclestage
                	Validates against the names of the Lifecycle enums
            --pattern
            --replacement
            --sandboxid 
            --sandboxname 
            --scanallnonfataltoplevelmodules 
            --scanpollinginterval 
            --scantimeout 
            --selected 
            --selectedpreviously 
            --toplevel 
            --criticality 
            --autoscan 
            --description 
            --vendorid 
            --policy 
            --businessunit 
            --businessowner
            --businessowneremail 
            --teams 
            --origin 
            --industry 
            --apptype 
            --deploymenttype 
            --webapplication 
            --archerappname 
            --tags 
            --install-wrapper 
    """
   
}


appname=""
createprofile=true
filepath=""
version=""
createsandbox=false
deleteincompletescan=1
exclude=""
include=""
includenewmodules=true
lifecyclestage=""
pattern=""
publishedscansonly=false
replacement=""
sandboxid=""
sandboxname=""
scanallnonfataltoplevelmodules=true
scanpollinginterval=120
scantimeout=""
selected=true
selectedpreviously=""
toplevel=false
business_criticality=""
description=""
vendor_id=""
policy=""
business_unit=""
business_owner=""
business_owner_email=""
teams=""
origin=""
industry=""
app_type=""
deployment_method=""
web_application=false
archer_app_name=""
tags=""
#next_day_scheduling_enabled=""

uploadArgs=""
createAppArgs=""
updateAppArgs=""


while [[ $# -gt 0 ]]; do
        case "$1" in
           
            # Display the Help Menu 
            --help)
                help_menu
                exit 1
                ;;
            # 
            --filepath)
                filepath=$2
                uploadArgs="$uploadArgs -filepath $filepath"
                shift 2
                ;;
            --update)
                update=true
                shift 1
                ;;
            --clean)
                clean
                shift 1
                ;;
            
            --vid)
                veracode_api_id=$2
                shift 2
                ;;

            --vkey)
                veracode_api_key=$2
                shift 2
                ;;
            --appname)
                appname=$2
                uploadArgs="$uploadArgs $filepath"
                shift 2
                ;;
            --createprofile)
                createprofile=$2
                uploadArgs="$uploadArgs -createprofile $createprofile"
                shift 2
                ;;
            --version)
                version=$2
                uploadArgs="$uploadArgs -version $version"
                shift 2
                ;;
            --createsandbox)
                createsandbox=$2
                uploadArgs="$uploadArgs -createsandbox $createsandbox"
                shift 2
                ;;
            --deleteincompletescan)
                deleteincompletescan=$2
                uploadArgs="$uploadArgs -deleteincompletescan $deleteincompletescan "
                shift 2
                ;;
            --exclude)
                exclude=$2
                uploadArgs="$uploadArgs -exclude $exclude"
                shift 2
                ;;
            --include)
                include=$2
                uploadArgs="$uploadArgs -include $include"
                shift 2
                ;;
            --includenewmodules)
                includenewmodules=$2
                uploadArgs="$uploadArgs -includenewmodules $includenewmodules"
                shift 2
                ;;
            --lifecyclestage)
                lifecyclestage=$2
                uploadArgs="$uploadArgs -lifecyclestage $lifecyclestage"
                shift 2
                ;;
            --pattern)
                pattern=$2
                uploadArgs="$uploadArgs -pattern $pattern"
                shift 2
                ;;
            --replacement)
                replacement=$2
                uploadArgs="$uploadArgs -replacement $replacement"
                shift 2
                ;;
            --sandboxid)
                sandboxid=$2
                uploadArgs="$uploadArgs -sandboxid $sandboxid"
                shift 2
                ;;
            --sandboxname)
                sandboxname=$2
                uploadArgs="$uploadArgs -sandboxname $sandboxname"
                shift 2
                ;;

            --scanallnonfataltoplevelmodules)
                scanallnonfataltoplevelmodules=$2
                uploadArgs="$uploadArgs -scanallnonfataltoplevelmodules $scanallnonfataltoplevelmodules"
                shift 2
                ;;
            --scanpollinginterval)
                scanpollinginterval=$2
                uploadArgs="$uploadArgs -scanpollinginterval $scanpollinginterval"
                shift 2
                ;;

            --scantimeout)
                scantimeout=$2
                uploadArgs="$uploadArgs -scantimeout $scantimeout"
                shift 2
                ;;
            --selected)
                selected=$2
                uploadArgs="$uploadArgs -selected $selected"
                shift 2
                ;;
            --selectedpreviously)
                selectedpreviously=$2 
                uploadArgs="$uploadArgs -selectedpreviously $selectedpreviously"
                shift 2
                ;;
            --toplevel)
                toplevel=$2
                uploadArgs="$uploadArgs -toplevel $toplevel"
                shift 2
                ;;
            --criticality)
                criticality=$2
                uploadArgs="$uploadArgs -criticality $criticality"
                shift 2
                ;;
            --autoscan)
                #-autoscan
                autoscan=$2
                createAppArgs="$createAppArgs -criticality $autoscan"
                shift 2
                ;;
            --description)
                description=$2
                createAppArgs="$createAppArgs -description $description"
                shift 2
                ;;
            --vendorid)
                vendor_id=$2
                createAppArgs="$createAppArgs -vendorid $vendor_id"
                updateAppArgs="$updateAppArgs -vendorid $vendor_id"
                shift 2
                ;;
            --policy)
                policy=$2
                uploadArgs="$uploadArgs -policy $policy"
                createAppArgs="$createAppArgs -policy $policy"
                updateAppArgs="$updateAppArgs -policy $policy"
                shift 2
                ;;
            --businessunit)
                business_unit=$2
                createAppArgs="$createAppArgs -businessunit $business_unit"
                updateAppArgs="$updateAppArgs -businessunit $business_unit"
                shift 2
                ;;
            --businessowner)
                business_owner=$2
                createAppArgs="$createAppArgs -businessowner $business_owner"
                updateAppArgs="$updateAppArgs -businessowner $business_owner"
                shift 2
                ;;
            --businessowneremail)
                business_owner_email=$2
                createAppArgs="$createAppArgs -businessowneremail $business_owner_email"
                updateAppArgs="$updateAppArgs -businessowneremail $business_owner_email"
                shift 2
                ;;
            --teams)
                teams="$2"
                createAppArgs="$createAppArgs -teams $teams"
                updateAppArgs="$updateAppArgs -teams $teams"
                shift 2
                ;;
            --origin)
                origin=$2
                createAppArgs="$createAppArgs -origin $origin"
                updateAppArgs="$updateAppArgs -origin $origin"
                shift 2
                ;;
            --industry)
                industry=$2
                createAppArgs="$createAppArgs -industry $industry"
                updateAppArgs="$updateAppArgs -industry $industry"
                shift 2
                ;;
            --apptype)
                app_type=$2
                createAppArgs="$createAppArgs -apptype $app_type"
                updateAppArgs="$updateAppArgs -apptype $app_type"
                shift 2
                ;;
            --deploymenttype)
                deployment_method=$2
                createAppArgs="$createAppArgs -deploymenttype $deployment_method"
                updateAppArgs="$updateAppArgs -deploymenttype $deployment_method"
                shift 2
                ;;
            --webapplication)
                web_application=$2
                createAppArgs="$createAppArgs -webapplication $web_application"
                updateAppArgs="$updateAppArgs -webapplication $web_application"
                shift 2
                ;;
            --archerappname)
                archer_app_name=$2
                createAppArgs="$createAppArgs -archerappname $archer_app_name"
                updateAppArgs="$updateAppArgs -archerappname $archer_app_name"
                shift 2
                ;;
            --tags)
                tags=$2
                createAppArgs="$createAppArgs -tags $tags"
                updateAppArgs="$updateAppArgs -tags $tags"
                shift 2
                ;;
            --install-wrapper)
                installWrapper
                shift 1
                ;;
            *)
                echo "Unknown argument: $2"
                help
                exit 1
                ;;
        esac
        
done


echo $uploadArgs
echo $updateAppArgs
echo $createAppArgs

installWrapper(){
        
    echo "Downloading the latest version of the Veracode Java API Wrapper"
    WRAPPER_VERSION=`curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/maven-metadata.xml | grep latest |  cut -d '>' -f 2 | cut -d '<' -f 1`
    if `wget https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/$WRAPPER_VERSION/vosp-api-wrappers-java-$WRAPPER_VERSION.jar -O VeracodeJavaAPI.jar`; 
    then
        chmod 755 VeracodeJavaAPI.jar
        echo '[INFO] SUCCESSFULLY DOWNLOADED WRAPPER'
    else
        echo '[ERROR] DOWNLOAD FAILED'
        exit 1
    fi

}

# runWrapper(){
#     additionalArgs=""
#     for arg in "$@"; do
#         additionalArgs="$additionalArgs $arg"
#     done
#     java -jar VeracodeJavaAPI.jar -vid $veracode_api_id -vkey $veracode_api_key $additionalArgs

# }

# cleanup(){

#     rm VeracodeJavaAPI.jar

# }

uploadandscan(){
    java -jar VeracodeJavaAPI.jar -action uploadandscan $uploadArgs

}


createapp(){
    java -jar VeracodeJavaAPI.jar -action getapplist >> applist.txt
    appid=$(cat applist.txt | grep -E \"$appname\" | cut -d '"' -f2)
    if [[ -z $appid  || "$appid" == "" ]]; then # if the app id doesn't exist or is null
        java -jar VeracodeJavaAPI.jar -action createapp $createAppArgs
    elif [ "$update" == "true" ]; then # else run the update app
        java -jar VeracodeJavaAPI.jar -action updateapp -appid $appid $updateAppArgs
    fi
    uploadandscan
}




if [ "$createprofile" == "true" ] || [ "$update" == "true" ]; then
    createapp
else
    uploadandscan 
fi
