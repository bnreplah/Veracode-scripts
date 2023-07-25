# BlackList-std.py
#   Version std-v00.03.2
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
import datetime
#vApiHelper = apihelper.APIHelper()
#veracodeAPI = veracode_api_py.VeracodeAPI()

#
# Functions:
#       isTrue():                   converts boolean to lowercase
#       scheduleScan():             formats the schedule scan json for the scan request
#       scheduleNow():              formats a schedule now json for the scan request
#       blacklistConfigCSVtoJSON(): creates a formatted bulk blacklist configuration using the csv passed to it   
#       blacklistConfigCSVtoList(): creates a parallel list from the blacklist csv
#       formatRequest():            formats the request for creation of or updating of a dynamic scan 
#       test():                     test function
#
#


# Configuration switches
DEBUG = True
VERBOSE = True

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
### Function name: isTrue
###
### Precondition: takes a boolean
### Postcondition: return lowercase boolean string
def isTrue(value):
    if (str(value).casefold() == "true"):
        return True
    else:
        return False

# checks to see last line


### Function name:
###
### Precondition:
### Postcondition:
def scheduleScan(startNow: bool = True, scheduled: bool = True, length = 1, unit = "DAY", start_date = datetime.date.isoformat(datetime.date(2023, 12, 30)), end_date = datetime.date.isoformat((datetime.date(2023, 12, 31)) ), recurrence_type = "WEEKLY", schedule_end_after = 2, reccurence_interval = 1, day_of_week = "FRIDAY"):
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
    schedule = { "schedule": {
        "now": startNow,
        "duration": {
            "length": length,
            "unit": unit
        },
        "scheduled": scheduled,
        "scan_recurrence_schedule": {
            "recurrence_type": recurrence_type,
            "schedule_end_after": schedule_end_after,
            "recurrence_internval": reccurence_interval,
            "day_of_week": day_of_week
        }
    }}

    if(startNow == "false"):
        schedule["schedule"].update({"start_date": start_date, "end_date": end_date})
    # remove after testing
    scheduleStr = schedule
    if(DEBUG): print(scheduleStr)
    return scheduleStr

### Function name: Schedule Now
### Precondition: takes a number of days for duration
### Postcondition: returns a schedule now schedule formatted to be inserted into the format json
def scheduleNow(nowB: str = isTrue(True), days: int = 1):
    schedule = {"schedule": {
        "now": nowB,
        "duration": {
            "length": str(days),
            "unit": "DAY"
        }
    }}
    # remove after testing
    scheduleStr =  schedule 
    if(DEBUG): print(scheduleStr)
    return (scheduleStr)





### Function name: blacklistConfigCSVtoJSON
### Precondition:
### Postcondition:
def blacklistConfigCSVtoJSON(blackListCSV: str = "blacklist.csv"):
    # initialization of variables ##########################################################################
    if(DEBUG): lineCount = 0
    
    # Todo: check to see if the last line is blank
    try:
        # identifying the last line of the csv ##################
        fileLastLine = open(blackListCSV, "r")
        lastLine = fileLastLine.readlines()[-1]
        if(lastLine == None or lastLine == str()):
            print("Error: Last Line is blank")
        fileLastLine.close()
        #########################################################
        
        # intializing configuration block
        blacklist_configuration= { "blacklist_configuration": {"black_list": [] } }
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
                    
                blacklist_configuration["blacklist_configuration"]["black_list"].append({"directory_restriction_type": "{}".format(lines['directory_restriction_type']), "http_and_https": "{}".format(isTrue(lines['http_and_https'])), "url": "{}".format(lines['url'])})    
               
                
                # if is the last entry of the csv file, then close out the array and add a comma
                if(lastLine.partition(',')[0] == lines['directory_restriction_type']  and lastLine.partition(',')[2].partition(',')[0] == lines['http_and_https'] and lastLine.partition(',')[2].partition(',')[2] == lines['url']):
                    break
                
            # End for Loop #####################################################################################
        # End reading CSV ######################################################################################    
        if(DEBUG):
            print(json.dumps(blacklist_configuration))
        return blacklist_configuration
    except:
        print("The CSV file failed to load", blackListCSV)
        return {}




### Function name: blacklistConfigCSVtoList
###
### Precondition:
### Postcondition: returns a tuple of parallel arrays of each from the blacklist csv
def blacklistConfigCSVtoList(blackListCSV = "blacklist.csv"):
    urls = []
    http_and_https = []
    directory_restriction_types = []
    try:
        with open(blackListCSV, mode = 'r') as file:
            csvFile = csv.DictReader(file)
            for lines in csvFile:
                urls.append(lines['url'])
                http_and_https.append(lines['http_and_https'])
                directory_restriction_types.append(lines['directory_restriction_type'])

            if(DEBUG):
                print("[DEBUG]:: " , urls)

            return urls, http_and_https, directory_restriction_types
    except:
        print("The CSV file failed to load", blackListCSV)

def formatOrgInfo(orgEmailContact):
    return {"org_info": {"email": orgEmailContact}}


# def formatVisibilityInfo(setupType: str, teamIdentifiers):
#     pass


# Todo: Modularize and send out

## Function name: formatRequest
##
## Precondition: Takes the components of a singular analysis and bulk creates the request to be sent to the api to configure the analysis, is formatted for scan creation
## Postcondition: will format the request with the different components and write out to a input.json file, which can then be used to update/create an analysis
def formatRequest(scanName: str,  scanConfiguration: bool = True, baseURL: str = '' ,
                  orgInfo: bool = False, orgInfoData: dict = { "org_info": { "email": "example@email.com", "owner": "" } },
                      http_and_https: str = isTrue(True) , blacklistConfig: dict = { "blacklist_configuration": {"black_list": [] } } ,
                      visibility:bool = False, visibilityData: dict = {"visibility": { "setup_type": "SEC_LEADS_ONLY", "team_identifiers": []}},
                        glScanSetting: bool = False, glScanSettingData: dict = {}, scanSchedule: bool = True, 
                        scheduleData: dict = scheduleNow()):


    scanRequest= { "name": scanName } 
    #scanRequest+= '"name": "{}"'.format(scanName) 
    if(scanConfiguration):
        scanConfig = { "scans": [ {"scan_config_request": { "target_url": { "url": "{}".format(baseURL), "http_and_https": "{}".format(http_and_https)  }, "scan_setting": { } }} ] }
        ((scanConfig["scans"][0])["scan_config_request"])["scan_setting"].update( blacklistConfig)
        scanRequest.update(scanConfig)
    if(scanSchedule):
        scanRequest.update(scheduleData)
    if(orgInfo):
        scanRequest.update(orgInfoData)
    if(visibility):
        scanRequest.update(visibilityData)
    if(glScanSetting):
        scanRequest.update(glScanSettingData) 
    # scanRequest.format(scanName, baseURL, http_and_https, blacklistConfig, orgEmailContact ,  glBlackListConfig)
    file = open("input.json", "w")
    if(DEBUG and VERBOSE): print(json.dumps(scanRequest))
    # default writes out to file
    if(DEBUG):
        print("Wrote output to file ", file.name)
    json.dump(scanRequest, file)
    #file.write(scanRequest)
    file.close()
    return json.dumps(scanRequest)


def creatSimpleScan(name, scanConfig, baseURL, blackListprovided):
    if(blackListprovided):
        return formatRequest(name, scanConfig,baseURL,False,{},isTrue(True),blacklistConfigCSVtoJSON())
    else:
        return formatRequest(name, scanConfig, baseURL)

creatSimpleScan("analysis-name-test",True,"" )



