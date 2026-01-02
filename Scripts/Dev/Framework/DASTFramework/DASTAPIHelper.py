#!/env/python
# Author: Ben Halpern
# Contributors:
# Inspiration: 
# VERSION: 001

import json
#import csv
import veracode_api_py
from veracode_api_py import apihelper

verbose = True
vApiHelper = apihelper.APIHelper()
veracodeAPI = veracode_api_py.VeracodeAPI()

# This is where all the magic happens
analysisIds = []
allAnalyses = []
scandIds = []
scans = []
audits = []
# Dast Health Check
## Metrics:
##  High Level:
##      Get From Analysis Occurances
##  Deep Dive:
##      Trace into each scan occurance and generate the full details for report


# Function Name: analysisOccurance2Obj
# Precondition: That API Credentails are stored in a credentials file or loaded into the enviornemnt 
# Postcondition: Will make a call to the dynamic analysis occurances and return objects with the populated analysis and generate a series of high level reports to go with it
def analysisOccurance2Obj():
    l_analysisIds = []
    allAnalyses = veracodeAPI.get_analyses()
    
    print("--------------------------------------")
    for analysis in allAnalyses:
        if verbose:
            print(analysis)
        print("--------------------------------------")
        print("Name: \t\t\t\t\t" + str(analysis['name']))    
        print("Analysis id: \t\t\t\t" + str(analysis['analysis_id']))
        analysisIds.append(str(analysis['analysis_id']))
        l_analysisIds.append(str(analysis['analysis_id']))
        if 'latest_occurence' in analysis['_links']:
            print("Latest Occurence: \t\t\t" + str(analysis['_links']['latest_occurrence']['href']))
        if 'schedule_summary' in analysis:
            if analysis['schedule_summary']['schedule_status'] == "COMPLETED":
                if 'analysis_result' in analysis['_links']:
                    print("Results Available: \t\t\t" + str(analysis['_links']['analysis_result']['href']))
                if 'analyses_occurences' in analysis['_links']:
                    print("Analyses Occurences: \t\t\t" + str(analysis['_links']['analyses_occurences']['href']))
                if 'latest_verification_occurrence_status' in analysis:
                    print("Latest Verification Occurrence Status: \t" + str(analysis['latest_verification_occurrence_status']['status_type']))
            
        print("Number of Scans: \t\t\t" + str(analysis['number_of_scans']))
        print("Schedule Frequency: \t\t\t" + str(analysis['schedule_frequency']['frequency_type']))
        print("Scan Type: \t\t\t\t" + str(analysis['scan_type']))
        if 'latest_occurrence_date_time' in analysis:
            print("Latest Occurrence Date and Time: \t" + str(analysis['latest_occurrence_date_time']))
        
    return l_analysisIds

# Function Name:
# Precondition: Populate all the analysis ID into an analysis object and populate that into an array
# Postcondition:
def analysisList():
    print(analysisIds)

def getAnalysisOccurences():
    return veracodeAPI.get_analysis_occurrences()    

def getAnalysisAudits(aid):
    return veracodeAPI.get_analysis_audits(aid)

def getAnalysisScans(aid):
    return veracodeAPI.get_analysis_scans(aid)

def getScanAudits(sguid):
    return veracodeAPI.get_dyn_scan_audits(sguid)

def getAnalysesScans():
    l_scans = []
    for id in analysisIds:
        tmp = getAnalysisScans(id)
        l_scans.append(tmp)
        scans.append(tmp)
    return l_scans

def getAnalysesScans(analysisIds: []):
    l_scans = []
    for id in analysisIds:
        tmp = getAnalysisScans(id)
        l_scans.append(tmp)
        scans.append(tmp)
    return l_scans

def getAnalysesAudits():
    l_audits = []
    for id in analysisIds:
        tmp = getAnalysisAudits(id)
        l_audits.append(tmp)
        audits.append(tmp)
    return l_audits
    


    
# "name": "verademo-DA-00",
#       "_links": {
#         "self": {
#           "href": "https://api.veracode.com/was/configservice/v1/analyses/89031c20ec68bb729746853cf7b23e49"
#         },
#         "audits": {
#           "href": "https://api.veracode.com/was/configservice/v1/analyses/89031c20ec68bb729746853cf7b23e49/audits"
#         },
#         "scans": {
#           "href": "https://api.veracode.com/was/configservice/v1/analyses/89031c20ec68bb729746853cf7b23e49/scans"
#         },
#         "analysis_result": {
#           "href": "https://analysiscenter.veracode.com/auth/index.jsp#ReviewResultsOneWASFlaws:90764:1520370:20506179:::20493645::414845:1"
#         },
#         "analysis_occurrences": {
#           "href": "https://api.veracode.com/was/configservice/v1/analysis_occurrences?analysis_id=89031c20ec68bb729746853cf7b23e49"
#         },
#         "latest_occurrence": {
#           "href": "https://api.veracode.com/was/configservice/v1/analysis_occurrences/ae435e9d7a23f18cafc6bb9e7de5142d"
#         }
#       },
#       "created_on": "2022-08-29T23:19:59Z[UTC]",
#       "last_modified_on": "2023-05-22T15:25:12Z[UTC]",
#       "capabilities": [
#         "stop_and_save_analysis_occurrence",
#         "stop_and_delete_analysis_occurrence",
#         "link_platform_result",
#         "update_analysis",
#         "delete_analysis",
#         "view_analysis_history"
#       ],
#       "analysis_id": "89031c20ec68bb729746853cf7b23e49",
#       "org": "90764",
#       "latest_verification_end_date_time": "2023-05-22T15:29:44Z[UTC]",
#       "number_of_scans": 1,
#       "latest_occurrence_date_time": "2022-08-29T23:46:21Z",
#       "latest_occurrence_end_date_time": "2022-08-30T00:46:21Z",
#       "latest_occurrence_id": "ae435e9d7a23f18cafc6bb9e7de5142d",
#       "actions": [],
#       "schedule_frequency": {
#         "frequency_type": "PRESCAN_ONLY"
#       },
#       "throttled": false,
#       "has_verification_failures": false,
#       "scan_type": "WEB_SCAN",
#       "latest_occurrence_status": {
#         "status_type": "FINISHED_RESULTS_AVAILABLE"
#       },
#       "has_result_import_in_progress": false,
#       "latest_verification_occurrence_status": {
#         "status_type": "FINISHED_VERIFYING_RESULTS"
#       },
#       "latest_verification_occurrence_id": "dd065744c32b0098f326630b9e5fb544"
#     }


def debug():
    print("Running Debug Mode")
    analysisOccurance2Obj()
    analysisList()
    analysis_scans = veracodeAPI.get_analysis_scans(analysisIds[0])
    print(analysis_scans)
    print("\n\n\n")
    print(getAnalysisScans(analysisIds[0]))
    #getAnalysisAudits(analysisIds[0])
    #getAnalysesScans()
    #getAnalysesAudits()
    #print(scans)
    #print(audits)

debug()