#! /env/python3
# File:     
# Author:   Ben Halpern - Veracode
# Role:     Associate CSE
# Manager:  Justin Yao
# Date:     09/06/22
#
import subprocess
import platform                                                # Used to determine the operating system
import os                                                      # Used to determine the operating system and for running shell commands
 
"""DOCSCRIPT:
The purpose of this script is to provide a convenient script that runs checks and installs 
the various veracode SaaS on the computer. It provides walk throughs to specify what is needed next and where to get it
The purpose of this script is to optimize the installation understanding.
Also checks the application for the proper build software, installs them if necessary
Hooks into APIs to provide a UI for the API backend

"""

# This is an MD5SUM of the Pipeline Scanner Zip
SAST_MD5SUM = "92a99cfa495d948f6ad72afd9668a939"
print("==============================================================")
print("================  Veracode SAST Installer ====================")
print("==============================================================")

# Variable declarations
debug = True # Current default is true, later change this to False
osname = os.name
osplatform = platform.system()
osversion = platform.release()
osprocess = platform.machine()
osarch = platform.architecture()

apiconfig = False # default is false, true when the apiconfig has been configured and detected

# Determine username
username = os.getlogin()
userhome = os.path.expanduser('~')

# poor practice, remove after testing, after sanitization, try to load the API key directly for less storage within the script
api_id_temp = ""  # temporary string to hold the API ID
api_key_temp = "" # temporary string to hold the API KEY




# step one:
#           Check to see operating system
#           Get API credentials
#           docker method
#           httpie method
#           actions menu

#subprocess.run()
################################################################################################################################################################################################################################
# Determining the enviornment ##################################################################################################################################################################################################
################################################################################################################################################################################################################################


# Check to see the operating system
print("\n\n==============  Determining operating system =================\n\n")
if(debug):
    print("[Debug] Name of the operating system: ", os.name)
    print("[Debug] Name of the OS System is running on: ", platform.system())
    print("[Debug] Name of the Operating System version: ", platform.release())
    print("[Debug] Name of the platform Machine: ", platform.machine())
    print("[Debug] Name of the platform architecture: ", platform.architecture())
    print("[Debug] Name of the User logged in: ", os.getlogin())
    print("[Debug] User Home: ", os.path.expanduser('~'))
    print("[Debug] [Windows] Location of credentials file if present: ", os.path.expanduser('~') + "\.veracode\credentials")

################################################################################################################################################################################################################################
# Enviornment Conditional Logic ################################################################################################################################################################################################
################################################################################################################################################################################################################################



# Pass this information to a condinal logic or switch and then run the commands accordingly
# Depending on the enviornmnet, determine if is being run in a CI/CD
# Depending on the enviornment, if not being run in a CI/CD then find out the user name in order to find the credentials file
    # otherwise prompt the user for the location of the credentials file
    # otherwise prompt the user for the creation of a credentials file
        # Request the user to go to the platform and generate API keys, and provide them into the script, the script will initialize the credentials file

if(osname == "nt" or osplatform == "Windows"):
    print("You are running a windows based machine")
    # Windows command block

elif(osname == "posix" or osplatform == "Linux"):
    print("You are running on a linux based machine")
    # linux command block

else:# Todo: add a mac os block
    print("Your machine is currently undeterminable")




################################################################################################################################################################################################################################
# API Credentials  #############################################################################################################################################################################################################
################################################################################################################################################################################################################################


print("\n\nIn order to use this script, you need to have the proper veracode permissions")
#TODO: check prerequesites:
#       - Check OS
#       - Check version of python installed
#       - check to see logged in username and location to save api credentials file

# Check to see if credentials file exists otherwise prompt the user to generate credentials



#print("You must aquire api credentials and place them in a file as specified by the veracode documentation")
#print("1) Log in to the Veracode Platform.")
#print("2) From the user account dropdown menu, select API Credentials option. Alternatively, from the homescreen click on the Generate API Credentials button if available")
#print("Click Generate API Credentials")
#print("Copy the ID and secret key to a secure place. Veracode recommends storing your credentials in an API Credentials file")
#api_id_input = input("API ID: ")
#api_key_input = input("API_KEY: ")
#TODO: check to see if the credentials file exists
#TODO: if exists move the old one to credentials.old
#TODO: create new credential file with the format
# 
# [default]
# veracode_api_key_id = {your_api_key_id}
# veracode_api_key_secret = {your_api_secret_key}
#print("-----------  Creating API Credentials file  -------------")
#TODO: Create a file with python and load the credentials in the file.
#TODO: verify that the credential file was created succesfully


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Docker method
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#TODO: Check to see if docker is installed
#TODO: Check to see if the operating system is supported
#TODO: Check to see if the docker installation is possible
#TODO: Check to see if the docker pull is succesful
#TODO: Check to see if the API Wrapper is able to be installed
#TODO: Check to see if the Pipeline scan is able to be pulled
#TODO: Check to see if the API-Signing is able to be pulled
#docker pull veracode/pipeline-scan
#docker pull veracode/api-signing
#docker pull veracode/api-wrapper-java

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# HTTPie Method
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~






#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Java method
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#TODO: Check to see if java is installed on the computer
#TODO: Check to see what version of java is downlaoded on the computer
#TODO: Check to see if can install java on the computer
#TODO: Attempt to run the java api wrapper 
#https://search.maven.org/search?q=a:vosp-api-wrappers-java
#https://docs.veracode.com/r/dW~~S13ypwpf3Z5jpcW5Ow/kte_sF_P9J7Y2qK~aH2JJw

#TODO: Use API Wrapper to see if the credentials are correct
#TODO: Get the available permissions from API

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# C# wrapper method
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Install SRCCLR
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#TODO: Get source clear agent for the os
#TODO: Instructions for installation
#TODO: Query token and pass to srcclr activate command
#TODO: run srcclr test command

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Actions menu Menu
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# SRCCLR


# UPLOAD and SCAN


# API Actions




#print("Testing out api credentials")
#TODO: Add link
#TODO: API Credentials initialization
#TODO: Check that docker is installed
#TODO: If not installed then install docker
#TODO: Check that the version of docker installed is up to date
#TODO: Check Operating System Type
#TODO: If Running in Unix based system allow for the install of docker images
#TODO: IF not running Unix based system install the jar files neccessary for scanning
#TODO: Check if java 8 JDK is insalled on the computer
#TODO: If not installed then install java 8 JDK
