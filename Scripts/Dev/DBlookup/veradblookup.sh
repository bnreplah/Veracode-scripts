#!/bin/bash

versioninfo="v2.0.1"
verbose=true
clearprompt=true

function versioninfo {
    echo "--------------------------------------------"
    echo "Version:" $versioninfo
    echo "Author: Ben Halpern - CSE "
    echo "License information found: https://github.com/bnreplah/Veracode-scripts/blob/main/LICENSE"
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
    echo ""
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
    echo "veradblookup -r <CPE> <Package Manager/Type> [Experimental]";
    echo "veradblookup -r <ref> [Experimental]";


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
 #       if [  -n $platform ] && [ "$platform" != " "  && "$platform" != "\n"]; then
 #           echo "srcclr lookup --coord1 "$namespace" --coord2 "$artifactid" --type "$collector" --platform "$platform" --version "$version" --json"
 #           srcclr lookup --coord1 $namespace --coord2 $artifactid --type $collector --platform $platform --version $version --json
 #       else
           echo "srcclr lookup --type="$collector" --coord1="$namespace" --coord2="$artifactid"  --version="$version" --json"
           srcclr lookup --type=$collector --coord1=$namespace --coord2=$artifactid --version=$version --json
 #       fi
    elif [ "$collector" == "gem" || "$collector" == "npm" || "$collector" == "pypi" || "$collector" == "cocoapods" || "$collector" == "go" || "$collector" == "packagist" ]; then
        echo "$collector detected "
        echo "-----------------------------------------------------------------------------"
        echo "GroupID or Module: $namespace "
        echo "Type: $collector"
        echo "Version: $version"

#        if [ -n $platform ]; then
#           echo "srcclr lookup --coord1 "$namespace" --coord2 "$artifactid" --type "$collector" --version "$version" --json"
#           srcclr lookup --json --coord1 $namespace --type $collector --platform $platform --version $version
#        else
           echo "srcclr lookup --json --coord1="$namespace" --type="$collector" --version=" $version
           srcclr lookup --json --type=$collector --coord1=$namespace --version=$version
#        fi
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
#                if [ -n $platform ] && [ "$platform" != " " ]; then
#                   echo "srcclr lookup --type $type --coord1 $namespace --coord2 $artifactid --platform $platform --version $version --json";
#                    srcclr lookup --type $type --coord1 $namespace --coord2 $artifactid --version $version --platform $platform --json;
#                else
                    echo "srcclr lookup --type $type --coord1 $namespace --coord2 $artifactid --version $version --json";
                    srcclr lookup --type $type --coord1 $namespace --coord2 $artifactid --version $version --json;
#                fi
            else
                echo "[ERROR] Artifact ID is required with the type maven"
                help
            fi
        elif [ -n $type ] && [ "$type" == "gem" || "$type" == "npm" || "$type" == "pypi" || "$type" == "cocoapods" || "$type" == "go" || "$type" == "packagist" ]; then
            if [ -n $artifactid ]; then
#                if [ -n $platform ]  && [ "$platform" != " " ]; then
#                   echo "srcclr lookup --type $type --coord1 $namespace --coord2 $artifactid --platform $platform --version $version --json";
#                    srcclr lookup --type $type --coord1 $namespace --coord2 $artifactid --version $version --platform $platform --json;
#                else
                    echo "srcclr lookup --type $type --coord1 $namespace --coord2 $artifactid --version $version --json";
                    srcclr lookup --type $type --coord1 $namespace --coord2 $artifactid --version $version --json;
#                fi
            else
                echo "srcclr lookup --type $type --coord1 $namespace --version $version --json";
                srcclr lookup --type $type --coord1 $namespace --version $version --json;
            fi
        else

            echo "[ERROR]: provide a supported type";
        fi
    fi

elif [ "$1" == "-r" ]; then

        echo "PURL lookup mode"
        if [ -z $2 ]; then
                echo "Please enter a parameter"
                read purl
        else

                purl=$2
        fi
        # Check to see if there is an argument is passed
        if [ -n $purl ] && [ "$verbose" == "true" ]; then
                echo "Input recieved";
        # else
        #       echo "Please enter a parameter"
        #       read purl
        fi

        if  [[ $( echo $purl | cut -d ':' -f1 ) == 'pkg' ]]; then
                echo "PURL identified "
                echo "-----------------------------------------------------------------------------"
                echo $(echo $purl | cut -d ':' -f2 | cut -d '/' -f1)
                if [ "$(echo $purl | cut -d ':' -f2 | cut -d '/' -f1)" == "maven" ]
                then
                        echo "Maven detected"
                        echo "-----------------------------------------------------------------------------"
                        echo "GroupID or Module: $( echo $purl | cut -d ':' -f2 | cut -d '/' -f2) "
                        echo "ArtifactID: $( echo $purl | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f1)"
                        echo "Type: $(echo $purl | cut -d ':' -f2 | cut -d '/' -f1)"
                        echo "Version: $( echo $purl |  cut -d '@' -f2)"

                        srcclr lookup --coord1 $( echo $purl | cut -d ':' -f2 | cut -d '/' -f2) --coord2 $( echo $purl | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f1) --type $(echo $purl | cut -d ':' -f2 | cut -d '/' -f1) --version $( echo $purl |  cut -d '@' -f2) --json=./SCALookup-Out.json
                else
                        echo "===== $(echo $purl | cut -d ':' -f2 | cut -d '/' -f1) detected ===== "
                        echo "GroupID or Module: $( echo $purl | cut -d ':' -f2 | cut -d '/' -f2 | cut -d '@' -f1) "
                        echo "Type: $(echo $purl | cut -d ':' -f2 | cut -d '/' -f1)"
                        echo "Version: $( echo $purl | cut -d '@' -f2)"

                        srcclr lookup --json --coord1 $( echo $purl | cut -d ':' -f2 | cut -d '/' -f2 | cut -d '@' -f1) --type  $(echo $purl | cut -d ':' -f2 | cut -d '/' -f1) --version $( echo $purl | cut -d '@' -f2)
                fi
        elif [ -n $2 ]
        then
                srcclr lookup --coord1 $1 --coord2 $2 --type $3 --version $4 --json=$5

        else
                echo "Error: PURL expected"
        fi


fi