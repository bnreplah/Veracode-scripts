#!/bin/bash

export app_id==$1

http --auth-type=veracode_hmac "https://analysiscenter.veracode.com/api/5.0/getbuildlist.do" "app_id==$1"
