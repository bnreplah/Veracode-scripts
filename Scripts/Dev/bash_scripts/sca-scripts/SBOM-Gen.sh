#!/bin/bash
#  Author: Ben Halpern
#  Version: v2.1.2 
#  Veracode 2023
#  LICENSE: MIT 
#  
#  Inspired by the work done by:
#    Alexander Klimetschek : https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu
#    gilmore867 : https://github.com/gilmore867/Veracode-SBOM-GUI
# This version does not use docker containers
VERSION="v2.1.2"


##################################################################
#
# Menu function
#
##################################################################

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
function select_option {
    # Menu function from this post, with modifications as needed: https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu
    # It was either this one or one using dialog, but didn't want to have to install anything on the system to get it to work
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { 
      printf "$ESC[?25h"; 
    }
    cursor_blink_off() { 
      printf "$ESC[?25l"; 
    }
    cursor_to()        { 
      printf "$ESC[$1;${2:-1}H"; 
    }
    print_option()     { 
      printf "   %s""$1"  2>/dev/null; 
    }
    print_selected()   { 
      printf "  $ESC[7m $1 $ESC[27m"  2>/dev/null; 
    }
    get_cursor_row()   { 
      IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; 
    }
    key_input()        { 
      read -s -n3 key 2>/dev/null >&2
      if [[ $key = $ESC[A ]]; then echo up;    fi
      if [[ $key = $ESC[B ]]; then echo down;  fi
      if [[ $key = ""     ]]; then echo enter; fi; 
    }

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


if cd .sbom ; then
        clear
        cd -
else
        clear
        mkdir .sbom
        #cd .sbom
fi

#pip install httpie
#pip install veracode-api-signing

shopt -s expand_aliases
# alias
alias 'veracode-http'='http --auth-type=veracode_hmac'
DEBUG=0

sbom_type_options[0]="Application Profile SBOM"
sbom_type_options[1]="Agent Based SBOM"

select_option "${sbom_type_options[@]}"
choice=$?

echo "Choosen index = $choice"
echo "        value = ${sbom_type_options[$choice]}"

if [ "$choice" == "0" ]; then
    echo "Application Profile SBOM"

        
    # Run the piped commands and store the output in a variable
    veracode-http -o .sbom/applications.json "https://api.veracode.com/appsec/v1/applications"
    idoutput=$(cat .sbom/applications.json | jq -r '._embedded.applications[].guid' )

    # Initialize an empty Bash array
    my_array=()

    # Use a while read loop to populate the array
    while IFS= read -r line; do
        my_array+=("$line")
    done <<< "$idoutput"

    if [ "$DEBUG" == "1" ]; then

            # Print the populated array
            echo "Populated Array:"
            for element in "${my_array[@]}"; do
                echo "$element"
            done
    fi

    # Run the piped commands and store the output in a variable
    nameoutput=$(cat .sbom/applications.json | jq -r '._embedded.applications[].profile.name')

    # Initialize an empty Bash array
    my_arrayy=()

    # Use a while read loop to populate the array
    while IFS= read -r line; do
        my_arrayy+=("$line")
    done <<< "$nameoutput"

    if [ "$DEBUG" == "1" ]; then

            # Print the populated array
            echo "Populated Array:"
            for element in "${my_arrayy[@]}"; do
                echo "$element"
            done
    fi

    options=()
    # Print the populated array
    #echo "Populated Array:"
    i=0

    #if [ "$DEBUG" == "1" ]; then

            for element in "${my_arrayy[@]}"; do
                #echo "$element : ${my_array[i]}"
                options+=("$element : ${my_array[i]}")
                i=$((i + 1 ))
            done
    #fi
    #echo $i


    ##################################################################
    #
    #  Select an application
    # ( array populated before the function )
    ###################################################################



    echo "Select an application"
    echo "Select one option using up/down keys and enter to confirm:"
    echo


    select_option "${options[@]}"
    choice=$?

    echo "Choosen index = $choice"
    echo "        value = ${options[$choice]}"



    # populate the next set of options array

    veracode-http -o .sbom/"${my_array[$choice]}" "https://api.veracode.com/srcclr/sbom/v1/targets/${my_array[$choice]}/cyclonedx?type=application"
    echo "CycloneDx SBOM written to .sbom/${my_array[$choice]}.json"
    #cd -f

elif "$choice" == "1"; then
    echo "Agent Based SBOM"
        
    # Run the piped commands and store the output in a variable
    veracode-http -o .sbom/workspaces.json "https://api.veracode.com/srcclr/v3/workspaces"
    idoutput=$(cat .sbom/workspaces.json | jq -r '._embedded.workspaces' | grep -i '"id":' | cut -d '"' -f4)

    # Initialize an empty Bash array
    my_array=()

    # Use a while read loop to populate the array
    while IFS= read -r line; do
        my_array+=("$line")
    done <<< "$idoutput"

    if [ "$DEBUG" == "1" ]; then

            # Print the populated array
            echo "Populated Array:"
            for element in "${my_array[@]}"; do
                echo "$element"
            done
    fi

    # Run the piped commands and store the output in a variable
    nameoutput=$(cat .sbom/workspaces.json | jq -r '._embedded.workspaces' | grep -i '"name":' | cut -d '"' -f4)

    # Initialize an empty Bash array
    my_arrayy=()

    # Use a while read loop to populate the array
    while IFS= read -r line; do
        my_arrayy+=("$line")
    done <<< "$nameoutput"

    if [ "$DEBUG" == "1" ]; then

            # Print the populated array
            echo "Populated Array:"
            for element in "${my_arrayy[@]}"; do
                echo "$element"
            done
    fi

    options=()
    # Print the populated array
    #echo "Populated Array:"
    i=0

    #if [ "$DEBUG" == "1" ]; then

            for element in "${my_arrayy[@]}"; do
                #echo "$element : ${my_array[i]}"
                options+=("$element : ${my_array[i]}")
                i=$((i + 1 ))
            done
    #fi
    #echo $i


    ##################################################################
    #
    #  Select a workspace
    # ( array populated before the function )
    ###################################################################



    echo "Select a workspace"
    echo "Select one option using up/down keys and enter to confirm:"
    echo


    select_option "${options[@]}"
    choice=$?

    echo "Choosen index = $choice"
    echo "        value = ${options[$choice]}"



    # populate the next set of options array

    veracode-http -o .sbom/projects.json "https://api.veracode.com/srcclr/v3/workspaces/${my_array[$choice]}/projects?type=agent"

    if [ "$DEBUG" == "1" ]; then

    cat .sbom/projects.json | jq -r '._embedded.projects' | grep -i '"name":' -F | cut -d '"' -f4

    fi

    # Run the piped commands and store the output in a variable
    idoutput=$(cat .sbom/projects.json | jq -r '._embedded.projects' | grep -i '"id":' | cut -d '"' -f4)

    # Initialize an empty Bash array
    my_array=()



    # Use a while read loop to populate the array
    while IFS= read -r line; do
        my_array+=("$line")
    done <<< "$idoutput"


    if [ "$DEBUG" == "1" ]; then
            # Print the populated array
            echo "Populated Array:"
            for element in "${my_array[@]}"; do
                echo "$element"
            done

    fi

    # Run the piped commands and store the output in a variable
    nameoutput=$(cat .sbom/projects.json | jq -r '._embedded.projects' | grep -i '"name":' | cut -d '"' -f4)

    # Initialize an empty Bash array
    my_arrayy=()

    # Use a while read loop to populate the array
    while IFS= read -r line; do
        my_arrayy+=("$line")
    done <<< "$nameoutput"


    if [ "$DEBUG" == "1" ]; then

            # Print the populated array
            echo "Populated Array:"
            for element in "${my_arrayy[@]}"; do
                echo "$element"
            done
    fi
    options=()
    # Print the populated array

    #echo "Populated Array:"
    i=0
    for element in "${my_arrayy[@]}"; do
        #echo "$element : ${my_array[i]}"
        if [ "$element" == "" ]; then
            echo "No Project Found"
            continue
        fi
        options+=("$element : ${my_array[i]}")
        i=$((i + 1))
    done
    #echo "i:" $i
    if [ "$i" == "0" ]; then
            exit 1
    fi

    echo "Select a project"

    select_option "${options[@]}"
    choice=$?

    echo "Choosen index = $choice"
    echo "        value = ${options[$choice]}"

    #####################################################################
    #
    # Generate Agent Based SBOM
    #
    ######################################################################


    veracode-http -o .sbom/"${my_array[$choice]}".json "https://api.veracode.com/srcclr/sbom/v1/targets/${my_array[$choice]}/cyclonedx?type=agent"

    echo "CycloneDx SBOM written to .sbom/${my_array[$choice]}.json"
    #cd -f
fi
