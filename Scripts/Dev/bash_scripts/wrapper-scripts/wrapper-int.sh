#!/bin/bash

# The purpose of this script is to make using the wrapper more user friendly and a precursor for the python version
shopt -s expand_aliases
# alias
alias 'veracode-api'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-wrapper-java:cmd'

DEBUG=0
app_history=()



function select_option {
    # Menu function from this post, with modifications as needed: https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu
    # It was either this one or one using dialog, but didn't want to have to install anything on the system to get it to work
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { 
      printf "$ESC[?25h"; 
    }
    cursor_blink_off() { 
      printf "$ESC[?25l"; 
    }
    cursor_to()        { 
      printf "$ESC[$1;${2:-1}H"; 
    }
    print_option()     { 
      printf "   %s""$1"  2>/dev/null; 
    }
    print_selected()   { 
      printf "  $ESC[7m $1 $ESC[27m"  2>/dev/null; 
    }
    get_cursor_row()   { 
      IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; 
    }
    key_input()        { 
      read -s -n3 key 2>/dev/null >&2
      if [[ $key = $ESC[A ]]; then echo up;    fi
      if [[ $key = $ESC[B ]]; then echo down;  fi
      if [[ $key = ""     ]]; then echo enter; fi; 
    }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}


options=('AllDetailedReports', 'Archer', 'BeginPreScan', 'BeginScan','CreateAndSubmitDynamicRescan', 'CreateApp', 'CreateBuild', 'CreateSandbox', 'CreateTeam', 'CreateUser', 'DeleteApp', 'DeleteTeam', 'DeleteUser','DetailedReport', 'DownloadArcherReport','DownloadFlawReport','GenerateArcherReport','GenerateFlawReport', 'GetAppBuilds','GetAppInfo', 'GetAppList', 'GetBuildInfo','GetBuildList', 'GetCallStacks','GetCurriculumList', 'GetFileList','GetMitigationInfo', 'GetPolicyList','GetPreScanResults', 'GetRegion','GetSandboxList', 'GetSharedReportInfo','GetSharedReportList', 'GetTeamInfo','GetTeamList', 'GetTrackList','GetUserInfo', 'GetUserList','GetVendorList', 'IsExpiring','IsFeatureEnabled', 'PassFail','PromoteSandbox', 'RemoveFile','RescanDynamicScan', 'SharedReport','SubmitDynamicScan', 'SummaryReport','SwitchToSaml', 'ThirdPartyReport','UpdateApp', 'UpdateBuild','UpdateMitigationInfo', 'UpdateSandbox','UpdateTeam', 'UpdateUser', 'UploadAndScan''UploadAndScanByAppId', 'UploadFile')
select_option "${options[@]}"
choice=$?
echo "Choosen index = $choice"
echo "        value = ${options[$choice]}"
echo "Veracode-api -action ${options[$choice]}"

passed_params=" "
case "${options[$choice]}" in
    'AllDetailedReports')
        echo "AllDetailedReports"

        echo "  outputfolderpath is required for the selected action.\nOutputfolderpath:"
        read outputfolderpath
        echo "The following parameters are optional for the selected action:"
        echo "-format              -includeinprogress   -inputfilepath"
        echo "-logfilepath         -onlylatest          -phost"
        echo "-ppassword           -pport               -puser"
        echo "-reportchangedsince"
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=("format", "includeinprogress", "inputfilepath", "logfilepath" ,"ppassword", "pport", "puser", "onlylatest","reportchangedsince" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    # 'Archer')
    #     echo "Archer"
    #     # ? need to find the parameters
    #     ;; 
    'BeginPreScan')
        echo "BeginPreScan"
        echo "appid is required for the selected action.\nApp Id:"
        #TODO: Add a check to see whether legacy guid is passed 
        read appid # fix with a better sanitized version to take input later
        echo "The following parameters are optional for the selected action:"
        echo   "-autoscan                        -format"
        echo   "-includenewmodules               -inputfilepath"
        echo   "-logfilepath                     -phost"
        echo   "-ppassword                       -pport"
        echo   "-puser                           -sandboxid"
        echo   "-scanallnonfataltoplevelmodules"
        echo "Would you like to select any of the optional arguments? "
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "autoscan", "format", "includenewmodules", "inputfilepath", "logfilepath" ,"ppassword", "pport", "puser", "sandboxid", "scanallnonfataltoplevelmodules" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        #veracode-api -action BeginPreScan -appid "$appid"
        ;; 
    'BeginScan')
        echo "BeginScan"
        echo "\n\tappid is required for the selected action. \n\tmodules is required for the selected action, or \n\tselected is required for the selected action, or \n\tselectedpreviously is required for the selected action, or \n\ttoplevel is required for the selected action."
        echo "App ID:"; read appid
        echo "The following parameters are optional for the selected action:"
        echo "  -format         -inputfilepath  -logfilepath    -phost"
        echo "  -ppassword      -pport          -puser          -sandboxid"
        echo "Would you like to select any of the optional arguments? "
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "format", "inputfilepath", "logfilepath", "phost","ppassword", "pport", "puser", "sandboxid" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;;
    'CreateAndSubmitDynamicRescan')
        echo "CreateAndSubmitDynamicRescan"
        #
        echo "appname is required for the selected action."
        echo "App Name: "
        read appname
        # The following parameters are optional for the selected action:
        #   -endtime        -format         -inputfilepath  -logfilepath
        #   -phost          -ppassword      -pport          -puser
        #   -starttime      -version
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "endtime",  "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser", "starttime", "version")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'CreateApp')
        echo "CreateApp"
            #
        echo "appname is required for the selected action."
        echo "criticality is required for the selected action.\n"
        echo "App Name: "
        read appname
        echo "Criticality: " 
        read criticality
        # The following parameters are optional for the selected action:
        #   -apptype                   -archerappname
        #   -businessowner             -businessowneremail
        #   -businessunit              -deploymenttype
        #   -description               -format
        #   -industry                  -inputfilepath
        #   -logfilepath               -nextdayschedulingenabled
        #   -origin                    -phost
        #   -policy                    -ppassword
        #   -pport                     -puser
        #   -tags                      -teams
        #   -vendorid                  -webapplication
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "apptype","archerappname", "businessowner","businessowneremail","businessunit", "deploymenttype", "description", "format", "industry","logfilepath","nextdayschedulingenabled","origin", "policy", "webapplication", "vendorid","teams", "tags", "phost" ,"ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'CreateBuild')
        echo "CreateBuild"
        #
        #         Parsing error(s):
        #   -appid is required for the selected action.
        #   -version is required for the selected action.
        echo "App Id: "
        read appid
        echo "Version/Scan Name: "
        read version
        # The following parameters are optional for the selected action:
        #   -format            -inputfilepath     -launchdate        -legacyscanengine
        #   -lifecyclestage    -lifecyclestageid  -logfilepath       -phost
        #   -platform          -platformid        -ppassword         -pport
        #   -puser             -sandboxid
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format", "inputfilepath", "launchdate" ,"legacyscanengine", "lifecyclestage", "lifecyclestageid","logfilepath", "phost" ,"ppassword","platform","platformid", "pport", "puser", "sandboxid")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'CreateSandbox')
        echo "CreateSandbox"
        #
        #         Parsing error(s):
        #   -appid is required for the selected action.
        #   -sandboxname is required for the selected action.
        echo "App Id: "
        read appid
        echo "Sandbox Name: "
        read sandboxname
        # The following parameters are optional for the selected action:
        #   -autorecreate   -format         -inputfilepath  -logfilepath
        #   -phost          -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "autorecreate",  "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'CreateTeam')
        echo "CreateTeam"
        #         #
        #         Parsing error(s):
        #   -teamname is required for the selected action.
        echo "Team Name: "
        read teamname
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -members
        #   -phost          -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format", "inputfilepath", "logfilepath","members", "phost" ,"ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'CreateUser')
        echo "CreateUser"
        #
        # Parsing error(s):
        echo "  emailaddress is required for the selected action."
        echo "  firstname is required for the selected action."
        echo "  lastname is required for the selected action."
        echo "  roles is required for the selected action."

        echo "email address: "
        read emailaddress
        echo "first name: "
        read firstname
        echo "last name: "
        read lastname 
        echo "roles: "
        read roles 

        # The following parameters are optional for the selected action:
        #   -customid       -format         -inputfilepath  -issamluser
        #   -logfilepath    -phost          -ppassword      -pport
        #   -puser          -teams
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "customid","format", "inputfilepath", "issamluser", "logfilepath", "phost" ,"ppassword", "pport", "puser", "teams")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'DeleteApp')
        echo "DeleteApp"
        #
        #         Parsing error(s):
        #   -appid is required for the selected action.
        echo "App Id:"
        read appid
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'DeleteTeam')
        echo "DeleteTeam"
        #
        #         Parsing error(s):
        #   -teamid is required for the selected action.
        echo "Team Id: "
        read teamid
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs

        ;;
    'DeleteUser')
        echo "DeleteUser"
        #         #
        #         Parsing error(s):
        #   -customid is required for the selected action.
        #   -username is required for the selected action.
        echo "Custom Id: "
        read customid
        echo "Username: "
        read username
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;;
    'DetailedReport')
        echo "DetailedReport"
        #
        # Parsing error(s):
        #   -buildid is required for the selected action.
        #   -outputfilepath is required for the selected action.
        echo "Build Id: "
        read buildid
        echo "Ouput File Path: "
        read outputfilepath
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    # 'DownloadArcherReport')
        #     echo "DownloadArcherReport"
        #     # ? also does a download, don't know the parameters

        #     ;;
    # 'DownloadFlawReport')
        #     echo "DownloadFlawReport"
        #     # ? similiar to the one above, may need more parameters

        #     ;;
    # 'GenerateArcherReport')
        #     echo "GenerateArcherReport"
        #     # ? similiar to the one above, may need more parameters , or to use the rest equivalent

        #     ;;
    # 'GenerateFlawReport')
        #     echo "GenerateFlawReport"
        #     # Returns access denied

        #     ;; 
    'GetAppBuilds')
        echo "GetAppBuilds"
        # TODO: populate into an array that can be used later
        
        veracode-api -action getappbuilds

        ;;
    'GetAppInfo')
        echo "GetAppInfo"
        #
        echo "appid is required for the selected action.\n"
        echo "App Id: "
        read appid
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'GetAppList')
        echo "GetAppList"
        # TODO: populate into array
        veracoode-api -action getapplist
        ;; 
    'GetBuildInfo')
        echo "GetBuildInfo"
        #
        echo " appid is required for the selected action.\n"
        echo "App Id: "
        read appid
        # The following parameters are optional for the selected action:
        #   -buildid        -format         -inputfilepath  -logfilepath
        #   -phost          -ppassword      -pport          -puser
        #   -sandboxid
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "buildid", "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser", "sandboxid")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        #         ;;
    'GetBuildList')
        echo "GetBuildList"
        #
        #         Parsing error(s):
        echo "appid is required for the selected action."
        echo "App Id: "
        read appid 
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser          -sandboxid
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser", "sandboxid")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'GetCallStacks')
        echo "GetCallStacks"
        #
        #         Parsing error(s):
        echo "buildid is required for the selected action."
        echo "flawid is required for the selected action."
        echo "Build Id: "
        read buildid
        echo "Flaw Id: "
        read flawid
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;;
    # 'GetCurriculumList')
    #     echo "GetCurriculumList"
    #     # Access denied.

    #     ;; 
    'GetFileList')
        echo "GetFileList"
        #
        echo " appid is required for the selected action."
        echo "App Id: "
        read appid
        # The following parameters are optional for the selected action:
        #   -buildid        -format         -inputfilepath  -logfilepath
        #   -phost          -ppassword      -pport          -puser
        #   -sandboxid
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "buildid", "format", "includenewmodules", "inputfilepath", "logfilepath" , "phost","ppassword", "pport", "puser", "sandboxid" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;;
    'GetMitigationInfo')
        echo "GetMitigationInfo"
        #
        #         Parsing error(s):
        #   -buildid is required for the selected action.
        #   -flawidlist is required for the selected action.
        echo "Build Id: " 
        read buildid
        echo "Flaw Id List: "
        read flawidlist
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format", "inputfilepath", "logfilepath" , "phost","ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'GetPolicyList')
        echo "GetPolicyList"
        #
        veracode-api -action getpolicylist
        ;;
    'GetPreScanResults')
        echo "GetPreScanResults"
        #
        #         Parsing error(s):
        #   -appid is required for the selected action.
        echo "App Id: "
        read appid
        # The following parameters are optional for the selected action:
        #   -buildid        -format         -inputfilepath  -logfilepath
        #   -phost          -ppassword      -pport          -puser
        #   -sandboxid
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "buildid", "format", "inputfilepath", "logfilepath" , "phost","ppassword", "pport", "puser", "sandboxid" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'GetRegion')
        echo "GetRegion"
        #
        veracode-api -action getregion
        ;;
    'GetSandboxList')
        echo "GetSandboxList"
        #
        #         Parsing error(s):
        #   -appid is required for the selected action.
        echo "App Id: "
        read appid
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        veracode-api -action getsandboxlist
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "format", "inputfilepath", "logfilepath" , "phost","ppassword", "pport", "puser", "sandboxid", "scanallnonfataltoplevelmodules" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'GetSharedReportInfo')
        echo "GetSharedReportInfo"
        #

        veracode-api -action GetSharedReportInfo
        ;;
    'GetSharedReportList')
        echo "GetSharedReportList"
        #
        #         Parsing error(s):
        #   -appid is required for the selected action.
        echo "App Id: "
        read appid
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        veracode-api -action GetSharedReportList
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "format", "inputfilepath", "logfilepath" , "phost","ppassword", "pport", "puser" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'GetTeamInfo')
        echo "GetTeamInfo"
        #
        #         Parsing error(s):
        #   -teamid is required for the selected action.
        echo "Team ID: "
        read teamid
        # The following parameters are optional for the selected action:
        #   -format               -includeapplications  -includeusers
        #   -inputfilepath        -logfilepath          -phost
        #   -ppassword            -pport                -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format", "includeapplications","includeusers" ,"inputfilepath", "logfilepath" , "phost","ppassword", "pport", "puser", "sandboxid", "scanallnonfataltoplevelmodules" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        #veracode-api -action GetTeamInfo
        ;;
    'GetTeamList')
        echo "GetTeamList"
        veracode-api -action GetTeamList
        ;; 
    # 'GetTrackList')
    #     echo "GetTrackList"
    #     veracode-api -action GetTrackList
    #     # access denied ?
    #     ;;
    'GetUserInfo')
        echo "GetUserInfo"
        #         Parsing error(s):
        #   -customid is required for the selected action.
        #   -username is required for the selected action.
        echo "Custom Id: "
        read customid
        echo "username: "
        read username
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "format", "inputfilepath", "logfilepath" , "phost","ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        #veracode-api -action GetUserInfo
        #
        ;; 
    'GetUserList')
        echo "GetUserList"
        veracode-api -action GetUserList
        #
        ;;
    'GetVendorList')
        echo "GetVendorList"
        veracode-api -action GetVendorList
        #
        ;; 
    'IsExpiring') # maybe add option to choose profile
        echo "IsExpiring"
        veracode-api -action IsExpiring
        #
        ;;
    # 'IsFeatureEnabled')
    #     echo "IsFeatureEnabled"
    #     veracode-api -action IsFeatureEnabled
    #     #?
    #     ;;  
    'PassFail')
        echo "PassFail"
        #
        #           -appname is required for the selected action.
        echo "App Name: "
        read appname
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser          -sandboxid
        #   -sandboxname
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser", "sandboxname")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        #veracode-api -action PassFail
        ;;
    'PromoteSandbox')
        echo "PromoteSandbox"
        #
        #         Parsing error(s):
        #   -buildid is required for the selected action.
        echo "Build Id: "
        read buildid
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format",  "inputfilepath", "logfilepath" , "phost","ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        # veracode-api -action PromoteSandbox
        ;; 
    'RemoveFile')
        echo "RemoveFile"
        veracode-api -action RemoveFile
        #         #
        #           -appid is required for the selected action.
        #   -fileid is required for the selected action.
        echo "App Id: "
        read appid
        echo "File Id:"
        read fileid
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser          -sandboxid
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;;
    'RescanDynamicScan')
        echo "RescanDynamicScan"
        #
        #           -appid is required for the selected action.
        echo "App Id: "
        read appid
        # The following parameters are optional for the selected action:
        #   -flawonly       -format         -inputfilepath  -logfilepath
        #   -phost          -ppassword      -pport          -puser
        #veracode-api -action RescanDynamicScan
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "flawonly", "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'SharedReport')
        echo "SharedReport"
        #
        #         Parsing error(s):
        # -appid is required for the selected action.
        # -outputfilepath is required for the selected action.
        # -sharedreportid is required for the selected action.
        echo "App Id: "
        read appid
        echo "Output File Path: "
        read outputfilepath
        echo "Shared Report Id: "
        read sharedreportid
        # The following parameters are optional for the selected action:
        # -format         -inputfilepath  -logfilepath    -phost
        # -ppassword      -pport          -puser
        #veracode-api -action SharedReport
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "format",  "inputfilepath", "phost" ,"logfilepath" ,"ppassword", "pport", "puser" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        
        ;;
    'SubmitDynamicScan')
        echo "SubmitDynamicScan"
        #
        #         -appid is required for the selected action.
        echo "App Id: "
        read appid
        # The following parameters are optional for the selected action:
        # -endtime        -format         -inputfilepath  -logfilepath
        # -phost          -ppassword      -pport          -puser
        # -starttime
        #veracode-api -action SubmitDynamicScan
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "endtime" , "format", "inputfilepath", "logfilepath", "phost" ,"ppassword", "pport", "puser", "starttime" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'SummaryReport')
        echo "SummaryReport"
        #
        #
        #         Parsing error(s):
        #   -buildid is required for the selected action.
        #   -outputfilepath is required for the selected action.
        echo "Build Id: "
        read buildid
        echo "Output File Path: "
        read outputfilepath
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format",  "inputfilepath", "logfilepath" , "phost","ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        #veracode-api -action SummaryReport
        ;;
    'SwitchToSaml')
        echo "SwitchToSaml"
        # Runs on all profiles in use
        veracode-api -action SwitchToSaml
        ;; 
    'ThirdPartyReport')
        echo "ThirdPartyReport"
        #
        #  -buildid is required for the selected action.
        #   -format is required for the selected action.
        #   -outputfilepath is required for the selected action.
        echo "build id: "
        read buildid 
        echo "format: "
        read format
        echo "outputfilepath: "
        read outputfilepath

        # The following parameters are optional for the selected action:
        #   -inputfilepath  -logfilepath    -phost          -ppassword
        #   -pport          -puser
        #veracode-api -action ThirdPartyReport
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "inputfilepath", "logfilepath" , "phost","ppassword", "pport", "puser")
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;;
    'UpdateApp')
        echo "UpdateApp"
        #
        echo "appid is required for the selected action."
        echo "App Id: "
        read appid
        # The following parameters are optional for the selected action:
        #   -appname                   -apptype
        #   -archerappname             -businessowner
        #   -businessowneremail        -businessunit
        #   -criticality               -customfieldname
        #   -customfieldvalue          -deploymenttype
        #   -description               -format
        #   -industry                  -inputfilepath
        #   -logfilepath               -nextdayschedulingenabled
        #   -origin                    -phost
        #   -policy                    -ppassword
        #   -pport                     -puser
        #   -tags                      -teams
        #veracode-api -action UpdateApp
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "appname", "apptype", "archerappname", "businessowner", "businessowneremail", "criticality", "customfieldname", "customfieldvalue", "deploymenttype", "description", "format", "industry", "inputfilepath", "logfilepath" , "nextdayschedulingisenabled", "origin", "policy" , "phost","ppassword", "pport", "puser",  "tags" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;; 
    'UpdateBuild')
        echo "UpdateBuild"
        #         #
        echo "appid is required for the selected action."
        echo "App Id: "
        read appid
        # The following parameters are optional for the selected action:
        #   -buildid         -format          -inputfilepath   -launchdate
        #   -lifecyclestage  -logfilepath     -phost           -ppassword
        #   -pport           -puser           -sandboxid       -version
        #veracode-api -action UpdateBuild
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "buildid",  "format", "includenewmodules", "inputfilepath", "lifecyclestage", "logfilepath" , "phost", "ppassword", "pport", "puser", "sandboxid", "version" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;;
    'UpdateMitigationInfo')
        echo "UpdateMitigationInfo"
        #
        #           -buildid is required for the selected action.
        #   -comment is required for the selected action.
        #   -flawidlist is required for the selected action.
        #   -mitigationaction is required for the selected action.
        echo "buildid"
        read buildid
        echo "comment"
        read comment
        echo "flawidlist"
        read flawidlist
        echo "mitigationaction"
        read mitigationaction
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "format","inputfilepath", "logfilepath" ,"ppassword", "pport", "puser" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        #veracode-api -action UpdateMitigationInfo
        ;; 
    'UpdateSandbox')
        echo "UpdateSandbox"
        #         #
        #           -customfieldname is required for the selected action.
        #   -customfieldvalue is required for the selected action.
        #   -sandboxid is required for the selected action.
        echo "Custom Field Name: "
        read customfieldname
        echo "Custom Field Value: "
        read customfieldvalue    
        echo "Sandbox Id: "
        read sandboxid
        # The following parameters are optional for the selected action:
        #   -autorecreate   -format         -inputfilepath  -logfilepath
        #   -phost          -ppassword      -pport          -puser
        #veracode-api -action UpdateSandbox
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "autorecreate", "format",  "inputfilepath", "logfilepath" , "phost" ,"ppassword", "pport", "puser" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -customfieldname $customfieldname -customvalue $customvalue -sandboxname $sandboxname $optargs
        ;;
    'UpdateTeam')
        echo "UpdateTeam"
        #
        #         Parsing error(s):
        #   -teamid is required for the selected action.
        echo "Team Id: "
        read teamid
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -members
        #   -phost          -ppassword      -pport          -puser
        #   -teamname
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=(  "format", "inputfilepath", "logfilepath" , "members", "phost","ppassword", "pport", "puser","teamname" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        #veracode-api -action UpdateTeam
        ;; 
    'UpdateUser')
        echo "UpdateUser"
        #
        #
        #         Parsing error(s):
        #   -customid is required for the selected action.
        #   -username is required for the selected action.
        echo "Custom Id: "
        read customid
        echo "Username: "
        read username

        # The following parameters are optional for the selected action:
        #   -custom1              -custom2              -custom3
        #   -custom4              -custom5              -elearningcurriculum
        #   -elearningmanager     -elearningtrack       -emailaddress
        #   -firstname            -format               -inputfilepath
        #   -iselearningmanager   -issamluser           -keepelearningactive
        #   -lastname             -logfilepath          -loginaccounttype
        #   -loginenabled         -newcustomid          -phone
        #   -phost                -ppassword            -pport
        #   -puser                -requirestoken        -roles
        #   -teams
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "custom1", "custom2", "custom3", "custom4", "custom5" ,"format", "inputfilepath","iselearningmanager", "issamluser", "keeplearningactive", "lastname", "logfilepath" ,"loginaccounttype", "loginenabled", "newcustomid", "phone", "ppassword", "pport", "puser", "requirestoken", "roles", "teams" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -customid $customid -username $username $optargs
        #veracode-api -action UpdateUser        
        ;; 
    'UploadAndScan')
        echo "UploadAndScan"
        #
        #           -appname is required for the selected action.
        #   -createprofile is required for the selected action.
        #   -filepath is required for the selected action.
        #   -version is required for the selected action.
        echo "App Name: "
        read appname
        echo "Create Profile: "
        read createprofile
        echo "filepath: "
        read filepath 

        # The following parameters are optional for the selected action:
        #   -autorecreate                    -autoscan
        #   -createsandbox                   -criticality
        #   -deleteincompletescan            -exclude
        #   -format                          -include
        #   -includenewmodules               -inputfilepath
        #   -logfilepath                     -maxretrycount
        #   -pattern                         -phost
        #   -ppassword                       -pport
        #   -puser                           -replacement
        #   -sandboxid                       -sandboxname
        #   -scanallnonfataltoplevelmodules  -scanpollinginterval
        #   -scantimeout                     -selected
        #   -selectedpreviously              -teams
        #   -toplevel
        #veracode-api -action UploadAndScan
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "autorecreate", "autoscan","createsandbox" , "criticality" , "deleteincompletescan",  "exclude" , "format", "include", "inputfilepath", "logfilepath","maxretrycount","pattern" ,"ppassword", "pport", "puser", "replacement", "sandboxid","sandboxname", "scanallnonfataltoplevelmodules" ,"scanpollinginterval", "scantimeout", "selected", "selectedpreviously","teams", "toplevel" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid $optargs
        ;;
    'UploadAndScanByAppId')
        echo "UploadAndScanByAppId"
        #
        #           -appid is required for the selected action.
        #   -filepath is required for the selected action.
        #   -version is required for the selected action.
        echo "App Id: "
        read appid 
        echo "File Path: "
        read filepath
        echo "Version: "
        read version

        # The following parameters are optional for the selected action:
        #   -autorecreate         -autoscan             -createsandbox
        #   -exclude              -format               -include
        #   -inputfilepath        -logfilepath          -pattern
        #   -phost                -ppassword            -pport
        #   -puser                -replacement          -sandboxid
        #   -sandboxname          -scanpollinginterval  -scantimeout
        #veracode-api -action UploadAndScanByAppId
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "autorecreate", "autoscan","createsandbox" , "exclude" , "format","include", "inputfilepath", "logfilepath","pattern" ,"ppassword", "pport", "puser", "replacement", "sandboxid","sandboxname", "scanpollinginterval" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid -filepath $filepath -version $version $optargs
        ;; 
    'UploadFile')
        echo "UploaqdFile"
        #
        #   -appid is required for the selected action.
        #   -filepath is required for the selected action.
        echo "App Id: "
        read appid
        echo "filepath: "
        read filepath
        # The following parameters are optional for the selected action:
        #   -format         -inputfilepath  -logfilepath    -phost
        #   -ppassword      -pport          -puser          -sandboxid
        #   -saveas
        #veracode-api -action UploadFile -appid "$appid" -filepath "$filepath"
        
        optargs=""    
        while true; do
    
            options_sub=("yes", "no")
            params_beginscan=( "format", "inputfilepath", "logfilepath" ,"ppassword", "pport", "puser", "sandboxid", "saveas" )
            select_option "${options_sub[@]}"
            choice_sub=$?
            echo "Choosen index = $choice_sub"
            echo "        value = ${options_sub[$choice_sub]}"
            if [[ "${options_sub[$choice_sub]}" == "yes"  ]]; then
                select_option "${param_beginscan[@]}"
                choice_param=$?
                echo "Enter a value to use the input, enter blank to leave the parameter unused"
                for param in "${!param_beginscan[@]}"; do
                    read -p "${param_beginscan[$param]}: " inputs_beginscan[$param]
                    echo "Your input: ${inputs_beginscan[$param]}"
                    if [[ -z "${inputs_beginscan[$param]}"]]; then
                        echo "[INFO]: input was blank"
                    else
                        optargs+="-${param_beginscan[$param]} ${inputs_beginscan[$param]}"
                    fi
                done
            else
                break
            fi
        done
        veracode-api -action ${options[$choice]} -appid $appid -filepath $filepath $optargs
        ;;
    *)
        echo "[Error] Unrecognized option... hmm how did that get there... "
        #
        veracode-api -help
        ;;
esac

