Write-Output "Downloading the latest version of the Veracode Java API"
$versionstring = curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/maven-metadata.xml | findstr /r "latest";
$version = $versionstring.Trim() -replace '<latest>', '' -replace '</latest>', '';

if( Test-Path .\wrapperVersion.txt -PathType leaf){

    $instVersion = cat .\wrapperVersion.txt


    if($version -ne $instVersion){
        echo $version > wrapperVersion.txt
        curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/$version/vosp-api-wrappers-java-$version-dist.zip -o java-wrapper-$version.zip
        mkdir java-wrapper-$version/
        Expand-Archive -Path java-wrapper-$version.zip -DestinationPath ./java-wrapper-$version/ -Force
        Copy-Item -Path ./java-wrapper-$version/VeracodeJavaAPI.jar -Destination ./ -Force
    }
    else {
        Write-Output "The latest version is currently installed";
    }
}
else{
    echo $version > wrapperVersion.txt
    curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/$version/vosp-api-wrappers-java-$version-dist.zip -o java-wrapper-$version.zip
    mkdir java-wrapper-$version/
    Expand-Archive -Path java-wrapper-$version.zip -DestinationPath ./java-wrapper-$version/ -Force
    Copy-Item -Path ./java-wrapper-$version/VeracodeJavaAPI.jar -Destination ./ -Force
}