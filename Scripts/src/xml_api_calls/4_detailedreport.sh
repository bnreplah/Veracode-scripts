#!/bin/bash

#echo "This Script Generates Detailed Report For the Build-ID that you Provided."

export build_id=$1

http --auth-type=veracode_hmac "https://analysiscenter.veracode.com/api/5.0/detailedreport.do" "build_id==$1"
