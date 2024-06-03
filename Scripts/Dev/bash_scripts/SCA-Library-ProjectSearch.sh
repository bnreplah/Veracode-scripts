#!/bin/bash

help(){

    echo "Search through your workspaces and projects for specific libraries"
    echo "------------------------------------------------------------------------------"
    echo "--help             |   Open up this help menu"
    echo "--library <lib>    |   [Required] Specify the library you want to look for"
    echo "--workspace <GUID> |   [Optional] Specify the specific workspaces to look into"
    echo "--json             |   [Optional] Create a JSON file output (Output: foundProjects.json)"
    echo "--clean            |   [Optional] Clean the folder of previous files"
    echo "--listWorkspaces   |   [Optional] Search through all workspaces (Output: foundWorkspaces.txt)"
    echo "--listProjects     |   [Optional] Look through all projects in all workspaces (Output: foundProjects.txt)"

}

workspacesGUIDs=()
projectsGUIDs=()
projectsNames=()
# Change this for the specified API
baseURL="https://api.veracode.com/srcclr"
FEDbaseURL="https://api.veracode.us/srcclr"
#baseURL="$FEDbaseURL"
traceWorkspaceGUID="" #"8cb1aabd-fc61-4cf2-9c48-3e898f58d463"
listProjects=0
listWorkspaces=0
params_gl="page=0&size=2000"
verbose=0
debug=0
searchLibrary=""
json=0
out_dir=".veracode-out"

while [[ $# -gt 0 ]]; do
        case "$1" in
            # Specify the output directory
            --outdir)
                out_dir="$2"
                shift 2
                ;;
            # Display the Help Menu 
            --help)
                help
                exit 1
                ;;
            # 
            --library)
                searchLibrary="$2"
                if [ "$verbose" -gt 0 ]; then
                        echo "Library: $searchLibrary"
                fi
                shift 2
                ;;
            --workspace)
                traceWorkspaceGUID="$2"
                if [ "$verbose" -gt 0 ]; then
                        echo "Workspace: $traceWorkspaceGUID"
                fi
                shift 2
                ;;
            --json)
                json=1
                if [ "$verbose" -gt 0 ]; then
                        echo "Json: True"
                fi
                shift 1
                ;;
            --clean)
                echo "Cleaning up files from folder"
                rm ./librarySearch-proj-*.json
                rm ./librarySearch-*.json
                rm ./projects-*.json
                rm ./foundProjects.json
                rm ./foundProjects.txt
                rm ./foundWorkspaces.txt
                
                shift 1
                ;;
            --listProjects)
                listProjects=1
                if [ "$verbose" -gt 0 ]; then
                        echo "List Projects: True"
                fi
                shift 1
                ;;
            --listWorkspaces)
                listWorkspaces=1
                if [ "$verbose" -gt 0 ]; then
                        echo "List Workspaces: True"
                fi
                shift 1
                ;;
            *)
                echo "Unknown argument: $2"
                help
                exit 1
                ;;
        esac
done


if [ -d $out_dir ]; then
    echo "directory exists"
    cd $out_dir
    pwd
else
    echo "Making directory"
    mkdir $out_dir
    cd $out_dir
    pwd
fi

# Functions:
#   - getWorkspaces
#   - loadArrayWorkspaces
#   - loadArrayProjects
#   - searchWorkspacesForLibrary
#   - searchAllProjectsForLibrary
#   - traceLibrary


# $1 params_lc
getWorkspaces(){
    local params_lc=$1
    http --auth-type=veracode_hmac "$baseURL/v3/workspaces?$params_lc" -o workspaces.json
    sleep 0.75
    if [ "$verbose" -gt 0 ]; then
        cat workspaces.json | jq
    fi


}   

# $1 input_file
loadArrayWorkspaces(){
    local input_file=$1
    
    local jq_query="._embedded.workspaces[].id"
    while IFS= read -r line; do
        workspacesGUIDs+=("$line")
        if [ "$verbose" -gt 0 ]; then
            echo "[DEBUG]: Adding $line to array"
        fi
    done < <(jq -r "$jq_query" "$input_file")
    
    if [ "$verbose" -gt 0 ]; then

        echo "Printing out the array"
        for id in "${workspacesGUIDs[@]}"; do
            echo "$id"
        done
    fi
}

# $1 input_file
loadArrayProjects(){
    local input_file=$1
    projectsGUIDs=()
    local jq_query="._embedded.projects[].id"
    while IFS= read -r line; do
        projectsGUIDs+=("$line")
        if [ "$verbose" -gt 0 ]; then
            echo "[DEBUG]: Adding $line to array"
        fi
    done < <(jq -r "$jq_query" "$input_file")
    jq_query="._embedded.projects[].name"
    while IFS= read -r line; do
        projectsNames+=("$line")
        if [ "$verbose" -gt 0 ]; then
            echo "[DEBUG]: Adding $line to array"
        fi
    done < <(jq -r "$jq_query" "$input_file")
    

    if [ "$verbose" -gt 0 ]; then

        echo "Printing out the array"
        for id in "${projectsGUIDs[@]}"; do
            echo "$id"
        done
    fi
}

# pass parameters to enter to the request
# $1 param_lc
# $2 search_params
searchWorkspacesForLibrary(){
    local param_lc=$1
    local search_params=$2
    for id in "${workspacesGUIDs[@]}"; do
        http --auth-type=veracode_hmac "$baseURL/v3/workspaces/$id/libraries?search=$search_params&$params_lc" -o librarySearch-$id.json
        sleep 0.75
        echo "$id"
        if [ $( cat librarySearch-$id.json | jq -r '.page.total_elements' ) == "0" ]; then
            echo "No entries in the response, removing page" 
            rm librarySearch-$id.json
        else
            echo "Library Found in the following workspace: $id" 
            echo "$id" >> foundWorkspaces.txt
        fi
    done
}

# $1 param_local
# $2 search_params
searchAllProjectsForLibrary(){
    local param_lc=$1
    local search_params=$2
    workspaceCount=0
    if [ "$json" -gt 0 ]; then
        echo "{ \"workspaces\":{" > foundProjects.json
    fi
    for id in "${workspacesGUIDs[@]}"; do

        if [ "$json" -gt 0 ]; then
            if [ "$workspaceCount" -gt 0 ]; then
                echo ",\"$id\": [" >> foundProjects.json
            else
                echo "\"$id\": [" >> foundProjects.json
            fi
        fi
        ((workspaceCount++))
        http --auth-type=veracode_hmac "$baseURL/v3/workspaces/$id/projects?page=0&size=2000" -o projects-$id.json
        if [ $( cat projects-$id.json | jq -r '.page.total_elements' ) == "0" ]; then
                echo "No entries in the workspace, removing page" 
                rm projects-$id.json
                if [ "$json" -gt 0 ]; then
                    echo "]" >> foundProjects.json
                fi
        else
            sleep 0.75
            loadArrayProjects projects-$id.json
            projCount=0
            for p_id in "${projectsGUIDs[@]}"; do
                http --auth-type=veracode_hmac "$baseURL/v3/workspaces/$id/projects/$p_id/libraries?search=$librarySearch&$params_gl" -o librarySearch-proj-$p_id.json
                sleep 0.75
                echo "$p_id"
                if [ $( cat librarySearch-proj-$p_id.json | jq -r '.page.total_elements' ) == "0" ]; then
                    echo "No entries in the response, removing page" 
                    rm librarySearch-proj-$p_id.json
                else
                    echo "Library Found in the following project: $p_id"
                    if [ "$listProjects" -gt 0 ]; then
                        for name in "${!projectsNames[@]}"; do
                            if [ "${projectsGUIDs[$name]}" == "$p_id" ];then
                                echo "${projectsNames[$name]}"
                                echo "----" >> foundProjects.txt
                                echo "Project Name: ${projectsNames[$name]} <> $p_id" >> foundProjects.txt
                                break
                            fi
                        done
                    fi
                    
                    if [ "$json" -gt 0 ]; then
                        if [ "$projCount" -gt 0 ]; then
                            echo ",\"$p_id\"" >> foundProjects.json # TODO: make a check to remove the last comma when there are no more elements
                        else
                            echo "\"$p_id\"" >> foundProjects.json # TODO: make a check to remove the last comma when there are no more elements
                        fi
                        ((projCount++))
                    fi
                    echo "Project GUID: $p_id" >> foundProjects.txt
                fi
            done
            if [ "$json" -gt 0 ]; then
                echo "]" >> foundProjects.json     
            fi
        fi 
        
    done
    if [ "$json" -gt 0 ]; then
        echo "}}" >> foundProjects.json

    fi
}



# $1 workspace guid
# $2 Library Name
# $3 Page
traceLibrary(){
    local page=$3
    local workspaceGuid=$1
    local librarySearch=$2
    http --auth-type=veracode_hmac "$baseURL/v3/workspaces/$workspaceGuid/projects?page=$page&size=2000" -o projects-$id-$page.json
    sleep 0.75
    loadArrayProjects projects-$id-$page.json
    for id in "${!projectsGUIDs[@]}"; do
        http --auth-type=veracode_hmac "$baseURL/v3/workspaces/$workspaceGuid/projects/${projectsGUIDs[$id]}/libraries?search=$librarySearch&$params_gl" -o librarySearch-proj-$id.json
        sleep 0.75
        echo "Searching in Project: ${projectsGUIDs[$id]}"
        if [ $( cat librarySearch-proj-$id.json | jq -r '.page.total_elements' ) == "0" ]; then
            echo "No entries in the response, removing page" 
            rm librarySearch-proj-$id.json
        else
            echo "Library Found in the following project: ${projectsGUIDs[$id]} : ${projectsNames[$id]}" 
        fi
    done



}

# updates 
checkPage(){
    local input_file=$1
    local page=$3
    current_page=$(jq -r '.page.number' "$input_file")
    page_size=$(jq -r '.page.size' $1)
    element_on_page=$(jq -r '.page.total_elements' $1)
    total_pages=$(jq -r '.page.total_pages' $1)
    if [ "$verbose" -gt 0 ]; then
        echo "Current Page Number: $current_page"
        echo "Page Size: $page_size" 
        echo "Elements on Page: $element_on_page" 
        echo "Total Pages: $total_pages" 
    fi

    if [[ "$total_pages" -gt 1  ]]; then
      
        # if the elements on the page are less than max, then set to max
        if [[ "$element_on_page" -lt 2000  ]]; then
            params_gl="page=$page&size=2000" 
            return $params_gl
        # Elif the elements are at the max and there are more pages 
        elif [ "$current_page" -lte $(( $total_pages - 1 )) ]; then
            echo "There are more pages"
            page=$(("$current_page" + 1 ))
            echo $page
            params_gl="page=$page&size=2000"
            return $params_gl
        else
            echo "No more pages"
        fi
    else
        return 0
    fi

}   

main(){
    if [ "$verbose" -gt 0 ]; then
        echo "[DEBUG]: Main Execution" 
    fi

    if [ "$searchLibrary" == "" ]; then
        echo "Search Library is blank.... Exiting"
        help
    else
        getWorkspaces $params_gl
        checkPage workspaces.json
        getWorkspaces $params_gl
        loadArrayWorkspaces workspaces.json
    fi

    if [ "$listWorkspaces" -gt 0 ]; then
        # check to see if library is set otherwise error out
        if [ "$verbose" -gt 0 ]; then
            echo "Running Search Against All Workspaces"
        fi
        searchWorkspacesForLibrary $params_gl  $searchLibrary
    # Else check to see if the workspace is set 
    elif [ "$traceWorkspaceGUID" != ""  ]; then
        if [ "$verbose" -gt 0 ]; then
            echo "Workspace GUID Not Null"
        fi
        traceLibrary $traceWorkspaceGUID $searchLibrary 0
    elif [ "$listProjects" -gt 0 ]; then
        searchAllProjectsForLibrary $params_gl $searchLibrary
    else
        searchAllProjectsForLibrary $params_gl $searchLibrary
    fi


}



tests(){
    echo "--------------------------------------------------------------"
    echo "Get Workspaces"
    getWorkspaces $params_gl
    echo "--------------------------------------------------------------"
    echo "Check Pagination"
    # Load params return value 
    checkPage workspaces.json
    echo "--------------------------------------------------------------"
    echo "Get Workspaces with new maximized parameters"
    getWorkspaces $params_gl
    echo "--------------------------------------------------------------"
    echo "Load Workspaces GUIDs into an array"
    loadArrayWorkspaces workspaces.json
    echo "--------------------------------------------------------------"
    echo "Searching through list of Workspaces for Library"
    searchWorkspacesForLibrary $params_gl  $searchLibrary
    echo "--------------------------------------------------------------"
    echo "Tracing a Library down projects within a specified workspace"
    traceLibrary $traceWorkspaceGUID $searchLibrary 0
    echo "--------------------------------------------------------------"
    echo "Searching through all projects for all instances of the library"
    searchAllProjectsForLibrary $params_gl $searchLibrary
}

# check to see if 0 
main
