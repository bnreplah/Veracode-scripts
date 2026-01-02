#!/bin/bash


http --auth-type veracode_hmac "https://api.veracode.com/srcclr/v3/workspaces" -o .veracode-out/workspaces.json
cat .veracode-out/workspaces.json | jq -r ' ._embedded.workspaces[] | [ .id , .name , .site_id ] '