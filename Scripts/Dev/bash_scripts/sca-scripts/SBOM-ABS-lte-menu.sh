#!/bin/bash
# Requires HTTPie to be installed https://docs.veracode.com/r/c_httpie_tool
# Requires veracode python authentication libary to be installed https://docs.veracode.com/r/t_install_api_authen 
# Requires Veracode API Keys to be either in a credential file or stored in the enviornment 
ret_value=0
help(){
        echo "Generate an SBOM from an Agent Based Project"
        echo "Requirements:"
        echo "- Python Installed, Pip Installed"
        echo "- HTTPie Python Module Installed: https://docs.veracode.com/r/c_httpie_tool"
        echo "- Veracode Authentication Library Installed: https://docs.veracode.com/r/t_install_api_authen"
        echo "- Veracode API Credentials stored as environmental variables VERACODE_API_KEY_ID VERACODE_API_KEY_SECRET or create a credentials file: https://docs.veracode.com/r/t_store_creds_linux_env"
        echo "Usage: ./$0 <WorkspaceName> <ProjectName>"
        echo "Output: <ApplicationProfileName>-SBOM.json"

}
# Add input sanitization on the calls to improve security in your pipelines or add variable sanitization before entry into the script

checkElementsWorkspace(){
        echo "Parsing Workspace Guid"
        elements=$( cat sbom-workspaces.json | jq -r '.page.total_elements'  )
        if [ "$elements" -eq "0" ]; then
                echo "No Workspaces found matching that name"
                ret_value=1
        else
                echo "$elements Workspaces found matching that name, generating sbom from the first match"
                ret_value=0
        fi

}


checkElementsProjects(){
        echo "Parsing Project Guid"
        elements=$( cat sbom-projects.json | jq -r '.page.total_elements'  )
        if [ "$elements" -eq "0" ]; then
                echo "No Workspaces found matching that name"
                ret_value=1
        else
                echo "$elements Workspaces found matching that name, generating sbom from the first match"
                ret_value=0
        fi

}


cleanUp(){
        rm sbom-workspaces.json
        rm sbom-projects.json
}

if [ -z "$1" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        help
elif [ -n "$1" ]; then

        name="$1"
        http --auth-type=veracode_hmac -o sbom-workspaces.json "https://api.veracode.com/appsec/v3/workspaces?workspace=$name"

        checkElements
        if [ "$ret_value" -eq "0" ];then

                #echo "Applications returned"
                appid=$( cat sbom-application.json | jq -r '._embedded.applications[0].id' )
                appguid=$( cat sbom-application.json | jq -r '._embedded.applications[0].guid' )
                http --auth-type=veracode_hmac -o $name-SBOM.json "https://api.veracode.com/srcclr/sbom/v1/targets/$appguid/cyclonedx?type=application"
                echo "SBOM written to $name-SBOM.json"

        elif [ "$ret_value" -eq "1" ]; then

                echo "No applications returned"
                cleanUp
                exit 1
        else

                echo "Error"
                cleanUp
                exit 2
        fi
        cleanUp
else
        echo "Error: Invalid input"
        help
fi
workspaceGUID = "$1"
veracode-http "https://api.veracode.com/srcclr/v3/workspaces/$workspaceGUID/projects?type=agent"
projectGUID = "$2"
veracode-http "https://api.veracode.com/srcclr/sbom/v1/targets/$projectGUID/cyclonedx?type=agent