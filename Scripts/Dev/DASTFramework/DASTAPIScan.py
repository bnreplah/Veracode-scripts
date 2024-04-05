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