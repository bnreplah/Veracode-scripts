json_response=$( http --auth-type=veracode_hmac "https://api.veracode.com/api/authn/v2/users" | cut -d '' -f2 )

# Note this is not meant as a replacement of the values from the Admin API but a way to get the Admin API format data from the Rest API

# Extract account_id and usernames from the JSON response
account_id=$(echo "$json_response" | jq -r '._embedded.users[0].user_id')
usernames=$(echo "$json_response" | jq -r '._embedded.users[].email_address' | tr '\n' ',' | sed 's/,$//')

# Construct the XML
xml_output="<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
xml_output+="<userlist xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\""
xml_output+=" xmlns=\"https://analysiscenter.veracode.com/schema/userlist/3.0\""
xml_output+=" xsi:schemaLocation=\"https://analysiscenter.veracode.com/schema/userlist/3.0 https://analysiscenter.veracode.com/resource/3.0/userlist.xsd\""
xml_output+=" userlist_version=\"3.0\""
xml_output+=" account_id=\"$account_id\">"
xml_output+="<filters/>"
xml_output+="<users usernames=\"$usernames\"/>"
xml_output+="</userlist>"

# Print the XML
echo "$xml_output"