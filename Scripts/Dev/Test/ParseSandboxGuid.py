import ParseAppGuid
from ParseAppGuid import json, veracodeAPI 

########### DEBUG ############
DEBUG=ParseAppGuid.DEBUG
VERBOSE=ParseAppGuid.VERBOSE
######## END DEBUG ###########


if(ParseAppGuid.DEBUG):
    test_sandbox_name="github-verademo"
    test_application_guid=ParseAppGuid.getAppGuid(ParseAppGuid.test_app_name)
    
    print("Found Application GUID: " + test_application_guid)

# if(ParseAppGuid.DEBUG):
#     test_sandbox_name

veracodeAPI.get_app_sandboxes(ParseAppGuid.getAppGuid(ParseAppGuid.test_app_name))

def getSandboxGuid(sandboxName, application_guid):
    sandboxGuid = None
    response=veracodeAPI.get_app_sandboxes(application_guid)
    # TODO: loop through all if there are more than one item in the response
    if(ParseAppGuid.DEBUG):
        print("[DEBUG]:: Return array length from API: " + str(len(response)) + " Sandboxes found ")
       
    for item in response:
        response_json=item
        data_obj=json.dumps(response_json)
        data = json.loads(data_obj)
        if(data['name'] == sandboxName):
            sandboxGuid=data['guid']            
    #data = 
        if(ParseAppGuid.DEBUG and ParseAppGuid.VERBOSE):
            print(item)
            print(data['name'])
            print("Found Sandbox GUID: " + sandboxGuid)
    
    return sandboxGuid

if(DEBUG):
    debugFound = getSandboxGuid(test_sandbox_name, test_application_guid)
    print("Found Sandbox GUID: " + debugFound)
    print("Sandbox Name: " + test_sandbox_name + " GUID: " + debugFound)
