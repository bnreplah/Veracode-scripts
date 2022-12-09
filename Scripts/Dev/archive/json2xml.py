import os
import json
import re
import veracode_api_py
import veracode_api_signing
from veracode_api_py import apihelper
import csv

vAapiHelper = apihelper
veraApi = veracode_api_py.VeracodeAPI
vApiHelper = apihelper.APIHelper()
veracodeAPI = veracode_api_py.VeracodeAPI()

class ApiBunit:
    def __init__(self):
        pass
class ApiTeams:
    def __init__(self):
        pass

class ApiUser:
    def __init__(self):
        self.first_name = str()
        self.last_name = str()
        self.custom_id = str()
        self.username = str() 
        self.email_address = str()
        self.login_account_type = str()
        self.teams = str()
        self.saml = bool()
        self.login_enabled = bool()
        self.roles = []
        self._links = []
    def set_first_name(self,pfn):
        self.first_name = pfn

    def set_last_name(self,qfn):
        self.last_name = qfn

    def set_custom_id(self,afn):
        self.custom_id = afn

    def set_email_address(self,efn):
        self.email_address = efn

    def set_login_account_type(self,tfn):
        self.login_account_type = tfn

    def set_roles(self, roles):
        self.roles = roles
        
        # dict_keys(['role_id', 'role_legacy_id', 'role_name', 'role_description', 'is_internal', 'assigned_to_proxy_users', 'team_admin_manageable', 'jit_assignable', 'jit_assignable_default', 'is_api', 
#'is_scan_type', '_links'])

    def set_login_enabled(self, loginEnabled):
        self.login_enabled = loginEnabled

    def set_saml(self, saml):
        self.saml = saml

    def set_teams(self, teams):
        self.teams = teams

    def getuserinfoxml(self):
        
        userinfo_schema = '''<userinfo xmlns:xsi="http&#x3a;&#x2f;&#x2f;www.w3.org&#x2f;2001&#x2f;XMLSchema-instance" 
              xmlns="https&#x3a;&#x2f;&#x2f;analysiscenter.veracode.com&#x2f;schema&#x2f;userinfo&#x2f;3.0" 
              xsi:schemaLocation="https&#x3a;&#x2f;&#x2f;analysiscenter.veracode.com&#x2f;schema&#x2f;userinfo&#x2f;3.0 
              https&#x3a;&#x2f;&#x2f;analysiscenter.veracode.com&#x2f;resource&#x2f;3.0&#x2f;userinfo.xsd" userinfo_version="3.0" 
              username="'''+str(self.username)+'''">
           <login_account first_name="'''+str(self.first_name)+'''" last_name="'''+str(self.last_name)+'''" login_account_type="'''+str(self.login_account_type)+'''" 
email_address="'''+str(self.email_address)+'''" 
              phone="[deprecated]" login_enabled="'''+str(self.login_enabled)+'''" requires_token="[deprecated]" teams="'''+str(self.teams) +'''" 
              roles="'''+ str(self.roles) +'''" is_elearning_manager="[deprecated]" elearning_manager="[deprecated]" 
              elearning_track="[deprecated]" elearning_curriculum="[deprecated]" keep_elearning_active="[deprecated]"/>
        </userinfo>'''

        return userinfo_schema
        
       #dict_keys(['role_id', 'role_legacy_id', 'role_name', 'role_description', 'is_internal', 'assigned_to_proxy_users', 'team_admin_manageable', 'jit_assignable', 'jit_assignable_default', 'is_api', 
#'is_scan_type', '_links'])

    
    #users_parsed
    
    #
    #apiUsers.append

    

class ApiLogin:
    def __init__(self):
        pass
class ApiSaml:
    def __init__(self):
        pass

class ApiRoles:
    def __init__(self):
        self.role_dict = {'role_id':"",
                          'role_legacy_id':"",
                          'role_name':"",
                          'role_description':"",
                          'is_internal':"",
                          'assigned_to_proxy_users':"",
                          'team_admin_manageable':"",
                          'jit_assignable':"",
                          'jit_assignable_default':"",
                          'is_api':"",
                          'is_scan_type':"",       
                          '_links':""}

        self.role_id=""
        self.role_legacy_id=""
        self.role_name=""
        self.role_description=""
        self.is_internal=""
        self.assigned_to_proxy_users=""
        self.team_admin_manageable=""
        self.jit_assignable=""
        self.jit_assignable_default=""
        self.is_api=""
        self.is_scan_type=""       
        self._links=""
class ApiEmail:
    def __init__(self):
        pass




#users_parsed[0].keys()
#dict_keys(['user_id', 'user_legacy_id', 'user_name', 'email_address', 'saml_user', 'login_enabled', '_links'])

users = json.dumps(veracodeAPI.get_users())
users_parsed = json.loads(users)

teams = json.dumps(veracodeAPI.get_teams())
teams_parsed = json.loads(teams)

roles = json.dumps(veracodeAPI.get_roles())
roles_parsed = json.loads(roles)

apiUsers = []
for i in users_parsed:
    temp_user = ApiUser()
    temp_user.first_name = i['user_id']
    temp_user.last_name = i['user_legacy_id']
    temp_user.username = i['user_name']
    temp_user.email_address = i['email_address']
    temp_user.saml = i['saml_user']
    temp_user.login_enabled = i['login_enabled']
    temp_user._links = list(i['_links'])
    apiUsers.append(temp_user)


veracodeAPI.get_teams()
veracodeAPI.get_business_units()
veracodeAPI.get_roles()
veracodeAPI.get_users()

