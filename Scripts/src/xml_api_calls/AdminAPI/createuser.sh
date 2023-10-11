#!/bin/bash
debug=true


# Note this is not meant as a replacement of the values from the Admin API but a way to get the Admin API format data from the Rest API

# Initialize variables with default values
custom_id=""
is_saml_user=false
login_enabled=true
phone=""
requires_token=false
teams=""
title=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --first_name)
            first_name="$2"
            shift 2
            ;;
        --last_name)
            last_name="$2"
            shift 2
            ;;
        --email_address)
            email_address="$2"
            shift 2
            ;;
        --roles)
            roles="$2"
            shift 2
            ;;
        --custom_id)
            custom_id="$2"
            shift 2
            ;;
        --is_saml_user)
            is_saml_user=true
            shift
            ;;
        --no_login_enabled)
            login_enabled=false
            shift
            ;;
        --phone)
            phone="$2"
            shift 2
            ;;
        --requires_token)
            requires_token=true
            shift
            ;;
        --teams)
            teams="$2"
            shift 2
            ;;
        --title)
            title="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done



if [ "$debug" == true ]; then

    # Print parsed values
    echo "First Name: $first_name"
    echo "Last Name: $last_name"
    echo "Email Address: $email_address"
    echo "Roles: $roles"
    echo "Custom ID: $custom_id"
    echo "Is SAML User: $is_saml_user"
    echo "Login Enabled: $login_enabled"
    echo "Phone: $phone"
    echo "Requires Token: $requires_token"
    echo "Teams: $teams"
    echo "Title: $title"
fi

json_data=$( http --auth-type=veracode_hmac "https://api.veracode.com/api/authn/v2/users" | cut -d '' -f2 )

# Define the XML header
xml_header='<?xml version="1.0" encoding="UTF-8"?>
<userinfo xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="https://analysiscenter.veracode.com/schema/userinfo/3.0" xsi:schemaLocation="https://analysiscenter.veracode.com/schema/userinfo/3.0 https://analysiscenter.veracode.com/resource/3.0/userinfo.xsd" userinfo_version="3.0" username="rmonarch@example.com">'

# Use jq to extract user data from JSON
user_data=$(echo "$json_data" | jq -c '._embedded.users[]')

# Initialize XML data
xml_data=""

while IFS= read -r user; do
    email_address=$(echo "$user" | jq -r '.email_address')
    first_name=$(echo "$user" | jq -r '.first_name')
    last_name=$(echo "$user" | jq -r '.last_name')
    login_enabled=$(echo "$user" | jq -r '.login_enabled')
    saml_user=$(echo "$user" | jq -r '.saml_user')

    # Construct user XML element
    user_xml="<login_account
        first_name=\"$first_name\"
        last_name=\"$last_name\"
        login_account_type=\"user\"
        email_address=\"$email_address\"
        login_enabled=\"$login_enabled\"
        requires_token=\"false\"  <!-- This attribute is not present in the JSON -->
        teams=\"Demo Team\"  <!-- This attribute is not present in the JSON -->
        roles=\"Creator,eLearning,Submitter,Any Scan\"  <!-- This attribute is not present in the JSON -->
        is_elearning_manager=\"false\"  <!-- This attribute is not present in the JSON -->
        elearning_manager=\"No Manager\"  <!-- This attribute is not present in the JSON -->
        elearning_track=\"No Track Assigned\"  <!-- This attribute is not present in the JSON -->
        elearning_curriculum=\"No Curriculum Assigned\"  <!-- This attribute is not present in the JSON -->
        keep_elearning_active=\"false\"  <!-- This attribute is not present in the JSON -->
    />"

    xml_data+="$user_xml"
done <<< "$user_data"

# Close the XML structure
xml_footer="</userinfo>"

# Combine the XML header, user data, and XML footer
xml_response="$xml_header$xml_data$xml_footer"

# Print the generated XML
echo "$xml_response"