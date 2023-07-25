#!/bin/bash
purl=$1


if  [ $( echo $1 | cut -d ':' -f1 ) == 'pkg' ]
then
	echo "PURL"
	type=$(echo $1 | cut -d ':' -f2 | cut -d '/' -f1) 
	namespace=$( echo $1 | cut -d ':' -f2 | cut -d '/' -f2)
	name=$( echo $1 | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f1)
	version=$( echo $1 | cut -d ':' -f2 | cut -d '/' -f3 | cut -d '@' -f2)
	vendor=$(echo $1 | cut -d ':' -f2 | cut -d '/' -f2 | cut -d '.' -f2)	
	echo "cpe:2.3:a:"$vendor":"$name":"$version":*:*:*:*:*:*:*"
	echo "cpa:/a:"$vendor":"$name":"$version  
	srcclr lookup --coord1 $namespace --coord2 $name --type $type --version $version --json
else
	type=$2
	echo "CPE"
	namespace=$(echo $1 | cut -d ':' -f4)
	name=$(echo $1 | cut -d ':' -f5)
	version=$(echo $1 |cut -d ':' -f6)
	srcclr lookup --coord1 $namespace --coord2 $name --type $type --version $version --json

fi

echo $type
echo $namespace
echo $name
echo $version

#srcclr lookup --coord1 $namespace --coord2 $name --type $type --version $version --json
