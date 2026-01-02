#!/bin/bash

test_modules(){
  echo "Testing, From Modules.sh"
}

echo "Loading Interactive Selecter Module"

source './InteractiveSelecter.sh'
echo "Loading Pager Module"
source './pager.sh'
echo "Loading Pipeline 2 Sarif Module"
source './Pipeline2Sarif.sh'
echo "Loading Utils Module"
source './utils.sh'

echo "Running Tests: "
test_pager
test_selecter
test_utils
