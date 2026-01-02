#!/env/python
# Author: Ben Halpern
# Contributors:
# Inspiration: 
# VERSION: 001

import json
#import csv
import veracode_api_py
from veracode_api_py import apihelper

# Description:
#   get the list of all application profiles, then delete the scanner variables, 
#   then once the scanner variables have been deleted, then unlink and then delete the DAST scans
#   
#


# Get the list of all the app profiles
full_application_id_list=[]
linked_applications_id_list=[]
unlinked_application_id_list=[]
dast_scan_ids=[]

full_application_id_list = veracode_api_py.Applications.get_all()

# sequence to check if the DAST scan is linked #

def check_if_application_is_linked ( app_id ):
    linked = bool()
    # add call to check if the scan is linked
    # parse the response
    # check if it is linked

    if(linked):
        linked_applications_id_list += app_id
    
    result = bool()   
    return result



# if the application is linked add it to the linked_application_id_list
# dsc:
# pre:
# pst:
def unlink_application( app_id ):
    # validation to check if the application profile is linked or not already 
    # then formulate the payload to send to the api 
    pass
    # retruns int code, 0 for success, -1 for the application is still linked,
    return int()








