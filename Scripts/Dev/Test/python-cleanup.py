# Customer developed script

import sys
import requests
from veracode_api_signing.plugin_requests import RequestsAuthPluginVeracodeHMAC
import veracode_api_py

################################################################
# added to include the API helper to make custom rest requests
from veracode_api_py import apihelper
# turn on to run in debug mode
DEBUG = True
vapihelper = apihelper.APIHelper() 
def checkCredentialExpire():
    uri = "https://api.veracode.com/api/authn/v2/api_credentials"
    return vapihelper._rest_request(uri, "GET", use_base_url=False)

#################################################################

vapi = veracode_api_py.VeracodeAPI()
api_base = "https://api.veracode.com/appsec/v1"
xml_base = "https://analysiscenter.veracode.com/api"
headers = {"User-Agent": "Python HMAC Auth"}


# Name: getBuildStatus
# Precondition: if buildInfo contains static analysis scans, parse the build status, otherwise returns str("None")
# Postcondition: returns build status or "None"
def getBuildStatus(buildInfo):
    #print(buildInfo)
    if 'analysis_unit analysis_type="Static"' in buildInfo:
        status = buildInfo.split('analysis_unit analysis_type="Static"', 1)[1].split("status", 1)[1].split('"', 2)[1]
        return status
    else:
        return "None"

# Name: cleanupApp
# Precondition: Provide AppInfo and Veracode AppId
# Postcondition: deletes builds in state incomplete or failed
def cleanupApp(appId,appInfo):
    if ("sandbox_id" not in appInfo):
        print("[INFO]:: No Sandbox ID Present in app: " + str(appId))
    while "sandbox_id" in appInfo:
        appInfo = appInfo.split("sandbox_id", 1)[1]
        sandboxId = appInfo.split('"', 2)[1]
        print("[INFO]:: Status for app: " + str(appId) + ", sandbox: " + str(sandboxId))
        status = getBuildStatus(str(vapi.get_build_info(appId, None, sandboxId)))
        print(str("[INFO]:: Status: " + status))
        if "Incomplete" in status or "Failed" in status:
            print("[DELETE]:: Deleting top build in app: " + str(appId) + ", sandbox: " + str(sandboxId))
            response = delete_build(app_id=appId, sandbox_id=sandboxId)
    return

# Precondition: Provide a dictionary containing the app info
# Postcondition: itterates through the dictionary until it finds a non archived app profile, and then runs a clean up on the list of sandboxes from that app profile
def searchForApp(appInfo):
    if len(appInfo) == 0:
        print("Application name not valid or in Veracode scan results.")
    else:
        counter = 0
        for i in appInfo:
            counter += 1
            currentAppName = i["profile"]["name"]
            if "Archive" not in currentAppName:
                print(currentAppName)
                currentAppInfo = dict(vapi.get_app_by_name(currentAppName)[0])
                cleanupApp(currentAppInfo["id"],str(vapi.get_sandbox_list(currentAppInfo["id"])))

# Name: delete_build
# Precondition: Provide Veracode App ID and or Sandbox ID
# Postcondition: deletes the most recent scan in that application profile or sandbox 
def delete_build(app_id: int, sandbox_id: int = None):
    """Deletes the last build in an application profile or sandbox."""
    if sandbox_id is None:
        params = {"app_id": app_id}
    else:
        params = {"app_id": app_id, "sandbox_id": sandbox_id}
    return veracode_api_py.apihelper.APIHelper()._xml_request(xml_base + "/5.0/deletebuild.do", "GET", params=params)


try:
    #response = requests.get(api_base + "/applications", auth=RequestsAuthPluginVeracodeHMAC(), headers=headers)
    response_body = vapihelper._rest_request(str(api_base + "/applications"),"GET", use_base_url=False )
    
    if DEBUG:
        # checking credentials
        print("[DEBUG]:: Checking API Credentials Expiration")
        print(checkCredentialExpire())

except requests.RequestException as e:
    print("Please ensure API credentials are correct and have not expired")
    print(e)
    sys.exit(1)

if DEBUG:
    print("[DEBUG]:: Response Status: ")

if response_body["_embedded"]:
     appInfo = vapi.get_apps()
     appName = searchForApp(appInfo)
else:
     print("[ERROR]:: There was an error.")
     print(response_body)
