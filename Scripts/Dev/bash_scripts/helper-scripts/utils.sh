#!/bin/bash


shopt -s expand_aliases
alias 'veracode-http'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-signing:cmd'
alias 'veracode-api'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-wrapper-java:cmd'
alias 'veracode-http'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-signing:cmd'


downloadJavaWrapper(){
    echo "Downloading the latest version of the Veracode Java API Wrapper"
    # This url might be dated and might need to get updated
    WRAPPER_VERSION=`curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/maven-metadata.xml | grep latest |  cut -d '>' -f 2 | cut -d '<' -f 1`
    if `wget https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/$WRAPPER_VERSION/vosp-api-wrappers-java-$WRAPPER_VERSION.jar -O VeracodeJavaAPI.jar`; then
        chmod 755 VeracodeJavaAPI.jar
        echo '[INFO] SUCCESSFULLY DOWNLOADED WRAPPER'
    else
        echo '[ERROR] DOWNLOAD FAILED'
        exit 1
    fi
}

downloadPipelineScanner(){
    echo "Downloading the latest version of the Veracode Pipeline Scanner"
    curl -sS https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip --output pipeline-scan-LATEST.zip --silent
    unzip pipeline-scan-LATEST.zip pipeline-scan.jar
}

# # Allow for the system to determine which is the best way to download the agent
# downloadSCAAgent(){

# }

healthcheck(){
    #shopt -s expand_aliases
    #alias 'veracode-http'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-signing:cmd'
    veracode-http https://api.veracode.com/healthcheck/status 
}


connection_check(){
    # Basic Connection check
    ping 8.8.8.8 # ping google DNS

}

download_sca_agent_curl(){
    curl -sSL https://sca-downloads.veracode.com/install | sh

}

download_sca_agent_apt(){

    curl -sSL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xdf7dd7a50b746dd4' | sudo gpg --dearmor -o /usr/share/keyrings/veracode-sca-archive.gpg
    echo 'deb [signed-by=/usr/share/keyrings/veracode-sca-archive.gpg] https://sca-downloads.veracode.com/ubuntu stable/' | sudo tee /etc/apt/sources.list.d/veracode-sca.list
    sudo apt-get update
    sudo apt-get install srcclr     

}

download_sca_agent_yum(){

    echo [SourceClear] name=SourceClear baseurl=https://sca-downloads.veracode.com/redhat/x86_64/ > /etc/yum.repos.d/SRCCLR.repo
    echo enabled=1 gpgcheck=1 gpgkey=https://sca-downloads.veracode.com/redhat/SRCCLR-GPG-KEY >> /etc/yum.repos.d/SRCCLR.repo

}

download_sca_agent_alpine(){
    sudo sh -c 'echo https://sca-downloads.veracode.com/alpine/main >> /etc/apk/repositories'
    sudo wget -P /etc/apk/keys https://sca-downloads.veracode.com/alpine/public-keys/production@srcclr.com-5e266d90.rsa.pub
    sudo apk add srcclr
}

download_sca_agent_homebrew(){
    brew tap veracode/srcclr
    brew install srcclr
}

download_veracode_cli_curl(){
    curl -fsS https://tools.veracode.com/veracode-cli/install | sh
}


download_veracode_cli_brew(){
    brew install veracode/tap/veracode-cli
}

download_phylum_cli(){
    curl https://sh.phylum.io/ | sh -
}

download_phlyum_cli_brew(){
    brew install phylum
}

# download_veracode_cli_curl(){

# }


# download_veracode_cli_curl(){

# }

update_cli_brew(){
 brew update
 brew upgrade veracode-cli 
}

# update_sca(){
# #Stub
# }

# update_java_wrapper(){
# #Stub
# }

 add_alias(){
    echo "Adding to .bashrc"
    echo "alias 'veracode-http'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-signing:cmd'" >> ~/.bashrc
    echo "alias 'veracode-api'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-wrapper-java:cmd'" >> ~/.bashrc
    echo "alias 'veracode-http'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-signing:cmd'" >> ~/.bashrc
 }

test_utils(){
  echo "Testing, From Utils.sh"
}

size_scan(){
    #echo "file to scan:"
    #read fileLocation
    fileLocation="$1"
    appname="pipeline"
    #scanname="$3"
    if [[ -z "$fileLocation" ]];then
        echo "No File has been passed"
        return 1
    fi
    echo $(stat --format=%s $fileLocation)

    if [[ $(stat --format=%s $fileLocation) -le 20000 ]]; then
        downloadPipelineScanner
        echo "The $fileLocation is less than 200 mb @ " $(stat --format=%s $fileLocation)
        java -jar pipeline-scan.jar --file $fileLocation
    else
        downloadJavaWrapper
        echo "The $fileLocation is greater than 200 mb @ " $(stat --format=%s $fileLocation)
        java -jar VeracodeAPI.jar -action uploadandscan -filepath $fileLocation -appname $appname -createprofile true -createsandbox true -sandboxname "pipeline" -version $(date +%Y%m%d%H%M%S) -deleteincompletescan 1
    fi
}
#size_scan $1