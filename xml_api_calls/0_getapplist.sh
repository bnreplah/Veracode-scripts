#!/bin/bash

# export appId=$1

http --auth-type=veracode_hmac "https://analysiscenter.veracode.com/api/5.0/getapplist.do" 
