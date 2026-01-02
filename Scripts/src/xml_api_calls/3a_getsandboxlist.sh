#!/bin/bash

export app_id==$1
echo "============================================================================================"
echo "Please Enter your Appliation ID Number: "
echo "aka... app_id== "
http --auth-type=veracode_hmac "https://analysiscenter.veracode.com/api/5.0/getsandboxlist.do" "app_id==$1" 
