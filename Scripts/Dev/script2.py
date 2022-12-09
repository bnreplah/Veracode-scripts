#! /env/python3.10
# ======================================
#     ##########        #####
#     ##      ##       ## ###
#     ##      ##          ###
#     ##      ##          ###
#     ##########      ###########
# ===========   Veracode   =============   
# ======================================
# File:   
# Authors:  
#    - Ben Halpern - Veracode
# Role:     Associate CSE
# Manager:  Justin Yao
# Date:     09/06/22
# Version Date: 12/8/2022
# Version: 0.00.001


import os
from pickle import TRUE  # Used to determine the operating system and for running shell commands
import platform  # Used to determine the operating system
import subprocess

#import docker
import veracode_api_py
from veracode_api_py import apihelper

#client = docker.from_env()

"""DOCSCRIPT:
The purpose of this script is to provide a convenient script that runs checks and installs 
the various veracode SaaS on the computer. It provides walk throughs to specify what is needed next and where to get it
The purpose of this script is to optimize the installation understanding.
Also checks the application for the proper build software, installs them if necessary
Hooks into APIs to provide a UI for the API backend

"""
description = """The purpose of this script is ....
"""
# This is an MD5SUM of the Pipeline Scanner Zip



print("==============================================================")
print("================ Veracode Script Installer ===================")
print("==============================================================")

# Variable declarations
DEBUG = True # Current default is true, later change this to False
osname = os.name
osplatform = platform.system()
osversion = platform.release()
osprocess = platform.machine()
osarch = platform.architecture()
vApiHelper = apihelper.APIHelper()
veracodeAPI = veracode_api_py.VeracodeAPI()
apiconfig = False # default is false, true when the apiconfig has been configured and detected





# The idea:
#          There is a global call cache object that holds the actual call and it's parsed data within it
#          There is a Call Object and a Call Class Object
#                   The Call Object will hold meta data and is what is passed to the call stack with an instance of the class in the call list
#                   The Call Object is the executor of the Call Class Object
#                       The Call Class Object is the specific class object for that grouping or action.
#                       Each will share the same variable names and methods, however the difference is in the constants and the actual code within each action
#                       They have the option to be menu driven or automated ( need to figure this switch out )
#                       The reason for the same variable names and  methods being used is so that the calls can be made as the object is passed as a parameter in the call stack
#
#
#
# Global Call Object
#       |           Holds an array of the call objects made in the call history, to be cached and used in subsequent scans
#       |____________ Call Class Object
#                           |_______________ Holds parsed call information for that grouping
#
#
#
#
#
#
#
# HealthCheck API
#
#
#
#
#
#
#
# 
# Application and Sandbox APIs
#
#
#
#
#
#
# Policy APIs
#
#
#
#
#
#
#
# Findings and Reporting APIs
#
#
#
#
#
# Collection APIs
#
#
#
#
#
#
#
#
#
#
# Identity APIs
#
#
#
#
#
#
#
#
# SCA APIs
#
#
#
#
#
#
#
# Dynamic APIs
#
#
#
#
#
#
#
# Upload and Scan
#
#
#
#
#
# Pipeline Scan
#
#
#
#
#
#
#
# SCA Agent-Based Scan
#
#
#


####################################################################################################################
## Template Classes
####################################################################################################################










####################################################################################################################
##  Classes
####################################################################################################################

##
#
#
#
##
class CallCache:

    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        self.callHist = []
        self.callObjects = []
        
    def addCallHist(self, newCall):
        # some check that newcall is what it is supposed to be

        # end 
        # if passes check
        self.callHist.append(newCall)
        return True

    def popCallHist(self):
        self.callHist.pop()




##
#
#
#
##
class CallOBj:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        # Call Variables
        self.rawCall = str()
        self.call = []
        self.callJson = str()
        self.callJsonParsed = []
        
        # Error Variables
        self.error = False
        self.errorCode = int()
        self.errorMessage = str()

        # The name of the call class being used
        self.callClass = str()
        # Call Chaining, the call added to this list will notify the program that there is another call that follows this one
        self.callList = []




##
#
#
#
##
class CallChain:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        self.callStack = []
        self.topIndex = int()
        self.lastCall = CallOBj()
        self.interactiveChain = True






##
#
#
#
##
class HealtCheckCall:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__ (self):
        self.currentIndex = int()
        self.interactiveCall = True
        self.lastOption = int()
        pass

    # Precondition:
    # Postcondition:
    def next(self, index):
        pass
            
    # Precondition: N/A
    # Postcondition: Displays the menu and gets the users selected option
    def menu(self):
        pass    

    # Precondition: N/A
    # Postcondition: returns the interactiveCall variable [True / False]
    def getInteractive(self):
        return self.interactiveCall

    # Precondition: N/A
    # Postcondition: Switches the interactiveCall variable on or off
    def setInteractive(self):
        self.interactiveCall = not self.interactiveCall
        return self.interactiveCall


    # Precondition:
    # Postcondition:
    def action(self, option, interactive = True):
        if(interactive):
            optionSelected = self.menu()

        if():
            pass
        elif():
            pass
        elif():
            pass

        pass


##
#
#
#
##
class AppSandBoxCall:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        self.currentIndex = int()
        self.interactiveCall = True
        self.lastOption = int()
        pass



    # Precondition:
    # Postcondition:
    def next(self, index):
        pass

    # Precondition:
    # Postcondition:
    def menu(self):
        pass

    # Precondition:
    # Postcondition:
    def getInteractive(self):
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def setInteractive(self):
        self.interactiveCall = not self.interactiveCall
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def action(self, option, interactive = True):
        if(interactive):
            optionSelected = self.menu()

        if():
            pass
        elif():
            pass
        elif():
            pass

        pass





##
#
#
#
##
class PolicyCall:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        self.currentIndex = int()
        self.interactiveCall = True
        self.lastOption = int()
        pass

    # Precondition:
    # Postcondition:
    def next(self, index):
        pass

    # Precondition:
    # Postcondition:
    def menu(self):
        pass

    # Precondition:
    # Postcondition:
    def getInteractive(self):
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def setInteractive(self):
        self.interactiveCall = not self.interactiveCall
        return self.interactiveCall


    # Precondition:
    # Postcondition:
    def action(self, option, interactive = True):
        if(interactive):
            optionSelected = self.menu()

        if():
            pass
        elif():
            pass
        elif():
            pass

        pass


##
#
#
#
##
class FindingReportingCall:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        self.currentIndex = int()
        self.interactiveCall = True
        self.lastOption = int()
        pass

    # Precondition:
    # Postcondition:
    def next(self, index):
        pass

    # Precondition:
    # Postcondition:
    def menu(self):
        pass


    # Precondition:
    # Postcondition:
    def getInteractive(self):
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def setInteractive(self):
        self.interactiveCall = not self.interactiveCall
        return self.interactiveCall


    # Precondition:
    # Postcondition:
    def action(self, option, interactive = True):
        if(interactive):
            optionSelected = self.menu()

        if():
            pass
        elif():
            pass
        elif():
            pass

        pass


##
#
#
#
##
class CollectionCall:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        self.currentIndex = int()
        self.interactiveCall = True
        self.lastOption = int()
        pass

    # Precondition:
    # Postcondition:
    def next(self, index):
        pass

    # Precondition:
    # Postcondition:
    def menu(self):
        pass

    # Precondition:
    # Postcondition:
    def getInteractive(self):
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def setInteractive(self):
        self.interactiveCall = not self.interactiveCall
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def action(self, option, interactive = True):
        if(interactive):
            optionSelected = self.menu()

        if():
            pass
        elif():
            pass
        elif():
            pass

        pass



##
#
#
#
##
class IdentityCall:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        self.currentIndex = int()
        self.interactiveCall = True
        self.lastOption = int()
        pass

    # Precondition:
    # Postcondition:
    def next(self, index):
        pass

    # Precondition:
    # Postcondition:
    def menu(self):
        pass

    # Precondition:
    # Postcondition:
    def getInteractive(self):
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def setInteractive(self):
        self.interactiveCall = not self.interactiveCall
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def action(self, option, interactive = True):
        if(interactive):
            optionSelected = self.menu()

        if():
            pass
        elif():
            pass
        elif():
            pass

        pass



##
#
#
#
##
class SCACall:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        self.currentIndex = int()
        self.interactiveCall = True
        self.lastOption = int()
        pass

    # Precondition:
    # Postcondition:
    def next(self, index):
        pass

    # Precondition:
    # Postcondition:
    def menu(self):
        pass

    
    # Precondition:
    # Postcondition:
    def getInteractive(self):
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def setInteractive(self):
        self.interactiveCall = not self.interactiveCall
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def action(self, option, interactive = True):
        if(interactive):
            optionSelected = self.menu()

        if():
            pass
        elif():
            pass
        elif():
            pass

        pass



##
#
#
#
##
class DynamicCall:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        self.currentIndex = int()
        self.interactiveCall = True
        self.lastOption = int()
        pass

    # Precondition:
    # Postcondition:
    def next(self, index):
        pass

    # Precondition:
    # Postcondition:
    def menu(self):
        pass


    # Precondition:
    # Postcondition:
    def getInteractive(self):
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def setInteractive(self):
        self.interactiveCall = not self.interactiveCall
        return self.interactiveCall


    # Precondition:
    # Postcondition:
    def action(self, option, interactive = True):
        if(interactive):
            optionSelected = self.menu()

        if():
            pass
        elif():
            pass
        elif():
            pass

        pass



##
#
#
#
##
class UploadScan:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        self.currentIndex = int()
        self.interactiveCall = True
        self.lastOption = int()
        pass

    # Precondition:
    # Postcondition:
    def next(self, index):
        pass

    # Precondition:
    # Postcondition:
    def menu(self):
        pass


    # Precondition:
    # Postcondition:
    def getInteractive(self):
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def setInteractive(self):
        self.interactiveCall = not self.interactiveCall
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def action(self, option, interactive = True):
        if(interactive):
            optionSelected = self.menu()

        if():
            pass
        elif():
            pass
        elif():
            pass

        pass




##
#
#
#
##
class PipelineScan:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        self.currentIndex = int()
        self.interactiveCall = True
        self.lastOption = int()
        pass

    # Precondition:
    # Postcondition:
    def next(self, index):
        pass

    # Precondition:
    # Postcondition:
    def menu(self):
        pass

    # Precondition:
    # Postcondition:
    def getInteractive(self):
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def setInteractive(self):
        self.interactiveCall = not self.interactiveCall
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def action(self, option, interactive = True):
        if(interactive):
            optionSelected = self.menu()

        if():
            pass
        elif():
            pass
        elif():
            pass

        pass




##
#
#
#
##
class ContainerScan:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__ (self):
        self.currentIndex = int()
        self.interactiveCall = True
        self.lastOption = int()
        pass

    # Precondition:
    # Postcondition:
    def next(self, index):
        pass

    # Precondition:
    # Postcondition:
    def menu(self):
        pass

    # Precondition:
    # Postcondition:
    def getInteractive(self):
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def setInteractive(self):
        self.interactiveCall = not self.interactiveCall
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def action(self, option, interactive = True):
        if(interactive):
            optionSelected = self.menu()

        if():
            pass
        elif():
            pass
        elif():
            pass

        pass



##
#
#
#
##
class SCAAgentScan:
    # Precondition: Default constructor
    # Postcondition: Instantiates class variables
    def __init__(self):
        self.currentIndex = int()
        self.interactiveCall = True
        self.lastOption = int()
        pass

    # Precondition:
    # Postcondition:
    def next(self, index):
        pass
   
    # Precondition:
    # Postcondition:
    def menu(self):
        pass

    # Precondition:
    # Postcondition:
    def getInteractive(self):
        return self.interactiveCall

    # Precondition:
    # Postcondition:
    def setInteractive(self):
        self.interactiveCall = not self.interactiveCall
        return self.interactiveCall


    # Precondition:
    # Postcondition:
    def action(self, option, interactive = True):
        if(interactive):
            optionSelected = self.menu()

        if():
            pass
        elif():
            pass
        elif():
            pass

        pass

    








####################################################################################################################

# Determine username
username = os.getlogin()
userhome = os.path.expanduser('~')

# poor practice, remove after testing, after sanitization, try to load the API key directly for less storage within the script
api_id_temp = ""  # temporary string to hold the API ID
api_key_temp = "" # temporary string to hold the API KEY

################################################################################################################################################################################################################################
# Menu ##################################################################################################################################################################################################
################################################################################################################################################################################################################################
# Move down later

menuRun = True
while(menuRun):
    print("=====================================================================================")
    print("Python UI Wrapper Script ------------------------------------------------------------")
    print(description)
    print("=====================================================================================")
    print(" \t\t1) Healthcheck APIs")
    print(" \t\t2) Application and Sandbox APIs")
    print(" \t\t3) Policy APIs")
    print(" \t\t4) Findings and Reporting APIs")
    print(" \t\t5) Collection APIs")
    print(" \t\t6) Identity APIs ")
    print(" \t\t7) SCA APIs - Must be human user to use these, not API user")
    print(" \t\t8) Dynamic APIs ")
    print(" \t\t9) Upload and Scan")
    print(" \t\t10) Pipeline Scan ")
    print(" \t\t11) SCA Agent-Based Scan")
    print("=====================================================================================")
   
    # !!!!!!!!!!!!!!!! USER INPUT !!!!!!!!!!!!!!!!!!!!!!!!! #
    #########################################################
    selectedMenuOption = int(input("Your Selection [1-11]: "))
    while (selectedMenuOption < 1 or selectedMenuOption > 11 ):
        print("Invalid input")
        selectedMenuOption = int(input("Your Selection [1-11]: "))
    ###########################################################

    if(selectedMenuOption == 1):
        print("=======================================================================")
        print("Healthcheck APIs")
        print("=======================================================================")
        print("\t\t1) Healthcheck")
        print("\t\t2) Status")
        print("\t\t3) return ")
        # !!!!!!!!!!! USER INPUT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
        ##############################################################
        healthCheckOption = int(input("Your Selection [1-3]: "))
        while(healthCheckOption < 1 or healthCheckOption > 3 ):
            print("Invalid input")
            healthCheckOption = int(input("Your Selection [1-3]: "))
        ###############################################################
        if(healthCheckOption == 1):
            veracodeAPI.healthcheck();
            


    elif(selectedMenuOption == 2):
        print("=======================================================================")
        print("Application and Sandbox APIs")
        print("=======================================================================")
        print("\t\t1) Get Apps")
        print("\t\t2) Get App")
        print("\t\t3) Get App by Name")
        print("\t\t4) Create App")
        print("\t\t5) Delete App")
        print("\t\t6) Get Custom Fields")
        print("\t\t7) Get App Sandboxes")
        print("\t\t8) Create Sandbox")
        print("\t\t9) Update Sandbox")
        print("\t\t10) Delete Sandbox")

    elif(selectedMenuOption == 3):
        print("=======================================================================")
        print("Policy APIs")
        print("=======================================================================")
        print("\t\t1) Get Policies")
        print("\t\t2) Get Policy")
        print("\t\t3) Create Policy")
        print("\t\t4) Delete Policy")
        print("\t\t5) Update Policy")
        print("\t6) Return")

    elif(selectedMenuOption == 4):
        print("=======================================================================")
        print("Findings and Reporting APIs")
        print("=======================================================================")
        print("\t\t1) Get Findings")
        print("\t\t2) Get Static Flaw Info")
        print("\t\t3) Get Dynamic Flaw Info")
        print("\t\t4) Get Summary Report")
        print("\t\t5) Add Annotation")
        print("\t\t6) Match Findings")
        print("\t7) Return ")

    elif(selectedMenuOption == 5):
        print("=======================================================================")
        print("Collection APIs")
        print("=======================================================================")
        print("\t\t1) Get Collections")
        print("\t\t2) Get Collectons By Name")
        print("\t\t3) Get Collections By Business Unit")
        print("\t\t4) Get Collections Statistics")
        print("\t\t5) Get Collection")
        print("\t\t6) Get Collection Assets")
        print("\t\t7) Create Collection")
        print("\t\t8) Update Collection")
        print("\t\t9) Delete Collection")
        print("\t10) Return")

    elif(selectedMenuOption == 6):
        print("=======================================================================")
        print("Identity APIs")
        print("=======================================================================")
        print("\t\t1) Get Users")
        print("\t\t2) Get User Self")
        print("\t\t3) Get User")
        print("\t\t4) Get User By Name")
        print("\t\t5) Get User By Search")
        print("\t\t6) Create User")
        print("\t\t7) Update User Roles")
        print("\t\t8) Update User ")
        print("\t\t9) Update User Email Address")
        print("\t\t10) Send Password Reset")
        print("\t\t11) Disable User")
        print("\t\t12) Get Teams")
        print("\t\t13) Create Team")
        print("\t\t14) Update Team")
        print("\t\t15) Delete Team")
        print("\t\t16) Get Business Units")
        print("\t\t17) Get Business Unit")
        print("\t\t18) Create Business Unit")
        print("\t\t19) Update Business  Unit")
        print("\t\t20) Delete Business Unit")
        print("\t\t21) Get API Credentials")
        print("\t\t22) Renew API Credentials")
        print("\t\t23) Revoke API Credentials")
        print("\t\t24) Get Roles")
        print("\t25) Return")

    elif(selectedMenuOption == 7):
        print("=======================================================================")
        print("SCA APIs")
        print("=======================================================================")
        print("\t\t1) Get Workspaces")
        print("\t\t2) Get Workspace by Name")
        print("\t\t3) Create Workspace")
        print("\t\t4) Add Workspace Team")
        print("\t\t5) Delete Workspace")
        print("\t\t6) Get Projects")
        print("\t\t7) Get Project")
        print("\t\t8) Get Project Issues")
        print("\t\t9) Get Project Libraries")
        print("\t\t10) Get Agents")
        print("\t\t11) Get Agent")
        print("\t\t12) Create Agent")
        print("\t\t13) Get Agent Tokens")
        print("\t\t14) Get Agent Token")
        print("\t\t15) Regenerate Agent Token")
        print("\t\t16) Revoke Agent Token")
        print("\t\t17) Get Issues")
        print("\t\t18) Get Issue")
        print("\t\t19) Get Libraries")
        print("\t\t20) Get SCA Events")
        print("\t\t21) Get SCA Scan")
        print("\t\t22) Get Component Scan")
        print("\t\t23) Get SBOM")
        print("\t\t24) Get SBOM Project")
        print("\t25) Return")

    elif(selectedMenuOption == 8):
        print("=======================================================================")
        print("Dynamic APIs")
        print("=======================================================================")
        print("\t\t1) Get Analyses")
        print("\t\t2) Get Analyses By Name")
        print("\t\t3) Get Analyses By Target URL")
        print("\t\t4) Get Analyses By Search Term")
        print("\t\t5) Get Analysis")
        print("\t\t6) Get Analysis Audits")
        print("\t\t7) Get Analysis Scans")
        print("\t\t8) Get Analysis Scanner Variable")
        print("\t\t9) Create Analysis")
        print("\t\t10) Update Analysis")
        print("\t\t11) Update Analysis Scanner Variable")
        print("\t\t12) Delete Analysis Scanner Variable")
        print("\t\t13) Delete Analysis")
        print("\t\t14) Get Dynamic Scan")
        print("\t\t15) Get Dynamic Scan Audits")
        print("\t\t16) Get Dynamic Scan Config")
        print("\t\t17) Update Dynamic Scan")
        print("\t\t18) Delete Dynamic Scan")
        print("\t\t19) Get Analysis Occurance")
        print("\t\t20) Stop Analysis Occurance")
        print("\t\t21) Get Scan Occurance")
        print("\t\t22) Get Scan Occurances")
        print("\t\t23) Stop Scan Occurance")
        print("\t\t24) Get Scan Occurance Verification Report")
        print("\t\t25) Get Scan Occurance Notes Report")
        print("\t\t26) Get Scan Occurance Screen Shots")
        print("\t\t27) Get Codegroups")
        print("\t\t28) Get Code Group")
        print("\t\t29) Get Dynamic Configuration")
        print("\t\t30) Get Dynamic Scan Capacity Summary")
        print("\t\t31) Get Global Scanner Variables")
        print("\t\t32) Create Global Scanner Variables")
        print("\t\t33) Update Global Scanner Variable")
        print("\t\t34) Delete Global Scanner Variable")
        print("\t\t35) Dynamic Setup User Agent")
        print("\t\t36) Dynamic Setup Custom Host")
        print("\t\t37) Dynamic Setup BlockList")
        print("\t\t38) Dynamic Setup URL")
        print("\t\t39) Dynamic Setup Scan Setting")
        print("\t\t40) Dynamic Setup Scan Contact Info")
        print("\t\t41) Dynamic Setup Crawl Script")
        print("\t\t42) Dynamic Setup Crawl Configuration")
        print("\t\t43) Dynamic Setup Login Logout Script")
        print("\t\t44) Dynamic Setup Auth")
        print("\t\t45) Dynamic Setup Auth Config")
        print("\t\t46) Dynamic Setup Scan Config Request")
        print("\t\t47) Dynamic Setup Scan")
        print("\t48) Return")
    elif(selectedMenuOption == 9):
        print("=======================================================================")
        print("Upload and Scan")    
        print("=======================================================================")
    elif(selectedMenuOption == 10):
        print("=======================================================================")
        print("Pipeline Scan")
        print("=======================================================================")
    elif(selectedMenuOption == 11):
        print("=======================================================================")
        print("SCA Agent-Based Scan")
        print("=======================================================================")

    os.system("pause")
    menuRun = False
    # if(DEBUG): menuRun = True
        #XML APIS
        # print("\t\t1) Get App List")
        # print("\t\t2) Get App Info")
        # print("\t\t3) Get Sandbox List")
        # print("\t\t4) Get Build List")
        # print("\t\t5) Get Build Info")
        # print("\t\t6) Get Detailed Report")
        # print("\t\t7) Set Mitigation Info")
        # print("\t\t8) Generate Archer")
        # print("\t\t9) Download Archer")
        # print("\t\t10) Upload Files")
        # print("\t\t11) Get File List")
        # print("\t\t12) Remove File")
        # print("\t\t13) Begin Prescan")
        # print("\t\t14) Get Prescan Results")
        # print("\t\t15) Begin Scan")


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
if(DEBUG):
    print("[Debug] Name of the operating system: ", os.name)
    print("[Debug] Name of the OS System is running on: ", platform.system())
    print("[Debug] Name of the Operating System version: ", platform.release())
    print("[Debug] Name of the platform Machine: ", platform.machine())
    print("[Debug] Name of the platform architecture: ", platform.architecture())
    print("[Debug] Name of the User logged in: ", os.getlogin())
    print("[Debug] User Home: ", os.path.expanduser('~'))
#    print("[Debug] [Windows] Location of credentials file if present: ", os.path.expanduser('~') + "\.veracode\credentials")

################################################################################################################################################################################################################################
# Enviornment Conditional Logic ################################################################################################################################################################################################
################################################################################################################################################################################################################################



# Pass this information to a condinal logic or switch and then run the commands accordingly
# Depending on the enviornmnet, determine if is being run in a CI/CD
# Depending on the enviornment, if not being run in a CI/CD then find out the user name in order to find the credentials file
    # otherwise prompt the user for the location of the credentials file
    # otherwise prompt the user for the creation of a credentials file
        # Request the user to go to the platform and generate API keys, and provide them into the script, the script will initialize the credentials file

# Testing to see if java runs
#os.system("java --version")


if(DEBUG): os.system("pause")

if(osname == "nt" or osplatform == "Windows"):
    if(DEBUG): print("[Debug] You are running a windows based machine")
    # Windows command block

elif(osname == "posix" or osplatform == "Linux"):
    if(DEBUG): print("[Debug] You are running on a linux based machine")
    # linux command block

else:# Todo: add a mac os block
    if(DEBUG): print("[Debug] Your machine is currently undeterminable")




################################################################################################################################################################################################################################
# API Credentials  #############################################################################################################################################################################################################
################################################################################################################################################################################################################################

if(DEBUG): os.system("pause")
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
if(DEBUG): os.system("pause")
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
if(DEBUG): os.system("pause")
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
