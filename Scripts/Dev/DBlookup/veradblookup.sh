function help { 
    echo "veradbLookup -h : Help";
    echo "veradblookup --namespace <Module/groupId> --type <Package Manager> --version <Library Version>";
    echo "veradblookup --namespace <Module/GroupId> --type maven --artifactid <ArtifactID>  --version <Library Version>";
    echo "veradblookup <PURL>";
    echo "veradblookup <CPE> <Package Manager>";
    echo "Supported package managers:";
    echo "gem, maven, npm, pypi, cocoapods, go, packagist";
}

if [ $1 ]
then
    if [ $1 == "-h" ]; then
        help
    fi

    echo "Veracode Database Lookup"

    if [ $1 == "--namespace" ]; then
        if [ $3 == "--type" ]; then
            if [ $4 == "maven" ]; then
            case "$5" in 
                --artifactid)
                    srcclr lookup --coord1 $2 --coord2 $4 --type $6 --version $8 --json 
                    ;;
                --version)
                    srcclr lookup --coord1 $2 --type $4 --version $6 --json
                    ;;
                *)
                    echo "Error: Missing artifactid, expected Maven Artifact Id"
                    ;;
            esac
            else
                srcclr lookup --coord1 $2 --type $4 --version $6 --json
            fi
        fi
    elif  [ $( echo $1 | cut -d ':' -f1 ) == 'pkg' ];
    then
        echo "--PURL--"
        #type=
        #$(echo $1 | cut -d ':' -f2 | cut -d '/' -f1) 
        #namespace=
        #$( echo $1 | cut -d ':' -f2 | cut -d '/' -f2)
        #name=
        #$( echo $1 | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f1)
        #version=
        #$( echo $1 | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f2)
        #vendor=
        #$(echo $1 | cut -d ':' -f2 | cut -d '/' -f2 | cut -d '.' -f2)	
        echo "cpe:2.3:a:"$(echo $1 | cut -d ':' -f2 | cut -d '/' -f2 | cut -d '.' -f2)":"$( echo $1 | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f1)":"$( echo $1 | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f2)":*:*:*:*:*:*:*"
        echo "cpa:/a:"$(echo $1 | cut -d ':' -f2 | cut -d '/' -f2 | cut -d '.' -f2)":"$( echo $1 | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f1)":"$( echo $1 | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f2)  
        srcclr lookup --coord1 $( echo $1 | cut -d ':' -f2 | cut -d '/' -f2) --coord2 $( echo $1 | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f1) --type $(echo $1 | cut -d ':' -f2 | cut -d '/' -f1) --version $( echo $1 | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f2) --json
    elif [$( echo $1 | cut -d ':' -f1 ) == 'CPE'];
    then
        # TODO: differentiate between CPE versions
        type=$2
        echo "--CPE--"
        #namespace=$(echo $1 | cut -d ':' -f4)
        #name=$(echo $1 | cut -d ':' -f5)
        #version=$(echo $1 |cut -d ':' -f6)
        srcclr lookup --coord1 $(echo $1 | cut -d ':' -f4) --coord2 $(echo $1 | cut -d ':' -f5) --type $type --version $(echo $1 |cut -d ':' -f6) --json
    else
        echo "veradbLookup -h : Help"
        echo "veradblookup --namespace <Module/groupId> --type <Package Manager> --version <Library Version>"   
        echo "veradblookup --namespace <Module/GroupId> --type maven --artifactid <ArtifactID>  --version <Library Version>"
        echo "veradblookup <PURL>"
        echo "veradblookup <CPE> <Package Manager>"
        echo "Supported package managers:"
        echo "gem, maven, npm, pypi, cocoapods, go, packagist"
    fi
else
    echo "veradbLookup -h : Help"
    echo "veradblookup --namespace <Module/groupId> --type <Package Manager> --version <Library Version>"
    echo "veradblookup --namespace <Module/GroupId> --type maven --artifactid <ArtifactID>  --version <Library Version>"
    echo "veradblookup <PURL>"
    echo "veradblookup <CPE> <Package Manager>"
    echo "Supported package managers:"
    echo "gem, maven, npm, pypi, cocoapods, go, packagist"
fi