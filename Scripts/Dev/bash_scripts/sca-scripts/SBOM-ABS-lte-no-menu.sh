#!/bin/bash
shopt -s expand_aliases
# alias
alias 'veracode-http'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-signing:cmd'
workspaceGUID = "$1"
veracode-http "https://api.veracode.com/srcclr/v3/workspaces/$workspaceGUID/projects?type=agent"
projectGUID = "$2"
veracode-http "https://api.veracode.com/srcclr/sbom/v1/targets/$projectGUID/cyclonedx?type=agent