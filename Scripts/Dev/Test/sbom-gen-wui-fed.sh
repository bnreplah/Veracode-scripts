#!/bin/bash


shopt -s expand_aliases
# alias
alias 'veracode-http'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-signing:cmd'
DEBUG=0
# Run the piped commands and store the output in a variable
veracode-http -o workspaces.json "https://api.veracode.us/srcclr/v3/workspaces"
idoutput=$(cat workspaces.json | jq -r '._embedded.workspaces' | grep -i '"id":' | cut -d '"' -f4)

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
nameoutput=$(cat workspaces.json | jq -r '._embedded.workspaces' | grep -i '"name":' | cut -d '"' -f4)

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


# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
function select_option {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   %s""$1"  2>/dev/null; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"  2>/dev/null; }
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

echo "Select a workspace"
echo "Select one option using up/down keys and enter to confirm:"
echo


select_option "${options[@]}"
choice=$?

echo "Choosen index = $choice"
echo "        value = ${options[$choice]}"

veracode-http -o projects.json "https://api.veracode.us/srcclr/v3/workspaces/${my_array[$choice]}/projects?type=agent"

if [ "$DEBUG" == "1" ]; then

cat projects.json | jq -r '._embedded.projects' | grep -i '"name":' -F | cut -d '"' -f4

fi

# Run the piped commands and store the output in a variable
idoutput=$(cat projects.json | jq -r '._embedded.projects' | grep -i '"id":' | cut -d '"' -f4)

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
nameoutput=$(cat projects.json | jq -r '._embedded.projects' | grep -i '"name":' | cut -d '"' -f4)

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

veracode-http -o "${my_array[$choice]}".json "https://api.veracode.us/srcclr/sbom/v1/targets/${my_array[$choice]}/cyclonedx?type=agent"

echo "CycloneDx SBOM written to ${my_array[$choice]}.json"