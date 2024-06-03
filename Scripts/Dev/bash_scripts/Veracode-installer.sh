#!/bin/bash
# Veracode installer

help(){
    echo "Veracode Simple Installer"
    echo "--install-sca-ci              | Install and scan in the current directory"
    echo "--install-sca-cli             | Install the linux SCA "
    echo "--force-install-local         | Install veracode cli and don't try to move into path"
    echo "--force-install               | Install veracode cli and try to move into path"
    echo "--install-api-wrapper         |"
    echo "--install-pipeline-scanner    |"
}


# Precondition:
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


while [[ $# -gt 0 ]]; do
        case "$1" in
            --installer-menu)
                shift 1
                ;;
            --install-sca-ci)
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
            --clone-python-api-py)
                git clone https://github.com/veracode/veracode-api-py
                shift 1
                ;;
            *)
                echo "Unknown argument: $2"
                help
                exit 1
                ;;
        esac
done




