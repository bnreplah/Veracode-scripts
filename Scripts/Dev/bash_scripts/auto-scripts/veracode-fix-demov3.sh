#!/bin/bash
# Veracode Fix Wrapper
# Major Version 3
# Minor Version 00
# Patch Version 0-beta-1

# Global 
version="3.00.0-alpha-1"
debug=false
verbose=false
verb_level=0
repo_dir=""
artifact_path=""
results_path="results.json"
all_results=()
all_paths=()
out_dir="./"
source=""
type="directory"
VERB=false  # DO NOT SET TO TRUE
veracode_cli_version=""
script_version="v3.0.23"
install_cli=false
files_not_found_warning=false

# Helper Functions

# Precondition:
# Postcondition:
help(){
    echo    " V     V  EEEEE  RRRR     AAA   CCCCCC   00000  DDDDDD   EEEEEEE"
    echo    "  V   V   E____  R  R    A   A  C        0 # 0  D     D  EE_____" 
    echo    "   V V    E      RRRR    AAAAA  C        0 # 0  D     D  EE"
    echo    "    V     EEEE   R   RR  A   A  CCCCCCC  00000  DDDDD    EEEEEEE"
    echo    "------------------------------------------------------------------------------------------------------------------------------------------"
    echo    "./veracode Fix Demo Tool"
    echo    "------------------------------------------------------------------------------------------------------------------------------------------"
    echo    "- Run without any parameters to use the default results.json file"
    echo    "- It will parse the results.json and look for found relative paths"
    echo    "- You will be prompted which file you want to run fix on in a menu"
    echo    "- You can select the file to attempt to apply a fix to, and then select the fix"
    echo    "- When you are done, you can tell the program you don't want to continue and it will close"
    echo    "- Each itteration, the program will ask if you want to attempt to apply a fix, if you say Y, or Yes, then it will take you to apply fixes"
    echo    "- If you don't want to continue to apply fixes, respond to the prompt N or No when asked if you want to apply fixes"
    echo    "- If you want to override the results.json and generate a new one, pass an artifact path for the static pipeline scanner to analyze"
    echo    "- If the results.json is named differently or in a different location specify that after the --results parameter"
    echo    "------ Usage ------------------------------------------------------------------------------------------------------------------------------"
    echo    "- Get Help:"
    echo    "           $0 --help"
    echo    "- Run ./veracode Fix against a results.json:"
    echo    "           $0"
    echo    "- Run A Pipeline Scan First, then ./veracode Fix against results.json:"
    echo    "           $0 --artifact app/target/verademo.war"
    echo    "- Run ./veracode Fix against results in specified file:"
    echo    "           $0 --results app/results.json"
    echo    "- Run a Pipeline Scan First and output to specified file, then run ./veracode Fix against the results file specified"
    echo    "           $0 --artifact app/target/verdemo.war --results app/results.json"
    echo    "[Experimental] - Package the artifact before scanning it with the pipeline scan"
    echo    "           $0 --outdir ./ --source verademo/ --type directory --trust --package"
    echo    "[Experimental] - Package the artifact, run a pipeline scan against the artifact, and generate fix recomendations from the results"
    echo    "           $0 --outdir ./ --source verademo/ --type directory --trust --results results.json --package"
    echo    "[Experimental] - Install the ./veracode Cli"
    echo    "           $0 --install-cli <additional args>"
    echo    "- Turn on debug"
    echo    "           $0 --debug <additional args>"
    echo    "[Experimental] - Install ./veracode CLI"
    echo    "           $0 --install-cli <additional args>"
    echo    "[Experimental] - Force Install ./veracode CLI"
    echo    "           $0 --force-install <additional args>"
    echo    "[Experimental] - Force Install ./veracode CLI Locally"
    echo    "           $0 --force-install-local "
    echo    "[Experimental] - Force Update ./veracode CLI "
    echo    "           $0 --force-update <additional args>"
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
        echo "[Error]: File does not exist."
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
    echo "[Error]: Permission denied. Cannot move file to any directory in the PATH."
    return 1
}

force_update(){
    local update_path=""
    local file_path=""
    if which veracode ; then
        echo "Updating path..."
        update_path="$( which ./veracode )"
        curl -fsS https://tools.veracode.com/veracode-cli/install | sh
        file_path="./veracode"
            
        # Check if the file exists
        if [ ! -e "$file_path" ]; then
            echo "Error: File does not exist."
            return 1
        fi

        mv -u "$file_path" "$update_path"    
        ./veracode configure
    else
        echo "./veracode CLI has not been installed yet, run the --install-cli parameter to install it"
    fi
}

# Precondition:
# Postcondition:
install_veracode_cli(){
    if program_exists "./veracode"; then
        if [ "$DEBUG" == "true" ]; then
            echo "[DEBUG=$DEBUG]:: ./veracode cli already exists in the execution path."
        fi
        echo "./veracode-Cli: $( which ./veracode )"
    else
        echo "[INFO]:: ./veracode Cli wasn't found in the execution path, installing..."
        curl -fsS https://tools../veracode.com/./veracode-cli/install | sh
        move_to_path ./veracode
    fi
    echo "[INFO]:: Running ./veracode Configure, Configure the CLI"
    ./veracode configure
    
    
}


# Precondition:
# Postcondition:
# Function to extract file name from FilePath
extract_file_name() {
    # Extract file name from the given FilePath
    filepath="$1"
    echo "$(basename "$filepath")"
    #return "$(basename "$filepath")"
}

# Precondition:
# Postcondition:
remove_trailing_period(){

    filename="$1"

    # Remove trailing period without affecting file extension
    new_filename=$(basename "$filename" .)
    new_filename_with_extension="${new_filename}${filename##*.}"
    if [ "$VERB" == "true" ]; then
        echo "Original filename: $filename"
        echo "New filename: $new_filename_with_extension"
    fi
    echo "$new_filename_with_extension"
}


# Precondition:
# Postcondition:
package_archive() {
    #    echo    "[Experimental] - Package the artifact before scanning it with the pipeline scan"
    #    echo    "           ././veracode-fix-demo.sh --outdir ./ --source verademo/ --type directory --trust --package"
    #check to see if type is set correctly
    if [ "$type" == "repo" ] || [ "$type" == "directory" ]; then
        if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG=$DEBUG]:: Type is set to $type "
        fi
    else
        if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG=$DEBUG]:: Type is set to $type "
        fi
        echo "[ERROR]:(Type_Error): Type not set properly. Valid options are 'repo'  and 'directory' "
        exit -1
    fi
    #check to see if package is set
    
    if [ "$package" == "true" ]; then
        if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG=$DEBUG]:: Package is set to $package "
        fi
    else
        if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG=$DEBUG]:: Package is set to $package "
        fi
        return
    fi

    #check to see if source is set
    if [ -n "$outdir" ] && [ -n "$source" ]; then
        if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG=$DEBUG]:: Outdir is set to $outdir "
            echo "[DEBUG=$DEBUG]:: Source is set to $source "
        fi
    else
        if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG=$DEBUG]:: Outdir is set to $outdir "
            echo "[DEBUG=$DEBUG]:: Source is set to $source "
        fi
        echo "[ERROR]:(Directory_Error): Confirm that the output directory and source are valid directories"
        exit -1
    fi
    
    #check to see if trust is set
    
    if [ -n $trust ] && [ "$trust" == "true" ]; then
        if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG=$DEBUG]:: Trust is set to $trust "
            if [ "$outdir" == "./" ]; then
                artifact_path="$( remove_trailing_period $( ./veracode package --output "$outdir" --source "$source" --type "$type" --trust 2>&1 | tee veracode-package.log | grep "Copied artifact:" | cut -d ':' -f3 ) )"
                echo "$artifact_path"
            else
                artifact_path="${outdir}$( remove_trailing_period $( ./veracode package --output "$outdir" --source "$source" --type "$type" --trust 2>&1 | tee veracode-package.log | grep "Copied artifact:" | cut -d ':' -f3 ) )"
                echo "$artifact_path"
            fi
        else
            if [ "$outdir" == "./" ]; then
                artifact_path="$( remove_trailing_period $( ./veracode package --output "$outdir" --source "$source" --type "$type" --trust 2>&1 | tee veracode-package.log | grep "Copied artifact:" | cut -d ':' -f3 ) )"
                echo "$artifact_path"
            else
                artifact_path="${outdir}$( remove_trailing_period $( ./veracode package --output "$outdir" --source "$source" --type "$type" --trust 2>&1 | tee veracode-pacakge.log | grep "Copied artifact:" | cut -d ':' -f3 ) )"
                echo "$artifact_path"
            fi
        fi
        

    else
        if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG=$DEBUG]:: Trust is set to $trust "
            if [ "$outdir" == "./" ]; then
                artifact_path="$( remove_trailing_period $( ./veracode package --output "$outdir" --source "$source" --type "$type"  2>&1 | tee veracode-package.log | grep "Copied artifact:" | cut -d ':' -f3 ) )"
                echo "$artifact_path"
            elif [ "$outdir" == "." ]; then
                artifact_path="${outdir}$( remove_trailing_period $( ./veracode package --source "$source" --type "$type" 2>&1 | tee veracode-package.log | grep "Copied artifact:" | cut -d ':' -f3 ) )"
                echo "$artifact_path"
            else
                artifact_path="${outdir}$( remove_trailing_period $( ./veracode package --output "$outdir" --source "$source" --type "$type" 2>&1 | tee veracode-package.log | grep "Copied artifact:" | cut -d ':' -f3 ) )"
                echo "$artifact_path"
            fi 
        else    
            if [ "$outdir" == "./" ]; then
                artifact_path="$( remove_trailing_period $( ./veracode package --output "$outdir" --source "$source" --type "$type" 2>&1 | tee veracode-package.log | grep "Copied artifact:" | cut -d ':' -f3 ) )"
                echo "$artifact_path"
            else
                artifact_path="${outdir}$( remove_trailing_period $( ./veracode package --output "$outdir" --source "$source" --type "$type"  2>&1 | tee veracode-package.log | grep "Copied artifact:" | cut -d ':' -f3 ) )"
                echo "$artifact_path"
            fi 
        fi
        
    fi

    


}


# Precondition:
# Postcondition:
is_filepath_in_array() {
    local filepath_to_check="$1"
    for existing_filepath in "${all_results[@]}"; do
        if [ "$existing_filepath" == "$filepath_to_check" ]; then
            return 1  # Filepath is already in the array
        fi
    done
    return 0  # Filepath is not in the array
}

# Precondition:
# Postcondition:
search_file() {
    # File name to search for
    filename="$1"

    # Get a list of directories using ls command
    directories=($(ls -d */ 2>/dev/null ))

    # Array to store all identified paths and filenames
    #all_results=()

    # Loop through each directory
    for dir in "${directories[@]}"; do
        # Check if the directory exists
        if [ -d "$dir" ]; then
            # Use find to search for the file recursively up to 12 levels deep
            result=$(find "$dir" -maxdepth 12 -type f -name "$filename" 2>/dev/null)

            # Check if the file was found
            if [ -n "$result" ]; then
                # Extract the relative path and file name
                relative_path="${result%/*}"
                file_name="${result##*/}"
                if is_filepath_in_array "$relative_path/$file_name"; then
                        all_results+=("$relative_path/$file_name")
                fi
                # Add the result to the array
                #all_results+=("${relative_path}")
            else
                if [ "$DEBUG" == "true" ]; then
                    echo "[DEBUG=$DEBUG] File not found in $dir or its subdirectories."
                fi
                files_not_found_warning=true
            fi
        else
            if [ "$DEBUG" == "true" ]; then
                echo "[DEBUG=$DEBUG]:: Directory $dir does not exist."
            fi
            continue
        fi
    done

    # Check if any results were found
    if [ ${#all_results[@]} -eq 0 ]; then
        if [ "$DEBUG" == "true" ]; then
            echo "[DEBUG=$DEBUG]:: No matching files found."
        fi
        files_not_found_warning=true
    else
        # Iterate through the array and print each unique filepath
        if [ "$DEBUG" == "true" ]; then
            echo "[DEBUG=$DEBUG]:: Unique File Paths:"
        fi
        for path in $(echo "${all_results[@]}" | tr ' ' '\n' | sort -u); do
 #            echo "$path"
            all_paths+=("$path")
        done
    fi

}

# Precondition:
# Postcondition:
file_exists(){
    filename="$1"
    if [ "$DEBUG" == "true" ]; then
        echo "[Debug=$DEBUG]:: checking filename: $filename"
    fi

    if [ -e $filename ]; then
        echo true
    else
        echo false
    fi

}

# Precondition:
# Postcondition:
select_option() {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

process_parameters() {
    echo "Running Menu"     
    # Proccess the input
    while [[ $# -gt 0 ]]; do
            case "$1" in
                # Specify the output directory
                --help)
                    help
                    shift 1
                    exit
                    ;;
                # Display the Help Menu
                --artifact)
                    artifact_path="$2"
                    shift 2
                    ;;
                #
                --results)
                    results_path="$2"
                    shift 2
                    ;;
                --outdir)
                    outdir="$2"
                    shift 2
                    ;;
                --source)
                    source="$2"
                    shift 2
                    ;;
                --type)
                    type="$2"
                    shift 2
                    ;;
                --trust)
                    trust=true
                    shift 1
                    ;;
                --package)
                    package=true
                    shift 1
                    ;;
                --package-only)
                    package_only=true
                    shift 1
                    ;;
                --version)
                    echo "$( ./veracode version )"
                    shift 1
                    ;;
                --install-cli)
                    install_cli=true
                    shift 1
                    ;;
                --force-install-local)
                    curl -fsS https://tools../veracode.com/./veracode-cli/install | sh
                    echo "Please place the ./veracode cli in the running user's path"
                    exit 0
                    ;;
                --force-install)
                    curl -fsS https://tools../veracode.com/./veracode-cli/install | sh
                    move_to_path ././veracode
                    shift 1
                    ;;
                --force-update)
                    force_update
                    shift 1
                    ;;
                --debug)
                    DEBUG=true
                    shift 1
                    ;;
                *)
                    echo "Unknown argument: $2"
                    help
                    exit 1
                    ;;
            esac
    done

}


main(){


    
}


main