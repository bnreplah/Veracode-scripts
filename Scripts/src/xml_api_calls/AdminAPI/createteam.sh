json_response=$(http --auth-type=veracode_hmac POST "https://api.veracode.com/api/authn/v2/teams" < $1 | cut -d '' -f2 ) 


# Note this is not meant as a replacement of the values from the Admin API but a way to get the Admin API format data from the Rest API


# Parse JSON values
account_id=$(jq -r '.organization.org_id' <<< "$json_response")
team_id=$(jq -r '.team_id' <<< "$json_response")
team_name=$(jq -r '.team_name' <<< "$json_response")
usernames=$(jq -r '.users | join(",")' <<< "$json_response")
creation_date=$(jq -r '.creation_date' <<< "$json_response")

# Use today's date if creation_date is empty
if [[ -z "$creation_date" ]]; then
    creation_date=$(date '+%Y-%m-%d')
fi

# Create XML
xml_output="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<teaminfo xmlns:xsi=\"http&#x3a;&#x2f;&#x2f;www.w3.org&#x2f;2001&#x2f;XMLSchema-instance\" 
  xmlns=\"https&#x3a;&#x2f;&#x2f;analysiscenter.veracode.com&#x2f;schema&#x2f;teaminfo&#x2f;3.0\" 
  xsi:schemaLocation=\"https&#x3a;&#x2f;&#x2f;analysiscenter.veracode.com&#x2f;schema&#x2f;teaminfo&#x2f;3.0 
  https&#x3a;&#x2f;&#x2f;analysiscenter.veracode.com&#x2f;resource&#x2f;3.0&#x2f;teaminfo.xsd\" teaminfo_version=\"3.1\" 
  account_id=\"$account_id\" team_id=\"$team_id\" team_name=\"$team_name\" creation_date=\"$creation_date\">
   <users usernames=\"$usernames\"/>
</teaminfo>"

# Print the XML
echo "$xml_output"