#!/bin/bash
# simple script to allow curl to make veracode hmac authenticated calls
# Author: Ben Halpern
# Inspired by the script created for DAST essentials
VERACODE_ID=$1
VERACODE_KEY=$2
# Todo change out the openssl library to use something
NONCE="$(cat /dev/random | xxd -p | head -c 32)"

TS="$(($(date +%s%N)/1000))"
URLBASE="https://api.veracode.com"
URLPATH=$4
METHOD=$3

# Usage: $1: url/endpoint/path $2: method
# ./veracode-http-REST.sh /healthcheck GET

encryptedNonce=$(echo "$NONCE" | xxd -r -p | openssl dgst -sha256 -mac HMAC -macopt hexkey:$VERACODE_KEY | cut -d ' ' -f 2)


encryptedTimestamp=$(echo -n "$TS" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$encryptedNonce | cut -d ' ' -f 2)


signingKey=$(echo -n "vcode_request_version_1" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$encryptedTimestamp | cut -d ' ' -f 2)


DATA="id=$VERACODE_ID&host=api.veracode.com&url=$URLPATH&method=$METHOD"
signature=$(echo -n "$DATA" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$signingKey | cut -d ' ' -f 2)
VERACODE_AUTH_HEADER="VERACODE-HMAC-SHA-256 id=$VERACODE_ID,ts=$TS,nonce=$NONCE,sig=$signature"



curl -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" "$URLBASE$URLPATH"
