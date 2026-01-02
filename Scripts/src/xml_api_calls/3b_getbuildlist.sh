#!/bin/bash

export app_id=$1
export sandbox_id=$2
echo "Please Enter Application ID as well as Sandbox ID" 

http --auth-type=veracode_hmac "https://analysiscenter.veracode.com/api/5.0/getbuildlist.do" "app_id==$1" "sandbox_id==$2" 
