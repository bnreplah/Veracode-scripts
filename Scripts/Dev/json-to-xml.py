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

DEPR = "Deprecated"
CDEBUG = True

class ApiTeams:
    def __init__(self):
        self.team_id = str()
        self.team_legacy_id = str()
        self.team_name = str()
        self.business_unit = str()
        self.bu_id = str()
        self.organization = str()
        self.org_id = str()
        self.org_legacy_id = str()
        self.member_only = str()
        self._links = []
        
    def set_team_id(self,atc):
        self.team_id = atc

    def set_team_legacy_id(self,alc):
        self.team_legacy_id = alc
    
    def set_team_name(self,anc):
        self.team_name = anc

    def set_business_unit(self,abc):
        self.business_unit = abc

    def set_organization(self,aoc):
        self.organization = aoc

    def set_member_only(self,amc):
        self.member_only = amc
   
    def getteaminfolist(self):
        teaminfo_schema = '''<teamlist xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="https://analysiscenter.veracode.com/schema/teamlist/3.0" xsi:schemaLocation="https://analysiscenter.veracode.com/schema/teamlist/3.0 https://analysiscenter.veracode.com/resource/3.0/teamlist.xsd" teamlist_version="3.0" account_id="'''+str(self.org_legacy_id)+'''" org_id="'''+str(self.org_id)+'''" organization="'''+str(self.organization)+'''"><team team_id="'''+str(self.team_id)+'''" team_name="'''+str(self.team_name)+'''" creation_date="[Deprecated]"/></teamlist>'''
        return teaminfo_schema

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
    #    self.roles = apiRoles
        self._links = []
        self.user_id = str()
        self.user_info = [] 
        self.organization = str()
        self.org_id = str()
        self.org_name = str() 
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
        
    def set_login_enabled(self, loginEnabled):
        self.login_enabled = loginEnabled

    def set_saml(self, saml):
        self.saml = saml

    def set_teams(self, teams):
        self.teams = teams

    

    def getuserinfoxml(self):
        
        userinfo_schema = '''<userinfo xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="https://analysiscenter.veracode.com/schema/userinfo/3.0" xsi:schemaLocation="https://analysiscenter.veracode.com/schema/userinfo/3.0 https://analysiscenter.veracode.com/resource/3.0/userinfo.xsd" userinfo_version="3.0" username="'''+str(self.username)+'''"> <login_account first_name="'''+str(self.first_name)+'''" last_name="'''+str(self.last_name)+'''" login_account_type="'''+str(self.login_account_type)+'''" email_address="'''+str(self.email_address)+'''" phone="[deprecated]" login_enabled="'''+str(self.login_enabled)+'''" requires_token="[deprecated]" teams="'''+str(self.teams) +'''" roles="'''+ str(self.roles) +'''" is_elearning_manager="[deprecated]" elearning_manager="[deprecated]" elearning_track="[deprecated]" elearning_curriculum="[deprecated]" keep_elearning_active="[deprecated]"/> </userinfo>'''

        return userinfo_schema
        
#dict_keys(['role_id', 'role_legacy_id', 'role_name', 'role_description', 'is_internal', 'assigned_to_proxy_users', 'team_admin_manageable', 'jit_assignable', 'jit_assignable_default', 'is_api', 'is_scan_type', '_links'])


class ApiRole:
    def __init__(self):
#       self.role_dict = {'role_id':"",
#                          'role_legacy_id':"",
#                          'role_name':"",
#                          'role_description':"",
#                          'is_internal':"",
#                          'assigned_to_proxy_users':"",
#                          'team_admin_manageable':"",
#                          'jit_assignable':"",
#                          'jit_assignable_default':"",
#                          'is_api':"",
#                          'is_scan_type':"",       
#                          '_links':""}

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

        

users = json.dumps(veracodeAPI.get_users())
users_parsed = json.loads(users)
#temp_user.user_info = json.loads(json.dumps(veracodeAPI.get_user(temp_user.user_id)))
#dict_keys(['user_id', 'user_legacy_id', 'user_name', 'email_address', 'saml_user', 'login_enabled', '_links'])

teams = json.dumps(veracodeAPI.get_teams())
teams_parsed = json.loads(teams)
#dict_keys(['team_id', 'team_legacy_id', 'team_name', 'business_unit', 'organization', 'member_only', '_links'])

roles = json.dumps(veracodeAPI.get_roles())
roles_parsed = json.loads(roles)
#dict_keys(['role_id', 'role_legacy_id', 'role_name', 'role_description', 'is_internal', 'assigned_to_proxy_users', 'team_admin_manageable', 'jit_assignable', 'jit_assignable_default', 'is_api', 'is_scan_type', '_links'])


apiTeams = []
apiUsers = []
apiRoles = []


#dict_keys(['role_id', 'role_legacy_id', 'role_name', 'role_description', 'is_internal', 'assigned_to_proxy_users', 'team_admin_manageable', 'jit_assignable', 'jit_assignable_default', 'is_api', 'is_scan_type', '_links'])

for k in roles_parsed:
    temp_roles = ApiRole()
    temp_roles.role_id = k['role_id']
    temp_roles.role_legacy_id = k['role_legacy_id']
    temp_roles.role_name = k['role_name']
    temp_roles.role_description = k['role_description']
    temp_roles.is_internal = k['is_internal']
    temp_roles.assigned_to_proxy_users = k['assigned_to_proxy_users']
    temp_roles.team_admin_manageable = k['team_admin_manageable']
    temp_roles.jit_assignable = k['jit_assignable']
    temp_roles.jit_assignable_default = k['jit_assignable_default']
    temp_roles.is_api = k['is_api']
    temp_roles.is_scan_type = k['is_scan_type']
    temp_roles._links = k['_links']
    apiRoles.append(temp_roles)


for j in teams_parsed:
    temp_teams = ApiTeams()
    temp_teams.team_id = j['team_id']
    temp_teams.team_legacy_id = j['team_legacy_id']
    temp_teams.team_name = j['team_name']
    #temp_teams.business_unit = j['business_unit']
    temp_teams.organization = j['organization']['org_name']
    temp_teams.org_id = j['organization']['org_id']
    temp_teams.org_legacy_id = j['organization']['org_legacy_id']
    temp_teams.member_only = j['member_only']
    temp_teams._links = list(j['_links'])
    apiTeams.append(temp_teams)


for i in users_parsed:
    temp_user = ApiUser()
    temp_user.user_id = i['user_id']
    temp_user.user_info = json.loads(json.dumps(veracodeAPI.get_user(temp_user.user_id)))
    temp_user.first_name = temp_user.user_info['first_name']
    temp_user.last_name = temp_user.user_info['last_name']
    #temp_user. = i['user_legacy_id']
    temp_user.username = i['user_name']
    temp_user.email_address = i['email_address']
    temp_user.saml = i['saml_user']
    temp_user.login_enabled = i['login_enabled']
#    temp_user.roles = i['roles']
    temp_user._links = list(i['_links'])
    
    apiUsers.append(temp_user)


veracodeAPI.get_teams()
veracodeAPI.get_business_units()
veracodeAPI.get_roles()
veracodeAPI.get_users()
