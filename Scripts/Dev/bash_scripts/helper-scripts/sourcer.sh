#!/bin/bash

# testing function sourcing
test_sourcer(){
  echo "Testing, From Sourcer.sh"
}
source utils.sh
source selecter.sh
#source ./pager.sh

echo "Running Function from utils"
downloadPipelineScanner
echo "Running function from selecter"
test

#echo "Running function from pager" 