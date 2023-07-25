#!/bin/bash

echo "PURL lookup"
if [ -z $1 ]; then
	echo "Please enter a parameter"
	read purl
else

	purl=$1
fi
# Check to see if there is an argument is passed
if [ -n $purl ]; then
	echo "Input recieved" 
# else
# 	echo "Please enter a parameter"
# 	read purl
fi

if  [[ $( echo $purl | cut -d ':' -f1 ) == 'pkg' ]]; then	
	echo "====== PURL identified ======"
	echo $(echo $purl | cut -d ':' -f2 | cut -d '/' -f1) 
	if [ "$(echo $purl | cut -d ':' -f2 | cut -d '/' -f1)" == "maven" ]
	then
		echo "==== Maven detected ===="
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

