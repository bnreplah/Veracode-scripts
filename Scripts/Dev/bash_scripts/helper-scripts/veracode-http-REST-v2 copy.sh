#!/bin/bash
# simple script to allow curl to make veracode hmac authenticated calls
# Author: Ben Halpern
# Inspired by the script created for DAST essentials

# Usage: $1: url/endpoint/path $2: method
# ./veracode-http-REST.sh /healthcheck GET


URLBASE="https://api.veracode.com"
URLPATH=$2
METHOD=$1


http --auth-type veracode_hmac $METHOD "$URLBASE$URLPATH" ""