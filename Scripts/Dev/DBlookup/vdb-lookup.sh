if [ -z $1 ]
then

    if [ $1 == "-h" ];
    then

        echo "veradbLookup -h : Help"
        echo "veradblookup --namespace <Module/groupId> --type <Package Manager> --version <Library Version>"
        echo "veradblookup --namespace <Module/GroupId> --type maven --artifactid <ArtifactID>  --version <Library Version>"
        # echo "veradblookup <PURL>"
        # echo "veradblookup <CPE> <Package Manager>"
        echo "Supported package managers:"
        echo "gem, maven, npm, pypi, cocoapods, go, packagist"
    fi


