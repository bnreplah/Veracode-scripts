from veracode_api_py import Findings, Applications
#import csv
from datetime import datetime
from ParseAppGuid import getAppGuid
from ParseSandboxGuid import getSandboxGuid


DEBUG = True

if(DEBUG):
    application_name="Verademo" 

# scan_type options: STATIC, SCA, DYNAMIC, MANUAL
def getFindings( application_name,  sandbox_name=None , scan_type="STATIC"):
    application_guid = None
    sandbox_guid = None
    if (application_name is not None):
        
        application_guid = getAppGuid(application_name)

        if(sandbox_name is not None):
            sandbox_guid = getSandboxGuid(sandbox_name, application_guid)

        if(DEBUG):   
            print(application_guid)

        if sandbox_guid is not None:
            json_report=Findings().get_findings(app=application_guid,sandbox=sandbox_guid,scantype=scan_type)

            if(DEBUG):
                print('-------- Sandbox --------')    
                print(json_report)
                
        else:
            json_report=Findings().get_findings(app=application_guid,scantype=scan_type)
        
        if(DEBUG):
            print('-------- Policy --------')
            print(json_report)
            
        
        return json_report
    
    else:
        return "[ERROR]: Missing Application Name"
    

if(DEBUG):
    getFindings(application_name, None , "SCA")