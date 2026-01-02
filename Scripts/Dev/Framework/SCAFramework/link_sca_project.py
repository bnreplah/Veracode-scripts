## !python
## Author: Thomas Saekao (CSE) [@tsaekao]
## Maintained by: Ben Halpern (CSE) [@bnreplah]
## Program Description:
# This is a simple python script that will link an SCA Agent-Based Scan project to a Veracode application profile
# The 5 parameters needed are the SCA Workspace name, SCA Project name, application profile name, and Veracode API ID and API Key
# It also uses the Veracode python API signing library for HMAC authentication, which is needed to use the APIs

import time
import requests
import uuid
import argparse
from veracode_api_signing.plugin_requests import RequestsAuthPluginVeracodeHMAC

def make_api_request(base_url, endpoint, method, api_id, api_key):
    url = f"{base_url}{endpoint}"
    
    # Prepare headers
    headers = {
        "x-request-timestamp": str(int(time.time())),
        "x-request-nonce": str(uuid.uuid4()),
        "Content-Type": "application/json"
    }

    # Create the HMAC Auth object using Veracode's signing library
    auth = RequestsAuthPluginVeracodeHMAC(api_key_id=api_id, api_key_secret=api_key)
    
    # check headers and URL
    print(f"Request URL: {url}")
    print(f"Headers: {headers}")

    # Make the API request
    response = requests.request(method, url, headers=headers, auth=auth)
    
    # check the response
    print(f"Response Status Code: {response.status_code}")
    print(f"Response Body: {response.text}")

    response.raise_for_status()  # this will raise the HTTPError for 400s and 500s
    return response.json()

# This function will get the workspace GUID of the workspace name passed in
def get_workspace_guid(base_url, workspace_name, api_id, api_key):
    endpoint = "/srcclr/v3/workspaces"
    data = make_api_request(base_url, endpoint, "GET", api_id, api_key)
    
    # Access the list of workspaces
    workspaces = data['_embedded']['workspaces']
    
    for workspace in workspaces:
        if workspace['name'] == workspace_name:
            return workspace['id']
    
    raise ValueError(f"Workspace with name {workspace_name} not found")

# This function will get the project GUID of the project named passed in
def get_project_guid(base_url, workspace_guid, project_name, api_id, api_key):
    endpoint = f"/srcclr/v3/workspaces/{workspace_guid}/projects"
    data = make_api_request(base_url, endpoint, "GET", api_id, api_key)
    
    # Access the list of projects
    projects = data['_embedded']['projects']
    
    for project in projects:
        if project['name'] == project_name:
            return project['id']
    
    raise ValueError(f"Project with name {project_name} not found in workspace {workspace_guid}")

# This function will get the application profile GUID of the application profile name passed in.
def get_app_guid(base_url, appname, api_id, api_key):
    endpoint = "/appsec/v1/applications"
    data = make_api_request(base_url, endpoint, "GET", api_id, api_key)
    
    if '_embedded' in data and 'applications' in data['_embedded']:
        applications = data['_embedded']['applications']
        for app in applications:
            if app['profile']['name'] == appname:
                return app['guid']
    raise ValueError(f"Application with name {appname} not found")

# This will link the SCA project to application profile
def link_sca_project(base_url, app_guid, project_guid, api_id, api_key):
    endpoint = f"/srcclr/v3/applications/{app_guid}/projects/{project_guid}"
    data = {}  
    
    headers = {
        "Content-Type": "application/json"
    }
    
    auth = RequestsAuthPluginVeracodeHMAC(api_key_id=api_id, api_key_secret=api_key)
    
    response = requests.put(f"{base_url}{endpoint}", headers=headers, json=data, auth=auth)
    
    # check responses
    print(f"Response Status Code: {response.status_code}")
    print(f"Response Body: {response.text}")
    
    response.raise_for_status()  # this will raise an HTTPError for bad responses
    print("SCA Project linked to Application Profile")

###########################################################################################################
# main Driver:

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Link an SCA project to a Veracode application profile.')
    parser.add_argument('--workspace_name', required=True, help='The name of the SCA workspace')
    parser.add_argument('--project_name', required=True, help='The name of the SCA project')
    parser.add_argument('--application_profile', required=True, help='The name of the application profile')
    parser.add_argument('--api_id', required=True, help='The Veracode API ID for authentication')#TODO: change to optional and read from credentials file if present
    parser.add_argument('--api_key', required=True, help='The Veracode API Key for authentication')#TODO: change to optional and read from credentials file if present

    args = parser.parse_args()
    #TODO: Add the ability to change the region, or determine the region from the API keys
    #TODO: Add error handling
    base_url = "https://api.veracode.com"

    # Get workspace GUID
    workspace_guid = get_workspace_guid(base_url, args.workspace_name, args.api_id, args.api_key)
    print(f"Workspace GUID: {workspace_guid}")

    # Get project GUID
    project_guid = get_project_guid(base_url, workspace_guid, args.project_name, args.api_id, args.api_key)
    print(f"Project GUID: {project_guid}")

    # Get application profile GUID
    app_guid = get_app_guid(base_url, args.application_profile, args.api_id, args.api_key)
    print(f"Application GUID: {app_guid}")

    # Link the project to the application profile
    link_sca_project(base_url, app_guid, project_guid, args.api_id, args.api_key)

