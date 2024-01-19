#!/bin/bash

# TODO: add a check that checks to see if the latest version installed

artifact_path=""
results_path="./results.json"
results_exist=false
test=false
install=false
help(){

    echo    "Veracode Fix Demo Tool"
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
    echo    "           ./veracode-fix-demo.sh --help"
    echo    "- Run Veracode Fix against results.json:"
    echo    "           ./veracode-fix-demo.sh"
    echo    "- Run A Pipeline Scan First, then Veracode Fix against results.json:"
    echo    "           ./veracode-fix-demo.sh --artifact app/target/verademo.war"
    echo    "- Run Veracode Fix against results in specified file:"
    echo    "           ./veracode-fix-demo.sh --results app/results.json"
    echo    "- Run a Pipeline Scan First and output to specified file, then run Veracode Fix against the results file specified"
    echo    "           ./veracode-fix-demo.sh --artifact app/target/verdemo.war --results app/results.json"
    echo    "------ Test --------------------------------------------------------------------------------------------------------------------------------"
    echo    " - Run all tests "
    echo    "           ./veracode-fix-demo.sh --test"

}
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
            # point to the results file if not in the same location
            --results)
                results_path="$2"
                shift 2
                ;;
            --test)
                test=true
                shift 1
                ;;
            --install)
                install=true
                shift 1
                ;;
                
            *)
                echo "Unknown argument: $2"
                help
                exit 1
                ;;
        esac
done

if [ -f $results_path ]; then
    echo "Results File Exists in specified location or default location"
    results_exist=true
else
    echo "Results File Doesn't Exist in specified location or default location"
    results_exist=false
fi


if [ -z "$artifact_path" ]; then
        echo "No artifact was passed"
        if $results_exist; then
               echo "Using Results file that found in default/specified location"
        else
                read -p "Please enter the artifact path and name: " artifact_path
                veracode static scan "$artifact_path" --results-file $results_path
        fi
else
     # if results file and artifact both passed will overwrite results file
       
        echo "artifact was passed"
        artifact_path="$1"
        veracode static scan "$artifact_path" --results-file $results_path

fi


all_results=()
all_paths=()
# Function to extract file name from FilePath
extract_file_name() {
    # Extract file name from the given FilePath
    filepath="$1"
    echo "$(basename "$filepath")"
}

is_filepath_in_array() {
    local filepath_to_check="$1"
    for existing_filepath in "${all_results[@]}"; do
        if [ "$existing_filepath" == "$filepath_to_check" ]; then
            return 1  # Filepath is already in the array
        fi
    done
    return 0  # Filepath is not in the array
}


search_file() {
    # File name to search for
    filename="$1"

    # Get a list of directories using ls command
    directories=($(ls -d */))

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
                #echo "File not found in $dir or its subdirectories."
                continue
            fi
        else
            echo "Directory $dir does not exist."
            continue
        fi
    done

    # Check if any results were found
    if [ ${#all_results[@]} -eq 0 ]; then
#        echo "No matching files found."
        continue
    else
        # Iterate through the array and print each unique filepath
#        echo "Unique File Paths:"
        for path in $(echo "${all_results[@]}" | tr ' ' '\n' | sort -u); do
#            echo "$path"
            all_paths+=("$path")
        done
    fi

}

function select_option {

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


# Example usage: jq query with file name extraction and search

# Uncomment to enable handlebars
#jq_result=($(jq -r '.findings[] as $finding | select(( $finding.cwe_id ) as $id | $id == "73" or $id == "80" or $id == "89" or $id == "113" or $id == "117" or $id == "327" or $id == "331" or $id == "382" or $id == "470" or $id == "597" or $id == "601"  or $id == "201" or $id == "209") | $finding.files.source_file.file' results.json ))
jq_result=($(jq -r '.findings[] as $finding  | $finding.files.source_file.file' results.json ))

filePaths=()
fileNames=()
options=()
for item in $(echo "${jq_result[@]}" | tr ' ' '\n' | sort -u) ; do
        fileNames+=("$(basename $item)")
        filePaths+=("$item")

        search_file "$(basename $item)"
done

for path in $( echo "${all_paths[@]}"| tr ' ' '\n' | sort -u); do
        options+=("$path")
done


while true; do
    # Prompt the user for input
    read -p "Do you want to attempt to apply a fix? [(Y)es/(N)o]: " response

    # Convert the response to lowercase for case-insensitive comparison
    response_lower=$(echo "$response" | tr '[:upper:]' '[:lower:]')

    # Check if the response is "yes" or "y"
    if [ "$response_lower" == "yes" ] || [ "$response_lower" == "y" ]; then
        #echo "Continuing..."
        # Add your logic here for what you want to do inside the loop
        echo "Select one option using up/down keys and enter to confirm:"
        echo ""
        select_option "${options[@]}"
        choice=$?

        echo "Choosen index = $choice"
        echo "        value = ${options[$choice]}"
        veracode fix "${options[$choice]}" --results $results_path
    else
        echo "Exiting loop."
        break  # Exit the loop if the response is not "yes" or "y"
    fi
done




# options=()
# # Print the populated array
# #echo "Populated Array:"
# i=0

# #if [ "$DEBUG" == "1" ]; then

#         for element in "${my_arrayy[@]}"; do
#             #echo "$element : ${my_array[i]}"
#             options+=("$element : ${my_array[i]}")
#             i=$((i + 1 ))
#         done
# #fi
# #echo $i


# # Renders a text based list of options that can be selected by the
# # user using up, down and enter keys and returns the chosen option.
# #
# #   Arguments   : list of options, maximum of 256
# #                 "opt1" "opt2" ...
# #   Return value: selected index (0 for opt1, 1 for opt2 ...)
# function select_option {
#     # Menu function from this post, with modifications as needed: https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu
#     # It was either this one or one using dialog, but didn't want to have to install anything on the system to get it to work
#     # little helpers for terminal print control and key input
#     ESC=$( printf "\033")
#     cursor_blink_on()  { printf "$ESC[?25h"; }
#     cursor_blink_off() { printf "$ESC[?25l"; }
#     cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
#     print_option()     { printf "   %s""$1"  2>/dev/null; }
#     print_selected()   { printf "  $ESC[7m $1 $ESC[27m"  2>/dev/null; }
#     get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
#     key_input()        { read -s -n3 key 2>/dev/null >&2
#                          if [[ $key = $ESC[A ]]; then echo up;    fi
#                          if [[ $key = $ESC[B ]]; then echo down;  fi
#                          if [[ $key = ""     ]]; then echo enter; fi; }

#     # initially print empty new lines (scroll down if at bottom of screen)
#     for opt; do printf "\n"; done

#     # determine current screen position for overwriting the options
#     local lastrow=`get_cursor_row`
#     local startrow=$(($lastrow - $#))

#     # ensure cursor and input echoing back on upon a ctrl+c during read -s
#     trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
#     cursor_blink_off

#     local selected=0
#     while true; do
#         # print options by overwriting the last lines
#         local idx=0
#         for opt; do
#             cursor_to $(($startrow + $idx))
#             if [ $idx -eq $selected ]; then
#                 print_selected "$opt"
#             else
#                 print_option "$opt"
#             fi
#             ((idx++))
#         done

#         # user key control
#         case `key_input` in
#             enter) break;;
#             up)    ((selected--));
#                    if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
#             down)  ((selected++));
#                    if [ $selected -ge $# ]; then selected=0; fi;;
#         esac
#     done

#     # cursor position back to normal
#     cursor_to $lastrow
#     printf "\n"
#     cursor_blink_on

#     return $selected
# }

# echo "Select a workspace"
# echo "Select one option using up/down keys and enter to confirm:"
# echo


# select_option "${options[@]}"
# choice=$?

# echo "Choosen index = $choice"
# echo "        value = ${options[$choice]}"
