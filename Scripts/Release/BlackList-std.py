# BlackList-std.py
#   Version: std-00.02
#   Type: standalone 
#   Description:
#       This script is for creating and formatting a blacklist for a Veracode Dynamic Web Application Scan
#       It takes a blacklist.csv and glblacklist.csv to configure a blacklist for the URL in question and a global blacklist file
#           if the files are not included or are empty then leaves that blacklist section out of the formatted results
#           the request is written to an input.json file to then be passed to the api to make the request
#       The script does not utilize the Veracode Python API Library, but a variation of this script will be

## Example request:
## https://docs.veracode.com/r/t_dynamic_useragent
##
## {
##   "name": "Name-of-Your-Dynamic-Analysis",
##   "scans": [
##     {
##       "scan_config_request": {
##         "target_url": {
##           "url": "http://www.example.com/one/"
##         },
##         "scan_setting": {
##           "user_agent": {
##             "type": "CUSTOM",
##             "custom_header": "Custom User Agent String"
##           },
##           "blacklist_configuration": {
##             "blackList": [
##               {
##                 "url": "http://www.example.com/one/black/",
##                 "http_and_https": true
##               }
##             ]
##           }
##         }
##       }
##     },
##     {
##       "scan_config_request": {
##         "target_url": {
##           "url": "http://www.example.com/two/",
##           "http_and_https": true
##         }
##       }
##     }
##   ],
##   "org_info": {
##     "email": "user@example.com"
##   },
##   "visibility": {
##     "setup_type": "SEC_LEADS_ONLY",
##     "team_identifiers": []
##   },
##   "scan_setting": {
##     "blacklist_configuration": {
##       "blackList": [
##         {
##           "url": "http://www.example.com/black1/",
##           "http_and_https": false
##         },
##         {
##           "url": "http://www.example.com/black2/site.html",
##           "http_and_https": false
##         }
##       ]
##     },
##     "user_agent": {
##       "type": "CUSTOM",
##       "custom_header": "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko VERACODE"
##     }
##   }
## }    

import json
import csv



# Functions:
#       isTrue():                   converts boolean to lowercase string
#       scheduleScan():             formats the schedule scan json for the scan request
#       scheduleNow():              formats a schedule now json for the scan request
#       blacklistConfigCSVtoJSON(): creates a formatted bulk blacklist configuration using the csv passed to it   
#       blacklistConfigCSVtoList(): creates a parallel list from the blacklist csv
#       formatRequest():            formats the request for creation of or updating of a dynamic scan 
#       test():                     test function
#
#

############################################################################################################################
# Configuration switches
############################################################################################################################
DEBUG = True                # Default is False
VERBOSE = False             # Default is False
#automateRequest = False    # Default is False
#mode = 0                   # Mode 0:   Create Mode
                            # Mode 1:   Edit Mode   [ In development ]
                            # Mode 2:   Both        [ In development ]
#blacklistCSV = True         # Default is True      [ In development ]
#glblacklistCSV = True       # Default is True      [ In development ]

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
def isTrue(value: bool):
    if (str(value).casefold() == "true"):
        return str(value).casefold()
    else:
        return str(value).casefold()





### Function name: scheduleScan
###
### Precondition:
### Postcondition: returns a json output of the configured scan
def scheduleScan(startNow = isTrue(False), length = 1, unit = "DAY", end_date = "", recurrence_type = "WEEKLY", schedule_end_after = 2, reccurence_interval = 1, day_of_week = "FRIDAY"):
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
    if(DEBUG):
        print(scheduleStr)
    return scheduleStr

### Function name: scheduleNow
### Precondition: takes a number of days for duration
### Postcondition: returns a schedule now schedule formatted to be inserted into the format json
def scheduleNow(days: int = 1):
    schedule = {
        "now": "true",
        "duration": {
            "length": str(int),
            "unit": "DAY"
        }
    }
    return ("\"schedule\": " + json.dumps(schedule))





### Function name: blacklistConfigCSVtoJSON
### Precondition: Takes a (path to) csv file , default is blacklist.csv in the same directory as the script
### Postcondition: returns bulk blacklist configuration based off of csv file
def blacklistConfigCSVtoJSON(blackListCSV: str = "blacklist.csv"):
    # initialization of variables ##########################################################################
    if(DEBUG): lineCount = 0
    
    try:
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
            # Looping through the csvFile converted to a dictionary ############################################
            for lines in csvFile:
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
    except:
        print("The CSV file failed to load", blackListCSV)
        return 1




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
        return 1


#       Todo: 
#           - ensure thhat baseURL is url encoded
#           - ensure that teams is a list and formatted as such 


## Function name: formatNewRequest
##                Ensure that the input is precompiled from the functions otherwise raises risk, need to add more sanitization checks
##                This version of the function does not include the scanner variables or special_instructions, and is geared toward a single URL with a Bulk Blacklist
##                  future itterations of this function will include multiple target urls and a allow list configuration that is currently being itterated on seperately
##                https://app.swaggerhub.com/apis/Veracode/veracode-dynamic_analysis_configuration_service_api/1.0#/v-1-analysis-api/createAnalysisUsingPOST
## Precondition:  Takes the components of a singular analysis with a single target URL and Bulk Blacklist from a CSV, creates the request to be sent to the api to configure the analysis, is formatted for scan creation. By Default utilizes a blacklist.csv and glblacklist.csv
## Postcondition: will format the request with the different components and write out to a input.json file, which can then be used to update/create an analysis
def formatNewRequest(scanName: str,  scanConfiguration: bool = True, baseURL: str = '' ,orgInfo: bool = True,  orgEmailContact: str = '', http_and_https: str = isTrue(True) , blacklistConfig: str = blacklistConfigCSVtoJSON("blacklist.csv"), visibility:bool = True,setupType: str = "SEC_LEADS_ONLY", includeGlBlacklist: bool = False,  glBlackListConfig: str = blacklistConfigCSVtoJSON("glblacklist.csv"),  teams: str = '' , scanSchedule: bool = True, schedule: str = scheduleNow()):
    # input validation:
    # if orgInfo is true, then check to see if the @ sign is present and a period otherwise throw an error 
    sec_leads_only = True


    if(orgInfo and (orgEmailContact.find('@') == -1 or orgEmailContact.find('.') == -1) ):
        return "ERROR: There was an error invalid email provided"

    # if scanConfiguration is true, and there is slash in the baseURL and no semicolon than proceed otherwise throw an error 
    if(scanConfiguration and (baseURL.find('/') == -1 or baseURL.find(';') != -1)):
        return "ERROR: Something went wrong and the baseURL is not formatted correctly"
    
    if(visibility and (setupType != "SEC_LEADS_ONLY" or setupType != "SEC_LEADS_AND_TEAM")):
        return "ERROR: an incorrect setup type was specified. Please input either 'SEC_LEADS_ONLY' or 'SEC_LEADS_AND_TEAM'"
    else:
        sec_leads_only = (setupType == "SEC_LEADS_ONLY")
    
    scanRequest= '{' 
    scanRequest+= '\"name\": \"{}\"'.format(scanName) 
    if(scanConfiguration):                                                                # Adding Scan information
        scanRequest+= ',\"scans\": [ { \"scan_config_request\": { \"target_url\": {'
        scanRequest+= ' \"url\": \"{}\",'.format(baseURL) 
        scanRequest+= '\"http_and_https\": {}'.format(http_and_https) 
        scanRequest+= ' }' 
        scanRequest+= ', \"scan_setting\": {' 
        scanRequest+= ' {} '.format((blacklistConfig))                                  # Bulk blacklist for the targetURL
        scanRequest+= ' } } } ' 
        scanRequest+=' ]'
    if(scanSchedule):                                                                   # Adding a Scan Schedule to the analysis
        scanRequest+= ',{}'.format(schedule)
    if(orgInfo):                                                                        # Adding Org informaiton to the analysis
        scanRequest+=' ,\"org_info\": {' 
        scanRequest+= ' \"email\": \"{}\"'.format(orgEmailContact) 
        scanRequest+= ' }'
    if(visibility):                                                                     # Adding Visibility settings to the analysis
        scanRequest += ' ,\"visibility\": { \"setup_type\": '
        scanRequest += '\" {}\", \"team_identifiers\": ['.format(setupType)
        scanRequest+= '{} ]'.format(teams) 
        scanRequest+= '},'
        scanRequest += '\"scan_setting\": {' 
        if(includeGlBlacklist):                                                         # Default is false, removing the glBlacklist if not turned on, to be configured for future itterations
            scanRequest+= ' {} '.format(glBlackListConfig)
        scanRequest+= '}'
    scanRequest+= '}' 
    # scanRequest.format(scanName, baseURL, http_and_https, blacklistConfig, orgEmailContact ,  glBlackListConfig)
    file = open("input.json", "w")
    file.write(scanRequest)
    file.close()
    return scanRequest

############################################################################################################################
# Under development UI
############################################################################################################################
# # TODO: Pull down list of analysis from the platform and check to see if name matches, if matches return invalid input, otherwise proceed ( depending on mode )
# # TODO: Input validation middleware
# ### Function name: Run
# ### 
# ### Precondition: N/A
# ### Postcontion: Queries the user for the values and creates a CLI UI for sending the requests
# def run():
#     print("Format New Request:")
#     #scanName: str,  scanConfiguration: bool = True, baseURL: str = '' ,orgInfo: bool = True,  orgEmailContact: str = '', http_and_https: str = "true" , blacklistConfig: str = blacklistConfigCSVtoJSON("blacklist.csv"),visibility:bool = True,setupType: str = "SEC_LEADS_ONLY", glBlackListConfig: str = blacklistConfigCSVtoJSON("glblacklist.csv"),  teams: str = '' , scanSchedule: bool = True, schedule: str = scheduleNow()
#     scanName = input("Please input the Analysis name: ")
#     scanConfig = input("Include scan configuration section? (T / F): [(T)rue]")
#     #TODO: 
#     baseURl = input("Please input ")
#     orgInfo = input()
#     orgEmailContact = input()


# ## Function name: test 
# ##
# ## Precondition: A test run to create a new Analysis input.json that can be passed to the API to then create a scan. If the blacklist files aren't present, simply remove and leave them as blank
# ## Postcondition:
def test():
    import datetime
    testString = formatNewRequest(str("veracode-api-test-" + datetime.date.today().ctime()) ,True,"http://veracode.com",True,"example@example.com", isTrue(True), blacklistConfigCSVtoJSON("blacklist.csv"),False, "SEC_LEADS_ONLY", False, "","",False, "")
    return testString    

# Main Execution block #####################################################################################
if(DEBUG):
    #scheduleScan()
    print(test())




