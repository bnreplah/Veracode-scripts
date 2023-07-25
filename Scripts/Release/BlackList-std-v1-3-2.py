# BlackList-std.py
#   Version std-v01.03.2
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

import json
import csv
import datetime


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


def isTrue(value):
    if (str(value).casefold() == "true"):
        return True
    else:
        return False



def scheduleScan(startNow: bool = True, scheduled: bool = True, length = 1, unit = "DAY", start_date = datetime.date.isoformat(datetime.date.today()), end_date = datetime.date.isoformat(datetime.date.today()) , recurrence_type = "WEEKLY", schedule_end_after = 2, reccurence_interval = 1, day_of_week = "FRIDAY"):
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

    if(VERBOSE): print(schedule)
    return schedule

def scheduleNow(nowB: str = isTrue(True), days: int = 1):
    schedule = {"schedule": {
        "now": nowB,
        "duration": {
            "length": str(days),
            "unit": "DAY"
        }
    }}

    if(VERBOSE): print(schedule)
    return (schedule)


def blacklistConfigCSVtoJSON(blackListCSV: str = "blacklist.csv"):
    if(DEBUG): lineCount = 0
    
    try:
        fileLastLine = open(blackListCSV, "r")
        lastLine = fileLastLine.readlines()[-1]
        if(lastLine == None or lastLine == str()):
            print("Error: Last Line is blank")
        fileLastLine.close()
        blacklist_configuration= { "blacklist_configuration": {"black_list": [] } }

        with open(blackListCSV, mode = 'r') as file:
            csvFile = csv.DictReader(file)
            for lines in csvFile:
                
                if(DEBUG): 
                    lineCount+= 1
                    if(VERBOSE):
                        print(lines)    
                blacklist_configuration["blacklist_configuration"]["black_list"].append({"directory_restriction_type": "{}".format(lines['directory_restriction_type']), "http_and_https": "{}".format(isTrue(lines['http_and_https'])), "url": "{}".format(lines['url'])})    
            
                if(lastLine.partition(',')[0] == lines['directory_restriction_type']  and lastLine.partition(',')[2].partition(',')[0] == lines['http_and_https'] and lastLine.partition(',')[2].partition(',')[2] == lines['url']):
                    break
                
        if(DEBUG):
            print(json.dumps(blacklist_configuration))
            print(lineCount)
        return blacklist_configuration
    except:
        print("The CSV file failed to load", blackListCSV)
        return {}


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
        return [],[],[]
    
def formatOrgInfo(orgEmailContact):
    return {"org_info": {"email": orgEmailContact}}

def formatVisbilityData(setup_type = "SEC_LEADS_ONLY", teams = []):
    return {"visibility": { "setup_type": setup_type, "team_identifiers": teams}}

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


def createSimpleScan(name, scanConfig, baseURL, blackListprovided):
    if(blackListprovided):
        return formatRequest(name, scanConfig,baseURL,False,{},isTrue(True),blacklistConfigCSVtoJSON())
    else:
        return formatRequest(name, scanConfig, baseURL)


# def formatRequest(scanName: str,  scanConfiguration: bool = True, baseURL: str = '' ,
#                   orgInfo: bool = False, orgInfoData: dict = { "org_info": { "email": "example@email.com", "owner": "" } },
#                       http_and_https: str = isTrue(True) , blacklistConfig: dict = { "blacklist_configuration": {"black_list": [] } } ,
#                       visibility:bool = False, visibilityData: dict = {"visibility": { "setup_type": "SEC_LEADS_ONLY", "team_identifiers": []}},
#                         glScanSetting: bool = False, glScanSettingData: dict = {}, scanSchedule: bool = True, 
#                         scheduleData: dict = scheduleNow()):


# def UI():

#     #what actions do you want to take



#     analysisName = input("Please enter an Analysis name: ")
#     scanConfig = input()
#     baseUrl = input()
#     orgInfo = input()
#     orgInfoData = input()
#     http_and_https = input()
#     blacklistConfig = input()
#     visibility = input()
#     visibilitData = input()
#     glScanSetting = input()



createSimpleScan("analysis-test-name" + str(datetime.date.today()), True, "http://example.com/",True)

