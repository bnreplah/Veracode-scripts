import veracode_api_py
import json
from urllib import parse
from uuid import UUID 
from veracode_api_py.apihelper import APIHelper
from veracode_api_py.constants import Constants


vAPI = veracode_api_py.VeracodeAPI()
vSCA = veracode_api_py.Workspaces()
class Project():
     sca_base_url = "srcclr/v3/workspaces"
     sca_project_url = "/projects"
     sca_global_issues_url = "srcclr/v3/issues"   
     sca_global_vulnerabilities_url = "srcclr/v3/vulnerabilities"
     sca_global_libraries_url = "srcclr/v3/libraries"
     sca_issues_url = "/issues"
     workspaceGUID = ""
     projectGUID = ""

     def setWorkspaceGUID(self, workspace_guid: UUID or str):
         self.workspaceGUID = workspace_guid
          
     def get_self(self):
         pass
         #get_project

     def get_vulnerabilities(self):
         pass
        
     # check to see if a library is present and returns the data around the library 
     def is_library_present(self):
         pass
     
     def get_projects_by_name(self,name: str, workspace_guid: UUID or str = None):
          if workspace_guid:
            self.workspaceGUID = workspace_guid
            #Does a name filter on the workspaces list. Note that this is a partial match. Only returns the first match
            name = parse.quote(name) #urlencode any spaces or special characters
            request_params = {'filter[projects]': name}
            return APIHelper()._rest_paged_request( self.sca_base_url + "/" + str(self.workspaceGUID) + self.sca_project_url ,"GET",params=request_params,element="projects")
          elif (not workspace_guid and self.workspaceGUID != ""):
            name = parse.quote(name) #urlencode any spaces or special characters
            request_params = {'filter[projects]': name}
            return APIHelper()._rest_paged_request( self.sca_base_url + "/" + str(self.workspaceGUID) + self.sca_project_url ,"GET",params=request_params,element="projects")
          else:
            # TODO: add more of an error response
            print("Error: No workspace ID")
            #error
            return 1
     
     def get_issues(self,name: str):
          pass
     
     
     def get_libraries(self,name: str):
          pass
     
     
     
     def get_vulnerabilities(self,name: str):
          pass
     
     def get_scans(self):
          pass
     
     def get_scan(self):
         pass

     def get_opened_in_scan(self, scanid:UUID):
         pass
