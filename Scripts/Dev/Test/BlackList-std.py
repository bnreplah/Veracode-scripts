# BlackList-std.py
#   standalone 
#   Description:
#       This script is for creating and formatting a blacklist for a Veracode Dynamic Web Application Scan
#       It takes a blacklist.csv and glblacklist.csv to configure a blacklist for the URL in question and a global blacklist file
#           if the files are not included or are empty then leaves that blacklist section out of the formatted results
#           the request is written to an input.json file to then be passed to the api to make the request
#   Available Dyanmic API functions:
#       
#
#
#
#
#
#
#
#
#
# What is needed for a basic creation of a scan request:
# name:
# Scans in the analysis:
#   Scan Config Request:
#       Target URL: (Required)
#           Url
#       Scan Setting
#           User Agent
#               Type
#               Custom Header
#           Blacklist Configuration
#               blacklist
#                   Directory Restriction Type
#                   URL
#                   Http and Https
# Org Info
#   email
# Visibility
#   Set up type:
#   team identifiers
# Global Scan Setting
#   blacklist configuration
#       blacklist
#           Directory Restriction Type
#           URL
#           Http and Https
#   User Agent
#       type
#       custom header           

# Example request:
# https://docs.veracode.com/r/t_dynamic_useragent
#
# {
#   "name": "Name-of-Your-Dynamic-Analysis",
#   "scans": [
#     {
#       "scan_config_request": {
#         "target_url": {
#           "url": "http://www.example.com/one/"
#         },
#         "scan_setting": {
#           "user_agent": {
#             "type": "CUSTOM",
#             "custom_header": "Custom User Agent String"
#           },
#           "blacklist_configuration": {
#             "blackList": [
#               {
#                 "url": "http://www.example.com/one/black/",
#                 "http_and_https": true
#               }
#             ]
#           }
#         }
#       }
#     },
#     {
#       "scan_config_request": {
#         "target_url": {
#           "url": "http://www.example.com/two/",
#           "http_and_https": true
#         }
#       }
#     }
#   ],
#   "org_info": {
#     "email": "user@example.com"
#   },
#   "visibility": {
#     "setup_type": "SEC_LEADS_ONLY",
#     "team_identifiers": []
#   },
#   "scan_setting": {
#     "blacklist_configuration": {
#       "blackList": [
#         {
#           "url": "http://www.example.com/black1/",
#           "http_and_https": false
#         },
#         {
#           "url": "http://www.example.com/black2/site.html",
#           "http_and_https": false
#         }
#       ]
#     },
#     "user_agent": {
#       "type": "CUSTOM",
#       "custom_header": "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko VERACODE"
#     }
#   }
# }    

#import veracode_api_py
#from veracode_api_py import apihelper
import json
import csv
#vApiHelper = apihelper.APIHelper()
#veracodeAPI = veracode_api_py.VeracodeAPI()


# Configuration switches
DEBUG = True
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

def scheduleScan(startNow = "true", length = 1, unit = "DAY", end_date = "", recurrence_type = "WEEKLY", schedule_end_after = 2, reccurence_interval = 1, day_of_week = "FRIDAY"):
#       "schedule": {
#     "now": true,
#     "duration": {
#       "length": 1,
#       "unit": "DAY"
#     },
#     "end_date": "",
#     "scan_recurrence_schedule": {
#       "recurrence_type": "WEEKLY",
#       "schedule_end_after": 2,
#       "recurrence_interval": 1,
#       "day_of_week": "FRIDAY"
#     }
#   }
    schedule = {
        "now": startNow,
        "duration": {
            "length": length,
            "unit": unit
        },
        "end_date": end_date,
        "scan_recurrence_schedule": {
            "recurrence_type": recurrence_type,
            "schedule_end_after": schedule_end_after,
            "recurrence_internval": reccurence_interval,
            "day_of_week": day_of_week
        }
    }

    scheduleStr = "\"schedule\": " + json.dumps(schedule) 
    print(scheduleStr)
    return scheduleStr



## Function name: 
##
## Precondition:
## Postcondition:
def blacklistConfigCSVtoJSON(blackListCSV: str = "blacklist.csv"):
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

    # Todo: check to see if the CSV file exists, if not error or default to user input 
    # Opening up the CSV ###################################################################################
    
    with open(blackListCSV, mode = 'r') as file:
        csvFile = csv.DictReader(file)
        # Looping through the csvFile converted to a Dictionary ############################################
        for lines in csvFile:
            #print(lines)
            if(DEBUG): 
                lineCount+= 1
                
                
            blacklist_configuration += '{'
            blacklist_configuration+= '''
            "directory_restriction_type": "{directory_restriction_type}",
            "http_and_https": {http_and_https},
            "url": "{url}"'''.format(directory_restriction_type=lines['directory_restriction_type'], http_and_https=isTrue(lines['http_and_https']), url=lines['url'] )
            blacklist_configuration+='}'
            
            # if is the last entry of the csv file, then close out the array and add a comma
            if(lastLine.partition(',')[0] == lines['directory_restriction_type']  and lastLine.partition(',')[2].partition(',')[0] == lines['http_and_https'] and lastLine.partition(',')[2].partition(',')[2] == lines['url']):
                blacklist_configuration+=']}'
            # else add a comma after the curly braces
            else:
                blacklist_configuration+=','
        # End for Loop #####################################################################################

    # End reading CSV ######################################################################################    
    return blacklist_configuration


## Function name: 
##
## Precondition: Takes the components of a singular analysis and bulk creates the request to be sent to the api to configure the analysis, is formatted for scan creation
## Postcondition: will format the request with the different components and write out to a input.json file, which can then be used to update/create an analysis
def FormatRequest(scanName: str,  scanConfiguration: bool = True, baseURL: str = '' ,orgInfo: bool = True,  orgEmailContact: str = '', http_and_https: str = "true" , blacklistConfig: str = '',visibility:bool = True, glBlackListConfig: str = '',  teams: str = '' , scanSchedule: bool = True, schedule: str = ''):
    scanRequest= '{' 
    scanRequest+= '\"name\": \"{}\",'.format(scanName) 
    if(scanConfiguration):
        scanRequest+= '\"scans\": [ { \"scan_config_request\": { \"target_url\": {'
        scanRequest+= ' \"url\": \"{}\",'.format(baseURL) 
        scanRequest+= '\"http_and_https\": {}'.format(http_and_https) 
        scanRequest+= ' }' 
        scanRequest+= ', \"scan_setting\": {' 
        scanRequest+= ' {} '.format((blacklistConfig))
        scanRequest+= ' } } } ' 
        scanRequest+=' ]'
    if(scanSchedule):
        scanRequest+= '{}'.format(schedule)
    if(orgInfo):
        scanRequest+=' ,\"org_info\": {' 
        scanRequest+= ' \"email\": \"{}\"'.format(orgEmailContact) 
        scanRequest+= ' }'
    if(visibility):
        scanRequest += ' ,\"visibility\": { \"setup_type\": \"SEC_LEADS_ONLY\", \"team_identifiers\": ['
        scanRequest+= '{} ]'.format(teams) 
        scanRequest+= '},'
        scanRequest += '\"scan_setting\": {' 
        scanRequest+= ' {} '.format(glBlackListConfig)
        scanRequest+= '}'
    scanRequest+= '}' 
    # scanRequest.format(scanName, baseURL, http_and_https, blacklistConfig, orgEmailContact ,  glBlackListConfig)
    file = open("input.json", "w")
    file.write(scanRequest)
    file.close()
    return scanRequest


## Function name: 
##
## Precondition:
## Postcondition:
def blacklistConfigCSVtoList(blackListCSV = "blacklist.csv"):
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



# ## Function name: 
# ##
# ## Precondition:
# ## Postcondition:
def test():
    testString = FormatRequest("Veracode",False,"http://veracode.com",True,"demo@example.com", "true",'',True, '','',True, scheduleScan())
    return testString    



# Main Execution block #####################################################################################
if(DEBUG):
    #scheduleScan()
    print(test())