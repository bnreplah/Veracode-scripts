json_input=$( http --auth-type=veracode_hmac "https://api.veracode.com/api/authn/v2/teams" | cut -d '' -f2 )

# Note this is not meant as a replacement of the values from the Admin API but a way to get the Admin API format data from the Rest API

# # Define XML header
# xml_header='<?xml version="1.0" encoding="UTF-8"?>'

# # Define the XML schema namespace and schemaLocation
# xml_namespace='xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="https://analysiscenter.veracode.com/schema/teamlist/3.0" xsi:schemaLocation="https://analysiscenter.veracode.com/schema/teamlist/3.0 https://analysiscenter.veracode.com/resource/3.0/teamlist.xsd" teamlist_version="3.0" account_id="<account id>"'

# # Extract team information from JSON and convert to XML
# xml_teams=$(jq -r '.["_embedded"]["teams"][] | "<team team_id=\"" + .["team_id"] + "\" team_name=\"" + .["team_name"] + "\" creation_date=\"09&#x2f;06&#x2f;2019\"/>"' <<< "$json_input")

# # Create the final XML output
# xml_output="<teamlist $xml_namespace>$xml_teams</teamlist>"

# # Print the XML output
# echo "$xml_header" 
# echo "$xml_output" 

# echo "$xml_header" | tee teamlist.do.xml
# echo "$xml_output" | tee teamlist.do.xml


# Define XML header
xml_header='<?xml version="1.0" encoding="UTF-8"?>'

# Define the XML schema namespace and schemaLocation
xml_namespace='xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="https://analysiscenter.veracode.com/schema/teamlist/3.0" xsi:schemaLocation="https://analysiscenter.veracode.com/schema/teamlist/3.0 https://analysiscenter.veracode.com/resource/3.0/teamlist.xsd" teamlist_version="3.0"'

# Extract the account_id from org_id
org_id=$(jq -r '.["_embedded"]["teams"][0]["organization"]["org_id"]' <<< "$json_input")
account_id="${org_id%-*}"

# Extract team information from JSON and convert to XML with the provided creation_date values
xml_teams=$(jq -r '.["_embedded"]["teams"][] | "<team team_id=\"" + .["team_id"] + "\" team_name=\"" + .["team_name"] + "\" creation_date=\"" + .["creation_date"] + "\" team_legacy_id=\"" + (.["team_legacy_id"] | tostring) + "\"/>"' <<< "$json_input")

# Create the final XML output
xml_output="<teamlist $xml_namespace account_id=\"$account_id\">$xml_teams</teamlist>"

# Print the XML output
echo "$xml_header" "$xml_output" | tee getteams.do.xml