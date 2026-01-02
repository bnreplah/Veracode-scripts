#!/bin/bash

downloadWrapper(){
      echo "Downloading the latest version of the Veracode Java API Wrapper"
      WRAPPER_VERSION=`curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/maven-metadata.xml | grep latest |  cut -d '>' -f 2 | cut -d '<' -f 1`
      if `wget https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/$WRAPPER_VERSION/vosp-api-wrappers-java-$WRAPPER_VERSION.jar -O VeracodeJavaAPI.jar`; then
            chmod 755 VeracodeJavaAPI.jar
            echo '[INFO] SUCCESSFULLY DOWNLOADED WRAPPER'
      else
            echo '[ERROR] DOWNLOAD FAILED'122w
            exit 1
      fi
}