#! /env/python3.10
import veracode_api_py
from veracode_api_py import apihelper
#import json

vApiHelper = apihelper.APIHelper()
veracodeAPI = veracode_api_py.VeracodeAPI()


import os
from pickle import TRUE  # Used to determine the operating system and for running shell commands
import platform  # Used to determine the operating system

# Variable declarations
DEBUG = True # Current default is true, later change this to False
osname = os.name
osplatform = platform.system()
osversion = platform.release()
osprocess = platform.machine()
osarch = platform.architecture()
username = os.getlogin()
userhome = os.path.expanduser('~')

print("OS Name: " + osname)
print("OS Platform: " + osplatform)
print("OS Version: " + osversion)
print("OS Process: " + osprocess)
print("OS Architecture: " ,osarch)
print("Username: " + username)
print("User Home: " + userhome)

#determines the file path to the credentials file
#credpath = os.path.join( userhome, '.veracode', 'credentials' )
#f = open(credpath, "r")

# Todo:
# Check to see if the credentials file exists
# if it does not exist prompt them with the doucmentation for the credentials file

print(veracodeAPI.healthcheck())