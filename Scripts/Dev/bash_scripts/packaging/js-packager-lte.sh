#!/bin/bash
# GPT Created script
# Check if directory argument is provided
if [ -z "$1" ]; then
    echo "Please provide the directory path as an argument."
    exit 1
fi

# Set the directory to zip
directory="$1"
zip_file="${directory}.zip"

# Set file extensions to search for
extensions="ASP CSS EHTML ES ES6 HANDLEBARS HBS HJS HTM HTML JS JSX JSON JSP MAP MUSTACHE PHP TS TSX VUE XHTML"
include_lock_files=false
include_bower=false

# Check if package-lock.json or npm-shrinkwrap.json is present
if [ -f "$directory/package-lock.json" ]; then
    include_lock_files=true
fi

if [ -f "$directory/npm-shrinkwrap.json" ]; then
    include_lock_files=true
fi

# Check if yarn.lock is present
if [ -f "$directory/yarn.lock" ]; then
    include_lock_files=true
fi

# Check if bower_components directory and bower.json is present
if [ -d "$directory/bower_components" ]; then
    include_bower=true
    if [ -f "$directory/bower.json" ]; then
        include_lock_files=true
    fi
fi

# Prepare file list to be zipped
file_list=""
for ext in $extensions; do
    file_list="$file_list *.$ext"
done

# Include lock files if needed
if [ "$include_lock_files" = true ]; then
    file_list="$file_list package-lock.json npm-shrinkwrap.json yarn.lock"
fi

# Include bower components if needed
if [ "$include_bower" = true ]; then
    file_list="$file_list bower_components"
fi

# Zip the files
echo "Zipping files..."
zip -r "$zip_file" $file_list "$directory"

echo "Zip completed."
