#!/bin/bash


help(){
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "Tool to list out the Dynamic analyses with/without teams"
        echo "Available parameters:"
        echo "----------------------------------------------------------"
        echo "--file    <outfile> "
        echo "--outDir  <outdir>  Default: .veracode-tmp "
        echo "--verbose           Default: False "
        echo "--withTeams         Default: False "
        echo "--listTeams         Default: False "

}


if [ -z $1 ]; then
        echo "No args"
        help
        exit 1
fi

#IFS=$'\n'
out_file="out.txt"
out_dir=".veracode-tmp"
verbose=0
with_teams=0
#list_teams=0
#team_leg_ids=()
#team_names=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --file)
            out_file="$2"
            shift 2
            ;;
        --outDir)
            out_dir="$2"
            shift 2
            ;;
        --verbose)
            verbose=1
            shift 1
            ;;
        --withTeams)
            with_teams=1
            shift 1
            ;;
        --listTeams)
            list_teams=1
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
    cd $out_dir
else
    mkdir $out_dir
    cd $out_dir
fi

if [ $verbose -gt 0  ];then
        pwd
        echo "Out Dir: $out_dir"
        echo "Out File: $out_file"
        echo "Throttled: True"
        echo "List Teams: $list_teams"
        echo "With Teams: $with_teams"
fi

#if [ $list_teams -gt 0 ]; then
#       http --auth-type=veracode_hmac --json -o teams.json "https://api.veracode.com/api/authn/v2/teams"
#       teams_leg_ids=($(cat teams.json | jq -r '._embedded.teams[].team_legacy_id'))
#       teams_names=($(cat teams.json | jq -r '._embedded.teams[].name'))
#fi

http --auth-type=veracode_hmac --json -o Analyses.json https://api.veracode.com/was/configservice/v1/analyses

analyses_ids=($(jq -r '._embedded.analyses[].analysis_id' Analyses.json ))

echo ""
for id in "${analyses_ids[@]}"; do
    http --auth-type=veracode_hmac --json -o "$id.json" "https://api.veracode.com/was/configservice/v1/analyses/$id"
    #comment out the sleep to disable throttling protection
    sleep 1
done

echo "" > $out_file
for id in "${analyses_ids[@]}"; do
    #if [ $list_teams -gt 0 ];then
    #    jq -r '.visibility.team_identifiers[]' $id.json
    #fi

    if [ $with_teams -gt 0 ]; then
        if [ "$( jq -e '.visibility.team_identifiers | if length > 0 then true else false end' $id.json )" == "true" ]; then
            team_identifiers=($( jq -r '.visibility.team_identifiers[]' $id.json ))
            if [ $verbose -gt 0 ]; then
                echo "$id has teams"
            fi

            if [ $list_teams -gt 0  ]; then
                echo "Listing Teams:"
                echo "${team_identifiers[@]}"
           fi
            name=$( jq -r '.name' $id.json)
            echo "$name::$id" >> $out_file
        fi
    else
        if [ $list_teams -gt 0 ];then
           jq -r '.visibility.team_identifiers[]' $id.json
        fi

        if [ "$( jq -e '.visibility.team_identifiers | if length == 0 then true else false end' $id.json )" == "true" ]; then
            #uncomment the following line if you want it to print each analysis id that didn't have a team otherwise they will be shown at the end
            if [ $verbose -gt 0 ]; then
                echo "$id has no teams"
            fi
            name=$( jq -r '.name' $id.json )
            echo "$name::$id" >> $out_file
        fi
    fi

done

if [ $with_teams -gt 0 ]; then

        echo "See $out_dir/$out_file for the list of Analysis IDs with team assignments"

else

        echo "See $out_dir/$out_file for the list of Analysis IDs without team assignments"

fi

if [ $verbose -gt 0 ]; then

    cat $out_file

fi