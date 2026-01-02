#!/bin/bash



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

# Import, run, or utilize the veracode installer script if needed
#

source ./installer-scripts/Veracode-installer.sh

# Add a module loader as a part of the Veracode-installer
# call the module loader, to then load an array, the array then appends those to a modules.sh which is included
# this file must be protected



# Precondition:
# Postcondition:
install_veracode_cli(){
    if program_exists "veracode"; then
        if [ "$DEBUG" == "true" ]; then
            echo "[DEBUG=$DEBUG]:: veracode cli already exists in the execution path."
        fi
        echo "Veracode-Cli Location: $( which veracode )"
    else
        echo "[INFO]:: Veracode CLI wasn't found in the execution path, installing..."
        curl -fsS https://tools.veracode.com/veracode-cli/install | sh
        move_to_path ./veracode
    fi
    # check with the documentation to see if this is still valid
    echo "[INFO]:: Running veracode Configure, Configure the CLI"
    if `veracode configure`; then # expirimental
        echo "Succesfully configured Veracode CLI"
    else
        echo "Error: There was an errror when configuring the Veracode CLI" 
    fi
    
}

# Step one: See that all the needed inputs are provided




# Step two: Look at the repo, directory, or container, and determine what is present





# Step three: Determine what is needed to be done to get the enviornment up to speed




# Step four: Determine which possible options are needed for compilation




# Step five: Default to the easiest, but be able to roll over to run all of them to see which one works




# Step six: upon build, determine the size, and the scope, provide a multipronged scan




# Step seven: produce the results in a variety of formats




# Step eight: produce the results in a convertable way ( be able to import and convert )






# Hook phylum into here as well





