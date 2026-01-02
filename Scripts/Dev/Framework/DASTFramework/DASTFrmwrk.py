# DASTConfigurationRequest.py
# Description:
#   This is the housing script that will piece together the other DAST configurations and send out the request to kick off a scan
#   The main driver/entry point
#
#
#
#
#
#
#
#

import json
#import DASTRequest
#import BulkDynHelper
import DASTStatus
import DASTTests
import DASTRequest
import DASTHooks
import DASTWebApp
import DASTAPIHelper
#
#
#
#
#
#
DEBUG = True

def menu():
    print("---------------------------------------------------------------------")
    print("| DAST Framework Options: ")
    print("|    a) Create Scans") # uses DASTRequest, DASTAPIScan, DASTRequest
    print("|    b) Manage Scans") # Goes to 
    print("|    c) Review Scans") # Goes to DAST Status
    print("|    d) Advanced Options") 
    print("|    e) Integrations") #
    print("---------------------------------------------------------------------")
def __main__():
    pass


if (not DEBUG):
    __main__()
else:
    DASTAPIHelper.debug()


