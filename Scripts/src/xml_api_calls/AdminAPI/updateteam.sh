json_input=$( http --auth-type=veracode_hmac PUT "https://api.veracode.com/api/authn/v2/teams/7cc821b9-aa04-40dd-915e-f4f51496e16c?partial=true" < $1 | cut -d '' -f2 )

# Extract data from JSON
org_id=$(echo "$json_input" | jq -r '.organization.org_id')
team_id=$(echo "$json_input" | jq -r '.team_id')
team_name=$(echo "$json_input" | jq -r '.team_name')
users=$(echo "$json_input" | jq -r '.users | join(",")')
creation_date=$(echo "$json_input" | jq -r '.creation_date')

# Generate the XML
xml_output="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<teaminfo xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"https://analysiscenter.veracode.com/schema/teaminfo/3.0\" xsi:schemaLocation=\"https://analysiscenter.veracode.com/schema/teaminfo/3.0 https://analysiscenter.veracode.com/resource/3.0/teaminfo.xsd\" teaminfo_version=\"3.1\" account_id=\"$org_id\" team_id=\"$team_id\" team_name=\"$team_name\" creation_date=\"$creation_date\">
   <users usernames=\"$users\"/>
</teaminfo>"

echo "$xml_output"