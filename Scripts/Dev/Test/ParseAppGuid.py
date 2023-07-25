import veracode_api_py
from veracode_api_py import apihelper
import json

vApiHelper = apihelper.APIHelper()
veracodeAPI = veracode_api_py.VeracodeAPI()


########### DEBUG ############
DEBUG=True
VERBOSE=False
######## END DEBUG ###########

if(DEBUG):
    test_app_name="Verademo-net"

def getAppGuid(application_name):
    response=veracodeAPI.get_app_by_name(application_name)
    response_json=response[0]
    data_obj=json.dumps(response_json)
    data = json.loads(data_obj)
    #data = 
    if(DEBUG and VERBOSE):
        print(response[0])
        print(data['guid'])
    app_guid=data['guid']
    return app_guid #data['guid']

if(DEBUG and VERBOSE):
    print(getAppGuid(test_app_name))
