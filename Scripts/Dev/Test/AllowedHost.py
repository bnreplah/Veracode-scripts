# WhiteList.py 
#
#
# The white list configuration goes under the allowed_host which is under the scan configuration or the scan configuration request
#
#
#
#
#
#
#

import veracode_api_py
from veracode_api_py import apihelper
import json
import csv
vApiHelper = apihelper.APIHelper()
veracodeAPI = veracode_api_py.VeracodeAPI()

# scanURL = {"directory_restriction_type": "DIRECTORY_AND_SUBDIRECTORY",
#            "http_and_https": True,
#            "url": }

# Configuration switches
DEBUG = False
VERBOSE = False

# "whitelist_configuration": {
#       "white_list": [
#         {
#           "directory_restriction_type": "DIRECTORY_AND_SUBDIRECTORY",
#           "http_and_https": true,
#           "url": "string"
#         }
#       ]
#     },


if(DEBUG):
    whitelistFileName = "whitelist.csv"
    if(VERBOSE):
        print(f"Using CSV file named {whitelistFileName}. Please ensure that the file is located in the same directory")

# Middleware
def isTrue(value):
    if (str(value).casefold() == "true"):
        return "true"
    else:
        return "false"

# checks to see last line
# Todo: Improve this block    
        
# Todo:

# Precondition:
# Postcondition:
def whitelistConfigCSV(whiteListCSV = "whitelist.csv"):
    
    
    
    # identifying the last line of the csv
    fileLastLine = open(whiteListCSV, "r")
    lastLine = fileLastLine.readlines()[-1]
    fileLastLine.close()

    # intiating configuration block
    whitelist_configuration='''"whitelist_configuration":{
            "white_list": '''

    print("LastLine " + lastLine)

    # itterating through the CSV
    with open(whitelistFileName, mode = 'r') as file:
        csvFile = csv.DictReader(file)
        
        if(DEBUG):
            print('''
            "whitelist_configuration":{
            "white_list": 
            ''')

        for lines in csvFile:
            #print(lines)
            whitelist_configuration+= "[{"
            if(DEBUG):
                print("[")
                print('\t{')
                print('\t\t "directory_restriction_type": "' + lines['directory_restriction_type'] + '",' )
                print('\t\t "http_and_https": ' + isTrue(lines['http_and_https']) + ',')
                print('\t\t"url": "' + lines['url'] + '"')
                print('\t}')
                print(']')
                if(VERBOSE):
                    print(lastLine)
                    print(lines['directory_restriction_type'])
                    print(lines['http_and_https'])
                    print(lines['url'])
                    print("partitioning")
                    print(lastLine.partition(',')[0] )
                    print(lastLine.partition(',')[2].partition(',')[0])
                    print(lastLine.partition(',')[2].partition(',')[2])
                    print(lastLine.partition(',')[0] == lines['directory_restriction_type'] )
                    print(lastLine.partition(',')[2].partition(',')[0] == lines['http_and_https'])
                    print(lastLine.partition(',')[2].partition(',')[2] == lines['url'])
                
            whitelist_configuration+= '''
            "directory_restriction_type": "{directory_restriction_type}",
            "http_and_https": {http_and_https},
            "url": "{url}"'''.format(directory_restriction_type=lines['directory_restriction_type'], http_and_https=isTrue(lines['http_and_https']), url=lines['url'] )
            whitelist_configuration+='}]'
            

            if(lastLine.partition(',')[0] == lines['directory_restriction_type']  and lastLine.partition(',')[2].partition(',')[0] == lines['http_and_https'] and lastLine.partition(',')[2].partition(',')[2] == lines['url']):
                whitelist_configuration+='},'

                
                if(DEBUG):
                    print('},')
                    if(VERBOSE):
                        print("Last Line of CSV")
            else:
                whitelist_configuration+=','
                if(DEBUG):
                    print(',')
    if(DEBUG):                
        if(VERBOSE):
            print("\n\nFinished product:")
        
        print(whitelist_configuration)
    
    return whitelist_configuration
