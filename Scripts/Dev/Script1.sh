# Author:       Ben-Ami Halpern - Veracode
# Contatct:     bhalpern@veracode.com
# Purpose:
# Date:         9/6/22
# In order to use this script run it on a linux machine and you must have docker installed and created a credential file as specified by Veracode Documentation
echo "============================================================"
echo "==================== DEVELOPMENT SCRIPT ===================="
echo "============================================================"
echo "Description: The purpose of this script is to utilize veracodes APIs easier"
echo "+-----------------------------------------------------------+"
echo "+--------- Checking to see if Docker is installed ----------+"
echo "+-----------------------------------------------------------+"
echo "if this script is running in a wsl2 please start docker \n before running this script"
if [!docker --version ]; then
echo "docker is not installed"
else
echo "docker is operational"
fi
#TODO: check to see that you have docker installed
#TODO: check to see that you have the API credentials in the correct folder
#TODO: Go down the API documentation and get a list of all the commands and create a template style for a menu of commands
#TODO: Show Menu
#EOF
