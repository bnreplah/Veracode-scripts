response=$(http --auth-type=veracode_hmac DELETE "https://api.veracode.com/api/authn/v2/teams/$1")
team_id=$1
# Check if the HTTP status code is 200


# Note this is not meant as a replacement of the values from the Admin API but a way to get the Admin API format data from the Rest API




if [[ $response == *"HTTP/1.1 200 OK"* ]]; then
    # Modify the XML with a "success" result
    modified_xml='<?xml version="1.0" encoding="UTF-8"?>
<deleteteamresult xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
xmlns="https://analysiscenter.veracode.com/schema/deleteteamresult" 
xsi:schemaLocation="https://analysiscenter.veracode.com/schema/deleteteamresult 
https://analysiscenter.veracode.com/resource/deleteteamresult.xsd" userlist_version="3.0" account_id="10023" team_id="10243">
  <result>success</result>
</deleteteamresult>'
else
    # Create an XML response with a "failure" result
    modified_xml='<?xml version="1.0" encoding="UTF-8"?>
<deleteteamresult xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
xmlns="https://analysiscenter.veracode.com/schema/deleteteamresult" 
xsi:schemaLocation="https://analysiscenter.veracode.com/schema/deleteteamresult 
https://analysiscenter.veracode.com/resource/deleteteamresult.xsd" userlist_version="3.0" account_id="10023" team_id="'$team_id'">
  <result>failure</result>
</deleteteamresult>'
fi

# Print or use the modified XML as needed
echo "$modified_xml"
#produces no response
