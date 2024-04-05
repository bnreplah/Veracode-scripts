#!/bin/bash

versioninfo="v2.0.1"
verbose=true
clearprompt=true

function versioninfo {
    echo "--------------------------------------------"
    echo "Version:" $versioninfo
    echo "Author: Ben Halpern - Veracode CSE "
    echo "License information for this tool: https://github.com/bnreplah/Veracode-scripts/blob/main/LICENSE"
    echo "Veracode Databse Lookup Wrapper $versioninfo"
}



function logo {

    echo "============================================"
    echo "====00000000000000==========11111111111====="
    echo "====000========000===========1111111111====="
    echo "====000========000===============111111====="
    echo "====000========000===============111111====="
    echo "====000========000===============111111====="
    echo "====00000000000000============11111111111==="
    echo "============================================"
    echo "      Veracode Database Lookup Wrapper"
    echo "============================================"
    versioninfo
}


function help {
    srcclr --version
    logo
    echo "veradbLookup -h : Help";
    echo "--------------------------------------------"
    echo "Modes"
    echo "~~~~~~~~~~~~~~~~~~~~~~~"
    echo "-p : Prompt mode - enter an interactive prompt"
    echo "-i : Inline mode - follow this parameter by the inline properties to search the database with"
    echo ""
    echo "veradbLookup -p "
    echo "veradblookup -i --type <Package Manager> --namespace <Module/groupId>  --version <Library Version>";
    echo "veradblookup -i --type maven --namespace <Module/GroupId> --artifactid <ArtifactID> --version <Library Version>";
    echo "veradblookup --search <search criteria>"
    echo "Search Parameters:"
    echo "~~~~~~~~~~~~~~~~~~~~~~~"
    echo "-namespace  : Module name or groupId"
    echo "              The primary library name in all cases except for type maven, where the first coordinate (namespace parameter) identifies the groupId in Maven nomenclature."
    echo "              The case sensitivity of the namespace depends on whether the underlying registry distinguishes packages by case."
    echo "              PyPI, for example, is not case-sensitive while Maven is case-sensitive. In the case of Go libraries, the namespace should be the domain and top-level package name."
    echo "              For example: github.com/docker/docker"
    echo "              [https://docs.veracode.com/r/Veracode_SCA_Agent_Commands]"
    echo ""
    echo "-artifactid : Artifact ID"
    echo "              optional, but required for Maven. If you include the type maven, this specifies the artifactId of the library to lookup."
    echo ""
    echo "-type       : Package Manager or Type"
    echo "              The type of registry that contains the library one is going to specify using"
    echo "              Acceptable options are:"
    echo "              gem       | to identify a Ruby Gem dependency as one would find on rubygems.org"
    echo "              maven     | to identify a Maven dependency as one would find on repo.maven.apache.org"
    echo "              npm       | to identify a JavaScript dependency as one would find on npmjs.com"
    echo "              pypi      | to identify a Python dependency as one would find on pypi.python.org"
    echo "              cocoapods | to identify a CocoaPods dependency as one would find on cocoapods.org"
    echo "              go        | to identify a Go dependency as one would find on the common Go repositories such as github.com, bitbucket.org, gopkg.in, golang.org"
    echo "              packagist | to identify a PHP dependency as one would find on packgist.org"
    echo "              nuget     | to identify a .NET dependency as one would find on nuget.org "
    echo "              [https://docs.veracode.com/r/Veracode_SCA_Agent_Commands]"
    echo ""
    echo "-platform   : Platform [Under development]"
    echo "              optional. Specify the target platform of a library located in the registry, such as freebsd or py3, depending on the package and registry used."
    echo ""
    echo "-version    : Version"
    echo "              The version number, as specified in the registry that you identify with the --type parameter, of the library to lookup. For Go, the version can be:"
    echo "                 A release tag in the library repository"
    echo "                 A prefix of a commit hash of at least seven digits"
    echo "                 In v0.0.0-{datetime}-{hash} format"
    echo "              [https://docs.veracode.com/r/Veracode_SCA_Agent_Commands]"
    echo ""
    echo "PURL CPE Lookup [Experimental]"
    echo "--------------------------------------------"
    echo "veradblookup -r <PURL>";
#    echo "veradblookup -r <CPE> <Package Manager/Type> [Experimental]";
#    echo "veradblookup -r <ref> [Experimental]";
#    echo "veradblookup -e CVE  [Experimental]"
#    echo ""
#    echo ""
#    echo "SBOM Functions [Experimental]"
#    echo "---------------------------------------------"
#    echo "veradblookup -s <SBOM File>                       : Parse SBOM file and produce report to the stdout"
#    echo "veradblookup -s <SBOM File> -o <outputfile>.txt   : Parse SBOM file and produce report to output file"
#    echo "veradblookup -s <SBOM File> -oS <Out SBOM File>   : Parse SBOM file and populate VEX data"
#    echo "veradblookup -s <SBOM File> <Second SBOM File>    : Combine 2 SBOMS"
#    echo "veradblookup -s <SBOM File> --generate-full       : Generates a Full SBOM based of the component information provided from the platform" 
#    echo ""
#    echo "INSPECT Functions [Experimental]"
#    echo "---------------------------------------------"
#    echo "veradblookup -a <actions> -s <SBOM File>          : Use an SBOM as a source"
#    echo "veradblookup -a <actions> -p                      : Use the platform as a source"
#    echo ""
#    echo "Actions:"
#    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#    echo "ListComponents"
#    echo "     Additional Options: -vulnerable"
#    echo "     List out all the components with no vulnerabilities, add the vulnerable parameter to list out all the components with vulnerabilities"
#    echo ""
#    echo "ListVulnerabilities"
#    echo "     Additional Options: -components"
#    echo "     List out all the identified vulnerabilities, add the components parameter to list under each vulnerability the components affected"
#    echo ""
#    echo "HumanReadable"
#    echo "     Turn the given SBOM into a human readable text report"
#    echo ""
#    echo "Convert"
#    echo "     Supported Formats: CycloneDx, SPDX, SWID, list, csv"
#    echo "     Allows you to convert one SBOM format to another"
#    echo "ReadSBOM"
#    echo "     Additional Options: -cyclonedx , -spdx , -swd, -list , -csv , "
#    echo "     "
#    echo ""
#    echo "ListSBOM"
#    echo "     Additional Options: -vex"
#    echo "     Lookup all the SBOM components in the vulnerability database, add the vex parameter to add the vex section to an SBOM"
#    echo "ListUpgrade"
#    echo "     Additional Options: -force"
#    echo "     Lists out all of the libraries with an available update. Add force to include those that might be breaking changes."
#    echo ""
#    echo "ListOutdated"
#    echo ""
#    echo ""



}   

echo "Veracode DB Look Up Tool"
if [ -z $1 ]; then
    help
fi

if [ "$1" == "-h" ]; then
    echo "Showing help"
    help
elif [ "$1" == "-p" ]; then
    logo
    echo "--------------------------------------------------------------------  Entering Interactive mode -----------------------------------------------------------------------------------"
    echo "Enter the Type / Package Manager. The following are the acceptable options:  [gem, maven, npm, pypi, cocoapods, go, packagist, nuget] "
    echo "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo "Your Input [Type]:> "
    read collector
    echo "Read " $collector
    if [ "$clearprompt" == "true" ]; then
        clear
    fi
    echo "Enter the primary library or groupId. This is the primary library name in all cases except for type maven, where the first coordinate identifies the groupId in Maven nomenclature."
    echo "The case sensitivity of the namespace depends on whether the underlying registry distinguishes packages by case."
    echo "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo "Your Input [Primary Library / groupId / namespace]:> "
    read namespace
    echo "Read " $namespace
    #clear
    if [ "$clearprompt" == "true" ]; then
         clear
    fi

    if [ "$collector" == "maven" ]; then
        echo "Enter the maven artifactId. This specifies the artifactId of the library to lookup. "
        echo "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
        echo "Your Input [Artifact ID]:> "
        read artifactid
        echo "Read " $artifactid
    fi
    echo "[Optional] Enter the platform, otherwise press enter: "
    echo "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo "Your input [Platform]:> "
    read platform
    echo "Read " $platform
    #clear
    if [ "$clearprompt" == "true" ]; then
         clear
    fi
    echo "Enter the library version. The version number, as specified in the registry that you identify with the type, of the library to lookup. "
    echo "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo "Your Input [Version]:>"
    read version
    echo "Read " $version
    if [ "$clearprompt" == "true" ]; then
         clear
    fi

    if [ "$collector" == "maven" ]; then
        echo "Maven detected "
        echo "-----------------------------------------------------------------------------"
        echo "GroupID or Module: $namespace "
        echo "ArtifactID: $artifactid"
        echo "Type: $collector"
        echo "Version: $version"

        echo "srcclr lookup --type="$collector" --coord1="$namespace" --coord2="$artifactid"  --version="$version" --json"
        srcclr lookup --type=$collector --coord1=$namespace --coord2=$artifactid --version=$version --json

    elif [ "$collector" == "gem" || "$collector" == "npm" || "$collector" == "pypi" || "$collector" == "cocoapods" || "$collector" == "go" || "$collector" == "packagist" ]; then
        echo "$collector detected "
        echo "-----------------------------------------------------------------------------"
        echo "GroupID or Module: $namespace "
        echo "Type: $collector"
        echo "Version: $version"
        echo "srcclr lookup --json --coord1="$namespace" --type="$collector" --version=" $version
        srcclr lookup --json --type=$collector --coord1=$namespace --version=$version

    else
        echo "[Error] Incorrect Syntax"
        help
    fi

# Inline mode

elif [ "$1" == "-i" ]; then
    shift 1
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type)
                type="$2"
                if [ "$verbose" == "true" ]; then
                        echo "Type: $type"
                fi
                shift 2
                ;;
            --namespace)
                namespace="$2"
                if [ "$verbose" == "true" ]; then
                        echo "Namespace: $namespace"
                fi
                shift 2
                ;;
            --artifactid)
                artifactid="$2"
                if [ "$verbose" == "true" ]; then
                        echo "ArtifactId: $artifactid"
                fi
                shift 2
                ;;
            --platform)
                platform="$2"
                if [ "$verbose" == "true" ]; then
                        echo "Platform: $platform"
                fi
                shift 2
                ;;
            --version)
                version="$2"
                if [ "$verbose" == "true" ]; then
                        echo "Version: $version"
                fi
                shift 2
                ;;
            *)
                echo "Unknown argument: $2"
                help
                exit 1
                ;;
        esac
    done

    if [ -z $type ]  && [ -z $namespace ] && [ -z $version  ]; then
        echo "[ERROR] Please provide a parameter";
        help;
    else
        if [ -n $type ] && [ "$type" == "maven" ]; then
            if [ -n $artifactid ]; then

                    echo "srcclr lookup --type $type --coord1 $namespace --coord2 $artifactid --version $version --json";
                    srcclr lookup --type $type --coord1 $namespace --coord2 $artifactid --version $version --json;

            else
                echo "[ERROR] Artifact ID is required with the type maven"
                help
            fi
        elif [ -n $type ] && [ "$type" == "gem" || "$type" == "npm" || "$type" == "pypi" || "$type" == "cocoapods" || "$type" == "go" || "$type" == "packagist" ]; then
            if [ -n $artifactid ]; then
                    echo "srcclr lookup --type $type --coord1 $namespace --coord2 $artifactid --version $version --json";
                    srcclr lookup --type $type --coord1 $namespace --coord2 $artifactid --version $version --json;

            else
                echo "srcclr lookup --type $type --coord1 $namespace --version $version --json";
                srcclr lookup --type $type --coord1 $namespace --version $version --json;
            fi
        else

            echo "[ERROR]: provide a supported type";
        fi
    fi

elif [ "$1" == "-r" ]; then
        if [ -z $2 ]; then
                echo "Please enter a parameter"
                read ref
        else

                ref=$2
        fi
        
        echo "ref lookup mode"
        
        # Check to see if there is an argument is passed
        if [ -n $ref ] && [ "$verbose" == "true" ]; then
                echo "Input recieved";
        fi



         echo $ref | cut -d ':'
        
        if $DEBUG; then
            echo $ref_header
            if [ "$ref_header" == "cpe" ]; then
                echo "CPE"
            elif [ "$ref_header" == "pkg" ]; then
                echo "PURL"
            else
                echo "ref"
            fi
        fi

        if  [ $( echo $ref | cut -d ':' -f1 ) == 'pkg' ]
        then
            
            echo "PURL"
            type=$(echo $ref | cut -d ':' -f2 | cut -d '/' -f1) 
            namespace=$( echo $ref | cut -d ':' -f2 | cut -d '/' -f2)
            name=$( echo $ref | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f1)
            version=$( echo $ref | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f2)
            vendor=$(echo $ref | cut -d ':' -f2 | cut -d '/' -f2 | cut -d '.' -f2)	
            echo "cpe:2.3:a:"$vendor":"$name":"$version":*:*:*:*:*:*:*"
            echo "cpa:/a:"$vendor":"$name":"$version  
            #srcclr lookup --coord1 $namespace --coord2 $name --type $type --version $version --json
            if  [[ $( echo $ref | cut -d ':' -f1 ) == 'pkg' ]]; then
                echo "PURL identified "
                echo "-----------------------------------------------------------------------------"
                echo $(echo $ref | cut -d ':' -f2 | cut -d '/' -f1)
                if [ "$(echo $ref | cut -d ':' -f2 | cut -d '/' -f1)" == "maven" ]
                then
                        echo "Maven detected"
                        echo "-----------------------------------------------------------------------------"
                        echo "GroupID or Module: $( echo $ref | cut -d ':' -f2 | cut -d '/' -f2) "
                        echo "ArtifactID: $( echo $ref | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f1)"
                        echo "Type: $(echo $ref | cut -d ':' -f2 | cut -d '/' -f1)"
                        echo "Version: $( echo $ref |  cut -d '@' -f2)"

                        srcclr lookup --coord1 $( echo $ref | cut -d ':' -f2 | cut -d '/' -f2) --coord2 $( echo $ref | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f1) --type $(echo $ref | cut -d ':' -f2 | cut -d '/' -f1) --version $( echo $ref |  cut -d '@' -f2) --json=./SCALookup-Out.json
                else
                        echo "===== $(echo $ref | cut -d ':' -f2 | cut -d '/' -f1) detected ===== "
                        echo "GroupID or Module: $( echo $ref | cut -d ':' -f2 | cut -d '/' -f2 | cut -d '@' -f1) "
                        echo "Type: $(echo $ref | cut -d ':' -f2 | cut -d '/' -f1)"
                        echo "Version: $( echo $ref | cut -d '@' -f2)"

                        srcclr lookup --json --coord1 $( echo $ref | cut -d ':' -f2 | cut -d '/' -f2 | cut -d '@' -f1) --type  $(echo $ref | cut -d ':' -f2 | cut -d '/' -f1) --version $( echo $ref | cut -d '@' -f2)
                fi
        elif [ $( echo $ref | cut -d ':' -f1 ) == "cpe" ]; then
            type=$3
            echo "CPE"
            namespace=$(echo $ref | cut -d ':' -f4)
            name=$(echo $ref | cut -d ':' -f5)
            version=$(echo $ref |cut -d ':' -f6)
            srcclr lookup --coord1 $namespace --coord2 $name --type $type --version $version --json        
        else
            echo "Attempting to look up the reference coordinates"
            echo "Type: $(echo $ref | cut -d ':' -f1 )"
            echo "GroupID or Module: $( echo $ref | cut -d ':' -f2 )"
            if [ "$(echo $ref | cut -d ':' -f1 )" == "maven" ]; then
                echo "Artifact Id: $( echo $ref | cut -d ':' -f3 )" 
                echo "Version: $( echo $ref | cut -d ':' -f4)"
            else 
                echo "Version: $( echo $ref | cut -d ':' -f3)"
            fi
        fi
elif [ "$1" == "--search" ]; then
    # experimental
    curl "https://api.sourceclear.com/catalog/search?q=$2" | jq 
    
fi


# Vulnerable Component List
# #!/bin/bash

# # Check if jq is installed
# if ! command -v jq &> /dev/null; then
#     echo "jq is not installed. Please install jq to use this script."
#     exit 1
# fi

# # Check if the input file is provided
# if [ $# -ne 1 ]; then
#     echo "Usage: $0 <input_sbom.json> <args>"
#     echo "Outputs a list of vulnerable components"
#     exit 1
# fi

# input_file="$1"

# # Check if the input file exists
# if [ ! -f "$input_file" ]; then
#     echo "Input file not found: $input_file"
#     exit 1
# fi

# # Create an associative array to store component names by bom-ref
# #declare -A component_names
# declare -A components
# componentRef=()
# declare -A componentMap
# # Populate the associative array with component names
# while read -r name bom_ref type; do
#     echo "--------------------"
#     echo "Name: "$name
#     components["$bom_ref"]="$name"
#     echo "Type:"$type
#     echo "bom-ref:"$bom_ref
#     componentRef=("$bom_ref")
#     componentMap["$bom_ref"]=""
# done < <( jq -r '.components[] |" \(."name") \(."bom-ref") \(."type")"' "$input_file")

# echo "---------------------------"
# echo "Vulnerabilities"

# declare -A vulnerabilityMap
# while read -r id affects; do
# #    vulnerabilityMap["$id"]=($(affects[@]))
#     echo "ID: "$id
#     echo "Affects:"
#     for element in "${affects[@]}"; do
#         echo "         $element"
#         componentMap["$element"]+="$id ,"
#     done
# done < <(jq -r '.vulnerabilities[] |" \(.id) \(.affects[].ref)"' "$input_file")
# # Export the component_names array as an environment variable
# #export component_name
# echo "Vulnerable components"
# echo "" > VulnerableComponents.txt
# for component in "${!componentMap[@]}"; do
#     if [ -n "${componentMap[$component]}" ]; then
#           echo "  ComponentName: ${components["$component"]}"
#           echo "                       Bom-Ref: $component"
#           echo "                       Vulnerabilities: ${componentMap[$component]}"
#           echo "  ComponentName: ${components["$component"]}" >> VulnerableComponents.txt
#           echo "                       Bom-Ref: $component" >> VulnerableComponents.txt
#           echo "                       Vulnerabilities: ${componentMap[$component]}" >> VulnerableComponents.txt
#     fi
# done




# # Look through the platform for library info across all projects
# #!/bin/bash

# help(){

#     echo "Search through your workspaces and projects for specific libraries"
#     echo "------------------------------------------------------------------------------"
#     echo "--help             |   Open up this help menu"
#     echo "--library <lib>    |   [Required] Specify the library you want to look for"
#     echo "--workspace <GUID> |   [Optional] Specify the specific workspaces to look into"
#     echo "--json             |   [Optional] Create a JSON file output (Output: foundProjects.json)"
#     echo "--clean            |   [Optional] Clean the folder of previous files"
#     echo "--listWorkspaces   |   [Optional] Search through all workspaces (Output: foundWorkspaces.txt)"
#     echo "--listProjects     |   [Optional] Look through all projects in all workspaces (Output: foundProjects.txt)"

# }

# workspacesGUIDs=()
# projectsGUIDs=()
# projectsNames=()
# # Change this for the specified API
# baseURL="https://api.veracode.com/srcclr"
# FEDbaseURL="https://api.veracode.us/srcclr"
# #baseURL="$FEDbaseURL"
# traceWorkspaceGUID="" #"8cb1aabd-fc61-4cf2-9c48-3e898f58d463"
# listProjects=0
# listWorkspaces=0
# params_gl="page=0&size=2000"
# verbose=0
# debug=0
# searchLibrary=""
# json=0
# out_dir=".veracode-out"

# while [[ $# -gt 0 ]]; do
#         case "$1" in
#             # Specify the output directory
#             --outdir)
#                 out_dir="$2"
#                 shift 2
#                 ;;
#             # Display the Help Menu 
#             --help)
#                 help
#                 exit 1
#                 ;;
#             # 
#             --library)
#                 searchLibrary="$2"
#                 if [ "$verbose" -gt 0 ]; then
#                         echo "Library: $searchLibrary"
#                 fi
#                 shift 2
#                 ;;
#             --workspace)
#                 traceWorkspaceGUID="$2"
#                 if [ "$verbose" -gt 0 ]; then
#                         echo "Workspace: $traceWorkspaceGUID"
#                 fi
#                 shift 2
#                 ;;
#             --json)
#                 json=1
#                 if [ "$verbose" -gt 0 ]; then
#                         echo "Json: True"
#                 fi
#                 shift 1
#                 ;;
#             --clean)
#                 echo "Cleaning up files from folder"
#                 rm ./librarySearch-proj-*.json
#                 rm ./librarySearch-*.json
#                 rm ./projects-*.json
#                 rm ./foundProjects.json
#                 rm ./foundProjects.txt
#                 rm ./foundWorkspaces.txt
                
#                 shift 1
#                 ;;
#             --listProjects)
#                 listProjects=1
#                 if [ "$verbose" -gt 0 ]; then
#                         echo "List Projects: True"
#                 fi
#                 shift 1
#                 ;;
#             --listWorkspaces)
#                 listWorkspaces=1
#                 if [ "$verbose" -gt 0 ]; then
#                         echo "List Workspaces: True"
#                 fi
#                 shift 1
#                 ;;
#             *)
#                 echo "Unknown argument: $2"
#                 help
#                 exit 1
#                 ;;
#         esac
# done


# if [ -d $out_dir ]; then
#     echo "directory exists"
#     cd $out_dir
#     pwd
# else
#     echo "Making directory"
#     mkdir $out_dir
#     cd $out_dir
#     pwd
# fi

# # Functions:
# #   - getWorkspaces
# #   - loadArrayWorkspaces
# #   - loadArrayProjects
# #   - searchWorkspacesForLibrary
# #   - searchAllProjectsForLibrary
# #   - traceLibrary


# # $1 params_lc
# getWorkspaces(){
#     local params_lc=$1
#     http --auth-type=veracode_hmac "$baseURL/v3/workspaces?$params_lc" -o workspaces.json
#     sleep 0.75
#     if [ "$verbose" -gt 0 ]; then
#         cat workspaces.json | jq
#     fi


# }   

# # $1 input_file
# loadArrayWorkspaces(){
#     local input_file=$1
    
#     local jq_query="._embedded.workspaces[].id"
#     while IFS= read -r line; do
#         workspacesGUIDs+=("$line")
#         if [ "$verbose" -gt 0 ]; then
#             echo "[DEBUG]: Adding $line to array"
#         fi
#     done < <(jq -r "$jq_query" "$input_file")
    
#     if [ "$verbose" -gt 0 ]; then

#         echo "Printing out the array"
#         for id in "${workspacesGUIDs[@]}"; do
#             echo "$id"
#         done
#     fi
# }

# # $1 input_file
# loadArrayProjects(){
#     local input_file=$1
#     projectsGUIDs=()
#     local jq_query="._embedded.projects[].id"
#     while IFS= read -r line; do
#         projectsGUIDs+=("$line")
#         if [ "$verbose" -gt 0 ]; then
#             echo "[DEBUG]: Adding $line to array"
#         fi
#     done < <(jq -r "$jq_query" "$input_file")
#     jq_query="._embedded.projects[].name"
#     while IFS= read -r line; do
#         projectsNames+=("$line")
#         if [ "$verbose" -gt 0 ]; then
#             echo "[DEBUG]: Adding $line to array"
#         fi
#     done < <(jq -r "$jq_query" "$input_file")
    

#     if [ "$verbose" -gt 0 ]; then

#         echo "Printing out the array"
#         for id in "${projectsGUIDs[@]}"; do
#             echo "$id"
#         done
#     fi
# }

# # pass parameters to enter to the request
# # $1 param_lc
# # $2 search_params
# searchWorkspacesForLibrary(){
#     local param_lc=$1
#     local search_params=$2
#     for id in "${workspacesGUIDs[@]}"; do
#         http --auth-type=veracode_hmac "$baseURL/v3/workspaces/$id/libraries?search=$search_params&$params_lc" -o librarySearch-$id.json
#         sleep 0.75
#         echo "$id"
#         if [ $( cat librarySearch-$id.json | jq -r '.page.total_elements' ) == "0" ]; then
#             echo "No entries in the response, removing page" 
#             rm librarySearch-$id.json
#         else
#             echo "Library Found in the following workspace: $id" 
#             echo "$id" >> foundWorkspaces.txt
#         fi
#     done
# }

# # $1 param_local
# # $2 search_params
# searchAllProjectsForLibrary(){
#     local param_lc=$1
#     local search_params=$2
#     workspaceCount=0
#     if [ "$json" -gt 0 ]; then
#         echo "{ \"workspaces\":{" > foundProjects.json
#     fi
#     for id in "${workspacesGUIDs[@]}"; do

#         if [ "$json" -gt 0 ]; then
#             if [ "$workspaceCount" -gt 0 ]; then
#                 echo ",\"$id\": [" >> foundProjects.json
#             else
#                 echo "\"$id\": [" >> foundProjects.json
#             fi
#         fi
#         ((workspaceCount++))
#         http --auth-type=veracode_hmac "$baseURL/v3/workspaces/$id/projects?page=0&size=2000" -o projects-$id.json
#         if [ $( cat projects-$id.json | jq -r '.page.total_elements' ) == "0" ]; then
#                 echo "No entries in the workspace, removing page" 
#                 rm projects-$id.json
#                 if [ "$json" -gt 0 ]; then
#                     echo "]" >> foundProjects.json
#                 fi
#         else
#             sleep 0.75
#             loadArrayProjects projects-$id.json
#             projCount=0
#             for p_id in "${projectsGUIDs[@]}"; do
#                 http --auth-type=veracode_hmac "$baseURL/v3/workspaces/$id/projects/$p_id/libraries?search=$librarySearch&$params_gl" -o librarySearch-proj-$p_id.json
#                 sleep 0.75
#                 echo "$p_id"
#                 if [ $( cat librarySearch-proj-$p_id.json | jq -r '.page.total_elements' ) == "0" ]; then
#                     echo "No entries in the response, removing page" 
#                     rm librarySearch-proj-$p_id.json
#                 else
#                     echo "Library Found in the following project: $p_id"
#                     if [ "$listProjects" -gt 0 ]; then
#                         for name in "${!projectsNames[@]}"; do
#                             if [ "${projectsGUIDs[$name]}" == "$p_id" ];then
#                                 echo "${projectsNames[$name]}"
#                                 echo "----" >> foundProjects.txt
#                                 echo "Project Name: ${projectsNames[$name]} <> $p_id" >> foundProjects.txt
#                                 break
#                             fi
#                         done
#                     fi
                    
#                     if [ "$json" -gt 0 ]; then
#                         if [ "$projCount" -gt 0 ]; then
#                             echo ",\"$p_id\"" >> foundProjects.json # TODO: make a check to remove the last comma when there are no more elements
#                         else
#                             echo "\"$p_id\"" >> foundProjects.json # TODO: make a check to remove the last comma when there are no more elements
#                         fi
#                         ((projCount++))
#                     fi
#                     echo "Project GUID: $p_id" >> foundProjects.txt
#                 fi
#             done
#             if [ "$json" -gt 0 ]; then
#                 echo "]" >> foundProjects.json     
#             fi
#         fi 
        
#     done
#     if [ "$json" -gt 0 ]; then
#         echo "}}" >> foundProjects.json

#     fi
# }



# # $1 workspace guid
# # $2 Library Name
# # $3 Page
# traceLibrary(){
#     local page=$3
#     local workspaceGuid=$1
#     local librarySearch=$2
#     http --auth-type=veracode_hmac "$baseURL/v3/workspaces/$workspaceGuid/projects?page=$page&size=2000" -o projects-$id-$page.json
#     sleep 0.75
#     loadArrayProjects projects-$id-$page.json
#     for id in "${!projectsGUIDs[@]}"; do
#         http --auth-type=veracode_hmac "$baseURL/v3/workspaces/$workspaceGuid/projects/${projectsGUIDs[$id]}/libraries?search=$librarySearch&$params_gl" -o librarySearch-proj-$id.json
#         sleep 0.75
#         echo "Searching in Project: ${projectsGUIDs[$id]}"
#         if [ $( cat librarySearch-proj-$id.json | jq -r '.page.total_elements' ) == "0" ]; then
#             echo "No entries in the response, removing page" 
#             rm librarySearch-proj-$id.json
#         else
#             echo "Library Found in the following project: ${projectsGUIDs[$id]} : ${projectsNames[$id]}" 
#         fi
#     done



# }

# # updates 
# checkPage(){
#     local input_file=$1
#     local page=$3
#     current_page=$(jq -r '.page.number' "$input_file")
#     page_size=$(jq -r '.page.size' $1)
#     element_on_page=$(jq -r '.page.total_elements' $1)
#     total_pages=$(jq -r '.page.total_pages' $1)
#     if [ "$verbose" -gt 0 ]; then
#         echo "Current Page Number: $current_page"
#         echo "Page Size: $page_size" 
#         echo "Elements on Page: $element_on_page" 
#         echo "Total Pages: $total_pages" 
#     fi

#     if [[ "$total_pages" -gt 1  ]]; then
      
#         # if the elements on the page are less than max, then set to max
#         if [[ "$element_on_page" -lt 2000  ]]; then
#             params_gl="page=$page&size=2000" 
#             return $params_gl
#         # Elif the elements are at the max and there are more pages 
#         elif [ "$current_page" -lte $(( $total_pages - 1 )) ]; then
#             echo "There are more pages"
#             page=$(("$current_page" + 1 ))
#             echo $page
#             params_gl="page=$page&size=2000"
#             return $params_gl
#         else
#             echo "No more pages"
#         fi
#     else
#         return 0
#     fi

# }   

# main(){
#     if [ "$verbose" -gt 0 ]; then
#         echo "[DEBUG]: Main Execution" 
#     fi

#     if [ "$searchLibrary" == "" ]; then
#         echo "Search Library is blank.... Exiting"
#         help
#     else
#         getWorkspaces $params_gl
#         checkPage workspaces.json
#         getWorkspaces $params_gl
#         loadArrayWorkspaces workspaces.json
#     fi

#     if [ "$listWorkspaces" -gt 0 ]; then
#         # check to see if library is set otherwise error out
#         if [ "$verbose" -gt 0 ]; then
#             echo "Running Search Against All Workspaces"
#         fi
#         searchWorkspacesForLibrary $params_gl  $searchLibrary
#     # Else check to see if the workspace is set 
#     elif [ "$traceWorkspaceGUID" != ""  ]; then
#         if [ "$verbose" -gt 0 ]; then
#             echo "Workspace GUID Not Null"
#         fi
#         traceLibrary $traceWorkspaceGUID $searchLibrary 0
#     elif [ "$listProjects" -gt 0 ]; then
#         searchAllProjectsForLibrary $params_gl $searchLibrary
#     else
#         searchAllProjectsForLibrary $params_gl $searchLibrary
#     fi


# }


