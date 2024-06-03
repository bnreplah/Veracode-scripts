#!/bin/bash
#TODO: Test and add the ability to handle the custom fields

# $1 Appname
# $2 Filepath or place inside .veracode-artifact directory
# $3 Businessunit
# $4 Tags
#
createAppArgs="-appname $1 -businessunit $3 "
updateAppArgs="-businessunit $3 -tags $4" # -custom_field_name	-custom_field_value "
update="$5"
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
installWrapper

appname="$1"
mkdir .veracode-artifact &2> /dev/null
echo "Attempting to upload artifact in the .veracode-artifact directory"
mv "$2" -t .veracode-artifact/
java -jar VeracodeJavaAPI.jar -action getapplist >> applist.txt
appid=$(cat applist.txt | grep -E \"$appname\" | cut -d '"' -f2)
if [[ -z $appid  || "$appid" == "" ]]; then # if the app id is not null and not empty create a new app
    java -jar VeracodeJavaAPI.jar -action createapp $createAppArgs
    
    # check to see
    
    java -jar VeracodeJavaAPI.jar -action getapplist >> applist.txt
    appid=$(cat applist.txt | grep -E \"$appname\" | cut -d '"' -f2)
    
    if [ -z "$appname" ]; then
        echo "Error App name not found, not created"
    fi

    java -jar VeracodeJavaAPI.jar -action getappinfo -appid $appid # confirms the app creation
elif [ "$update" == "true" ]; then # if the app exists update it
    java -jar VeracodeJavaAPI.jar -action updateapp -appid $appid $updateAppArgs
fi

java -jar VeracodeJavaAPI.jar -action uploadandscan -filepath .veracode-artifact/ -appname $appname -createprofile true -version $3 -deleteincompletescan 2
