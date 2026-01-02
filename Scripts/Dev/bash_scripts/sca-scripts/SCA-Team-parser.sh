#!/bin/bash
shopt -s expand_aliases
# alias
alias 'veracode-http'='docker run -it --rm -v $PWD:/home/luser -v ~/.veracode/credentials:/home/luser/.veracode/credentials veracode/api-signing:cmd'
# How do I want to do this:
# The objective here is to be able tof identifiy some tag to them create a mapping of the teams to workspaces
# Or the projects to the teams then through that to the workspace, or some other identifier
