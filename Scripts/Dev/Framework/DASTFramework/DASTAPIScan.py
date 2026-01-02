# Actions that would be available in the following modules
# - List out all API Scans
# - Review an API specification
#   - Run a health check on an API specification, to see that it is configured properly
#   - Use the har file in the API specification health check
# - Run a prescan on the API scan
# - Get Recomendations on the prescan
# - Get Recomendations on the full scan
# - TEST Authentication from the API Scan [ Experimental ]
# - Configure an API scan
# - Compare an API Scan
# - Review an API Scan Results
# - Confirm an API Scan Results [ Experimental ]



import DASTAPIHelper

analysis_ids=DASTAPIHelper.analysisOccurance2Obj()
print(analysis_ids)
scans=DASTAPIHelper.getAnalysesScans(analysis_ids)[0]
print(scans)
print("Scans::::::")
for scan in scans:
    if 'latest_occurrence_verifications' in scan:
        for verification in scan['latest_occurrence_verifications']:
            print(str(verification['verification_type']) + " : <<Successful?>> " + str(verification['success']) )