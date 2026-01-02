#!/env/python

import json
#import csv
import veracode_api_py
from veracode_api_py import apihelper
import subprocess
import os
vApiHelper = apihelper.APIHelper()
veracodeAPI = veracode_api_py.VeracodeAPI()


VERACODE_API_KEY_ID="5c09a399c711809cbe8e89b8702909d3" #os.getenv('VERACODE_API_KEY_ID')
VERACODE_API_KEY_SECRET="735c138eb32581884435ba1caed052fcb712c287449a6693c9e19bfde8e30906e3957e6d81626f11b6d6fb2a236a5f17e68c98cf6b2b57b059752a9065e8ad8d" #os.getenv('VERACODE_API_KEY_SECRET')

find_workspace_name="General Workspace (001)"
t_find_workspace_slug="jppF8bMA"


found_workspace_slug=None
proj_build_loc=""
proj_root_loc=""

teams_names=["Demo Team"]
matched_teams=[]
teams=[]

# parallel arrays
workspaces_ids=[]
workspaces_site_ids=[]
workspaces_names=[]

workspaces = veracodeAPI.get_workspaces()

for workspace in workspaces:
    print(workspace['id'])
    workspaces_ids.append(workspace['id'])
    workspaces_site_ids.append(workspace['site_id'])
    workspaces_names.append(workspace['name'])
    if workspace['name'] is find_workspace_name:
        found_workspace_slug=workspace['site_id']


#TODO: Grab the teams to add to the workspace
teams=veracodeAPI.get_teams()

for team in teams:
    print(team['team_id'])
    # need to add a match or searching function here        
    # add matched_teams if match is found
    # compare against the teams_names list
    # if the required field to add a team to a workspace is one at a time or all at once


# if the workspace slug is none
if found_workspace_slug is None:
    created_workspace=None  # initialize the created_workspace
    created_workspace=veracodeAPI.create_workspace(find_workspace_name) # sets the response of the created workspace
    
    # if create_workspace doesn't return the created workspace, then grab the workspace from the list
    
    new_workspace=veracodeAPI.get_workspace_by_name(find_workspace_name)
    
    # grab the details around the newly updated workspace
    
    # parse out the guid of the workspace

    # query through the teams for 
    # TODO: add logic to handle more than one value in the matched name
    new_workspace_teams=veracodeAPI.get_workspace_teams((new_workspace[0])['id'])
    found_workspace_slug=(new_workspace[0])['site_id']

    #found_workspace_slug=created_workspace['site_id']
    #TODO: add logic to check the matched workspace, and cross check against the team list
    #TODO: if there are multiple matches, added logic to determine, and handle
    #TODO: Add new teams to the workspace based of the list if not found
    #TODO: look for matching teams/ app names / should match meta data or giturl
    #TODO: Auto link to app matching if set to true 
    #veracodeAPI.add_workspace_team()

print(found_workspace_slug)

# TODO: add parameters that either replicate SRCCLR calls in the python or use the SRCCLR call diretly in the OS
# by running os level commands


# result = subprocess.run(
#     ["srcclr", "scan",proj_build_loc ,"--ws", found_workspace_slug, "--recursive"],          # Command as a list
#     capture_output=True,   # Captures stdout and stderr
#     text=True,             # Decodes output as a string (Python 3.5+)
#     check=True             # Raises an exception if the command fails
# )

## Testing out if the subprocess runs properly
result = subprocess.run(
    ["srcclr", "--help"],          # Command as a list
    capture_output=True,   # Captures stdout and stderr
    text=True,             # Decodes output as a string (Python 3.5+)
    check=True             # Raises an exception if the command fails
)

print(result.stdout)
