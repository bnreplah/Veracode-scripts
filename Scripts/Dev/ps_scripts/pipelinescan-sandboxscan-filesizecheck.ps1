param(
    [string]$File,
    [string]$ScanName,
    [string]$AppName
)

# Download latest version of the pipeline scan
curl https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip -o .\pipeline-scan.zip
expand-archive .\pipeline-scan.zip -force

# Download latest version of the api wrapper
Write-Output "Downloading the latest version of the Veracode Java API"
$versionstring = curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/maven-metadata.xml | findstr /r "latest";
$version = $versionstring.Trim() -replace '<latest>', '' -replace '</latest>', '';

if( Test-Path .\wrapperVersion.txt -PathType leaf ){

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


    
$PipelineArgs=""
$uploadandscanArgs=""
$Threshold = 200MB
$PATH_TO_PIPELINE_SCAN = "pipeline-scan\pipeline-scan.jar"
$PATH_TO_API_WRAPPER="VeracodeJavaAPI.jar"
    $FileSize = (Get-Item $File).Length
    if ($FileSize -gt $Threshold) {
        #return 1
        java -jar $PATH_TO_API_WRAPPER -action uploadandscan -filepath "$File" -version "$ScanName" -appname "$AppName" -createprofile false
    } else {
        #return 0
        java -jar $PATH_TO_PIPELINE_SCAN --file "$File" "$PipelineArgs"
    }