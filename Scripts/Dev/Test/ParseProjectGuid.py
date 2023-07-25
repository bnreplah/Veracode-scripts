import veracode_api_py
from veracode_api_py import apihelper
import json

vApiHelper = apihelper.APIHelper()
veracodeAPI = veracode_api_py.VeracodeAPI()


DEBUG = True
VERBOSE = True

def getWorkspaceGuid(workspaceName: str):
    response = veracodeAPI.get_workspace_by_name(workspaceName)
    if(DEBUG and VERBOSE): print(response)
    response_json=response[0]
    data_obj=json.dumps(response_json)
    data = json.loads(data_obj)
    if(DEBUG and VERBOSE):
        print(response[0])
        print(data['id'])
        print("There are " + str(data['projects_count']) + " Projects in the workspace")
        print("Workspace Slug: " + str(data['site_id']))
    wrkspc_guid=data['id']
    return wrkspc_guid #data['guid']

def listProjects(workspaceGuid):
    response = veracodeAPI.get_projects(workspaceGuid)
    if(DEBUG and VERBOSE): print(response)
    projectNames = []
    projectIds = []
    for project in response:
        data_obj = json.dumps(project)
        data = json.loads(data_obj)
        if(DEBUG): print(str(data['id']) + ":::" + str(data['name']))
        if(data['id'] is not None):
            projectIds.append(data['id'])
            projectNames.append(data['name'])
    return (projectIds, projectNames)



if(DEBUG):
    print(listProjects(getWorkspaceGuid("Demo 004")))



    
