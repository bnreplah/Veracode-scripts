# DASTWebAppRequest-std.py
#   Version std-v01.00.0
#   standalone 
#   Description:
#       This application, allows you to configure a new dynamic web application scan with an allowlist and a blocklist for a single url
#           reading the allowlist and blocklist from a csv file called allowlist.csv and blocklist.csv
#           Further configuration is possible with this script, but the UI portion is only enabled for request configurations that have been tested to be valid
#           Use the other configurations and customization at your own risk of the requests being invalid
#           You can also provide commandline arguments when the stdout flag is set to true to be able to pipe the request into the http command to send directly to the REST API
#           The command line options are currently limited to the defaults set in the request variable around line 300-320
# The allowlist is configured in the allowed_hosts object which can be found in the scan configuration and the scan configuration request
# - https://app.swaggerhub.com/apis/Veracode/veracode-dynamic_analysis_configuration_service_api/1.0#/ScanConfigurationRequest
# - https://app.swaggerhub.com/apis/Veracode/veracode-dynamic_analysis_configuration_service_api/1.0#/ScanConfiguration
# The allowlist would be set inside the ScanRequest object which resides as an element of the Scans object in an analysis request
#
#
#
#
#
#
#import veracode_api_py
#from veracode_api_py import apihelper
import json
import csv
import datetime
import sys
import re
#vApiHelper = apihelper.APIHelper()
#veracodeAPI = veracode_api_py.VeracodeAPI()

argAnalysisName = ""
argBaseUrl = ""
argEmail = ""
argOrgOwner = ""
if(len(sys.argv) >= 2):
    argAnalysisName = sys.argv[1]
    argBaseUrl = sys.argv[2]
    argEmail = sys.argv[3]
    argOrgOwner = sys.argv[4]
# Configuration switches
DEBUG = False
VERBOSE = False
WEB_APP = True
stdout= True
#CONFIG_FILE_FOUND= False #[Experimental]
#USE_OLD_CONFIG = False #[Experimental]


### Function name: isTrue
### Precondition: converts a value into a boolean equivalent otherwise returns false
def isTrue(value, varTrue: bool = False):
    if (str(value).casefold() == "true"):
        if(varTrue):
            return True
        else:
            return "true"
    else:
        if(varTrue):
            return False
        else:
            return "false"

### Function name: scheduleScan
### [EXPERIMENTAL] NOTE: UTC time is needed for a valid scan, if the scan is not scheduled for now then it will need to be scheduled with a specific start time, currently configured to start at midnight
### Precondition: 
####            startNow: Boolean | Default is True : When true, will schedule the scan to start immidiatly, when false, an exact start time is needed to be specified in the start_date
####            length: int | Default is 1 : This is the quantitative value that maps to the unit, for the length of the scan, see the documentation for the availble values for unit
####            unit: enum | Default is "DAY": Check the veracode help center documentation before changing this. It must match one of the predefined enum values
####            start_date: Date | Default is today: The start date defaults to a format without a start time, if the startNow is true, then a start time is not needed in the date, but if startNow is false, a start time is needed and one is appended to the end to be accepted by the API
####            includeEndDate: Boolean | Default is False : If the value is false then an end_date is not included in the request as one is not needed. It will match the date time conventions of the start date
####            recurring: Boolean | Default is False, If true will use the values that follow for the recurrence schedule
####            recurrence_type: enum | Default is "WEEKLY" NOTE: See veracode documentation for acceptable values before changing this
####            schedule_end_after: int | Default is 2
####            reccurence_interval: int | Default is 1
####            day_of_week: enum | Default is "FRIDAY"  NOTE: See veracode documentation for acceptable values before changing this
### Postcondition:
def scheduleScan(startNow: bool = False, length = 1, unit = "DAY", start_date = datetime.date.isoformat(datetime.datetime.utcnow()),includeEndDate: bool = True, end_date = datetime.date.isoformat((datetime.date(datetime.date.today().year, datetime.date.today().month, datetime.date.today().day + 2)) ),recurring: bool = False, recurrence_type = "WEEKLY", schedule_end_after = 2, reccurence_interval = 1, day_of_week = "FRIDAY"):
    if(not startNow):
        end_date += "T00:00:00Z[UTC]" # ends at midnight
        start_date += "T23:59:00Z[UTC]"
    schedule = { "schedule": {
        "duration": {
            "length": length,
            "unit": unit
        }
        
    }}
    if(recurring):
        schedule["schedule"].update({"scan_recurrence_schedule": {
            "recurrence_type": recurrence_type,
            "schedule_end_after": schedule_end_after,
            "recurrence_internval": reccurence_interval,
            "day_of_week": day_of_week
        }})
    if(startNow ):
        schedule["schedule"].update({"scheduled": True, "now": True})
    else:
        schedule["schedule"].update({"start_date": start_date})
        if(includeEndDate):
            schedule["schedule"].update({"end_date": end_date })

    # remove after testing
    scheduleStr = schedule
    if(DEBUG): print(scheduleStr)
    return scheduleStr

### Function name: scheduleNow
### Precondition: takes a number of days for duration, if NowB is true, then will apply the values for scheduling the scan starting now
### Postcondition: returns a schedule now schedule formatted to be inserted into the format json
def scheduleNow(nowB: str = isTrue(False), days: int = 1):
    schedule = {"schedule": {
        "now": nowB,
        "duration": {
            "length": str(days),
            "unit": "DAY"
        }
    }}
    if(nowB == isTrue(True)):
        schedule["schedule"].update({"scheduled": True})    # remove after testing
    else:
        schedule = scheduleScan(False,days)
    scheduleStr =  schedule 
    if(DEBUG): print(scheduleStr)
    return (scheduleStr)

### Function name: blocklistConfigCSVtoJSON
### Precondition: takes a blocklist csv file and formats it into an acceptable blocklist to be passed to the API for a web application scan request
def blocklistConfigCSVtoJSON(blocklistCSV: str = "blocklist.csv"):
    # initialization of variables ##########################################################################
    if(DEBUG): lineCount = 0
    
    # Todo: check to see if the last line is blank
    try:
        # identifying the last line of the csv ##################
        fileLastLine = open(blocklistCSV, "r")
        lastLine = fileLastLine.readlines()[-1]
        if(lastLine == None or lastLine == str()):
            print("Error: Last Line is blank")
        fileLastLine.close()
        #########################################################
        
        # intializing configuration block
        blocklist_configuration= { "blocklist_configuration": {"black_list": [] } }
        # End initialization of variables ######################################################################

        # Todo: check to see if the CSV file exists, if not error or default to user input 
        # Opening up the CSV ###################################################################################
        
        with open(blocklistCSV, mode = 'r') as file:
            csvFile = csv.DictReader(file)
            # Looping through the csvFile converted to a Dictionary ############################################
            for lines in csvFile:
                #print(lines)
                if(DEBUG): 
                    lineCount+= 1
                    
                blocklist_configuration["blocklist_configuration"]["black_list"].append({"directory_restriction_type": "{}".format(lines['directory_restriction_type']), "http_and_https": "{}".format(isTrue(lines['http_and_https'])), "url": "{}".format(lines['url'])})    
               
                
                # if is the last entry of the csv file, then close out the array and add a comma
                if(lastLine.partition(',')[0] == lines['directory_restriction_type']  and lastLine.partition(',')[2].partition(',')[0] == lines['http_and_https'] and lastLine.partition(',')[2].partition(',')[2] == lines['url']):
                    break
                
            # End for Loop #####################################################################################
        # End reading CSV ######################################################################################    
        if(DEBUG):
            print(json.dumps(blocklist_configuration))
        return blocklist_configuration
    except:
        print("The CSV file failed to load", blocklistCSV)
        return 1

### Function name: allowlistConfigCSVtoJSOn
### Precondition: takes a allowlist csv file and formats it into an acceptable allowed_hosts list to be passed to the API for a web application scan request
def allowlistConfigCSVtoJSON(allowlistCSV: str = "allowlist.csv"):
    # initialization of variables ##########################################################################
    if(DEBUG): lineCount = 0
    
    # Todo: check to see if the last line is blank
    try:
        # identifying the last line of the csv ##################
        fileLastLine = open(allowlistCSV, "r")
        lastLine = fileLastLine.readlines()[-1]
        if(lastLine == None or lastLine == str()):
            print("Error: Last Line is blank")
        fileLastLine.close()
        #########################################################
        
        # intializing configuration block
        allowlist_configuration= { "allowed_hosts": [] }
        # End initialization of variables ######################################################################

        # Todo: check to see if the CSV file exists, if not error or default to user input 
        # Opening up the CSV ###################################################################################
        
        with open(allowlistCSV, mode = 'r') as file:
            csvFile = csv.DictReader(file)
            # Looping through the csvFile converted to a Dictionary ############################################
            for lines in csvFile:
                #print(lines)
                if(DEBUG): 
                    lineCount+= 1
                    
                allowlist_configuration["allowed_hosts"].append({"directory_restriction_type": "{}".format(lines['directory_restriction_type']), "http_and_https": "{}".format(isTrue(lines['http_and_https'])), "url": "{}".format(lines['url'])})    
               
                
                # if is the last entry of the csv file, then close out the array and add a comma
                if(lastLine.partition(',')[0] == lines['directory_restriction_type']  and lastLine.partition(',')[2].partition(',')[0] == lines['http_and_https'] and lastLine.partition(',')[2].partition(',')[2] == lines['url']):
                    break
                
            # End for Loop #####################################################################################
        # End reading CSV ######################################################################################    
        if(DEBUG):
            print(json.dumps(allowlist_configuration))
        return allowlist_configuration
    except:
        print("The CSV file failed to load", allowlistCSV)
        return None

### Function name: FormatAnalysisRequest
### Precondition: takes the values specified, and formats a request and writes out the request to an input.json which can then be sent to create a new scan
###               NOTE: This is the formatAnalysisRequest function for Web Application Scan configuration, one for the API Scan will be added to this program at a later time
def formatAnalysisRequest(scanName: str,                                                                                    # Analysis Name
                        scanConfiguration: bool = True,                                                                     # Include ScanConfiguration
                        baseURL: str = '' ,                                                                                 # If ScanConfiguration is true, used as the base url for the target url
                        allowlist: bool = True,                                                                             # Include allowlist configuration
                        allowlistData: dict = allowlistConfigCSVtoJSON(),                                                                           # If allowlist is true, use allowlist Dictionary as the allowed_hosts
                        orgInfo: bool = False,                                                                              # Include Org Information in the analysis request
                        orgInfoData: dict = { "org_info": { "email": "example@email.com", "owner": "" } },                  # If OrgInfo is true, then use the orgInfoData for the org info
                        http_and_https: str = isTrue(True),                                                                 # To include both http_and_https globally for the blocklist and allowlist
                        blocklist: bool = False,                                                                            # Include the blocklist
                        blocklistConfig: dict = { "blocklist_configuration": {"black_list": [] } } ,                        # The blocklist configuration data to include for the singular URL in the analysis configured
                        visibility:bool = False,                                                                            # Include Visibility Data
                        visibilityData: dict = {"visibility": { "setup_type": "SEC_LEADS_ONLY", "team_identifiers": []}},   # The visibility data to include
                        glScanSetting: bool = False,                                                                        # Include Global Scan Settings
                        glScanSettingData: dict = {},                                                                       # Global Scan Setting Data to include
                        scanSchedule: bool = True,                                                                          # Include Scan Schedule 
                        scheduleData: dict =  scheduleNow(False)                                                            # Schedule data to include NOTE: scheduleNow has been tested, the other function is experimental and the scan json may need to be modified first if the other function is used to make it valid
                        #scannerVariables: bool = False,      # [EXPERIMENTAL]                                              # Include Scanner Variables
                        #scannerVariablesData: dict = {}      # [EXPERIMENTAL]                                              # Scanner Variable Data to include
                        ):                                                        


    analysisRequest= { "name": scanName } 
    if(orgInfo):                                                                                             # under org info on the analysis request
        analysisRequest.update(orgInfoData)
    if(scanConfiguration):                                                                                   # under scans on the analysis request
        scanConfig = { "scans": [ {
            "scan_config_request": {
                "target_url": {
                    "url": "{}".format(baseURL),
                    "http_and_https": "{}".format(http_and_https)
                },
                
            }
        }] }
        if(blocklist):
            ((scanConfig["scans"][0])["scan_config_request"]).update( {"scan_setting": {} })
            ((scanConfig["scans"][0])["scan_config_request"])["scan_setting"].update( blocklistConfig)

        if(allowlist):
            ((scanConfig["scans"][0])["scan_config_request"]).update( allowlistData )
        analysisRequest.update(scanConfig)
    if(scanSchedule):                                                                                        # under schedule on the analysis request
        analysisRequest.update(scheduleData)
    if(visibility):                                                                                          # under visibility on the analysis request
        analysisRequest.update(visibilityData)
    if(glScanSetting):                                                                                       # under scan settings on the analysis request
        analysisRequest.update(glScanSettingData) 
    
    file = open("input.json", "w")
    if(DEBUG and VERBOSE): print(json.dumps(analysisRequest))
    # default writes out to file
    if(DEBUG): print("Wrote output to file ", file.name)
    json.dump(analysisRequest, file)
    file.close()
    return json.dumps(analysisRequest)



def is_valid_email(email):
    # Regular expression pattern for a simple email validation
    email_pattern = r'^[\w\.-]+@[\w\.-]+\.\w+$'
    
    if re.match(email_pattern, email):
        return True
    else:
        return False






def __main__():
    ## Variable initialization
    blocklist_include = False
    allowlist_include = False
    loopUserInput = ""
    scan_name = ""
    scan_url = ""
    org_email = ""
    org_owner = ""
    if(argAnalysisName != ""):
        scan_name = argAnalysisName
    if(argBaseUrl != ""):
        scan_url = argBaseUrl
    if(argEmail != ""):
        org_email = argEmail
    if(argOrgOwner != ""):
        org_owner = argOrgOwner
    
    if ( stdout and (scan_name != "") and (scan_url != "") and (org_email != "") and (org_owner != "")):
        request = formatAnalysisRequest(scan_name,True,scan_url,allowlist_include,( allowlistConfigCSVtoJSON() if (allowlist_include) else {} ), True,{ "org_info": { "email": org_email,"owner": org_owner } }, isTrue(True),blocklist_include,(blocklistConfigCSVtoJSON() if (blocklist_include) else {}),True) #,False ,blocklistConfigCSVtoJSON("glblocklist-1.csv"),'',False, scheduleScan())
        print(request)
        return request
    
    # User input
    scan_name = input("Enter the Analysis name: ")
    scan_url = input("Enter the scan base URL: ")
    #org_email = input("Enter the email the org owner email (to be notified about the scan): ")
    # Check if the input is a valid email address
    while True:
        org_email = input("Enter the email the org owner email (to be notified about the scan): ")
        if is_valid_email(org_email):
            break
        else:
            print("Invalid email address!")
            continue

    org_owner = input("Enter the name of the org owner name: ")
    
    # Light user response checking
    loopUserInput = "DEF"
    while not (loopUserInput == "n" or loopUserInput == "no" or loopUserInput == "") or not (loopUserInput == "y" or loopUserInput == "ye" or loopUserInput == "yes"):
        # User input
        loopUserInput = (input("Do you want to include a allowlist configuration for this URL ? [ (Y)es or (N)o ]: ").lower())
        if (loopUserInput == "y" or loopUserInput == "ye" or loopUserInput == "yes"):
            allowlist_include = True                                                                     
            break                                                                                          # redundent, put in place as a loop control safety
        elif (loopUserInput == "n" or loopUserInput == "no" or loopUserInput == ""):                       # redundent, put in place as a safety
            allowlist_include = False                                                                    
            break                                                                                          # redundent, put in place as a loop control safety
        else:
            print("Invalid input, please enter in Y for Yes or N for No")

    if(DEBUG):
        print("[DEBUG] ============================================  Running post loop checks  ============================================")
        if((loopUserInput == "n" or loopUserInput == "no" or loopUserInput == "") and allowlist_include):
            print("[Error]: manipulation detected. User input is N and the blocklist boolean is True")
            print("Please ensure that variables are in the proper scope")
            input("Exiting... Press enter to close.")
            exit(1)
        elif((loopUserInput == "y" or loopUserInput == "ye" or loopUserInput == "yes") and not allowlist_include):
            print("[Error]: manipulation detected. User input is Y and the blocklist boolean is False")
            print("Please ensure that variables are in the proper scope")
            input("Exiting... Press enter to close.")
            exit(1)
        else:
            print("[DEBUG] Passed...")

    if(allowlist_include):
        print("Place the allowlist host values in the allowlist.csv in the current folder location. Make sure that it is in the proper format")
        print("The proper format for the allowlist:")
        print("directory_restriction_type,http_and_https,url")
        print("""FOLDER_ONLY,TRUE,www.veracode.com,
                FILE,TRUE, www.veracode.com,
                NONE, TRUE, www.veracode.com,
                DIRECTORY_AND_SUBDIRECTORY, TRUE, www.veracode.com """)
        print("Ensure that the urls provided are valid domains or ip addresses")
        print("Note: That this is currently configured for the creation of new analysis not the updating of an analysis in the platform.\nLater versions will include the ability to update an Analysis and URLs in the platform")
    
    input("Press enter to continue...")

    # Light user response checking
    loopUserInput = "DEF"
    while not (loopUserInput == "n" or loopUserInput == "no" or loopUserInput == "") or not (loopUserInput == "y" or loopUserInput == "ye" or loopUserInput == "yes"):
        # User input
        loopUserInput = (input("Do you want to include a blocklist configuration for this URL ? [ (Y)es or (N)o ]: ").lower())
        if (loopUserInput == "y" or loopUserInput == "ye" or loopUserInput == "yes"):
            blocklist_include = True                                                                     
            break                                                                                          # redundent, put in place as a loop control safety
        elif (loopUserInput == "n" or loopUserInput == "no" or loopUserInput == ""):                       # redundent, put in place as a safety
            blocklist_include = False                                                                    
            break                                                                                          # redundent, put in place as a loop control safety
        else:
            print("Invalid input, please enter in Y for Yes or N for No")
            #continue
    
    if(DEBUG):
        print("[DEBUG] ============================================  Running post loop checks  ============================================")
        if((loopUserInput == "n" or loopUserInput == "no" or loopUserInput == "") and blocklist_include):
            print("[Error]: manipulation detected. User input is N and the blocklist boolean is True")
            print("Please ensure that variables are in the proper scope")
            input("Exiting... Press enter to close.")
            exit(1)
        elif((loopUserInput == "y" or loopUserInput == "ye" or loopUserInput == "yes") and not blocklist_include):
            print("[Error]: manipulation detected. User input is Y and the blocklist boolean is False")
            print("Please ensure that variables are in the proper scope")
            input("Exiting... Press enter to close.")
            exit(1)
        else:
            print("[DEBUG] Passed...")

    if(blocklist_include):
        print("Place the blocklist host values in the blocklist.csv in the current folder location. Make sure that it is in the proper format")
        print("The proper format for the blocklist:")
        print("directory_restriction_type,http_and_https,url")
        print("""FOLDER_ONLY,TRUE,www.veracode.com,
                FILE,TRUE,www.veracode.com,
                NONE, TRUE, www.veracode.com,
                DIRECTORY_AND_SUBDIRECTORY, TRUE, www.veracode.com """)
        print("Ensure that the urls provided are valid domains or ip addresses")
        print("Note: That this is currently configured for the creation of new analysis not the updating of an analysis in the platform.\nLater versions will include the ability to update an Analysis and URLs in the platform")
    
    input("Press enter to continue...")
    try:
        testString = formatAnalysisRequest(scan_name,True,scan_url,allowlist_include,( allowlistConfigCSVtoJSON() if (allowlist_include) else {} ), True,{ "org_info": { "email": org_email,"owner": org_owner } }, isTrue(True),blocklist_include,(blocklistConfigCSVtoJSON() if (blocklist_include) else {}),True) #,False ,blocklistConfigCSVtoJSON("glblocklist-1.csv"),'',False, scheduleScan())
        print("\n\nThe Request can be found in input.json")
    except:
        print("Error, invalid input, ensure that if you are configuring a blocklist or allowlist the proper csv files are present")

    if(stdout): print(testString)
    #return testString 


__main__()