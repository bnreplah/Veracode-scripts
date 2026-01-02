#!/bin/bash


# Check if a CSV file is provided
if [ -z "$1" ]; then
    echo "Please provide a CSV file."
    exit 1
fi

# Check if the provided CSV file exists
if [ ! -f "$1" ]; then
    echo "CSV file '$1' not found."
    exit 1
fi

# Read values from the CSV file and execute the command alias over each value
while IFS=, read -r value; do
     docker run -t -v "$HOME/.veracode:/.veracode" antfie/scan_health:latest -action health -sast "$value"
done < "$1"
