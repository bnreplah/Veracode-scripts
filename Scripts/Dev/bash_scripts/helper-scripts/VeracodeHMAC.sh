#!/bin/bash
# simple script to allow curl to make API hmac authenticated calls
# Author: Ben Halpern
# Inspired by the script created for DAST essentials
help(){
    
    echo "Usage $0 {API_ID} {API_KEY} {METHOD} {URI}"
}

API_ID=$VERACODE_API_KEY_ID
API_KEY=$VERACODE_API_KEY_SECRET

make_call(){
   
    # Todo change out the openssl library to use something
    NONCE="$(cat /dev/random | xxd -p | head -c 32)"

    TS="$(($(date +%s%N)/1000))"
    URLBASE="http://"
    METHOD=$3
    URLPATH=$4
    

    # Usage: $1: url/endpoint/path $2: method
    # ./API-http-REST.sh $API_API_ID $API_API_KEY GET /healthcheck

    encryptedNonce=$(echo "$NONCE" | xxd -r -p | openssl dgst -sha256 -mac HMAC -macopt hexkey:$API_KEY | cut -d ' ' -f 2)


    encryptedTimestamp=$(echo -n "$TS" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$encryptedNonce | cut -d ' ' -f 2)


    signingKey=$(echo -n "vcode_request_version_1" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$encryptedTimestamp | cut -d ' ' -f 2)


    DATA="id=$API_ID&host=api.veracode.com&url=$URLPATH&method=$METHOD"
    signature=$(echo -n "$DATA" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$signingKey | cut -d ' ' -f 2)
    API_AUTH_HEADER="VERACODE-HMAC-SHA-256 id=$API_ID,ts=$TS,nonce=$NONCE,sig=$signature"



   return (curl -X $METHOD -H "Authorization: $API_AUTH_HEADER" "$URLBASE$URLPATH")
}

make_call $1 $2 $3 $4 