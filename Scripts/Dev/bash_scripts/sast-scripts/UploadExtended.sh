#!/bin/bash
#TODO: Test and add the ability to handle the custom fields

# $1 Appname
# $2 Filepath or place inside .veracode-artifact directory
# $3 Businessunit
# $4 Tags
#
createAppArgs="-appname $1 -businessunit $3 " #add additional custom create app arguments to be run and set everytime an app needs to be created
updateAppArgs="-businessunit $3 -tags $4 "
#customfieldvalueParam=$5
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
# create a CSV, and then itterate over the CSV using the update app and the custom fields argument to add all the custom fields to the app at once
updateCustomFields(){
    # write a scritp that takes in a key as the first entry and the value as the second entry
    # the script will then create a key item pair formatted for the API wrapper to be able to run across the CSV and provide the itteration
    

}

installWrapper


appname="$1"
# Attempting to create the artifact output directory
mkdir .veracode-artifact &2> /dev/null
# if there are any errors, ports them out to null
echo "Attempting to upload artifact in the .veracode-artifact directory"
mv "$2" -t .veracode-artifact/ # move the second parameter passed to the script into the .veracode-artifact directory
java -jar VeracodeJavaAPI.jar -action getapplist >> applist.txt 
# java - jar VeracodeJavaAPI.jar -action getapplist -outputfilepath applist.txt
# Get a full applist and then port it out to the applist.txt file

appid=$(cat applist.txt | grep -E \"$appname\" | cut -d '"' -f2) # parse the applist and look for the entry matching the app name specified ( the first parameter )
# IF the appid comes back as blank or is null, then trigger the following conditional flow
if [[ -z $appid  || "$appid" == "" ]]; then # if the app id is not null and not empty create a new app
    java -jar VeracodeJavaAPI.jar -action createapp $createAppArgs
    
    # check to see if the app exists, it doesn't, so providing the option to create an app if CreateApp is set to true
    # Creating the app using the values defined in the $createAppArgs at the top
    # after the create app is run, it then checks to see that the app was created, parses to confirm
    java -jar VeracodeJavaAPI.jar -action getapplist >> applist.txt
    appid=$(cat applist.txt | grep -E \"$appname\" | cut -d '"' -f2)
    # if still not found, then spits out an error describing that an error occurred and the app name was not found or created
    if [ -z "$appname" ]; then
        echo "Error App name not found, not created"
    elif [ -z $appid  || "$appid" == "" ]; then
        echo "Error: Trouble verifying the app creating, please confirm that it was created"
    else
    
        # Then it attempts to get the app with the new parses app ID
        java -jar VeracodeJavaAPI.jar -action getappinfo -appid $appid # confirms the app creation
    fi
elif [ "$update" == "true" ]; then # if the app exists update it
    java -jar VeracodeJavaAPI.jar -action updateapp -appid $appid $updateAppArgs # and use the updateAppArgs to update it
    #java -jar VeracodeJavaAPI.jar -action updateapp -appid $appid -customfieldname "Release Version" -customfieldvalue $customfieldvalueParam # uncomment for custom fields
fi

java -jar VeracodeJavaAPI.jar -action uploadandscan -filepath .veracode-artifact/ -appname $appname -createprofile true -version $3 -deleteincompletescan 2
