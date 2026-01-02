#!/bin/bash
# Veracode installer

help(){
    echo " Veracode Installer -----------------------------------------------------------------------------------------------------"
    echo " Install Options: "
    echo "      --install sca-ci              | Install and scan in the current directory [CI Installation]"
    echo "      --install sca-cli             | Install the SCA  "
    echo "      --install veracode-cli        | Install the latest version of the Veracode CLI"
    echo "      --install api-wrapper-java    | Install the latest version of the API Wrapper"
    # echo "    --install api-wrapper-c       |"
    # echo "    --install api-wrapper-python  |"
    # echo "    --install api-wrapper-shell   |"
    echo "      --install pipeline-scanner    | Install the latest version of the Pipeline Scanner"
    echo " --------------------------------------------------------------------------------------------------------------------------"
    echo " Install Community Options:"
    echo "      --dev-install python-wrapper  | clone veracode-api-py "
    echo "      --dev-install scan-health     | clone scan-health"
    echo "      --dev-install vdblookup       | clone vdblookup" 
    echo "      --dev-install SBOM-Tools      | clone veracode SBOM Tools"
    #echo "      --dev-install "
    echo " --------------------------------------------------------------------------------------------------------------------------"
    echo " Install Alias Options: "
    echo "      --alias-install api-wrapper   | install api-wrapper docker variant as an alias"
    echo "      --alias-install httpie        | install httpie docker variant as an alias"
    echo "      --alias-install scan-health   | install scan-health docker variant as an alias"
    #echo "      --alias-install               |"
    echo " --------------------------------------------------------------------------------------------------------------------------"
    echo " Install Force Options: "
    echo "      --force-install vccli-local   | Install veracode cli and don't try to move into path"
    echo "      --force-install vccli         | Install veracode cli and try to move into path replacing any previous version"
    echo " --------------------------------------------------------------------------------------------------------------------------"
    echo " Other Options: " 
    echo "      --int                         | Interactive menu"
    echo "      --test                        | Tests the installed enviornment"
    echo " Install Experimental Options: "
    echo "      --framework                   | Expiremental : Install the unofficial veracode framework"
    echo "      --sdk                         | Expiremental : Install the unoffical veracode sdk"
    echo " -------------------------------------------------------------------------------------------------------------------------"
    

}

#######################################################################################
##
##
## Check Functions
##
#######################################################################################


check_python_and_pip() {
    # Check if Python is installed
    echo "Checking Python Installation --------------------------------------------------"
    if command -v python3 &> /dev/null; then
        echo "Python3: Installed."
        python_version=$(python3 --version)
        echo "           Python3 version: $python_version"
    elif command -v python &> /dev/null; then
        echo "Python: Installed."
        python_version=$(python --version)
        echo "           Python version: $python_version"
    else
        echo "Python: NOT Installed."
        return 1
    fi
    echo "Checking Pip(3) Installation --------------------------------------------------"
    
    # Check if pip is installed
    if command -v pip3 &> /dev/null; then
        echo "pip3: Installed."
        pip_version=$(pip3 --version)
        echo "           pip3 version: $pip_version"
    elif command -v pip &> /dev/null; then
        echo "pip: Installed."
        pip_version=$(pip --version)
        echo "           pip version: $pip_version"
    else
        echo "pip: NOT Installed."
    fi
    echo "-------------------------------------------------------------------------------"
}

check_java() {
    echo "Checking Java Installation   --------------------------------------------------"
    if command -v java &> /dev/null; then
        echo "Java: Installed."
        java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo "           Java version: $java_version"
    else
        echo "Java: NOT Installed."
    fi
    echo "-------------------------------------------------------------------------------"
}

check_gradle() {
    echo "Checking Gradle Installation   ------------------------------------------------"
    if command -v gradle &> /dev/null; then
        echo "Gradle: Installed"
        gradle_version=$(gradle -v | awk '/Gradle / {print $2}')
        echo "           Gradle version: $gradle_version"
    else
        echo "Gradle: NOT Installed."
    fi
    echo "-------------------------------------------------------------------------------"
}

check_maven() {
    echo "Checking Maven Installation    ------------------------------------------------"
    if command -v mvn &> /dev/null; then
        echo "Maven: Installed."
        maven_version=$(mvn -v | awk '/Apache Maven/ {print $3}')
        echo "           Maven version: $maven_version"
    else
        echo "Maven: NOT Installed."
    fi
    echo "-------------------------------------------------------------------------------"
}

check_curl() {
    echo "Checking Curl Installation    -------------------------------------------------"
    if command -v curl &> /dev/null; then
        echo "Curl: Installed."
        curl_version=$(curl --version | head -n 1)
        echo "           Curl version: $curl_version"
    else
        echo "Curl: NOT Installed."
    fi
    echo "-------------------------------------------------------------------------------"
}


check_env(){
        
    # Display operating system name and version
    echo "Checking Enviornment ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "Operating System Information: -------------------------------------------------"
    echo "           Name: $(uname -s)"
    echo "           Version: $(uname -r)"
    # Display username
    echo "User Information: -------------------------------------------------------------"
    echo "           Username: $(whoami)"
    echo "           User Home: $HOME"
    
    echo "Veracode Configuration Files:"
    if [ -d "$HOME/.veracode" ]; then
        echo "           Veracode Config: $HOME/.veracode - [EXISTS] "

    else
        echo "           Veracode Config: $HOME/.veracode - [DOESN'T EXIST]"
    fi
    if [ -z "$HOME/.veracode/credentials" ]; then
        echo "           Veracode Config: $HOME/.veracode/credentials - [EXISTS] "

    else
        echo "           Veracode Config: $HOME/.veracode/credentials - [DOESN'T EXIST]"
    fi
    if [ -z "$HOME/.veracode/veracode.yml" ]; then
        echo "           Veracode Config: $HOME/.veracode/veracode.yml - [EXISTS] "

    else
        echo "           Veracode Config: $HOME/.veracode/veracode.yml - [DOESN'T EXIST]"
    fi
    echo " Checking installation of Docker: ---------------------------------------------"
    check_command docker
    echo " Checking installation of Veracode CLI: ---------------------------------------"
    check_command veracode
    echo " Checking installation of Veracode SCA Agent Based Scan: "
    check_command srcclr
    echo "-------------------------------------------------------------------------------"


}


# Precondition:
# Postcondition:
check_docker(){





}


# Precondition:
# Postcondition:
check_veracode-cli(){

}


# Precondition:
# Postcondition:
check_srcclr(){


}


# Precondition:
# Postcondition:
check_homebrew(){


}


# Precondition:
# Postcondition:
check_choco(){

}



# Precondition:
# Postcondition:
check_command(){
       
    if command -v $1 &> /dev/null
    then
        echo "$1: $(command -v $1) | $(which $1)"
    else
        echo "$1: not found"
    fi
}


# Precondition:
# Postcondition:
test(){
    check_env
    check_curl
    check_java
    check_maven
    check_gradle
    check_python_and_pip
    check_command veracode
    check_command srcclr
    check_command docker
    

}

#######################################################################################
##
##
## Action Functions
##
#######################################################################################




# Precondition: takes 
# Postcondition:
program_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Precondition:
# Postcondition:
move_to_path(){
  
    # Check if the correct number of arguments is provided
    if [ "$#" -ne 1 ]; then
        return 1
    fi
    local file_path="$1"

    # Check if the file exists
    if [ ! -e "$file_path" ]; then
        echo "Error: File does not exist."
        return 1
    fi

    #TODO: check to see if file already exists in the path first

    # Iterate through each directory in the PATH
    IFS=':' read -ra path_directories <<< "$PATH"
    for dir in "${path_directories[@]}"; do
        # Check if the script has permission to move the file to the current path location
        if [ -w "$dir" ]; then
            mv "$file_path" "$dir"
            echo "File moved successfully to '$dir'."
            return 0  # Exit the function with success status
        fi
    done

    # If the loop completes without successfully moving the file
    echo "Error: Permission denied. Cannot move file to any directory in the PATH."
    return 1
}


#######################################################################################
##
##
## Install Functions
##
#######################################################################################



# Precondition:
# Postcondition:
install_veracode_cli(){
    if program_exists "./veracode"; then
        if [ "$DEBUG" == "true" ]; then
            echo "[DEBUG=$DEBUG]:: veracode cli already exists in the execution path."
        fi
        echo "Veracode-Cli: $( which ./veracode )"
    else
        echo "[INFO]:: Veracode Cli wasn't found in the execution path, installing..."
        curl -fsS https://tools.veracode.com/veracode-cli/install | sh
        move_to_path ./veracode
    fi
    echo "[INFO]:: Running veracode configure, Configure the CLI"
    veracode configure
    
    
}

#The purpose of this function will 
run_discover(){

}

run_install(){

    case "$1" in
        sca-ci)
            curl -sSL https://download.sourceclear.com/install | sh
            shift 1
        ;;
        sca-cli)
            curl -sSL https://download.sourceclear.com/install | CACHE_DIR="$2" sh
            shift 2
        ;;
        veracode-cli)
            curl -fsS https://tools.veracode.com/veracode-cli/install | sh
            move_to_path ./veracode
        ;;
        api-wrapper-java)
            echo "Downloading the latest version of the Veracode Java API Wrapper"
            WRAPPER_VERSION=`curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/maven-metadata.xml | grep latest |  cut -d '>' -f 2 | cut -d '<' -f 1`
            if `wget https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/$WRAPPER_VERSION/vosp-api-wrappers-java-$WRAPPER_VERSION.jar -O VeracodeJavaAPI.jar`; then
                chmod 755 VeracodeJavaAPI.jar
                echo '[INFO] SUCCESSFULLY DOWNLOADED WRAPPER'
            else
                echo '[ERROR] DOWNLOAD FAILED'122w
                exit 1
            fi
            shift 1
        ;;
        pipeline-scanner)
            curl -sSO https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip
            unzip -o pipeline-scan-LATEST.zip
        ;;
        *)
            echo "A valid command was not passed, please pass a valid directive"
        ;;
        esac
}

run_dev_install(){
    
  case "$1" in
        sca-ci)
            
        ;;
        sca-cli)
            
        ;;
        veracode-cli)
            
        ;;
        api-wrapper-java)
            
        ;;
        pipeline-scanner)
            
        ;;
        *)
            echo "A valid command was not passed, please pass a valid directive"
        ;;
        esac

}

run_alias_install(){
    
     case "$1" in
        sca-ci)
            
        ;;
        sca-cli)
            
        ;;
        veracode-cli)
            
        ;;
        api-wrapper-java)
            
        ;;
        pipeline-scanner)
            
        ;;
        *)
            echo "A valid command was not passed, please pass a valid directive"
        ;;
        esac

}


run_env_install(){
    
    case "$1" in
        sca-ci)
            
        ;;
        sca-cli)
            
        ;;
        veracode-cli)
            
        ;;
        api-wrapper-java)
            
        ;;
        pipeline-scanner)
            
        ;;
        *)
            echo "A valid command was not passed, please pass a valid directive"
        ;;
        esac



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


## __main__ ##

# Parsing the passed parameters and taking the required input 

while [[ $# -gt 0 ]]; do
        case "$1" in
            --install)
                install_command=$2
                shift 2
                ;;
            --dev-install)
                dev_install_command=$2
                shift 2
                ;;
            --alias-install)
                alis_install_command=$2
                shift 2
                ;;
            --env-install)
                env_install_command=$2
                shift 2
                ;;
            --installer-menu)
                echo "[Experimental Prompt Mode]"
                shift 1
                ;;
            --install-sca-ci) 
                # TODO: add a prompt or option to pass the token inline
                echo "Make sure the Agent Token is in the enviornment"
                curl -sSL https://download.sourceclear.com/ci.sh | sh -s scan 
                shift 1
                ;;
            --install-sca-cli)
                curl -sSL https://download.sourceclear.com/install | sh
                echo "Run Srcclr Activate and enter the token provided"
                srcclr activate
                shift 1
                ;;
            --force-install-vccli-local)
                curl -fsS https://tools.veracode.com/veracode-cli/install | sh
                echo "Please place the ./veracode cli in the running user's path"
                shift 1
                ;;
            --force-install-vccli)
                curl -fsS https://tools.veracode.com/veracode-cli/install | sh
                move_to_path ./veracode
                shift 1
                ;;
            --install-pipeline-scanner)
                curl -sSO https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip
                unzip -o pipeline-scan-LATEST.zip
                shift 1
                ;;
            --install-api-wrapper)
                echo "Downloading the latest version of the Veracode Java API Wrapper"
                WRAPPER_VERSION=`curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/maven-metadata.xml | grep latest |  cut -d '>' -f 2 | cut -d '<' -f 1`
                if `wget https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/$WRAPPER_VERSION/vosp-api-wrappers-java-$WRAPPER_VERSION.jar -O VeracodeJavaAPI.jar`; then
                    chmod 755 VeracodeJavaAPI.jar
                    echo '[INFO] SUCCESSFULLY DOWNLOADED WRAPPER'
                else
                    echo '[ERROR] DOWNLOAD FAILED'122w
                    exit 1
                fi
                shift 1
                ;;
            --install-docker-alias)
                echo "Installing the docker containers as aliases"
                #TODO: Check to see if docker if installed
                #TODO: add an append to the .bashrc, .zshrc, or whatever shell enviornment they are working in and then install the aliases on the local user
                shift 1
                ;;
            --clone-python-api-py)
                git clone https://github.com/veracode/veracode-api-py
                shift 1
                ;;
            --help)
                help
                shift 1
                ;;
            --test)
                test
                shift 1
                exit
                ;;
            *) 
                echo "Unknown argument: $2"
                help
                exit 1
                ;;
        esac
done




