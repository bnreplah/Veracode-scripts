#! /bin/python3.11.0
###
###
###
"""DOC

"""

import ParseAppGuid
#import ParseSandboxGuid
from ParseAppGuid import json, veracodeAPI 


########### DEBUG ############
DEBUG=ParseAppGuid.DEBUG
VERBOSE=ParseAppGuid.VERBOSE
######## END DEBUG ###########
#
#
#
#
#


# Todo: add sanitization
#
#
## Function name: generate SBOM
## Precondition:
## Postcondition:
def generateSBOM(applicationName: str, toFile: bool = False):
    appGuid = ParseAppGuid.getAppGuid(applicationName)
    outSBOM = veracodeAPI.get_sbom(appGuid)
    if(DEBUG): print(outSBOM)
    if(toFile):
        sbomName = str(applicationName) + "-SBOM.json"
        with open(sbomName, 'w') as file:
            json.dump(outSBOM, file)
            if(VERBOSE): print("Wrote out SBOM to file: " + sbomName)

# def generateSBOM(projectName: str, workspaceName: str, toFile: bool = False):
    
    
#     outSBOM = veracodeAPI.get_sbom_project()
#     if(DEBUG): print(outSBOM)
#     if(toFile):
#         sbomName = str(projectName) + "-SBOM.json"
#         with open(sbomName, 'w') as file:
#             json.dump(outSBOM, file)
#             if(VERBOSE): print("Wrote out SBOM to file: " + sbomName)

if (DEBUG):
    generateSBOM("Verademo", True)