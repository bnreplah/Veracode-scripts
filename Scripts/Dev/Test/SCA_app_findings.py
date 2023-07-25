# import veracode_api_py
# from veracode_api_py import apihelper
# vApiHelper = apihelper.APIHelper()
# veracodeAPI = veracode_api_py.VeracodeAPI()

import ParseAppGuid
import ParseSandboxGuid
from ParseAppGuid import veracodeAPI

#######################################################
# Debug
#######################################################
DEBUG = ParseAppGuid.DEBUG
VERBOSE = ParseAppGuid.VERBOSE
TEST_APP_NAME = ParseAppGuid.test_app_name
TEST_SANDBOX_NAME = ParseSandboxGuid.test_sandbox_name
TEST_APP_GUID = ParseAppGuid.getAppGuid(TEST_APP_NAME)
TEST_SANDBOX_GUID = ParseSandboxGuid.getSandboxGuid(TEST_SANDBOX_NAME, TEST_APP_GUID)
if(DEBUG):
    print("[DEBUG]:: TEST APP NAME: " + TEST_APP_NAME)
    print("[DEBUG]:: TEST SANDBOX NAME: " + TEST_SANDBOX_NAME)
    print("[DEBUG]:: TEST APP GUID: " + TEST_APP_GUID )
    print("[DEBUG]:: TEST SANDBOX GUID: " + TEST_SANDBOX_GUID)
#######################################################

# def get_applist():
#     print("Getting Application List")
#     results=veracodeAPI.get_apps()
#     print(results)

# def get_sandboxlist(application_guid):
#     print("Getting Sanbox List")
#     results=veracodeAPI.get_app_sandboxes(application_guid)
#     print(results)

def sca_app(application_guid, sandbox_guid=None):
    print("SCA App findigns")
    if sandbox_guid is not None:
        response=veracodeAPI.get_findings(app=application_guid, scantype='SCA', request_params=None, sandbox=sandbox_guid)
    else:
        response=veracodeAPI.get_findings(app=application_guid, scantype='SCA')
    print("Printing response")    
    print(response)

if(DEBUG):
    print("========================================= Testing without Sandboxid ================================")
    sca_app(TEST_APP_GUID)
    print("========================================== Testing with Sandboxid ====================================")
    sca_app(TEST_APP_GUID, TEST_SANDBOX_GUID)