#!/bin/bash

# Input CPE string
cpe="cpe:/o:microsoft:windows:10:::home:::"

# Split the CPE into parts using ':' as the delimiter
IFS=':' read -ra parts <<< "$cpe"

# Define the part names
part_names=("Part" "Vendor" "Product" "Version" "Update" "Edition" "Language" "SwEdition" "TargetSW" "TargetHW" "Other")

# Check if it's an application CPE
is_application_cpe() {
  local part_value="${parts[1]}"  # The Vendor part
  if [[ "$part_value" == "/a" ]]; then
    return 0  # It's an application CPE
  else
    return 1  # It's not an application CPE
  fi
}

# Check if it's an application CPE and print information
if is_application_cpe; then
  echo "This is an Application CPE."
  for i in "${!parts[@]}"; do
    part_name="${part_names[$i]}"
    part_value="${parts[$i]}"
    echo "$part_name: $part_value"
  done
else
  echo "This is not an Application CPE."
fi
