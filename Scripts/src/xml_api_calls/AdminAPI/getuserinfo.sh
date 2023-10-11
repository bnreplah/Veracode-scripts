
# Note this is not meant as a replacement of the values from the Admin API but a way to get the Admin API format data from the Rest API

json=$(http --auth-type=veracode_hmac https://api.veracode.com/api/authn/v2/users/$1 | cut -d '' -f2 )

# Replace special XML characters with their entities
function escape_xml() {
    echo "$1" | sed -e 's/&/\&amp;/g' -e 's/"/\&quot;/g' -e "s/'/\&apos;/g" -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

# Parse JSON and generate XML
user_id=$(echo "$json" | jq -r '.user_id')
user_name=$(echo "$json" | jq -r '.user_name')
first_name=$(echo "$json" | jq -r '.first_name')
last_name=$(echo "$json" | jq -r '.last_name')
email_address=$(echo "$json" | jq -r '.email_address')
login_enabled=$(echo "$json" | jq -r '.login_enabled')
teams=$(echo "$json" | jq -r '.teams[0].team_name')
roles=$(echo "$json" | jq -r '.roles[].role_name' | tr '\n' ',' | sed 's/,$//')  # Comma-delimited roles

# Generate XML output
cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<userinfo xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="https://analysiscenter.veracode.com/schema/userinfo/3.0" xsi:schemaLocation="https://analysiscenter.veracode.com/schema/userinfo/3.0 https://analysiscenter.veracode.com/resource/3.0/userinfo.xsd" userinfo_version="3.0" username="$(escape_xml "$user_name")">
   <login_account first_name="$(escape_xml "$first_name")" last_name="$(escape_xml "$last_name")" login_account_type="user" email_address="$(escape_xml "$email_address")" login_enabled="$login_enabled" teams="$(escape_xml "$teams")" roles="$(escape_xml "$roles")"/>
</userinfo>
EOF