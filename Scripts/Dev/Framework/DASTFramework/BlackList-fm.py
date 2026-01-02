# BlackList-fm.py
#   framework module 
#   Description:
#       This script is for creating and formatting a blacklist for a Veracode Dynamic Web Application Scan
#       It takes a blacklist.csv and glblacklist.csv to configure a blacklist for the URL in question and a global blacklist file
#           if the files are not included or are empty then leaves that blacklist section out of the formatted results
#           the request is written to an input.json file to then be passed to the api to make the request
#   Available Dyanmic API functions:
#   
#   dynamic.py:
#   - setup_auth_config
#   - setup_auth
#   
#   - setup_scan_config_request
#   - setup_scan       
#
# get_analyses(self):
#     return Analyses().get_all()
# get_analyses_by_name(self, name):
#     return Analyses().get_by_name(analysis_name=name)
# get_analyses_by_target_url(self, url):
#     return Analyses().get_by_target_url(target_url=url)
# get_analyses_by_search_term(self, search_term):
#     return Analyses().get_by_search_term(search_term=search_term)
# get_analysis(self, analysis_id: UUID):
#     return Analyses().get(guid=analysis_id)
# get_analysis_audits(self, analysis_id: UUID):
#     return Analyses().get_audits(guid=analysis_id)
# get_analysis_scans(self, analysis_id: UUID):
#     return Analyses().get_scans(guid=analysis_id)
# get_analysis_scanner_variables(self, analysis_id: UUID):
#     return Analyses().get_scanner_variables(guid=analysis_id)
# create_analysis(self, name, scans, business_unit_guid: UUID = None, email=None, owner=None):
#     return Analyses().create(name, scans, business_unit_guid, email, owner)
# update_analysis(self, guid: UUID, name, scans, business_unit_guid: UUID = None, email=None, owner=None):
#     return Analyses().update(guid, name, scans, business_unit_guid, email, owner)
# update_analysis_scanner_variable(self, analysis_guid: UUID, scanner_variable_guid: UUID, reference_key, value,
#                                      description):
#     return Analyses().update_scanner_variable(analysis_guid, scanner_variable_guid, reference_key, value,
#                                               description)
# delete_analysis_scanner_variable(self, analysis_guid: UUID, scanner_variable_guid: UUID):
#     return Analyses().delete_scanner_variable(analysis_guid, scanner_variable_guid)
# delete_analysis(self, analysis_guid: UUID):
#     return Analyses().delete(guid=analysis_guid)
# get_dyn_scan(self, scan_guid: UUID):
#     return Scans().get(guid=scan_guid)
# get_dyn_scan_audits(self, scan_guid: UUID):
#     return Scans().get_audits(guid=scan_guid)
# get_dyn_scan_config(self, scan_guid: UUID):
#     return Scans().get_configuration(guid=scan_guid)
# update_dyn_scan(self, scan_guid: UUID, scan):
#     return Scans().update(guid=scan_guid, scan=scan)
# delete_dyn_scan(self, scan_guid: UUID):
#     return Scans().delete(guid=scan_guid)
# get_scan_scanner_variables(self, scan_id: UUID):
#     return Scans().get_scanner_variables(guid=scan_id)
# update_scan_scanner_variable(self, scan_guid: UUID, scanner_variable_guid: UUID, reference_key, value,
#                                  description):
#     return Scans().update_scanner_variable(scan_guid, scanner_variable_guid, reference_key, value, description)
# delete_scan_scanner_variable(self, scan_guid: UUID, scanner_variable_guid: UUID):
#     return Scans().delete_scanner_variable(scan_guid, scanner_variable_guid)
# get_analysis_occurrences(self):
#     return Occurrences().get_all()
# get_analysis_occurrence(self, occurrence_guid: UUID):
#     return Occurrences().get(guid=occurrence_guid)
# stop_analysis_occurrence(self, occurrence_guid: UUID, save_or_delete):
#     return Occurrences().stop(guid=occurrence_guid, save_or_delete=save_or_delete)
# get_scan_occurrences(self, occurrence_guid: UUID):
#     return Occurrences().get_scan_occurrences(guid=occurrence_guid)
# get_scan_occurrence(self, scan_occ_guid: UUID):
#     return ScanOccurrences().get(guid=scan_occ_guid)
# stop_scan_occurrence(self, scan_occ_guid: UUID, save_or_delete):
#     return ScanOccurrences().stop(guid=scan_occ_guid, save_or_delete=save_or_delete)
# get_scan_occurrence_configuration(self, scan_occ_guid: UUID):
#     return ScanOccurrences().get_configuration(guid=scan_occ_guid)
# get_scan_occurrence_verification_report(self, scan_occ_guid: UUID):
#     return ScanOccurrences().get_verification_report(guid=scan_occ_guid)
# get_scan_occurrence_notes_report(self, scan_occ_guid: UUID):
#     return ScanOccurrences().get_scan_notes_report(guid=scan_occ_guid)
# get_scan_occurrence_screenshots(self, scan_occ_guid: UUID):
#     return ScanOccurrences().get_screenshots(guid=scan_occ_guid)
# get_codegroups(self):
#     return CodeGroups().get_all()
# get_codegroup(self, name):
#     return CodeGroups().get(name=name)
# get_dynamic_configuration(self):
#     return Configuration().get()
# get_dynamic_scan_capacity_summary(self):
#     return ScanCapacitySummary().get()
# get_global_scanner_variables(self):
#     return ScannerVariables().get_all()
# get_global_scanner_variable(self, guid: UUID):
#     return ScannerVariables().get(guid)
# create_global_scanner_variable(self, reference_key, value, description):
#     return ScannerVariables().create(reference_key, value, description)
# update_global_scanner_variable(self, guid: UUID, reference_key, value, description):
#     return ScannerVariables().update(guid, reference_key, value, description)
# delete_global_scanner_variable(self, guid: UUID):
#     return ScannerVariables().delete(guid)
# dyn_setup_user_agent(self, custom_header, type):
#     return DynUtils().setup_user_agent(custom_header, type)
# dyn_setup_custom_host(self, host_name, ip_address):
#     return DynUtils().setup_custom_host(host_name, ip_address)
# dyn_setup_blocklist(self, urls: List):
#     return DynUtils().setup_blocklist(urls)
# dyn_setup_url(self, url, directory_restriction_type='DIRECTORY_AND_SUBDIRECTORY', http_and_https=True):
#     return DynUtils().setup_url(url, directory_restriction_type, http_and_https)
# dyn_setup_scan_setting(self, blocklist_configs: list, custom_hosts: List, user_agent: None):
#     return DynUtils().setup_scan_setting(blocklist_configs, custom_hosts, user_agent)
# dyn_setup_scan_contact_info(self, email, first_and_last_name, telephone):
#     return DynUtils().setup_scan_contact_info(email, first_and_last_name, telephone)
# dyn_setup_crawl_script(self, script_body, script_type='SELENIUM'):
#     return DynUtils().setup_crawl_script(script_body, script_type)
# dyn_setup_crawl_configuration(self, scripts: List, disabled=False):
#     return DynUtils().setup_crawl_configuration(scripts, disabled)
# dyn_setup_login_logout_script(self, script_body, script_type='SELENIUM'):
#     return DynUtils().setup_login_logout_script(script_body, script_type)
# dyn_setup_auth(self, authtype, username, password, domain=None, base64_pkcs12=None, cert_name=None,
#                    login_script_data=None, logout_script_data=None):
#     return DynUtils().setup_auth(authtype, username, password, domain, base64_pkcs12, cert_name, login_script_data,
#                                  logout_script_data)
# dyn_setup_auth_config(self, authentication_node: dict):
#     return DynUtils().setup_auth_config(authentication_node)
# dyn_setup_scan_config_request(self, url, allowed_hosts: List, auth_config=None, crawl_config=None,
#                                   scan_setting=None):
#     return DynUtils().setup_scan_config_request(url, allowed_hosts, auth_config, crawl_config, scan_setting)
# dyn_setup_scan(self, scan_config_request, scan_contact_info=None, linked_app_guid: UUID = None):
#     return DynUtils().setup_scan(scan_config_request, scan_contact_info, linked_app_guid)



import veracode_api_py
from veracode_api_py import apihelper
import json
import csv
vApiHelper = apihelper.APIHelper()
veracodeAPI = veracode_api_py.VeracodeAPI()


# Configuration switches
DEBUG = False
VERBOSE = False

# "blacklist_configuration": {
#       "black_list": [
#         {
#           "directory_restriction_type": "DIRECTORY_AND_SUBDIRECTORY",
#           "http_and_https": true,
#           "url": "string"
#         }
#       ]
#     },


if(DEBUG):
    blacklistFileName = "blacklist.csv"
    if(VERBOSE):
        print(f"Using CSV file named {blacklistFileName}. Please ensure that the file is located in the same directory")

# Middleware
def isTrue(value):
    if (str(value).casefold() == "true"):
        return "true"
    else:
        return "false"

# checks to see last line
# Todo: Improve this block    
# Todo:




## Function name: 
##
## Precondition:
## Postcondition:
def blacklistConfigCSVtoJSON(blackListCSV = "Dev/Test/blacklist.csv"):
    # initialization of variables ##########################################################################
    if(DEBUG): lineCount = 0
    
    # Todo: check to see if the last line is blank
    # identifying the last line of the csv ##################
    fileLastLine = open(blackListCSV, "r")
    lastLine = fileLastLine.readlines()[-1]
    if(lastLine == None or lastLine == str()):
        print("Error: Last Line is blank")
    fileLastLine.close()
    #########################################################
    
    # intializing configuration block
    blacklist_configuration='''"blacklist_configuration": 
                                {"black_list": ['''
    # End initialization of variables ######################################################################

    # Debug block ###########################################
    if(DEBUG): print("[DEBUG]:: LastLine: " + lastLine)
    # End Debug Block #######################################
    # Todo: check to see if the CSV file exists, if not error or default to user input 
    # Opening up the CSV ###################################################################################
    
    with open(blackListCSV, mode = 'r') as file:
        csvFile = csv.DictReader(file)
        # Debug block #######################################
        if(DEBUG):
            if(VERBOSE):
                print("[DEBUG]:: size of csv: " + str(csvFile.__sizeof__()))
                print("[DEBUG]:: Line Number: " + str(csvFile.line_num))
            print('''
            "blacklist_configuration":{
            "black_list": [
            ''')
        #####################################################

        # Looping through the csvFile converted to a Dictionary ############################################
        for lines in csvFile:
            #print(lines)
            if(DEBUG): 
                lineCount+= 1
                print("[DEBUG]:: Line itteration: " + str(lineCount))
                print("[DEBUG]:: CSV Line Count: " + str(csvFile.line_num))

            # Debug block ###################################
            if(DEBUG):
                print('[DEBUG]:: \t{')
                print('[DEBUG]::\t\t "directory_restriction_type": "' + lines['directory_restriction_type'] + '",' )
                print('[DEBUG]::\t\t "http_and_https": ' + isTrue(lines['http_and_https']) + ',')
                print('[DEBUG]::\t\t"url": "' + lines['url'] + '"')
                print('[DEBUG]::\t}')
                if(VERBOSE):
                    print("[DEBUG]::[VERBOSE]:: Last Line:                  " + lastLine)
                    print("[DEBUG]::[VERBOSE]:: Directory Restriction Type: " + lines['directory_restriction_type'])
                    print("[DEBUG]::[VERBOSE]:: Http and Https:             " + lines['http_and_https'])
                    print("[DEBUG]::[VERBOSE]:: Url:                        " + lines['url'])
                    print("[DEBUG]::[VERBOSE]:: partitioning ~~~~~~~~~~~~~~~")
                    print("[DEBUG]::[VERBOSE]:: Partition 1                 " +  lastLine.partition(',')[0] )
                    print("[DEBUG]::[VERBOSE]:: Partition 2                 " + lastLine.partition(',')[2].partition(',')[0])
                    print("[DEBUG]::[VERBOSE]:: Partition 3                 " + lastLine.partition(',')[2].partition(',')[2])
                    print("[DEBUG]::[VERBOSE]:: Partition 4                 " + lastLine.partition(',')[0] == lines['directory_restriction_type'] )
                    print("[DEBUG]::[VERBOSE]:: Partition 5                 " + lastLine.partition(',')[2].partition(',')[0] == lines['http_and_https'])
                    print("[DEBUG]::[VERBOSE]:: Partition 6                 " + lastLine.partition(',')[2].partition(',')[2] == lines['url'])
            ################################################
               
            blacklist_configuration += '{'
            blacklist_configuration+= '''
            "directory_restriction_type": "{directory_restriction_type}",
            "http_and_https": {http_and_https},
            "url": "{url}"'''.format(directory_restriction_type=lines['directory_restriction_type'], http_and_https=isTrue(lines['http_and_https']), url=lines['url'] )
            blacklist_configuration+='}'
            
            # if is the last entry of the csv file, then close out the array and add a comma
            if(DEBUG and VERBOSE):
                print("[DEBUG]::[VERBOSE]:: " + lastLine.partition(',')[0] + " <::> " + lines['directory_restriction_type'])
                print("[DEBUG]::[VERBOSE]:: " + lastLine.partition(',')[2].partition(',')[0] + " <::> " + lines['http_and_https'] )
                print("[DEBUG]::[VERBOSE]:: " + lastLine.partition(',')[2].partition(',')[2] + " <::> " + lines['url'])
            if(lastLine.partition(',')[0] == lines['directory_restriction_type']  and lastLine.partition(',')[2].partition(',')[0] == lines['http_and_https'] and lastLine.partition(',')[2].partition(',')[2] == lines['url']):
                blacklist_configuration+=']}'
                # Debug Block ##############################
                if(DEBUG):
                    print("[DEBUG]:: " + ']}')
                    if(VERBOSE):
                        print("[DEBUG]::[VERBOSE]:: Last Line of CSV")
                ###########################################
            # else add a comma after the curly braces
            else:
                blacklist_configuration+=','
                if(DEBUG):
                    print("[DEBUG]:: ,")
        # End for Loop #####################################################################################

        # if(DEBUG and lineCount == 1):
        #     blacklist_configuration+= ']'
    
    # End reading CSV ######################################################################################
    if(DEBUG):                
        if(VERBOSE):
            print("[DEBUG]::[VERBOSE]:: " + "\n\nFinished product:")
        print("[DEBUG]::\n\t " + blacklist_configuration)
    
    return blacklist_configuration


'''
Description:

'''
## Function name: 
##
## Precondition:
## Postcondition:

def FormatRequest(scanName, baseURL ,  orgEmailContact, http_and_https = "true" , blacklistConfig = None, glBlackListConfig = None ):
    scanRequest= '{' 
    scanRequest+= '\"name\": \"{}\",'.format(scanName) 
    scanRequest+= '\"scans\": [ { \"scan_config_request\": { \"target_url\": {'
    scanRequest+= ' \"url\": \"{}\",'.format(baseURL) 
    scanRequest+= '\"http_and_https\": {}'.format(http_and_https) 
    scanRequest+= ' }' 
    scanRequest+= ', \"scan_setting\": {' 
    scanRequest+= ' {} '.format(blacklistConfig)
    scanRequest+= ' } } } ' 
    scanRequest+=' ], \"org_info\": {' 
    scanRequest+= ' \"email\": \"{}\"'.format(orgEmailContact) 
    scanRequest+= ' }, \"visibility\": { \"setup_type\": \"SEC_LEADS_ONLY\", \"team_identifiers\": [] }'
    scanRequest+= ',\"scan_setting\": {' 
    scanRequest+= ' {} '.format(glBlackListConfig)
    scanRequest+= '} }' 
    # scanRequest.format(scanName, baseURL, http_and_https, blacklistConfig, orgEmailContact ,  glBlackListConfig)
    if(DEBUG):
        print("[DEBUG]:: " + scanRequest)

    file = open("input.json", "w")
    file.write(scanRequest)
    file.close()
    if(DEBUG):
        print("[DEBUG]:: " + "Wrote out to a file, input.json")
    return scanRequest


'''
Description:

'''
## Function name: 
##
## Precondition:
## Postcondition:
def blacklistCSVtoList(blackListCSV = "blacklist.csv"):
    urls = []
    try:
        with open(blackListCSV, mode = 'r') as file:
            csvFile = csv.DictReader(file)
            for lines in csvFile:
                urls.append(lines['url'])
            if(DEBUG):
                print("[DEBUG]:: " , urls)
            return urls
    except:
        print("The CSV file failed to load", blackListCSV)



# '''
# Description:

# '''
# ## Function name: 
# ##
# ## Precondition:
# ## Postcondition:
# def SendRequest():
#     pass

# '''
# Description:

# '''
# ## Function name: 
# ##
# ## Precondition:
# ## Postcondition:
# def UserIntRequest():
#     pass

'''
Description:

'''
## Function name: 
##
## Precondition:
## Postcondition:
def test():
    testString = FormatRequest("Verademo-DA002","http://verademo.bhalpern.vuln.sa.veracode.io/verademo","bhalpern@veracode.com", "true",blacklistConfigCSVtoJSON(), blacklistConfigCSVtoJSON("Dev/Test/glblacklist.csv"))
    return testString    



# Main Execution block #####################################################################################
if(DEBUG):
    print(test())